import { LightningElement, wire, track } from 'lwc';
import { API_NAMES, labels, RESOURCES } from './properties.js';
import { getObjectInfos, getPicklistValues } from "lightning/uiObjectInfoApi";
import { loadScript } from 'lightning/platformResourceLoader';
import Contract_Status from '@salesforce/schema/Contract__c.Status__c';
import initData from '@salesforce/apex/ContractSellInMatrixCtrl.initData';
import loadData from '@salesforce/apex/ContractSellInMatrixCtrl.loadData';
import save from '@salesforce/apex/ContractSellInMatrixCtrl.save';
import processRestForExcel from '@salesforce/apex/ContractSellInMatrixCtrl.processRestForExcel';
import Toast from 'lightning/toast';
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class ContractSellInMatrix extends LightningElement {
    //Tracks
    @track isLoading = true;
    @track searchMode = true;
    @track labels = labels
    @track wireIsDone = {
        buildFields: false,
        picklistValues: false,
    }
    @track records = [];
    @track allRecordsToExport = [];
    @track API_NAMES = { ...API_NAMES }
    @track contractStatusOptions = '[]';
    @track noOfRecords = 0;
    @track pageNumber = 1;
    @track pageSize = '100';
    @track pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' }];
    @track contractSequenceOptions = '[]';
    @track displayedFields = [];
    @track stringifiedFilters = {
        years: '',
        contractSequence: '',
        status: ''
    }

    //Variables
    totalPagesCount = 0;
    changeMap = []
    nbOfFixedColumns;
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    }
    filters = {
        year: [`${new Date().getFullYear()}`, `${new Date().getFullYear() + 1}`],
        status: ['Signed', 'Updated wAddendum', 'Updated woAddendum'],
        supplier: [],
        contractSequence: ['Signed'],
    };
    toastEventVariant = {
        error: 'error',
        success: 'success',
        warning: 'warning'
    }
    contractSellInToUpdateMap = {}

    //Getters
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.noOfRecords ? this.pageNumber * pageSize + 1 - pageSize : this.noOfRecords - this.recordsLength) + '-' + (this.pageNumber * pageSize > this.noOfRecords ? this.noOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.noOfRecords;
    }

    get filterDetails() {
        let output = []
        const selectedSuppliers = JSON.parse(this.stringifiedSelectedSupplier || "[]")?.map(item => item?.recName) || [];
        const selectedContractSequence = JSON.parse(this.contractSequenceOptions || "[]")
            ?.filter(item => JSON.parse(this.stringifiedFilters.contractSequence || "[]")?.includes(item?.value))?.map(item => item?.label) || [];
        if (this.filters.status.length > 0) {
            const selectedStatusLabels = JSON.parse(this.contractStatusOptions || "[]").filter(opt => this.filters.status.includes(opt.value)).map(opt => opt.label);
            if (selectedStatusLabels.length > 0) {
                output.push(labels.LBL_SellIn_ContractStatus + ': ' + selectedStatusLabels.join(', '));
            }
        }
        if (this.filters.contractSequence.length > 0) {
            output.push(labels.LBL_SellIn_ContractSequence + ': ' + selectedContractSequence.join(', ') + '');
        }
        if (this.filters.year.length > 0) {
            output.push(labels.ContractSellin__c.year + ': ' + this.filters.year.join(', ') + '');
        }
        if (this.filters.supplier.length > 0) {
            output.push(labels.NegoScope__c.supplier + ': ' + selectedSuppliers.join(', ') + '');
        }
        return output;
    }

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

    //Wires
    /**
     * get object info and build fields info
     */
    @wire(getObjectInfos, {
        objectApiNames: [
            API_NAMES.ContractSellin__c.objectApiName,
            API_NAMES.NegoScope__c.objectApiName,
            API_NAMES.Supplier__c.objectApiName,
            API_NAMES.Contract__c.objectApiName,
        ]
    }) wiredObjectInfos({ error, data }) {
        try {
            if (data) {
                let objMap = {};
                data.results.forEach(item => {
                    objMap[item.result.apiName] = item.result;
                });
                this.labels.Contract__c.status = objMap[API_NAMES.Contract__c.objectApiName]?.fields[API_NAMES.Contract__c.Status__c]?.label;
                this.labels.NegoScope__c.status = objMap[API_NAMES.NegoScope__c.objectApiName]?.fields[API_NAMES.NegoScope__c.Status__c]?.label;
                this.labels.NegoScope__c.supplier = objMap[API_NAMES.NegoScope__c.objectApiName]?.fields[API_NAMES.NegoScope__c.Supplier__c]?.label;
                this.labels.ContractSellin__c.year = objMap[API_NAMES.ContractSellin__c.objectApiName]?.fields[API_NAMES.ContractSellin__c.Year__c]?.label;
                this.wireIsDone.buildFields = true;
                this.checkIfWireIsDone();
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    /**
     * get status picklist info
     * @get contractStatusOptions
     */
    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: Contract_Status
    }) wiredNegoStatus({ error, data }) {
        if (data) {
            this.contractStatusOptions = JSON.stringify(data.values.map(v => ({ label: v.label, value: v.value })));
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
                this.init();
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    // Life Cycle
    connectedCallback() {
        Promise.all([
            loadScript(this, RESOURCES.ExcelJSScript),
            loadScript(this, RESOURCES.xlsx + '/js-xlsx-master/dist/jszip.js')
                .then(() => {
                    return loadScript(this, RESOURCES.xlsx + '/js-xlsx-master/dist/xlsx.js');
                }),
            loadStyle(this, negOptimGlobalCSS)
        ])
        .catch(error => {
            console.log(error?.body?.message || error?.message || error);
        });
        this.stringifiedFilters.status = JSON.stringify(this.filters.status);
        this.stringifiedFilters.contractSequence = JSON.stringify(this.filters.contractSequence);
        this.stringifiedFilters.years = JSON.stringify(this.filters.year);
        window.addEventListener('resize', this.setPageSize);
    };

    renderedCallback() {
        try {
            let self = this;
            clearTimeout(self.setPageSizeTimeOut);
            this.setPageSizeTimeOut = setTimeout(() => {
                self.setPageSize();
                self.setFixedColumns();
            }, 500);
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
        try {
            initData().then(data => {
                const parsedData = JSON.parse(data);
                this.contractSequenceOptions = JSON.stringify(
                    Object.entries(parsedData.contractRecordTypesOptions || {}).map(([value, label]) => ({
                        label: label,
                        value: value
                    }))
                );
                this.buildDisplayedFields(parsedData.contractSellInFields, parsedData.groupingFields);
                this.isLoading = false;
            })
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('InitData: %c' + error.message, 'color : red');
            console.log('InitData: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    // Builds the grid column definitions (displayed fields) from Apex data.
    buildDisplayedFields(contractSellInFields, groupingFields) {
        try {
            this.displayedFields = [];
            // Build Grouping Fields
            for (let field of groupingFields) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    isPercent: field.fieldType == 'PERCENT',
                    isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    link: '',
                    scale: field.scale,
                    step: field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                    isInputField: field.isInputField,
                    style: field.styleWrapper.bodyStyle,
                    headerStyle: field.styleWrapper.headerStyle,
                    pickListValues: field.pickListValues,
                    merged: true,
                }
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.isBoolean) {
                    fieldWrapper.style += 'text-align:center;';
                }
                this.displayedFields.push(fieldWrapper);
            }
            // Build Contract SellIn Fields
            for (let field of contractSellInFields) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    isPercent: field.fieldType == 'PERCENT',
                    isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    link: '',
                    scale: field.scale,
                    step: field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                    isInputField: field.isInputField,
                    style: field.styleWrapper.bodyStyle,
                    headerStyle: field.styleWrapper.headerStyle,
                    pickListValues: field.pickListValues,
                    merged: false,
                }
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.isBoolean) {
                    fieldWrapper.style += 'text-align:center;';
                }

                if (field.fieldName == API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c || field.fieldName === API_NAMES.ContractSellin__c.Review__c) {
                    fieldWrapper.isInputField = true
                }

                this.displayedFields.push(fieldWrapper);
                if (field.fieldName == API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c) {
                    let extraField = {
                        objectName: API_NAMES.ContractSellin__c.objectApiName,
                        fieldType: "DOUBLE",
                        fieldName: "LBL_SellIn_BO_Total",
                        fieldLabel: this.labels.LBL_SellIn_BO_Total.toUpperCase(),
                        preDefined: true,
                        headerStyle: `background-color: #4d93d9; color: white; min-width: 125px; max-width: 125px; overflow-wrap: anywhere;`,
                        style: `background-color: #dae9f8; overflow-wrap: break-word; min-width: 125px; max-width: 125px;`,
                        scale: 2,
                        class: 'slds-text-align--right',
                        isNumberField: true
                    };
                    this.displayedFields.push(extraField);
                }
                if (field.fieldName == API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c) {
                    let extraField = {
                        objectName: API_NAMES.ContractSellin__c.objectApiName,
                        fieldType: "PERCENT",
                        fieldName: "LBL_SellIn_Evol1",
                        fieldLabel: this.labels.LBL_SellIn_Evol1.toUpperCase(),
                        preDefined: true,
                        headerStyle: `background-color: #d86dcd; color: white; min-width: 125px; max-width: 125px; overflow-wrap: anywhere;`,
                        style: `background-color: #fcf2fb; overflow-wrap: break-word; min-width: 125px; max-width: 125px;`,
                        scale: 0,
                        class: 'slds-text-align--right',
                        isPercent: true
                    };
                    let extraField2 = {
                        objectName: API_NAMES.ContractSellin__c.objectApiName,
                        fieldType: "PERCENT",
                        fieldName: "LBL_SellIn_Evol2",
                        fieldLabel: this.labels.LBL_SellIn_Evol2.toUpperCase(),
                        preDefined: true,
                        headerStyle: `background-color: #d86dcd; color: white; min-width: 125px; max-width: 125px; overflow-wrap: anywhere;`,
                        style: `background-color: #fcf2fb; overflow-wrap: break-word; min-width: 125px; max-width: 125px;`,
                        scale: 0,
                        class: 'slds-text-align--right',
                        isPercent: true
                    };
                    let extraField3 = {
                        objectName: API_NAMES.ContractSellin__c.objectApiName,
                        fieldName: "New_NegoSellInDiscTotal",
                        fieldLabel: this.labels.LBL_SellIn_Nego_New.toUpperCase(),
                        headerStyle: `background-color: #d86dcd; color: white; min-width: 125px; max-width: 125px; overflow-wrap: anywhere;`,
                        style: `background-color: #fcf2fb; overflow-wrap: break-word; min-width: 125px; max-width: 125px;`,
                        scale: 2,
                        isInputField: true,
                        isNumberField: true,
                        class: 'slds-text-align--right',
                    };
                    this.displayedFields.push(extraField);
                    this.displayedFields.push(extraField2);
                    this.displayedFields.push(extraField3);
                }
                if (field.fieldName == API_NAMES.ContractSellin__c.Review__c) {
                    let extraField4 = {
                        objectName: API_NAMES.ContractSellin__c.objectApiName,
                        fieldType: "PERCENT",
                        fieldName: "LBL_SellIn_Evol3",
                        fieldLabel: this.labels.LBL_SellIn_Evol3.toUpperCase(),
                        preDefined: true,
                        headerStyle: `background-color: #d86dcd; color: white; min-width: 125px; max-width: 125px; overflow-wrap: anywhere;`,
                        style: `background-color: #fcf2fb; overflow-wrap: break-word; min-width: 125px; max-width: 125px;`,
                        scale: 0,
                        isPercent: true,
                        class: 'slds-text-align--right',
                    };
                    let extraField5 = {
                        objectName: API_NAMES.ContractSellin__c.objectApiName,
                        fieldType: "PERCENT",
                        fieldName: "LBL_SellIn_Evol4",
                        fieldLabel: this.labels.LBL_SellIn_Evol4.toUpperCase(),
                        preDefined: true,
                        headerStyle: `background-color: #d86dcd; color: white; min-width: 125px; max-width: 125px; overflow-wrap: anywhere;`,
                        style: `background-color: #fcf2fb; overflow-wrap: break-word; min-width: 125px; max-width: 125px;`,
                        scale: 0,
                        isPercent: true,
                        class: 'slds-text-align--right',
                    };
                    this.displayedFields.push(extraField4);
                    this.displayedFields.push(extraField5);
                }
            }
            this.nbOfFixedColumns = this.displayedFields.filter(item => item.merged).length + 2 || 0;
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    // Calls Apex loadData to fetch table rows.
    loadData() {
        this.isLoading = true;
        this.records = [];
        try {
            loadData({
                pageSize: parseInt(this.pageSize),
                pageNumber: this.pageNumber,
                filtersJson: JSON.stringify(this.filters),
            }).then(result => {
                let parsedResult = JSON.parse(result);
                this.noOfRecords = parsedResult.totalSize;
                this.totalPagesCount = Math.ceil((parsedResult.totalSize / parseInt(this.pageSize)));
                this.records = this.buildTotalData(parsedResult.totalRecords, parsedResult.records);
                this.isLoading = false;
            }).catch(error => {
                this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
                console.log('loadData: %c' + error.message, 'color : red');
                console.log('loadData: %c' + error.body?.message, 'color : red');
                this.isLoading = false;
            })
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    buildTotalData(totalRecords, data) {
        let groups = this.buildData(data);
        let totalKeyMap = {};
        if (Array.isArray(totalRecords)) {
            for (let item of totalRecords) {
                let negoScopeName = item?.[this.API_NAMES.ContractSellin__c.NegoScope__r]?.[this.API_NAMES.NegoScope__c?.Name];
                let sellInBaseName = item?.[this.API_NAMES.ContractSellin__c.SellInBaseName__c];
                const groupKey = (negoScopeName || sellInBaseName)
                    ? `${negoScopeName}_${sellInBaseName}`
                    : "empty";
                if (!totalKeyMap[groupKey]) totalKeyMap[groupKey] = [];
                totalKeyMap[groupKey].push(item);
            }
        }
        groups.forEach(group => {
            const fullList = totalKeyMap[group.key] || [];
            if (fullList.length <= 1) return;
            let totalRow = [];
            for (let field of this.displayedFields) {
                if (field.merged) continue;
                let fw = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: "",
                    isNumberField: field.isNumberField,
                    scale: field.scale,
                    style: (field.style ? field.style : "") + "font-weight:bold;",
                    isPercent: field.isPercent,
                    class: field.class
                };
                if (field.fieldName === this.API_NAMES.ContractSellin__c.Year__c) {
                    fw.fieldValue = "TOTAL";
                    fw.isText = true;
                    fw.isNumberField = false;
                    fw.class += ' slds-border--left ';
                } else if (field.isNumberField || field.isPercent) {
                    fw.fieldValue = 0;
                    for (let item of fullList) {
                        let value = 0;             
                        let changedItem = this.contractSellInToUpdateMap[item.Id] || {};
                        if (field.fieldName === "New_NegoSellInDiscTotal") {
                            value = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                        } else if (field.fieldName === "LBL_SellIn_BO_Total") {
                            const boTotal = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.StatedSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.StatedSellInDiscTotal__c]) || 0;
                            const boAdditional = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c]) || 0;
                            value = boTotal + boAdditional;
                        } else if (field.fieldName === "LBL_SellIn_Evol1") {
                            const negoSell = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const negoInit = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[this.API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[this.API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || 0;
                            value = negoInit !== 0 ? negoSell / negoInit : 0;
                        } else if (field.fieldName === "LBL_SellIn_Evol2") {
                            const negoSell = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const negoInit = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || 0;
                            value = negoInit !== 0 ? negoSell / negoInit : 0;
                        } else if (field.fieldName === "LBL_SellIn_Evol3") {
                            const negoSell = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const prevSell = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            value = prevSell !== 0 ? negoSell / prevSell : 0;
                        } else if (field.fieldName === "LBL_SellIn_Evol4") {
                            const negoSell = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) || 0;
                            const negoInit = parseFloat(changedItem[this.API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || parseFloat(item[this.API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) || 0;
                            value = negoInit !== 0 ? negoSell / negoInit : 0;
                        } else {
                            let values = field.fieldName.split('.');
                            for (let index = 0; index < values.length; index++) {
                                let val = index == 0 ? item : value;
                                if (val) {
                                    value = val[values[index]];
                                }
                            }
                            if (changedItem.hasOwnProperty(field.fieldName)) {
                                value = parseFloat(changedItem[field.fieldName]);
                            } else {
                                value = parseFloat(value) || 0;
                            }
                        }
                        fw.fieldValue += value;
                    }
                } else {
                    fw.fieldValue = '';
                }
                totalRow.push(fw);
            }
            group.total = totalRow;
        });
        return groups;
    }

    recalculateGroupTotals(group, fieldName, oldValue, newValue) {
        try {
            group.total.forEach(field => {
                if (field.isNumberField || field.isPercent) {
                    if (field.fieldName == fieldName) {
                        field.fieldValue -= parseFloat(oldValue) || 0;
                        field.fieldValue += parseFloat(newValue) || 0;
                    }
                }
            })
        } catch (error) {
            console.log('recalculateGroupTotals: %c' + error.message, 'color : red');
        }
    }

    buildData(data) {
        let dataMap = {};
        for (let item of data) {
            let negoScopeName = item?.[API_NAMES.ContractSellin__c.NegoScope__r]?.[API_NAMES.NegoScope__c?.Name];
            let sellInBaseName = item?.[API_NAMES.ContractSellin__c.SellInBaseName__c];
            const groupKey = (negoScopeName || sellInBaseName) ? `${negoScopeName}_${sellInBaseName}` : 'empty';
            let groupWrapper;
            if (!dataMap.hasOwnProperty(groupKey)) {
                groupWrapper = {
                    key: groupKey,
                    values: [],
                    records: [],
                    total: null,
                    get rowspan() {
                        return this.records.length + (this.total ? 2 : 1);
                    }
                };
                for (let field of this.displayedFields) {
                    if (field.merged) {
                        let fieldWrapper = {
                            Id: item.Id,
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
                            link: '',
                            scale: field.scale,
                            step: field.step,
                            pickListValues: [],
                            style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                            class: field.class,
                        }

                        let values = field.fieldName.split('.');
                        for (let index = 0; index < values.length; index++) {
                            let val = index == 0 ? item : fieldWrapper.fieldValue;
                            if (val) {
                                if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                                    fieldWrapper.fieldOutputValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                    fieldWrapper.link = '/' + val[values[index]];
                                } else {
                                    fieldWrapper.fieldOutputValue = val[values[index]];
                                }
                                fieldWrapper.fieldValue = val[values[index]];
                            }
                        }
                        if (fieldWrapper.isPicklist) {
                            for (let pickVal of field.pickListValues) {
                                fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                                if (fieldWrapper.fieldValue == pickVal.value) {
                                    fieldWrapper.fieldOutputValue = pickVal.label;
                                }
                            }
                            fieldWrapper.pickListValues.unshift({
                                label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                            })
                        }
                        groupWrapper.values.push(fieldWrapper)
                    }
                }
                dataMap[groupKey] = groupWrapper;
            }
            groupWrapper = dataMap[groupKey];
            let recordWrapper = {
                Name: item.Name,
                Id: item.Id,
                item: item,
                link: '/' + item.Id,
                values: [],
            }
            for (let field of this.displayedFields) {
                if (!field.merged) {
                    let fieldWrapper = {
                        Id: item.Id,
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
                        link: '',
                        scale: field.scale,
                        step: field.step,
                        isInputField: field.isInputField,
                        pickListValues: [],
                        style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                        rowspan: 1,
                        class: field.class,
                        isPercent: field.isPercent
                    }
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let val = index == 0 ? item : fieldWrapper.fieldValue;
                        if (val) {
                            if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                                fieldWrapper.fieldOutputValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                fieldWrapper.link = '/' + val[values[index]];
                            } else {
                                fieldWrapper.fieldOutputValue = val[values[index]];
                            }
                            fieldWrapper.fieldValue = val[values[index]];
                        }
                    }
                    if (fieldWrapper.isPicklist) {
                        for (let pickVal of field.pickListValues) {
                            fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                            if (fieldWrapper.fieldValue == pickVal.value) {
                                fieldWrapper.fieldOutputValue = pickVal.label;
                            }
                        }
                        fieldWrapper.pickListValues.unshift({
                            label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                        })
                    }
                    if (field.fieldName == API_NAMES.ContractSellin__c.Year__c) {
                        fieldWrapper.class += ' slds-border--left ';
                    }
                    if (field.fieldName === "New_NegoSellInDiscTotal") {
                        fieldWrapper.fieldValue = item[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]
                    }
                    const updated = this.contractSellInToUpdateMap[item.Id] || {};
                    if (field.isInputField && updated.hasOwnProperty(field.fieldName)) {
                        fieldWrapper.fieldValue = updated[field.fieldName];
                    }
                    recordWrapper.values.push(fieldWrapper);
                }
            }
            this.recalculateFormulaFields(groupWrapper, recordWrapper);
            groupWrapper.records.push(recordWrapper);
        }
        return Object.values(dataMap);
    }

    changePageSizeHandler(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.loadData();
    }

    handleChangePage(event) {
        this.isLoading = true;
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.totalPagesCount;
            }
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    // handle methods
    handleChangeMultiPicklistValues(event) {
        let filterName = event.target.dataset.filterName;
        const isLookupField = event.target.dataset.field === 'lookupField';
        let values = [];
        this.filters[filterName] = [];
        if (isLookupField) {
            event?.detail?.selRecords?.forEach(item => {
                values.push(item.recId);
            })
            if (filterName == 'supplier') {
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
        if (filterName == 'year') {
            this.stringifiedFilters.years = JSON.stringify(this.filters.year);
        }
        if (filterName == 'status') {
            this.stringifiedFilters.status = JSON.stringify(this.filters.status);
        }
        if (filterName == 'contractSequence') {
            this.stringifiedFilters.contractSequence = JSON.stringify(this.filters.contractSequence);
        }
    }

    handleSearch() {
        this.nextRecordsUrl = null;
        this.contractSellInToUpdateMap = {}
        this.loadData();
        this.searchMode = false;
    }

    handleReset() {
        this.nextRecordsUrl = null;
        this.contractSellInToUpdateMap = {}
        // const scrollBody = this.template.querySelector('.scrollBody');
        // if (scrollBody) {
        //     scrollBody.scrollLeft = 0;
        // }
        this.loadData();
    }

    handleFieldEdits(event) {
        const recordIndex = event.target?.dataset.index;
        const fieldIndex = event.target?.dataset.fieldIndex;
        const groupIndex = event.target?.dataset.groupIndex;
        let newValue = event.detail == null
            ? (event.target.value == null ? event.target.checked : event.target.value)
            : (event.detail.value == null ? event.detail.checked : event.detail.value);
        newValue = (Array.isArray(newValue) ? newValue[0] : newValue) || null;
        if (event.target.type === 'checkbox') {
            newValue = event.target.checked;
        }    
        const group = this.records[groupIndex];
        const record = group.records[recordIndex];
        let oldValue = record.values[fieldIndex].fieldValue;
        record.values[fieldIndex].fieldValue = newValue;
        let fieldName = record.values[fieldIndex].fieldName;

        if (group && group.total && group.total.length > 0) {
            this.recalculateGroupTotals(group, fieldName, oldValue, newValue);
        }
        let object;
        if (this.contractSellInToUpdateMap.hasOwnProperty(record.Id)) {
            object = this.contractSellInToUpdateMap[record.Id];
        } else {
            object = {
                attributes: { type: this.API_NAMES.ContractSellin__c.objectApiName },
                Id: record.Id
            };
        }
        if (fieldName == 'New_NegoSellInDiscTotal') {
            fieldName = API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c;
        }
        object[fieldName] = newValue;
        if (fieldName == API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c) {
            const BoAdd = parseFloat(newValue) || 0;
            const Stated = parseFloat(record.values.find(field => field.fieldName == API_NAMES.ContractSellin__c.StatedSellInDiscTotal__c)?.fieldValue) || 0;
            let New_NegoSellInDiscTotal = record.values.find(field => field.fieldName == 'New_NegoSellInDiscTotal');
            let oldValue = New_NegoSellInDiscTotal.fieldValue;
            New_NegoSellInDiscTotal.fieldValue = BoAdd + Stated;
            if (group && group.total && group.total.length > 0) {
                this.recalculateGroupTotals(group, 'New_NegoSellInDiscTotal', oldValue, BoAdd + Stated);
            }
            object[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c] = BoAdd + Stated;
        }
        this.contractSellInToUpdateMap[record.Id] = object;
        this.recalculateFormulaFields(group, record);
    }

    recalculateFormulaFields(group, record) {
        let item = record.item;
        let changedItem = this.contractSellInToUpdateMap[record.Id] || {};
        record.values.forEach(field => {
            if (field.fieldName === 'LBL_SellIn_BO_Total') {
                const boTotal =(changedItem[API_NAMES.ContractSellin__c.StatedSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.StatedSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.StatedSellInDiscTotal__c])) || 0;
                const boAdditional = (changedItem[API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c]) : parseFloat(item[API_NAMES.ContractSellin__c.BOSellInDiscAdditional__c])) || 0;
                let oldValue = field.fieldValue;
                field.fieldValue = boTotal + boAdditional;
                if (group && group.total && group.total.length > 0) {
                    this.recalculateGroupTotals(group, field.fieldName, oldValue, field.fieldValue);
                }
            } else if (field.fieldName === 'LBL_SellIn_Evol1') {
                const negoSellInDisc = (changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c])) || 0;
                const negoInit = (changedItem[API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.ContractSellInP1__r][API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c])) || 0;
                let oldValue = field.fieldValue;
                field.fieldValue = negoInit !== 0 ? (negoSellInDisc / negoInit) : 0;
                if (group && group.total && group.total.length > 0) {
                    this.recalculateGroupTotals(group, field.fieldName, oldValue, field.fieldValue);
                }
            } else if (field.fieldName === 'LBL_SellIn_Evol2') {
                const negoSellInDisc = (changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c])) || 0;
                const negoInit = (changedItem[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c])) || 0;
                let oldValue = field.fieldValue;
                field.fieldValue = negoInit !== 0 ? (negoSellInDisc / negoInit) : 0;
                if (group && group.total && group.total.length > 0) {
                    this.recalculateGroupTotals(group, field.fieldName, oldValue, field.fieldValue);
                }
            } else if (field.fieldName === 'LBL_SellIn_Evol3') {
                const negoSellInDisc = (changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c])) || 0;
                const prevNegoSellInDisc = (changedItem[API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.ContractSellInP1__r][API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.ContractSellInP1__r]?.[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c])) || 0;
                let oldValue = field.fieldValue;
                field.fieldValue = prevNegoSellInDisc !== 0 ? (negoSellInDisc / prevNegoSellInDisc) : 0;
                if (group && group.total && group.total.length > 0) {
                    this.recalculateGroupTotals(group, field.fieldName, oldValue, field.fieldValue);
                }
            } else if (field.fieldName === 'LBL_SellIn_Evol4') {
                const negoSellInDisc = (changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.NegoSellInDiscTotal__c])) || 0;
                const negoInit = (changedItem[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c] !== undefined ? parseFloat(changedItem[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c]) : parseFloat(item[API_NAMES.ContractSellin__c.NegoInitSellInDiscTotal__c])) || 0;
                let oldValue = field.fieldValue;
                field.fieldValue = negoInit !== 0 ? (negoSellInDisc / negoInit) : 0;
                if (group && group.total && group.total.length > 0) {
                    this.recalculateGroupTotals(group, field.fieldName, oldValue, field.fieldValue);
                }
            }
        });
    }

    toggleFilter() {
        this.searchMode = true;
    }
    /**
     *  save all changes made by the user
     */
    handleSave() {
        this.isLoading = true;   
        let todayDate = new Date();
        Object.keys(this.contractSellInToUpdateMap || {}).forEach(id => {
            if (this.contractSellInToUpdateMap[id].hasOwnProperty(API_NAMES.ContractSellin__c.Review__c)
                && this.contractSellInToUpdateMap[id][API_NAMES.ContractSellin__c.Review__c] == true
                && (!this.contractSellInToUpdateMap[id].hasOwnProperty(API_NAMES.ContractSellin__c.ReviewDate__c)
                    || (this.contractSellInToUpdateMap[id].hasOwnProperty(API_NAMES.ContractSellin__c.ReviewDate__c)
                        && this.contractSellInToUpdateMap[id][API_NAMES.ContractSellin__c.ReviewDate__c] == null))) {
                this.contractSellInToUpdateMap[id][API_NAMES.ContractSellin__c.ReviewDate__c] = todayDate.getFullYear() + '-' + (todayDate.getMonth() + 1) + '-' + todayDate.getDate();
            } else {
                this.contractSellInToUpdateMap[id][API_NAMES.ContractSellin__c.ReviewDate__c] = null
            }
        });
        const recordToUpdate = JSON.stringify(Object.values(this.contractSellInToUpdateMap));
        console.log('recordToUpdate >>>> ' + recordToUpdate);
        save({
            recordsToUpdateJSON: recordToUpdate
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.contractSellInToUpdateMap = {};
                this.showNotification(this.labels.LBL_Success, '', this.toastEventVariant.success);
                this.loadData();
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error');
                console.log('Save: %c' + result, 'color : red');
                this.isLoading = false;
            }
        }).catch((error) => {
            this.showNotification(this.labels.LBL_Error, (error?.body?.message || error?.message), this.toastEventVariant.error);
            console.log('Save: %c' + error.message, 'color : red');
            console.log('Save: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    //Export Excel
    exportExcel() {
        this.allRecordsToExport = [];
        try {
            this.isLoading = true;
            processRestForExcel({
                filtersJson: JSON.stringify(this.filters),
                restURL: null
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    this.totalExportSize = parsedResult.totalSize;
                    this.rowCounter = 0;
                    if (parsedResult.error != null) {
                        this.showNotification(this.labels.LBL_Error, parsedResult.error, 'error');
                        return;
                    }
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                            this.rowCounter += parsedResult.records.length;
                        }
                        if (parsedResult.done) {
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.showNotification(this.labels.LBL_Error, error.message, 'error');
                }
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.showNotification(this.labels.LBL_Error, error.message, 'error');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification(this.labels.LBL_Error, error.message, 'error');
        }
    }

    excelLoadMore(nextRecordsUrl) {
        processRestForExcel({
            restURL: nextRecordsUrl
        }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result)
                try {
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                            this.rowCounter += parsedResult.records.length;
                        }
                        if (parsedResult.done) {
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.showNotification(this.labels.LBL_Error, error.message, 'error');
                }
            }
        });
    }

    buildExcel() {
        let dataToExport = this.buildTotalData(this.allRecordsToExport, this.allRecordsToExport);
        try {
            const workbook = new ExcelJS.Workbook();
            workbook.properties.date1904 = true;
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet(this.labels.LBL_SellIn_Mass_Update, { properties: { tabColor: { argb: 'worksheet' } } });
            let rowCounter = 1;
            const headerRow1 = worksheet.getRow(rowCounter);
            const header1Values = [];
            const colWidthStyle = [];
            const headerStyles = [];
            for (let field of this.displayedFields) {
                header1Values.push(field.fieldLabel);
                colWidthStyle.push(field.width);
                headerStyles.push(field.headerStyle);
            }
            headerRow1.values = header1Values;
            rowCounter++;
            headerRow1.eachCell(function (cell, colNumber) {
                const style = headerStyles[colNumber - 2] || '';
                const bgMatch = style.match(/(?:^|;)\s*background-color:\s*#([0-9a-fA-F]{6})/);
                const colorMatch = style.match(/(?:^|;)\s*color:\s*#([0-9a-fA-F]{6})/);
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: bgMatch ? bgMatch[1] : '0d807d' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: colorMatch ? colorMatch[1] : 'FFFFFF' },
                }
                cell.border = {
                    top: { style: 'thin', color: { argb: 'E6E6E6' } },
                    left: { style: 'thin', color: { argb: 'E6E6E6' } },
                    bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                    right: { style: 'thin', color: { argb: 'E6E6E6' } }
                };
                cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center', };
            });
            for (let group of dataToExport) {
                let rowLine;
                let rowValues = [];
                let recordIndex = 0;
                for (let record of group.records) {
                    rowLine = worksheet.getRow(rowCounter);
                    rowLine.height = 20;
                    rowValues = [];
                    let style = [];
                    let index = 1;
                    if (recordIndex == 0) {
                        for (let field of group.values) {
                            let value = '';
                            if (field.isPicklist || field.isReference) {
                                value = field.fieldOutputValue ?? ' ';
                            } else if (field.isDate) {
                                value = new Date(field.fieldValue) ?? ' ';
                            } else {
                                value = field.fieldValue ?? ' ';
                            }
                            rowValues.push(value);
                            style.push({ fgColor: field.bgColor });
                        }
                    } else {
                        for (let field of group.values) {
                            rowValues.push('');
                            style.push({ fgColor: field.bgColor });
                        }
                    }
                    for (let field of record.values) {
                        let value = '';
                        if (field.isPicklist || field.isReference) {
                            value = field.fieldOutputValue ?? ' ';
                        } else if (field.isDate) {
                            value = new Date(field.fieldValue) ?? ' ';
                        } else {
                            value = field.fieldValue ?? ' ';
                        }
                        rowValues.push(value);
                        style.push({ fgColor: field.bgColor });
                        index++;
                    }
                    rowLine.values = rowValues;
                    recordIndex++;
                    rowLine.eachCell(function (cell, colNumber) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: style[colNumber - 1].fgColor },
                        };
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'E6E6E6' } },
                            left: { style: 'thin', color: { argb: 'E6E6E6' } },
                            bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                            right: { style: 'thin', color: { argb: 'E6E6E6' } }
                        };
                        cell.alignment = {
                            wrapText: true,
                            vertical: 'middle',
                            horizontal: style[colNumber - 1].horizAlign
                        };
                    });
                    // if (recordIndex == group.records.length) {
                    //     let rowIndex = rowCounter - group.records.length + 1
                    //     for (let col = 1; col <= this.displayedFields.length; col++) {
                    //         if (this.displayedFields[col - 1].merged) {
                    //             worksheet.mergeCells(rowIndex, col, rowCounter, col);
                    //         }
                    //     }
                    // }
                    rowCounter++;
                }

                if (group.total && group.total.length) {
                    let rowLine = worksheet.getRow(rowCounter);
                    rowLine.height = 20;
                    let rowValues = [];
                    let style = [];
                    for (let field of group.values) {
                        rowValues.push('');
                        style.push({ fgColor: field.bgColor || 'FFFFFF', horizAlign: 'center' });
                    }
                    for (let field of group.total) {
                        let value = '';
                        if (field.isNumberField || field.isPercent) {
                            value = field.fieldValue ?? 0;
                        } else {
                            value = field.fieldValue ?? ' ';
                        }
                        rowValues.push(value);
                        style.push({ fgColor: field.bgColor || 'FFFFFF', horizAlign: 'right' });
                    }
                    rowLine.values = rowValues;
                    rowLine.eachCell(function (cell, colNumber) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: style[colNumber - 1].fgColor },
                        };
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'E6E6E6' } },
                            left: { style: 'thin', color: { argb: 'E6E6E6' } },
                            bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                            right: { style: 'thin', color: { argb: 'E6E6E6' } }
                        };
                        cell.alignment = {
                            wrapText: true,
                            vertical: 'middle',
                            horizontal: style[colNumber - 1].horizAlign
                        };
                    });
                    rowCounter++;
                }
                const totalRows = group.records.length + (group.total?.length ? 1 : 0);
                const mergeStart = rowCounter - totalRows;
                const mergeEnd = rowCounter - 1;
                for (let col = 1; col <= this.displayedFields.length; col++) {
                    if (this.displayedFields[col - 1].merged) {
                        const startCell = worksheet.getCell(mergeStart, col);
                        const endCell = worksheet.getCell(mergeEnd, col);
                        if (!startCell.isMerged && !endCell.isMerged) {
                            worksheet.mergeCells(mergeStart, col, mergeEnd, col);
                        }
                    }
                }
            }
            for (let index in colWidthStyle) {
                let colIndex = parseInt(index) + 1;
                worksheet.getColumn(colIndex).width = colWidthStyle[index];
            }
            worksheet._rows[0]._cells.forEach(cell => {
                cell.protection = { locked: true, lockText: false };
            });
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement("a");
                document.body.appendChild(a);
                a.style = "display: none";
                let base64Bin = result.toString('base64');
                a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
                a.download = this.labels.LBL_SellIn_Mass_Update + '.xlsx'; //File name Here
                a.click();
                this.isLoading = false;
            });
        } catch (error) {
            this.isLoading = false;
            console.log('error > ' + error)
        }
    }

    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBodyDiv = this.template.querySelector(".bodyDiv");
            let footerDiv = this.template.querySelector(".footerDiv");
            if (
                pageHeader != null &&
                mainContainer != null &&
                pageBodyDiv != null
            ) {
                pageBodyDiv.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - (footerDiv ? footerDiv.offsetHeight : 0) + "px";
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

    setFixedColumns() {
        let tables = this.template.querySelectorAll('.sessionTable');
        let headers = this.template.querySelectorAll('.main-header');
        for (const table of tables) {
            let tableTrs = table?.rows
            if (tableTrs) {
                let top = 0;
                let sitckyLeft = 0;
                for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                    let childrens = tableTrs[index].children;
                    let removedRowsCount = this.displayedFields.length - childrens.length;
                    if (childrens.length < this.nbOfFixedColumns) {
                        removedRowsCount = 0;
                    }
                    let left = removedRowsCount > 0 ? sitckyLeft : 0;
                    for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                        if (index2 < this.nbOfFixedColumns - removedRowsCount) {
                            const innerDiv = childrens[index2].querySelector('div');
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.left = (left - (index2 + 1)) + 'px';
                            if (innerDiv) {
                                if (index == 0) {
                                    top = childrens[index2].offsetHeight;
                                } else {
                                    // innerDiv.style.top = 67 + 'px';
                                    // childrens[index2].style.verticalAlign = 'top';
                                }
                                // innerDiv.style.position = 'sticky';
                            }
                            childrens[index2].style.zIndex = 1;
                            left += childrens[index2].offsetWidth;
                            childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                            if (removedRowsCount == 0 && sitckyLeft == 0 && index2 == 4) {
                                sitckyLeft = left - (index2 + 1);
                            }
                        }
                        // childrens[index2].style.border = "none";
                        // childrens[index2].style.outline = "rgb(189 183 183 / 49%) solid 0.1px";
                    }
                }
            }
        }
        let left = 0;
        for (let index = 0; headers && index < headers.length; index++) {
            let childrens = headers[index];
            if (index < this.nbOfFixedColumns) {
                childrens.style.position = 'sticky';
                childrens.style.left = ((left - (index + 1)) + 'px');
                childrens.style.zIndex = 1;
                left += childrens.offsetWidth;
            }
        }
    }

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