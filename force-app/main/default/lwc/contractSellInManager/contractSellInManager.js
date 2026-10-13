import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import initData from '@salesforce/apex/ContractSellInManagerController.initData';
import loadData from '@salesforce/apex/ContractSellInManagerController.loadData';
import save from '@salesforce/apex/ContractSellInManagerController.save';
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { labels, CONTRACTSELLIN_API_NAMES } from './properties.js';

export default class ContractSellInManager extends NavigationMixin(LightningElement) {

    @api recordId;
    @api displayAsScopedView;
    @track loading = false;
    @track headerName = '';
    @track labels = labels;
    CONTRACTSELLIN_API_NAMES = CONTRACTSELLIN_API_NAMES;
    @track records = [];
    @track initRecords = [];
    @track summaryRecords = [];
    @track sellInFields = [];
    @track sellInQtyFields = [];
    @track displayedFields = [];
    contractSellInInitial = [];
    contractSellInToUpdateMap = {};
    openedRecord;
    rendered = false;
    @track isAdvancedNS = false;

    get hasChanges() {
        return this.contractSellInToUpdateMap && Object.keys(this.contractSellInToUpdateMap).length > 0;
    }
    @wire(getObjectInfo, { objectApiName: CONTRACTSELLIN_API_NAMES.objectApiName }) objectInfoCS({ error, data }) {
        if (data) {
            this.labels.ContractSellInLabel = data.label;
        } else if (error) {
            console.log('ERROR');
        }
    }


    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                if (pageRef.state.hasOwnProperty('c__recordId')) {
                    this.recordId = pageRef.state.c__recordId;
                } else if (pageRef.state.hasOwnProperty('recordId')) {
                    this.recordId = pageRef.state.recordId;
                } else {
                    this.recordId = this.recordId;
                }
                this.initData();
            }
        } catch (error) {
            this.handleError(error, 'getPageReference');
        }
    }

    connectedCallback() {
        loadStyle(this, negOptimGlobalCSS);
        this.initData();
        window.addEventListener('resize', this.changeHeight);
    }

    renderedCallback() {
        let body = this.template.querySelector('.main-panel');
        let header = this.template.querySelector('.header');
        if (!this.rendered && body && header) {
            this.changeHeight();
            this.rendered = true;
        }
    }

    initData() {
        this.loading = true;
        initData({ contractId: this.recordId }).then((result) => {
            let parsedResult = JSON.parse(result);
            let contract = parsedResult.contract;
            this.isAdvancedNS = parsedResult.isAdvancedNS;
            this.headerName = contract.Name;
            this.sellInFields = parsedResult.sellInFields;
            this.sellInQtyFields = parsedResult.sellInQtyFields;
            this.sellInFields.forEach(field => {
                field.style1 = 'background-color:' + field.colorShade1 + ';color:white;text-align:center;';
                field.style2 = 'background-color:' + field.colorShade2 + ';text-align:center;';
            })
            this.sellInQtyFields.forEach(field => {
                field.style1 = 'background-color:' + field.colorShade1 + ';color:white;text-align:center;';
                field.style2 = 'background-color:' + field.colorShade2 + ';text-align:center;';
            })
            this.loadData();
        }).catch(error => {
            console.error(error);
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
        });

    }

    loadData() {
        this.loading = true;
        loadData({ contractId: this.recordId }).then((result) => {
            let data = JSON.parse(result);
            this.contractSellInInitial = data;
            this.buildData(data);
        }).catch(error => {
            console.error(error);
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
        });

    }

    buildData(data) {
        let dataMap = {};
        let sellInBaseNames = [...new Set(data.filter(item => (item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c] == null || item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c] == undefined)
            && (item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] == null || item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] == undefined)).map(item => item[CONTRACTSELLIN_API_NAMES.SellInBaseName__c]))];
        let years = [...new Set(data.filter(item => item[CONTRACTSELLIN_API_NAMES.LineType__c] == 'YearBase' && (item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c] == null || item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c] == undefined)
            && (item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] == null || item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] == undefined)).map(item => item[CONTRACTSELLIN_API_NAMES.Year__c]))];
        for (let sellInBaseName of sellInBaseNames) {
            let scope = {};
            if (!dataMap.hasOwnProperty(sellInBaseName)) {
                let scope = {
                    Name: sellInBaseName,
                    sellInValues: [],
                    firstRowSellInValue: {},
                    sellInQuantities: [],
                    firstRowSellInQty: {},
                    rowspan: 0,
                    rowspanSellInValues: 0,
                    rowspanSellInQty: 0,
                    isOpen: this.openedRecord && this.openedRecord == sellInBaseName,
                    iconUtility: this.isOpen ? 'utility:down' : 'utility:right',
                }
                dataMap[sellInBaseName] = scope;
            }
            scope = dataMap[sellInBaseName];
            // build Total Line
            let totalData = data.filter(item => item[CONTRACTSELLIN_API_NAMES.SellInBaseName__c] == sellInBaseName && item[CONTRACTSELLIN_API_NAMES.LineType__c] == 'TotalBase');
            // let totalData = data.filter(item => item[CONTRACTSELLIN_API_NAMES.LineType__c] == 'TotalBase' && (item[CONTRACTSELLIN_API_NAMES.SellInBaseName__c] == sellInBaseName || (item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c] && item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__r][CONTRACTSELLIN_API_NAMES.SellInBaseName__c] == sellInBaseName)));
            let totalLineWrapperValue = {
                key: 'TOTAL',
                name: this.labels.LBL_SummaryTotal,
                parentId: null,
                advancedContractSellIn: totalData[0].Id,
                nsId: totalData[0][CONTRACTSELLIN_API_NAMES.NegoScope__c],
                style: '',
                class: 'groupCell tdCell',
                values: []
            }
            for (let field of this.sellInFields) {
                totalLineWrapperValue.values.push({ value: 0, style: field.style1, class: '' })
            }
            let totalLineWrapperQty = {
                key: 'TOTAL',
                name: this.labels.LBL_SummaryTotal,
                parentId: null,
                advancedContractSellIn: totalData[0].Id,
                nsId: totalData[0][CONTRACTSELLIN_API_NAMES.NegoScope__c],
                style: '',
                class: 'groupCell tdCell',
                values: []
            }
            for (let field of this.sellInQtyFields) {
                totalLineWrapperQty.values.push({ value: 0, style: field.style1, class: '' })
            }
            let totalN1LineWrapperValue = {
                name: this.labels.LBL_SummaryTotalN1,
                style: 'background-color: #b1adac;',
                class: 'groupCell tdCell',
                values: []
            }
            for (let field of this.sellInFields) {
                totalN1LineWrapperValue.values.push({ value: 0, style: field.style1, class: '' })
            }
            let totalN1LineWrapperQty = {
                name: this.labels.LBL_SummaryTotalN1,
                style: 'background-color: #b1adac;',
                class: 'groupCell tdCell',
                values: []
            }
            for (let field of this.sellInQtyFields) {
                totalN1LineWrapperQty.values.push({ value: 0, style: field.style1, class: '' })
            }
            for (let item of totalData) {
                // Total Value
                for (let index in this.sellInFields) {
                    totalLineWrapperValue.values[index].value += item[this.sellInFields[index].fieldName] ? item[this.sellInFields[index].fieldName] : 0;
                }
                // Total N1 Value
                for (let index in this.sellInFields) {
                    totalN1LineWrapperValue.values[index].value += item[CONTRACTSELLIN_API_NAMES.ContractSellInP1__c] && item[CONTRACTSELLIN_API_NAMES.ContractSellInP1__r][this.sellInFields[index].fieldName] ? item[CONTRACTSELLIN_API_NAMES.ContractSellInP1__r][this.sellInFields[index].fieldName] : 0;
                }
                // Total Qty
                for (let index in this.sellInQtyFields) {
                    totalLineWrapperQty.values[index].value += item[this.sellInQtyFields[index].fieldName] ? item[this.sellInQtyFields[index].fieldName] : 0;
                }
                // Total N1 Qty
                for (let index in this.sellInQtyFields) {
                    totalN1LineWrapperQty.values[index].value += item[CONTRACTSELLIN_API_NAMES.ContractSellInP1__c] && item[CONTRACTSELLIN_API_NAMES.ContractSellInP1__r][this.sellInQtyFields[index].fieldName] ? item[CONTRACTSELLIN_API_NAMES.ContractSellInP1__r][this.sellInQtyFields[index].fieldName] : 0;
                }
            }
            scope.sellInValues.push(totalLineWrapperValue);
            scope.sellInQuantities.push(totalLineWrapperQty);
            // build Year Lines + NS
            for (let year of years) {
                year = year;
                let yearData = data.filter(item => item[CONTRACTSELLIN_API_NAMES.SellInBaseName__c] == sellInBaseName && item[CONTRACTSELLIN_API_NAMES.LineType__c] == 'YearBase' && item[CONTRACTSELLIN_API_NAMES.Year__c] == year
                    && (item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] == null || item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] == undefined)
                );
                if (yearData && yearData.length > 0) {
                    let yearLineWrapperValue = {
                        key: 'YEAR',
                        year: year,
                        name: year || '---',
                        nsId: '',
                        style: 'background-color: #b1adac;',
                        class: 'groupCell tdCell',
                        values: []
                    }
                    for (let field of this.sellInFields) {
                        yearLineWrapperValue.values.push({ value: 0, style: field.style2, class: '' })
                    }
                    let yearLineWrapperQty = {
                        key: 'YEAR',
                        year: year,
                        name: year || '---',
                        nsId: '',
                        style: 'background-color: #b1adac;',
                        class: 'groupCell tdCell',
                        values: []
                    }
                    for (let field of this.sellInQtyFields) {
                        yearLineWrapperQty.values.push({ value: 0, style: field.style2, class: '' })
                    }
                    for (let item of yearData) {
                        // Total Value
                        for (let index in this.sellInFields) {
                            yearLineWrapperValue.values[index].value += item[this.sellInFields[index].fieldName] ? item[this.sellInFields[index].fieldName] : 0;
                        }
                        // Total Qty
                        for (let index in this.sellInQtyFields) {
                            yearLineWrapperQty.values[index].value += item[this.sellInQtyFields[index].fieldName] ? item[this.sellInQtyFields[index].fieldName] : 0;
                        }
                    }
                    scope.sellInValues.push(yearLineWrapperValue);
                    scope.sellInQuantities.push(yearLineWrapperQty);
                    let negoScopes = data.filter(item => item[CONTRACTSELLIN_API_NAMES.LineType__c] == 'YearBase'
                        && item[CONTRACTSELLIN_API_NAMES.Year__c] == year
                        && ((item[CONTRACTSELLIN_API_NAMES.SellInBaseName__c] == sellInBaseName && item[CONTRACTSELLIN_API_NAMES.NegoScope__r].RecordType.DeveloperName != 'Advanced')
                            || (item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c] && item[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__r][CONTRACTSELLIN_API_NAMES.SellInBaseName__c] == sellInBaseName)));
                    for (let nsLine of negoScopes) {
                        let buYearBases = data.filter(item => item[CONTRACTSELLIN_API_NAMES.LineType__c] == 'BUYearBase'
                            && item[CONTRACTSELLIN_API_NAMES.Year__c] == year
                            && ((item[CONTRACTSELLIN_API_NAMES.BusinessUnitMaster__c] != null && item[CONTRACTSELLIN_API_NAMES.ContractSellInParent__c] == nsLine.Id)));
                        let isExistBUYearBases = (buYearBases && buYearBases.length > 0);
                        let NSLineWrapperValue = {
                            key: isExistBUYearBases ? nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__c] : '',
                            year: year,
                            advancedContractSellIn: nsLine[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c],
                            parentId: nsLine[CONTRACTSELLIN_API_NAMES.ContractSellInParent__c],
                            nsId: nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__c],
                            name: nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__c] || '---',
                            style: '',
                            class: 'groupCell tdCell',
                            values: []
                        }
                        for (let field of this.sellInFields) {
                            NSLineWrapperValue.values.push({
                                Id: '',
                                isInput: isExistBUYearBases ? false : field.isEditable,
                                isEdit: false,
                                fieldName: field.fieldName,
                                value: 0,
                                style: isExistBUYearBases ? field.style2 : ('border: 1px solid' + field.colorShade2 + ';text-align:right;'),
                                class: isExistBUYearBases ? 'groupCell tdCell' : '',
                            })
                        }
                        let NSLineWrapperQty = {
                            key: isExistBUYearBases ? nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__c] : '',
                            year: year,
                            advancedContractSellIn: nsLine[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c],
                            parentId: nsLine[CONTRACTSELLIN_API_NAMES.ContractSellInParent__c],
                            nsId: nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__c],
                            name: nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__c] || '---',
                            style: '',
                            class: 'groupCell tdCell',
                            values: []
                        }
                        for (let field of this.sellInQtyFields) {
                            NSLineWrapperQty.values.push({
                                Id: '',
                                isInput: isExistBUYearBases ? false : field.isEditable,
                                isEdit: false,
                                fieldName: field.fieldName,
                                value: 0,
                                style: isExistBUYearBases ? field.style2 : ('border: 1px solid' + field.colorShade2 + ';text-align:right;'),
                                class: isExistBUYearBases ? 'groupCell tdCell' : '',
                            })
                        }
                        // Total Value
                        NSLineWrapperValue.Id = nsLine.Id;
                        NSLineWrapperValue.name = nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__r]?.Name;
                        for (let index in this.sellInFields) {
                            NSLineWrapperValue.values[index].value += nsLine[this.sellInFields[index].fieldName] ? nsLine[this.sellInFields[index].fieldName] : 0;
                        }
                        // Total Qty
                        NSLineWrapperQty.Id = nsLine.Id;
                        NSLineWrapperQty.name = nsLine[CONTRACTSELLIN_API_NAMES.NegoScope__r]?.Name;
                        for (let index in this.sellInQtyFields) {
                            NSLineWrapperQty.values[index].value += nsLine[this.sellInQtyFields[index].fieldName] ? nsLine[this.sellInQtyFields[index].fieldName] : 0;
                        }
                        scope.sellInValues.push(NSLineWrapperValue);
                        scope.sellInQuantities.push(NSLineWrapperQty);
                        // case BUYearBase
                        if (isExistBUYearBases) {
                            for (let buLine of buYearBases) {
                                let BULineWrapperValue = {
                                    year: year,
                                    advancedContractSellIn: buLine[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c],
                                    parentId: buLine[CONTRACTSELLIN_API_NAMES.ContractSellInParent__c],
                                    nsId: buLine[CONTRACTSELLIN_API_NAMES.NegoScope__c],
                                    name: buLine[CONTRACTSELLIN_API_NAMES.BusinessUnit__c] || '---',
                                    style: '',
                                    class: 'groupCell tdCell',
                                    values: []
                                }
                                for (let field of this.sellInFields) {
                                    BULineWrapperValue.values.push({
                                        Id: '',
                                        isInput: field.isEditable,
                                        isEdit: false,
                                        fieldName: field.fieldName,
                                        value: 0,
                                        style: 'border: 1px solid' + field.colorShade2 + ';text-align:right;',
                                        class: ''
                                    })
                                }
                                let BULineWrapperQty = {
                                    year: year,
                                    advancedContractSellIn: buLine[CONTRACTSELLIN_API_NAMES.ContractSellInAdvanced__c],
                                    parentId: buLine[CONTRACTSELLIN_API_NAMES.ContractSellInParent__c],
                                    nsId: buLine[CONTRACTSELLIN_API_NAMES.NegoScope__c],
                                    name: buLine[CONTRACTSELLIN_API_NAMES.BusinessUnit__c] || '---',
                                    style: '',
                                    class: 'groupCell tdCell',
                                    values: []
                                }
                                for (let field of this.sellInQtyFields) {
                                    BULineWrapperQty.values.push({
                                        Id: '',
                                        isInput: field.isEditable,
                                        isEdit: false,
                                        fieldName: field.fieldName,
                                        value: 0,
                                        style: 'border: 1px solid' + field.colorShade2 + ';text-align:right;',
                                        class: ''
                                    })
                                }
                                // Total Value
                                BULineWrapperValue.Id = buLine.Id;
                                BULineWrapperValue.name = buLine[CONTRACTSELLIN_API_NAMES.BusinessUnit__r]?.Name;
                                for (let index in this.sellInFields) {
                                    BULineWrapperValue.values[index].value += buLine[this.sellInFields[index].fieldName] ? buLine[this.sellInFields[index].fieldName] : 0;
                                }
                                // Total Qty
                                BULineWrapperQty.Id = buLine.Id;
                                BULineWrapperQty.name = buLine[CONTRACTSELLIN_API_NAMES.BusinessUnit__r]?.Name;
                                for (let index in this.sellInQtyFields) {
                                    BULineWrapperQty.values[index].value += buLine[this.sellInQtyFields[index].fieldName] ? buLine[this.sellInQtyFields[index].fieldName] : 0;
                                }
                                scope.sellInValues.push(BULineWrapperValue);
                                scope.sellInQuantities.push(BULineWrapperQty);
                            }
                        }
                    }
                }
            }
            scope.sellInValues.push(totalN1LineWrapperValue);
            scope.sellInQuantities.push(totalN1LineWrapperQty);
            scope.rowspan = scope.sellInValues.length - 1 + scope.sellInQuantities.length + 1;
            scope.rowspanSellInValues = scope.sellInValues.length;
            scope.rowspanSellInQty = scope.sellInQuantities.length;
            scope.firstRowSellInValue = scope.sellInValues[0];
            scope.firstRowSellInQty = scope.sellInQuantities[0];
            dataMap[sellInBaseName] = scope;
        }
        this.records = Object.values(dataMap);
        this.initRecords = JSON.parse(JSON.stringify(this.records));
        this.loading = false;
    }

    toggleEdit(event) {
        let field = event.target.dataset.field;
        let index = event.target.dataset.index;
        this.sellInFields.forEach(item => {
            if (item.fieldName == field) {
                item.isEdit = !item.isEdit;
            }
        })
        this.records.forEach(item => {
            item.sellInValues.forEach(line => {
                line.values[index].isEdit = !line.values[index].isEdit;
            });
            item.sellInQuantities.forEach(line => {
                line.values[index].isEdit = !line.values[index].isEdit;
            });
        });
    }

    handleFieldEdits(event) {
        this.loading = true;
        let Id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let year = event.target.dataset.year;
        let value = event.target.value;
        let recordIndex = event.target.dataset.recordIndex;
        let lineIndex = event.target.dataset.lineIndex;
        let index = event.target.dataset.index;
        let advancedContractSellIn = event.target.dataset.advancedContractsellin;
        let parentId = event.target.dataset.parentid;
        let nsId = event.target.dataset.nsid;
        let arrayValues = event.target.dataset.arrayValues;
        let obj;
        if (this.contractSellInToUpdateMap.hasOwnProperty(Id)) {
            obj = this.contractSellInToUpdateMap[Id];
        } else {
            obj = {
                attributes: {
                    type: CONTRACTSELLIN_API_NAMES.objectApiName,
                },
                Id: Id
            };
        }
        obj[field] = value;
        this.contractSellInToUpdateMap[Id] = obj;
        let oldValue = this.records[recordIndex][arrayValues][lineIndex].values[index].value;
        // Synchro with displayed data
        this.records[recordIndex][arrayValues][lineIndex].values[index].value = value;
        let yearLine = this.records[recordIndex][arrayValues].find(item => item.key == 'YEAR' && item.year == year);
        if (yearLine) {
            yearLine.values[index].value -= oldValue;
            yearLine.values[index].value += parseFloat(value);
        }
        let nsLine = this.records[recordIndex][arrayValues].find(item => item.key == nsId && item.year == year);
        let parentIds = [];
        let advancedContractSellInIds = [];
        if (parentId) parentIds.push(parentId);
        if (advancedContractSellIn) advancedContractSellInIds.push(advancedContractSellIn);
        if (nsLine) {
            nsLine.values[index].value -= oldValue;
            nsLine.values[index].value += parseFloat(value);
            parentIds.push(nsLine.parentId);
            advancedContractSellInIds.push(nsLine.advancedContractSellIn);
        }
        this.records[recordIndex][arrayValues][0].values[index].value -= oldValue;
        this.records[recordIndex][arrayValues][0].values[index].value += parseFloat(value);
        if (advancedContractSellInIds && advancedContractSellInIds.length > 0) {
            for (let advancedContractSellIn of advancedContractSellInIds) {
                let obj2;
                if (this.contractSellInToUpdateMap.hasOwnProperty(advancedContractSellIn)) {
                    obj2 = this.contractSellInToUpdateMap[advancedContractSellIn];
                } else {
                    obj2 = {
                        attributes: {
                            type: CONTRACTSELLIN_API_NAMES.objectApiName,
                        },
                        Id: advancedContractSellIn
                    };
                }
                obj2[field] = yearLine.values[index].value;
                this.contractSellInToUpdateMap[advancedContractSellIn] = obj2;
                //TotalBase record
                let obj3;
                let recAdvancedContractSellIn = this.records[recordIndex][arrayValues][0].advancedContractSellIn;
                if (this.contractSellInToUpdateMap.hasOwnProperty(recAdvancedContractSellIn)) {
                    obj3 = this.contractSellInToUpdateMap[recAdvancedContractSellIn];
                } else {
                    obj3 = {
                        attributes: {
                            type: CONTRACTSELLIN_API_NAMES.objectApiName,
                        },
                        Id: recAdvancedContractSellIn
                    };
                }
                obj3[field] = this.records[recordIndex][arrayValues][0].values[index].value;
                this.contractSellInToUpdateMap[recAdvancedContractSellIn] = obj3;
            }
        }
        if (parentIds && parentIds.length > 0) {
            for (let parentId of parentIds) {
                //TotalBase record
                let relatedParentLines = this.records[recordIndex][arrayValues].filter(item => item.parentId == parentId);
                let parentValue = 0;
                if (relatedParentLines) {
                    for (let item of relatedParentLines) {
                        parentValue += parseFloat(item.values[index].value);
                    }
                }
                let obj4;
                if (this.contractSellInToUpdateMap.hasOwnProperty(parentId)) {
                    obj4 = this.contractSellInToUpdateMap[parentId];
                } else {
                    obj4 = {
                        attributes: {
                            type: CONTRACTSELLIN_API_NAMES.objectApiName,
                        },
                        Id: parentId
                    };
                }
                obj4[field] = parentValue;
                this.contractSellInToUpdateMap[parentId] = obj4;
            }
        }
        this.loading = false;
    }

    handleSave() {
        this.loading = true;
        if (!this.contractSellInToUpdateMap || Object.keys(this.contractSellInToUpdateMap).length == 0) {
            this.showNotification(this.labels.MSG_No_Changes_To_Save, '', 'info');
            return;
        }
        save({
            recordsToUpsertJSON: JSON.stringify(Object.values(this.contractSellInToUpdateMap)),
            contractSellInInitialJSON: JSON.stringify(this.contractSellInInitial),
            isAdvancedNS: this.isAdvancedNS
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error');
            }
            this.loading = false;
            this.sellInFields.forEach(item => {
                item.isEdit = false;
            })
            this.records.forEach(item => {
                item.sellInValues.forEach(line => {
                    line.values.forEach(value => {
                        value.isEdit = false;
                    })
                });
                item.sellInQuantities.forEach(line => {
                    line.values.forEach(value => {
                        value.isEdit = false;
                    })
                });
            });
            this.loadData();
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.loading = false;
        })
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
        });
    }

    cancelChanges() {
        this.loading = true;
        this.sellInFields.forEach(item => {
            item.isEdit = false;
        })
        this.records.forEach(item => {
            item.sellInValues.forEach(line => {
                line.values.forEach(value => {
                    value.isEdit = false;
                })
            });
            item.sellInQuantities.forEach(line => {
                line.values.forEach(value => {
                    value.isEdit = false;
                })
            });
        });
        this.contractSellInToUpdateMap = {};
        this.records = JSON.parse(JSON.stringify(this.initRecords));
        this.loading = false;
    }

    changeHeight = () => this.setTableDimension();
    // setTableDimension
    setTableDimension() {
        let pageHeader = this.template.querySelector('.header');
        let pageBody = this.template.querySelector('.main-panel');
        if (pageHeader != null && pageBody != null) {
            //pageBody.style.height = window.innerHeight - (4 * 35) - pageHeader.offsetHeight - 10 + 'px';
        }
    }

    // show notification 
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    openCampaignData(event) {
        let nsName = event.currentTarget.dataset.id;
        for (let record of this.records) {
            if (record.Name == nsName) {
                record.isOpen = !record.isOpen;
                this.openedRecord = record.Name;
            } else {
                record.isOpen = false;
            }
            record.iconUtility = record.isOpen ? 'utility:down' : 'utility:right';
        }
    }
}