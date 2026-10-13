import { LightningElement, wire, track } from 'lwc';
import { tableFields, API_NAMES, BATCH_SIZE, labels, RESOURCES } from './properties.js';
import { getObjectInfos, getPicklistValues } from "lightning/uiObjectInfoApi";
import { loadScript } from 'lightning/platformResourceLoader';
import NegoScope_Status from '@salesforce/schema/NegoScope__c.Status__c';
import initData from '@salesforce/apex/ContractSellInMatrixCtrl.initData';
import updateRecords from '@salesforce/apex/ContractSellInMatrixCtrl.updateRecords';
import importRecords from '@salesforce/apex/ContractSellInMatrixCtrl.importRecords';
import Toast from 'lightning/toast';

export default class SellInMassUpdate extends LightningElement {
    @track isLoading = true;
    @track isReady = false;
    @track labels = labels
    @track fieldsWrapperList = [];
    @track wireIsDone = {
        buildFields: false,
        picklistValues: false,
        init: false,
    }
    @track contractSellInList = [];
    @track API_NAMES = { ...API_NAMES }
    @track negoscopeStatusOptions = [];
    changeMap = []
    pageSettings = {
        URL: undefined,
        AccessKey: undefined,
        BASEURL: undefined,
    };
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    }
    filters = {
        year: [],
        status: [],
        supplier: []
    }
    toastEventVariant = {
        error: 'error',
        success: 'success',
        warning: 'warning'
    }
    // Life Cycle
    connectedCallback() {
        loadScript(this, RESOURCES.ExcelJSScript).then(() => {
        }).catch(error => {
            console.log(error?.body?.message || error?.message);
        });
        loadScript(this, RESOURCES.xlsx + '/js-xlsx-master/dist/jszip.js').then(() => {
            loadScript(self, RESOURCES.xlsx + '/js-xlsx-master/dist/xlsx.js').then(() => {
            }).catch(error => {
                console.log(error?.body?.message || error?.message);
            });
        }).catch(error => {
            console.log(error?.body?.message || error?.message);
        });
        this.init();
    };

    renderedCallback() {
        try {
            let self = this;
            clearTimeout(self.setPageSizeTimeOut);
            this.setPageSizeTimeOut = setTimeout(() => {
                self.setPageSize();
            }, 500);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBodyDiv = this.template.querySelector(".bodyDiv");
            if (
                pageHeader != null &&
                mainContainer != null &&
                pageBodyDiv != null
            ) {
                pageBodyDiv.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - 16 + "px";
            }
            if (pageHeader != null && pageHeader.offsetWidth < 1200) {
                this.screenBig = false;
            } else if (pageHeader != null && pageHeader.offsetWidth >= 1200) {
                this.screenBig = true;
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    /**
     * init data
     * @get prefix and session data
     */
    init() {
        initData().then(data => {
            const parsedData = JSON.parse(data);
            const self = this;
            if (!self.pageSettings.AccessKey) {
                ({ URL: self.pageSettings.URL, KeyPageWSubstring: self.pageSettings.AccessKey, BASEURL: self.pageSettings.BASEURL } = parsedData.keys);
                self.wireIsDone.init = true;
                self.checkIfWireIsDone();
            }
        })
    }
    /**
     * get object info and build fields info
     * @get build fieldsWrapperList
     */
    @wire(getObjectInfos, {
        objectApiNames: [
            API_NAMES.ContractSellin__c.objectApiName,
            API_NAMES.NegoScope__c.objectApiName,
            API_NAMES.Supplier__c.objectApiName,
        ]
    })
    wiredObjectInfos({ error, data }) {
        try {
            if (data) {
                let objMap = {};
                data.results.forEach(item => {
                    objMap[item.result.apiName] = item.result;
                });
                this.labels.NegoScope__c.status = objMap[API_NAMES.NegoScope__c.objectApiName]?.fields[API_NAMES.NegoScope__c.Status__c]?.label;
                this.labels.NegoScope__c.supplier = objMap[API_NAMES.NegoScope__c.objectApiName]?.fields[API_NAMES.NegoScope__c.Supplier__c]?.label;
                this.labels.ContractSellin__c.year = objMap[API_NAMES.ContractSellin__c.objectApiName]?.fields[API_NAMES.ContractSellin__c.Year__c]?.label;
                let allFields = [];
                tableFields.fields.forEach(item => {
                    const field = this.buildFieldWrapper(item, objMap)
                    allFields.push(field);
                });
                this.fieldsWrapperList = allFields;
                this.wireIsDone.buildFields = true;
                this.checkIfWireIsDone();
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    /**
     * get status picklist info
     * @get negoscopeStatusOptions
     */
    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: NegoScope_Status
    })
    wiredNegoStatus({ error, data }) {
        if (data) {
        this.negoscopeStatusOptions = JSON.stringify(data.values.map(v => ({ label: v.label, value: v.value })));
        this.wireIsDone.picklistValues = true;
        this.checkIfWireIsDone();
        } else if (error) {
        // console.error(error);
        }
    }

    /**
     * check if all configuration and depenedecies are setup before loading the data
     * @retrun loadData
     */
    checkIfWireIsDone() {
        try {
            if (Object.values(this.wireIsDone).every(it => it)) {
                this.isReady = true;
                this.loadData();
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    loadData() {
        this.afterload();
    }

    /**
     * build data
     * @retrurn buil Data
     */
    afterload() {
        const query = this.buildQuery(this.filters); // get query
        this.buildContractSellInWrapper(query); // load data
    }

    buildFieldWrapper(field, objMap) {
        try {
            field.headerStyle = `background-color: ${field.headerColor}; color: white;`;
            field.bodyStyle = `background-color: ${field.bodyColor};`;

            let _field = null;
            let fieldName = field.fieldName;
            const parts = field.fieldName.split('__r.');
            fieldName = parts[parts.length - 1];
            if (field?.preDefined == null || !field?.preDefined) {
                _field = objMap[field?.objectName]?.fields[fieldName];
            }
            field.fieldType = field.fieldType ?? _field.dataType.toLocaleUpperCase();
            field.fieldLabel = field.fieldLabel ?? _field.label;
            field.fieldHelpText = _field?.fieldHelpText;
            field.scale =_field?.scale;
            field.isNumberField = field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER';
            field.isNumber = field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE' || _field?.isNumber;
            field.isReference = (field.fieldType == 'REFERENCE' && !fieldName.endsWith('RecordTypeId')) || fieldName == 'Name';
            field.isDate = field.fieldType == 'DATE' || field.fieldType == 'DATETIME';
            field.isDateTime = field.fieldType == 'DATETIME';
            field.isPicklist = field.fieldType == 'PICKLIST';
            field.isBoolean = field.fieldType == 'BOOLEAN';
            field.isTextArea = field.fieldType == 'TEXTAREA';
            field.link = '';
            field.isText = !field.isNumberField && !field.isReference && !field.isDate
                        && !field.isPicklist && !field.isBoolean && !field.isTextArea
            if (field.isPicklist) {
                field.selectedValues = [];
                field.picklistOptions = [];
            }
            if (field.isReference) {
                field.referenceTo = _field?.referenceToInfos[0]?.apiName;
            }
            field.isSearchable = _field?.filterable;
            return field;

        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    buildQuery(filters) {
        let query = 'SELECT Id, NegoScope__r.Supplier__r.Code__c, NegoScope__r.Supplier__c, NegoScope__r.Supplier__r.Name, BOSellInDiscAdditional__c, ';
        query += ' NegoScope__c, NegoScope__r.Name, NegoScope__r.OwnerId, SellInBaseName__c, MainBase__c, LineType__c, Year__c,';
        query += ' ContractSellInP1__r.NegoSellInDiscTotal__c, BOSellInDiscTotal__c, NegoInitSellInDiscTotal__c, NegoSellInDiscTotal__c';
        query += ' FROM ContractSellIn__c';
        query += " WHERE LineType__c IN ('YearBase') AND ContractSellInMaster__c = null AND NegoScope__r.RecordType.DeveloperName <> 'Advanced'";
        if (filters?.status && filters?.status?.length > 0) {
            query += ` AND NegoScope__r.Status__c IN (${filters.status.map(s => `'${s}'`).join(',')})`;
        }
        if (filters?.year && filters?.year?.length > 0) {
            query += ` AND Year__c IN (${filters.year.map(y => `${y}`).join(',')})`;
        }
        if (filters?.supplier && filters?.supplier?.length > 0) {
            query += ` AND NegoScope__r.Supplier__c IN (${filters.supplier.map(s => `'${s}'`).join(',')})`;
        }

        return query;
    }
    /**
     * buildContractSellInWrapper
     * @get contractSellInList
     */
    buildContractSellInWrapper(query) {
        try {
            let self = this;
            let loadingMore = false;
            let url = self.pageSettings.URL + encodeURI(query); // build url
            // lazy load get the next data
            if (self.nextRecordsUrl) {
                url = self.pageSettings.BASEURL + self.nextRecordsUrl;
                loadingMore = true;
            }
            // req data
            fetch(url, {
                headers: {
                    "Content-Type": "application/json; charset=utf-8",
                    "Authorization": "Bearer " + self.pageSettings.AccessKey,
                    'Sforce-Query-Options': `batchSize=${BATCH_SIZE}`,
                },
                method: 'GET',
            }).then(response => {
                // handle invalid response
                if (!response.ok) {
                    response.json().then(res => {
                        if (res[0].message) {
                            throw new Error(res[0].message);
                        }
                    });
                    throw new Error(" response was not OK");
                }
                const contentType = response.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new TypeError("Oops, we haven't got JSON!");
                }
                // handle data
                return response.json().then(response => {
                    let contractSellIn = response.records;
                    this.recordsTotalNumber = response.totalSize;
                    let contractSellInWrapper = [];
                    self.nextRecordsUrl = response.nextRecordsUrl;
                    // build record info
                    const process = (item) => {
                        let contractSellIn = self.buildIContractSellInInfo(item);
                        contractSellInWrapper.push(contractSellIn);
                    }
                    try {
                        contractSellIn.forEach(item => {
                            process(item);
                        });
                    } catch (error) {
                        console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                    }
                    // callback method post build
                    let callback = () => {
                        if (loadingMore) {
                            self.contractSellInList = [...self.contractSellInList, ...contractSellInWrapper];
                        } else {
                            self.contractSellInList = contractSellInWrapper;
                        }
                        self.isLoading = false;
                        self.hascontractSellIn = self.contractSellInList.length != 0;
                    }
                    callback();

                });
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    /**
     * handleScroll lazy load
     * @get get the next batch of data
     * @param {event} event
     */
    handleScroll(event) {
        try {
            let self = this;
            const scrollContainer = event.target;
            const scrollPercentage = (scrollContainer.scrollTop + scrollContainer.clientHeight) / scrollContainer.scrollHeight * 100;
            if (scrollPercentage >= 90 && !self.isLoading && self.nextRecordsUrl) {
                self.isLoading = true;
                self.scrollLoadMoreTimeOut = setTimeout(() => {
                    self.buildContractSellInWrapper();
                }, 0);
            }
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }


    /**
     *  buildIContractSellInInfo
     * @param {this reference} self
     * @param {contractSellIn to be wrapped} contractSellIn
     * @param {wrapper} contractSellInWrapper
     */
    buildIContractSellInInfo(contractSellIn) {
        try {
            let self = this;
            let _fields = self.fieldsWrapperList.map(field => {
                    let value = contractSellIn;
                    let url;
                    let childField = false
                    if (field.preDefined) {
                        if (field.fieldName === 'LBL_SellIn_BO_Total') {
                            const boTotal = parseInt(value[API_NAMES.ContractSellin__c.BOSellInDiscTotal__c]) || 0;
                            const boAdditional = parseInt(value[API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c]) || 0;
                            value = boTotal + boAdditional;

                        } else if (field.fieldName === 'LBL_SellIn_Evol1') {
                            const negoSellInDisc = parseInt(value[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const negoInit = parseInt(value[API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || 0;
                            value = negoInit !== 0 ? (negoSellInDisc / negoInit) * 100 : 0;

                        } else if (field.fieldName === 'LBL_SellIn_Evol2') {
                            const negoSellInDisc = parseInt(value[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const negoInit = parseInt(value[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || 0;
                            value = negoInit !== 0 ? (negoSellInDisc / negoInit) * 100 : 0;

                        } else if (field.fieldName === 'LBL_SellIn_Evol3') {
                            const negoSellInDisc = parseInt(value[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const prevNegoSellInDisc = parseInt(value[API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            value = prevNegoSellInDisc !== 0 ? (negoSellInDisc / prevNegoSellInDisc) * 100 : 0;

                        } else if (field.fieldName === 'LBL_SellIn_Evol4') {
                            const negoSellInDisc = parseInt(value[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const negoInit = parseInt(value[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || 0;
                            value = negoInit !== 0 ? (negoSellInDisc / negoInit) * 100 : 0;
                        }
                        return { ...field, value: value, url: `${url ? '/' + url : ''}` };
                    }
                    if (field.fieldName == 'Name') {
                        field.isReference = true;
                        url = value.Id || url || '';
                    }
                    if (field.fieldName.match(/\./g)) {
                        let sOriginFieldName = field.fieldName.split('\.');
                        sOriginFieldName.forEach(__field => {
                            if (field.isReference) {
                                url = value.Id || url || '';
                            }
                            if (__field == 'Name') {
                                url = value.Id || url || '';
                                field.isReference = true;
                                field.isText = false;
                            }
                            childField = true;
                            url = value.Id || url || '';
                            value = value[__field] == 0 ? value[__field] : (value[__field] || '');
                        });
                    } else {
                        value = value[field.fieldName] == 0 ? value[field.fieldName] : (value[field.fieldName] || '');
                    }
                    if (field.isReference && field.fieldName != 'Name' && !childField) {
                        if (field.fieldName.endsWith('Id')) {
                            value = contractSellIn[field.fieldName.replace('Id', '')]?.Name;
                        } else {
                            value = contractSellIn[field.fieldName.replace('__c', '__r')]?.Name;
                        }
                        url = contractSellIn[field.fieldName];
                    }
                    if (field.fieldName == 'Name') {
                        let neField = { ...field, value: value, url: `${url ? '/' + url : ''}` };
                    }
                    if (field.isPicklist) {
                        let found = field.picklistOptions.find(item => item.value === value);
                        value = found?.label;
                    }
                    return { ...field, value: value, url: `${url ? '/' + url : ''}` };
            });
            return {
                contractSellIn: contractSellIn,
                fields: _fields,
                isSelected: this.selected,
            };
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
    }
    // handle methods
    handleChangeMultiPicklistValues(event) {
        this.isLoading = true;
        let filterName = event.target.dataset.filterName;
        const isLookupField = event.target.dataset.field === 'lookupField';
        let values = [];
        this.filters[filterName] = '';
        if (isLookupField) {
            event?.detail?.selRecords?.forEach(item => {
            values.push(item.recId);
            })
            if(filterName == 'supplier') {
                this.stringifiedSelectedSupplier = JSON.stringify(event?.detail?.selRecords);
            }
        } else {
            event?.detail?.selOptions?.forEach(item => {
                if (item.hasOwnProperty('value')) {
                    values.push(item.value);
                } else {
                    values.push(item);
                }
            })
        }
        if (values && values.length > 0) {
            this.filters[filterName] = values;
        }
        if(filterName == 'year') {
            this.stringifiedSelectedYears = JSON.stringify(this.filters.year);
        }
        if(filterName == 'status') {
            this.stringifiedSelectedStatus = JSON.stringify(this.filters.status);
        }
        this.nextRecordsUrl = null;
        this.afterload();
    }

    /**
     *  handle field edits
     *  @param {event} event
     */
    handleFieldEdits(event) {
        let recordIndex = event.target?.dataset.index;
        let fieldIndex = event.target?.dataset.fieldIndex;
        let value = event.target.value;
        let record = structuredClone(this.contractSellInList?.[recordIndex]);
        const fieldName = record?.fields?.[fieldIndex]?.fieldName;
        if (record?.contractSellIn && record?.contractSellIn?.[fieldName] != value) {
            record.contractSellIn[fieldName] = value;
        } else {
            return;
        }
        const id = record?.contractSellIn?.Id;
        // add to changeMap
        this.changeMap[id] = {
            ...this.changeMap[id],
            Id: id,
            [fieldName]: value,
        };
        const updatedWrapper = this.buildIContractSellInInfo(record.contractSellIn); // rebuild record with new data
        this.contractSellInList[recordIndex] = updatedWrapper;  // update record in the list
    }
    /**
     *  reset all changes made by the user
     */
    handleReset() {
        this.isLoading = true;
        this.changeMap = {};
        this.filters = {};
        this.nextRecordsUrl = null;
        this.stringifiedSelectedStatus = JSON.stringify([]);
        this.stringifiedSelectedYears = JSON.stringify([]);
        this.stringifiedSelectedStatus = JSON.stringify([]);
        this.afterload();
    }
    /**
     *  save all changes made by the user
     */
    handleSave() {
        this.isLoading = true;
        const recordToUpdate = JSON.stringify(Object.values(this.changeMap));
        updateRecords({
            jsonField: recordToUpdate
        }).then(() => {
            this.isLoading = false;
            this.changeMap = {};
            this.showNotification(this.labels.LBL_Success, '', this.toastEventVariant.success);
        }).catch((error) => {
            this.showNotification(this.labels.LBL_Error, (error?.body?.message || error?.message), this.toastEventVariant.error);
            this.handleReset();
        })
    }

    exportExcel() {
        let docName = `${this.labels.LBL_SellIn_Mass_Update}-${(new Date()).toISOString().substring(0, 10)}`;
        // Create WorkBook
        let workbook = new ExcelJS.Workbook();
        // Create WorkSheet
        let worksheet = workbook.addWorksheet(docName);
        worksheet.properties.defaultRowHeight = 25;
        worksheet.properties.defaultColWidth = 20;
        const columns = [];
        const headerOutputs = [null ,...this.fieldsWrapperList.map(field => field.fieldLabel)];
        const bodyOutputs = this.contractSellInList.map(records =>{return [records.contractSellIn?.Id,
            ...records.fields.map(field => {
                return field.value;
            })
        ]});
        columns.push({ header: 'Id', width: 10, style: {}, hidden: true });
        this.fieldsWrapperList.forEach(field => {
            let newItem = {
                header: field.fieldName, width: field?.fieldLabel?.length, style: {}
            };
            if (field.isNumber) {
                newItem.style.numFmt = '0';
                if (field.scale) {
                    newItem.style.numFmt += ".";
                    for (let index = 0; index < field.scale; index++) {
                        newItem.style.numFmt += '0';
                    }
                }
                if (field.isPercent) {
                    newItem.style.numFmt += '"%"';
                }
            } else if (field.isBoolean || field.isDate || field.isDateTime) {
                newItem.style.numFmt = undefined;
            } else {
                newItem.style.numFmt = '@';
            }
            field.numFmt = newItem.style.numFmt;
            columns.push(newItem);
        });
        worksheet.columns = columns;
        // add header
        worksheet.addRow(headerOutputs);
        bodyOutputs.forEach(item => {
            worksheet.addRow(item);
        });
        const colorMap = [null, ...tableFields.fields.map(field => {
            return {
                headerColor: field.headerColor.replace(/^#/, ''),
                bodyColor: field.bodyColor.replace(/^#/, ''),
            }
        })]
        const toNumberStrict = (v) => {
        if (typeof v === 'number' && Number.isFinite(v)) return v;
        if (typeof v !== 'string') return v;
        // normalize: trim, remove NBSP, spaces, commas, unicode minus
        let s = v.trim().replace(/\u00A0/g, ' ').replace(/[\s,]/g, '').replace(/\u2212/g, '-');

        // handle percentages like "12.3%"
        let isPct = false;
        if (s.endsWith('%')) { isPct = true; s = s.slice(0, -1); }

        // numeric?
        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(s)) {
            const n = Number(s);
            return isPct ? n / 100 : n;
        }
        return v; // keep non-numeric as-is
        }

        worksheet.eachRow((row, rowIndex) => {
            if (rowIndex == 1) {
                    row.hidden = true;
            }
            row.eachCell((cell, colNumber) => {
                let fill = null;
                let font = null;
                if (colorMap[colNumber -1] == null) return;
                if (rowIndex < 3) {
                    fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: colorMap[colNumber -1]?.headerColor } };
                    font = { color: { argb: 'FFFFFFFF' } };
                } else {
                    fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: colorMap[colNumber -1]?.bodyColor } };
                }
                if (fill) cell.fill = fill;
                if (font) cell.font = font;
                if (colNumber > 7) {
                    const coerced = toNumberStrict(cell.value);
                    if (typeof coerced === 'number' && Number.isFinite(coerced)) {
                        cell.value = coerced;
                        cell.numFmt = '#,##0.00';
                        cell.alignment = { horizontal: 'right' };
                    }

                }
                cell.border = {
                    top: { style: 'thin', color: { argb: '000000' } },
                    left: { style: 'thin', color: { argb: '000000' } },
                    bottom: { style: 'thin', color: { argb: '000000' } },
                    right: { style: 'thin', color: { argb: '000000' } }
                };
            });
        });

        workbook.xlsx.writeBuffer().then(result => {
            self.isLoading = false;
            let a = document.createElement("a");
            document.body.appendChild(a);
            a.style = "display: none";
            let base64Bin = result.toString('base64');
            a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
            a.download = docName + '.xlsx'; //File name Here
            a.click();
        })
    }

    // get mothods
    // get year options
    get yearOptions() {
        let currentYear = new Date().getFullYear();
        return JSON.stringify([
            { label: '' + (currentYear + 2), value: '' + (currentYear + 2) },
            { label: '' + (currentYear + 1), value: '' + (currentYear + 1) },
            { label: '' + (currentYear), value: '' + currentYear },
            { label: '' + (currentYear - 1), value: '' + (currentYear - 1) },
            { label: '' + (currentYear) - 2, value: '' + (currentYear - 2) }
        ])
    };

    // Import Excel
    @track openImportPopup = false;
    file;
    @track fileName = '';
    importedJSONData = [];
    handleOpenImport() {
        this.file = '';
        this.fileName = '';
        this.openImportPopup = true;
    }
    handleCloseImportPopup() {
        this.fileName = '';
        this.openImportPopup = false;
    }
    handleFileSelect(event) {
        var files = event.target.files;
        this.file = files[0];
        this.fileName = this.file.name;
    }
    excelToJSON(file) {
        this.loading = true;
        var reader = new FileReader();
        reader.onload = event => {
            var data = event.target.result;
            try {
                var workbook = XLSX.read(data, {
                    type: 'binary'
                });
                Object.keys(workbook.Sheets).forEach(sheetName => {
                    var XL_row_object = XLSX.utils.sheet_to_row_object_array(workbook.Sheets[sheetName]);
                    this.fieldsToImport = ['Id', ...Object.keys(XL_row_object[0])]
                    this.importedJSONData = XL_row_object;
                    this.handleImportRecords();
                });
            } catch (err) {
                toastError(this, ' ' + (err && err.body && err.body.message ? err.body.message : err));
            }
            this.loading = false;
        };
        reader.onerror = function (ex) {
            this.error = ex;
            toastError(this, this.Labels.LBL_Error_While_Reading_The_File + ex.message);
        };
        reader.readAsBinaryString(file);
    }
    handleConfirmImport(event) {
        if (this.file.name.endsWith('.xls') || this.file.name.endsWith('.xlsx')) {
            this.excelToJSON(this.file);
        }
    }
    handleImportRecords() {
        this.openImportPopup = false;
        this.isLoading = true;
        importRecords({
            objectName: API_NAMES.ContractSellin__c.objectApiName,
            xlsData: JSON.stringify(this.importedJSONData),
            fieldsToImport: this.fieldsToImport,
        }).then(result => {
            this.showNotification(this.labels.LBL_Success, this.labels.LBL_Import_Finish, this.toastEventVariant.success);
            this.handleReset();
        }).catch(error => {
            this.isLoading = false;
            console.log('error >>> ' + JSON.stringify(error))
            this.showNotification(this.labels.LBL_Error, (error?.body?.message || error?.message), this.toastEventVariant.error);
        });
    }

    // helper methods
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
}