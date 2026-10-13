/**
* @author ULiT
* @date 25-09-2024
* @description Component to handle Creating/Editing the import settings of screens, as well as the use of those import settings to import excel files.
*******************************************************************************************************************************************
*/
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { labels } from './properties.js';
import xlsxLib from '@salesforce/resourceUrl/xlsxLib';
import ExcelJSURL from '@salesforce/resourceUrl/ExcelJS';
//APEX
import loadImportSettings from '@salesforce/apex/ImportSettingsController.loadImportSettings';
import uploadFile from '@salesforce/apex/ImportSettingsController.uploadFile';
export default class ImportSettings extends LightningElement {
    @api objectName;
    @api importSettingsName;
    @api reminderMsg;
    @api recordId;
    @api recordExtId;
    @api lookupName;
    @track loadingData = false;
    @track isAdvancedMode = false;
    @track fieldsToImport = [];
    @track externalIdField = '';
    @track fieldOptions = {};
    @track picklistOptions = {};
    @track importSettings = {};
    @track loadStartLine = 2;
    @track sheetNumber = 1;
    acceptedFormats = ['.xls', '.xlsx'];
    @track labels = labels;
    @track reReadFile = false;
    @track WireVariables = {
        wireObjectInfo: false,
        wirePicklistValues: false,
        importSettingsLoaded: false
    }
    data = {};
    prefix = '';

    get defaultValueFieldsList() {
        return this.fieldsToImport.filter(f => f.allowDefaultValue);
    }
    //LIFECYCLE
    connectedCallback() {
        console.log('recordExtId >>>>>>>>>>>>>>>>> ' + this.recordExtId)
        this.loadingData = true;
        this._loadImportSettingsTemplate();
        loadScript(this, ExcelJSURL).then(() => {
            console.log('Excel JS Loaded');
        }).catch(error => {
            console.log(error.message);
            console.log(error.body?.message);
        });
        loadScript(this, xlsxLib + '/js-xlsx-master/dist/jszip.js').then(() => {
            loadScript(this, xlsxLib + '/js-xlsx-master/dist/xlsx.js').then(() => {
                console.log('loaded')
            }).catch(error => {
                console.log(error.message);
                console.log(error.body?.message);
            });
        }).catch(error => {
            console.log(error.message);
            console.log(error.body?.message);
        });
    }
    // WIRES
    @wire(getObjectInfo, { objectApiName: '$objectName' }) objectInfo({ error, data }) {
        if (data) {
            let fieldOptions = {};
            for (let fieldKey of Object.keys(data.fields)) {
                let field = data.fields[fieldKey];
                fieldOptions[field.apiName] = field;
            }
            this.fieldOptions = fieldOptions;
            this.WireVariables.wireObjectInfo = true;
            this.init();
        } else if (error) {
            console.log('ERROR');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: '$objectName', recordTypeId: '012000000000000AAA' }) picklistValues({ error, data }) {
        if (data) {
            this.picklistOptions = data.picklistFieldValues;
            this.WireVariables.wirePicklistValues = true;
            this.init();
            console.log('this.picklistOptions >>> ' + JSON.stringify(this.picklistOptions))
        } else if (error) {
            console.log('ERROR');
        }
    }

    init() {
        if (Object.values(this.WireVariables).every(it => it)) {
            this._processFields();
        }
    }

    // Phase 1: load the template from Apex, derive objectName, then let wires react.
    _loadImportSettingsTemplate() {
        loadImportSettings({ importSettingsName: this.importSettingsName }).then((result) => {
            let parsedResult = JSON.parse(result);
            this.importSettings = JSON.parse(parsedResult.importSettingsJSON);
            console.log("this.importSettings >>>", JSON.stringify(this.importSettings));
            this.prefix = parsedResult.prefix;
            const isAdmin = parsedResult.isAdmin;
            this.fieldsToImport = this.importSettings.fields.filter(field => isAdmin ? field.isAdmin : field.isUser);
            this.separator = this.importSettings.extIdSeparator;
            this.externalIdField = this.importSettings.externalIdField;
            this.loadStartLine = this.importSettings.defaultLoadStartLine ? this.importSettings.defaultLoadStartLine : this.loadStartLine;
            this.sheetNumber = this.importSettings.defaultSheetNumber ? this.importSettings.defaultSheetNumber : this.sheetNumber;
            // Always derive objectName from the template.
            // Assigning it here makes the @wire adapters reactive and triggers them to fire.
            this.objectName = this.importSettings.objectName;
            this.WireVariables.importSettingsLoaded = true;
            this.init();
        }).catch(error => {
            console.error(error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.loadingData = false;
        });
    }

    // Phase 2: enrich fieldsToImport with wire-provided field metadata (labels, types, picklists).
    // Only called once both @wire adapters AND the template Apex call have all completed.
    _processFields() {
        try {
            this.fieldsToImport.forEach((field) => {
                if (field.name && this.fieldOptions[field.name]) {
                    const meta = this.fieldOptions[field.name];
                    field.label = meta.label;
                    field.fieldType = meta.dataType;
                    if (field.fieldType === 'Reference') {
                        field.refObject = meta.referenceToInfos[0].apiName;
                    }
                    if (field.fieldType === 'Picklist' || field.fieldType === 'Multipicklist') {
                        field.picklistOptions = this.picklistOptions[field.name]
                            ? this.picklistOptions[field.name].values.map(({ label, value }) => ({ label, value }))
                            : [];
                    }
                    // Type flags drive which default-value input renders
                    field.isPicklist = field.fieldType === 'Picklist' || field.fieldType === 'Multipicklist';
                    field.isCheckbox = field.fieldType === 'Boolean';
                    field.isReference = field.fieldType === 'Reference';
                    field.isDate = field.fieldType === 'Date';
                    field.isDateTime = field.fieldType === 'DateTime';
                    field.isTextarea = field.fieldType == 'Textarea',
                        field.isNumberField = ['Double', 'Currency', 'Int', 'Percent'].includes(field.fieldType);
                }
            });
            this.loadingData = false;
        } catch (error) {
            console.error(error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.loadingData = false;
        }
    }

    handleDefaultValueChange(event) {
        const fieldName = event.target.dataset.field;
        const field = this.fieldsToImport.find(f => f.name === fieldName);
        if (!field) return;
        let value = event.detail == null
            ? (event.target.value == null ? event.target.checked : event.target.value)
            : (event.detail.value == null ? event.detail.checked : event.detail.value);
        value = (Array.isArray(value) ? value[0] : value) || null;
        field.defaultValue = value;
        this.reReadFile = true;
    }

    handleChangeColumnNumber(event) {
        let index = event.target.dataset.index;
        this.fieldsToImport[index].columnName = event.target.value;
        this.fieldsToImport[index].columnIndex = this.getColumnIndex(event.target.value);
        this.reReadFile = true;
    }

    handleChangeLoadStartLine(event) {
        this.loadStartLine = event.target.value;
        this.reReadFile = true;
    }

    handleChangeSheetNumber(event) {
        this.sheetNumber = event.target.value;
        this.reReadFile = true;
    }

    file;
    mustIncludeField = false;
    importExcel(event) {
        try {
            var files = event.target.files;
            this.file = files[0];
            this.noDataToProcess = !this.file;
            if (this.file) {
                this.readFile();
            }
        } catch (error) {
            console.log('Error' + '%c' + (error.message ? error.message : error.body?.message));
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    preparedData = {
        importedRecords: {},
        fileData: {},
        atLeastOneRowhavingMissingMandatoryValue: false,
    }

    readFile() {
        try {
            console.log("Readdddd >>> " + this.recordExtId);
            if (this.file) {
                let self = this;
                self.loadingData = true;
                let columnsMap = {};
                //if (!this.isAdvancedMode) {
                this.fieldsToImport.forEach((item, index) => {
                    //item.columnIndex = index;
                    item.columnName = item.defaultColumn || this.getExcelColumnName(index);
                    item.columnIndex = this.getColumnIndex(item.columnName);
                })
                //}
                this.fieldsToImport.filter(item => item.columnIndex != null && item.columnIndex !== '')?.forEach(item => {
                    columnsMap[item.columnIndex] = item;
                });
                // console.log("columnsMap", JSON.stringify(columnsMap))
                let importedRecords = {};
                let fileData = {};
                //SET-UP EXTERNAL ID LIST
                let extIdFields = this.fieldsToImport.filter(field => field.isRequired).sort((a, b) => a.referenceExtIdOrder - b.referenceExtIdOrder);
                let fileReader = new FileReader();
                fileReader.onload = () => {
                    try {
                        let binaryStr = fileReader.result;
                        let workbook = XLSX.read(binaryStr, { type: 'binary' });
                        let sheetName = Object.keys(workbook.Sheets).length >= this.sheetNumber ? Object.keys(workbook.Sheets)[this.sheetNumber - 1] : Object.keys(workbook.Sheets)[0];
                        console.log('sheetName >>> ' + sheetName);
                        //let sheetName = workbook.SheetNames[this.sheetNumber];
                        let sheetRows = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], { header: 1, raw: true });
                        console.log('sheetRowss>>>> ' + JSON.stringify(sheetRows));
                        //REMOVE ALL sheetRows BEFORE THE LOAD START TIME
                        sheetRows.splice(0, this.loadStartLine - 1);
                        let recIndex = 0;
                        let atLeastOneRowhavingMissingMandatoryValue = false;
                        for (let index = 0; index < sheetRows.length; index++) {
                            let isMissingMandatoryValue = false;
                            let row = sheetRows[index];
                            console.log('row>>>> ' + JSON.stringify(row));
                            console.log("recIndex >>> " + recIndex);
                            if (row && row.length > 0) {
                                let record = {
                                    attributes: {
                                        type: self.objectName,
                                    }
                                };
                                //BUILD FIELDS TO IMPORT
                                try {
                                    console.log('columnsMap>>>>>>>>>> ' +  JSON.stringify(columnsMap));
                                    for (const [columnIndex, field] of Object.entries(columnsMap)) {
                                        const hasDefault = field.allowDefaultValue && field.defaultValue !== '' && field.defaultValue !== null && field.defaultValue !== undefined;
                                        if (hasDefault) {
                                            record[field.name] = field.defaultValue;
                                            continue;
                                        }
                                        if ((row[columnIndex] == null || row[columnIndex] == undefined || row[columnIndex] == '' || row[columnIndex] == 'undefined') && field.isMandatory == true) {
                                            isMissingMandatoryValue = true;
                                            break;
                                        }
                                        if (row[columnIndex] !== undefined) {
                                            let value = row[columnIndex];
                                            if (field.fieldType == 'Date') {
                                                let currentDate = this.excelDateToJSDate(value);
                                                console.log('current Date is: ' + typeof value);
                                                console.log('current Date is: ' + value);
                                                console.log('current Date is: ' + currentDate);
                                                value = currentDate.getFullYear() + '-' + (currentDate.getMonth() + 1) + '-' + currentDate.getDate();
                                            } else if (field.fieldType == 'Boolean') {
                                                let currentVal = String(value);
                                                if (currentVal == '✓' || currentVal.toLowerCase() == 'true' || currentVal == '1' || currentVal.toLowerCase() == 'yes' || currentVal.toLowerCase() == 'y') {
                                                    value = 'true';
                                                } else if (currentVal == '✗' || currentVal.toLowerCase() == 'false' || currentVal == '0' || currentVal.toLowerCase() == 'no' || currentVal.toLowerCase() == 'n') {
                                                    value = 'false';
                                                }
                                            } else if (field.fieldType == 'Percent') {
                                                value = value ? value * 100 : null;
                                            } else if (field.fieldType == 'Reference' && field.referenceExtId != 'Id') {
                                                field.name = field.name.replace(/__c$/, '__r').replace(/Id$/, '');
                                                value = {
                                                    attributes: {
                                                        type: field.refObject,
                                                    }
                                                };
                                                value[field.referenceExtId ? field.referenceExtId : 'ExtId__c'] = row[columnIndex];
                                            } else if (field.fieldType == 'Picklist') {
                                                let currentVal = String(value);
                                                value = field.picklistOptions.find(item => item.label.toLowerCase() == currentVal.toLowerCase() || item.value.toLowerCase() == currentVal.toLowerCase())?.value;
                                            } else if (field.fieldType == 'Multipicklist') {
                                                if (value && value.length) {
                                                    value = field.value.map(val => {
                                                        val = val.trim();
                                                        return field.picklistOptions.find(item => item.label == val || item.value == val)?.value;
                                                    }).join(';');
                                                }
                                            }
                                            record[field.name] = value;
                                        }
                                    }
                                    console.log('TEST_TEST111 >>> ' + JSON.stringify(record))
                                    const recordHasData = Object.keys(record).some(key => {
                                        if (key === 'attributes') return false;
                                        const val = record[key];
                                        return val !== null && val !== undefined && String(val).trim() !== '';
                                    });
                                    console.log('recordHasData >>> ' + recordHasData)
                                    if (isMissingMandatoryValue == true) {
                                        if (atLeastOneRowhavingMissingMandatoryValue == false) {
                                            atLeastOneRowhavingMissingMandatoryValue = true;
                                        }
                                        continue;
                                    }
                                    if (!recordHasData) continue;
                                    // console.log("TEST_TEST", JSON.stringify(row))
                                    let ExtIdList = [];
                                    extIdFields.forEach(field => {
                                        if (field.allowDefaultValue) {
                                            ExtIdList.push(field.defaultValue);
                                        } else if (row[field.columnIndex] && row[field.columnIndex] != '' && row[field.columnIndex] != undefined) {
                                            ExtIdList.push(row[field.columnIndex]);
                                        }
                                    });
                                    console.log("ExtIdList.length >>> " + ExtIdList.length);
                                    // if (ExtIdList.length == 0) {
                                    //     continue;
                                    // }
                                    //BUILD EXTERNAL ID                                  
                                    let separator = this.separator === 'No separator' ? '' : (this.separator === 'Space' ? ' ' : this.separator);
                                    // console.log('TEST_TEST11111 >>> ' + (record[this.prefix + 'ExtId__c']));
                                    if (this.externalIdField && extIdFields.length > 0) {
                                        record[this.externalIdField] = ExtIdList.join(separator)?.slice(0, 80);

                                    }
                                    // Priority: recordIdLookupField configured in importSettingsManager > lookupName passed to component
                                    const effectiveLookup = (this.importSettings.recordIdLookupField || '').trim() || this.lookupName;
                                    if (this.recordId != undefined && effectiveLookup != undefined) {
                                        let lookupAlreadyImported = this.fieldsToImport.some(field => field.name === effectiveLookup);
                                        if (!lookupAlreadyImported) {
                                            record[effectiveLookup] = this.recordId;
                                            if (this.externalIdField && extIdFields.length > 0) {
                                                record[this.externalIdField] += separator + (this.recordExtId != undefined && this.recordExtId != '' ? this.recordExtId : this.recordId);
                                            }
                                        }
                                    }
                                    if (this.externalIdField && extIdFields.length > 0) {
                                        importedRecords[record[this.externalIdField]] = record;
                                    } else {
                                        importedRecords[recIndex] = record;
                                    }
                                    recIndex++;
                                } catch (error) {
                                    console.log('Error: %c' + (error && error.body ? error.body.message : error), 'color : red');
                                    this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
                                }
                            }
                        }
                        const base64 = window.btoa(binaryStr);
                        fileData = {
                            fileName: self.file.name,
                            base64: base64,
                            fileType: self.file.type
                        };
                        self.preparedData = {
                            importedRecords: importedRecords,
                            fileData: fileData,
                            atLeastOneRowhavingMissingMandatoryValue: atLeastOneRowhavingMissingMandatoryValue,
                        }
                        self.loadingData = false;
                        console.log('TEST_TEST44444 >>> ' + JSON.stringify(importedRecords))
                    } catch (err) {
                        console.log('Error' + '%c' + (err.message ? err.message : err.body?.message));
                        this.showNotification(this.labels.LBL_Error, err.message ? err.message : err.body?.message, 'error', 'sticky');
                        self.loadingData = false;
                    }
                };
                fileReader.readAsBinaryString(this.file);
            } else {
                this.showNotification(this.labels.LBL_Error, 'No Selected File', 'error', 'sticky');
            }
        } catch (error) {
            console.log('Error' + '%c' + (error.message ? error.message : error.body?.message));
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    @api
    prepareFile() {
        let self = this;
        if (this.reReadFile) {
            this.readFile();
        }
        // //TO REPLACE WITH APEX CALLING DIRECTLY (NO NEED FOR HANDLING IN PARENT COMPONENT)
        self.uploadFile(self.preparedData.fileData).then(result => {
            self.dispatchEvent(new CustomEvent('getfileid', {
                detail: {
                    fileDirectoryId: result
                }
            }));
            self.dispatchEvent(new CustomEvent('uploadexcel', {
                    detail: {
                    value: JSON.stringify(Object.values(self.preparedData.importedRecords)),
                    fileData: self.preparedData.fileData,
                    }
                }));
            if (self.preparedData.atLeastOneRowhavingMissingMandatoryValue) {
                self.showNotification(self.labels.LBL_Error, self.labels.MSG_ImportSettings_MandatoryFields, 'error', 'sticky');
            }
            self.loadingData = false;
        }).catch(err => {
            self.showNotification(self.labels.LBL_Error, err.body?.message || err.message, 'error', 'sticky')
            self.loadingData = false;
        });
    }

    uploadFile(fileData) {
        return uploadFile({
            parentId: this.recordId,
            fileName: fileData.fileName,
            base64Data: fileData.base64,
            fileType: fileData.fileType
        });
    }

    excelDateToJSDate(excelDate) {
        const baseDate = new Date(Date.UTC(1899, 11, 30)); // Excel base date
        return new Date(baseDate.getTime() + excelDate * 24 * 60 * 60 * 1000);
    }

    handleValidateImportSettings(event) {
        if (this.isAdvancedMode) {
            this.mustIncludeField = false;
            let isValid = true;
            let elements = this.template.querySelectorAll('.importInput');
            if (elements.length > 0) {
                for (let element of elements) {
                    isValid &= element.reportValidity();
                }
            }
            let hasNonrequiredField = this.fieldsToImport.some(item => item.columnIndex != null && item.columnIndex != '' && !item.isRequired);
            if (!isValid || !hasNonrequiredField) {
                this.mustIncludeField = !hasNonrequiredField;
                event.preventDefault();
                return;
            }
        }
    }
    getColumnIndex(columnName) {
        let index = 0;
        for (let i = 0; i < columnName.length; i++) {
            const charCode = columnName.toUpperCase().charCodeAt(i) - 64; // A=1, B=2, ..., Z=26
            index = index * 26 + charCode;
        }
        return index - 1; // Excel is 1-based, JavaScript is 0-based
    }

    getExcelColumnName(index) {
        let columnName = '';
        let dividend = index + 1;

        while (dividend > 0) {
            let modulo = (dividend - 1) % 26;
            columnName = String.fromCharCode(65 + modulo) + columnName;
            dividend = Math.floor((dividend - 1) / 26);
        }

        return columnName;
    }

    columnLetterToNumber(column) {
        let number = 0;
        for (let i = 0; i < column.length; i++) {
            number = number * 26 + (column.charCodeAt(i) - 64);
        }
        return number;
    }

    exportExcel() {
        try {
            const workbook = new ExcelJS.Workbook();
            console.log(JSON.stringify(this.fieldsToImport));
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet('Sheet1', { properties: { tabColor: { argb: 'worksheet' } } });
            const headerRow = worksheet.getRow(1);
            let index = 1;
            for (let field of this.fieldsToImport) {
                const colIndex = field.defaultColumn ? this.columnLetterToNumber(field.defaultColumn) : index;
                headerRow.getCell(colIndex).value = field.isMandatory ? `${field.label} *` : field.label;
                if (field.fieldType == 'String') {
                    worksheet.getColumn(colIndex).numFmt = '@';
                }
                index++;
            }
            headerRow.eachCell(function (cell, colNumber) {
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: 'FFFFFF' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: '000000' },
                };
                cell.border = {
                    top: { style: 'thin', color: { argb: 'E6E6E6' } },
                    left: { style: 'thin', color: { argb: 'E6E6E6' } },
                    bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                    right: { style: 'thin', color: { argb: 'E6E6E6' } }
                };
                cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center', };
            });
            // Temporary test data — add after your header loop, before writeBuffer()
            const testRow = worksheet.getRow(2);
            testRow.getCell(this.columnLetterToNumber('C')).value = '3178041430869'; 
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement('a');
                document.body.appendChild(a);
                a.style = 'display: none';
                let base64Bin = result.toString('base64');
                if (this.isSendEmail) {
                    this.handleSend(base64Bin);
                } else {
                    a.href = 'data:application/vnd.ms-excel;base64,' + base64Bin;
                    a.download = 'templateExcel.xlsx'; //File name Here
                    a.click();
                    this.loadingData = false;
                }
            });
        } catch (error) {
            console.log('Error' + '%c' + (error.message ? error.message : error.body?.message));
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    toggleAdvancedMode() {
        this.isAdvancedMode = !this.isAdvancedMode;
        if (this.isAdvancedMode) {
            this.fieldsToImport.forEach((item, index) => {
                //item.columnName = this.getExcelColumnName(index);
                item.columnName = item.defaultColumn || this.getExcelColumnName(index);
                item.columnIndex = index;
            })
        }
        if (this.file) this.readFile();
    }
    //MISC
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