import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// APEX
import loadData from '@salesforce/apex/SellInSummaryControllerV2.loadData';
import save from '@salesforce/apex/SellInSummaryControllerV2.save';
//IMPORTS
import { API_NAMES, labels, tableHeader, colFieldsStyle } from './properties.js';
export default class SellInSummaryV2 extends LightningElement {
    @api recordId;
    tableHeader = tableHeader;
    labels = { ...labels }
    @track contractSellinData = [];
    @track isLoading = false;
    @track contractSellInWrapper = {};
    @track sellInNamesCols = {};
    contractSellInValueFields = [];
    contractSellInQtyFields = [];
    @track disableSave = true;
    @track years = [];
    @track isMultiYear = false;
    @track isAdvancedNS = false;
    @track hasData = false;
    @track changesMap = {};

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.isLoading = true;
        this.disableSave = true;
        this.contractSellInWrapper = {};
        this.contractSellinData = [];
        this.sellInNamesCols = [];
        this.contractSellInValueFields = [];
        this.contractSellInQtyFields = [];
        this.recordId = 'a0DQH00000ETZYb2AP';
        loadData({
            contractId: this.recordId,
        }).then(result => {
            this.contractSellInWrapper = JSON.parse(result);
            if (this.contractSellInWrapper) {
                this.hasData = this.contractSellInWrapper.contractSellinTotalBaseMap ?? false;
                this.contractSellInWrapper.years.forEach(year => {
                    this.years.push(year);
                });
                this.isMultiYear = this.years.length > 1;
                this.isAdvancedNS = this.contractSellInWrapper.isAdvancedNS;
                if (this.contractSellInWrapper.sellInConfiguration) {
                    this.contractSellInWrapper.sellInConfiguration.forEach(item => {
                        if (item.isActive) {
                            const header = tableHeader.find(element => element.key == item.sellInKey);
                            let sellInNameColWrapper = {
                                colNumber: item.colNumber,
                                sellInKey: item.sellInKey,
                                sellInName: item.sellInName,
                                isActive: item.isActive,
                                isEdit: item.isEdit,
                                fields: [],
                                style: header.style,
                                color: header.color,
                            }
                            switch (item.sellInKey) {
                                case "SummaryNego":
                                    sellInNameColWrapper.fields = [API_NAMES.ContractSellIn__c.NegoSellInDiscTotal__c, API_NAMES.ContractSellIn__c.NegoSellInDiscTotalQty__c];
                                    this.contractSellInValueFields.push(API_NAMES.ContractSellIn__c.NegoSellInDiscTotal__c);
                                    this.contractSellInQtyFields.push(API_NAMES.ContractSellIn__c.NegoSellInDiscTotalQty__c);
                                    break;
                                case "SummaryExitNego":
                                    sellInNameColWrapper.fields = [API_NAMES.ContractSellIn__c.NegoInitSellInDiscTotal__c, API_NAMES.ContractSellIn__c.NegoInitSellInDiscTotalQty__c];
                                    this.contractSellInValueFields.push(API_NAMES.ContractSellIn__c.NegoInitSellInDiscTotal__c);
                                    this.contractSellInQtyFields.push(API_NAMES.ContractSellIn__c.NegoInitSellInDiscTotalQty__c);
                                    break;
                                case "SummaryProvision":
                                    sellInNameColWrapper.fields = [API_NAMES.ContractSellIn__c.BOSellInDiscTotal__c, API_NAMES.ContractSellIn__c.BOSellInDiscTotalQty__c];
                                    this.contractSellInValueFields.push(API_NAMES.ContractSellIn__c.BOSellInDiscTotal__c);
                                    this.contractSellInQtyFields.push(API_NAMES.ContractSellIn__c.BOSellInDiscTotalQty__c);
                                    break;
                                case "SummarySupplier":
                                    sellInNameColWrapper.fields = [API_NAMES.ContractSellIn__c.StatedSellInDiscTotal__c, API_NAMES.ContractSellIn__c.StatedSellInDiscTotalQty__c];
                                    this.contractSellInValueFields.push(API_NAMES.ContractSellIn__c.StatedSellInDiscTotal__c);
                                    this.contractSellInQtyFields.push(API_NAMES.ContractSellIn__c.StatedSellInDiscTotalQty__c);
                                    break;
                                case "SummaryInvoicing":
                                    sellInNameColWrapper.fields = [API_NAMES.ContractSellIn__c.FactSellInTotal__c, API_NAMES.ContractSellIn__c.FactSellInTotalQty__c];
                                    this.contractSellInValueFields.push(API_NAMES.ContractSellIn__c.FactSellInTotal__c);
                                    this.contractSellInQtyFields.push(API_NAMES.ContractSellIn__c.FactSellInTotalQty__c);
                                    break;
                                case "SummaryBalanced":
                                    sellInNameColWrapper.fields = [API_NAMES.ContractSellIn__c.BalancedSellInTotal__c, API_NAMES.ContractSellIn__c.BalancedSellInTotalQty__c];
                                    this.contractSellInValueFields.push(API_NAMES.ContractSellIn__c.BalancedSellInTotal__c);
                                    this.contractSellInQtyFields.push(API_NAMES.ContractSellIn__c.BalancedSellInTotalQty__c);
                                    break;
                            }
                            this.sellInNamesCols.push(sellInNameColWrapper);
                        }
                    });
                }
                // get SellIn TO
                let sellInRows = this.buildSellInRow(true, this.contractSellInValueFields);
                this.contractSellinData.push({
                    label: this.labels.LBL_SummarySellInValue,
                    sellInRows: sellInRows
                });
                // get SellIn Qty
                sellInRows = this.buildSellInRow(false, this.contractSellInQtyFields);
                this.contractSellinData.push({
                    label: this.labels.LBL_SummarySellInQty,
                    sellInRows: sellInRows
                });
            }
            this.isLoading = false;
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    buildSellInRow(isSellinValue, contractSellInFields) {
        let sellInRows = [];
        let fieldValues = [];
        // get SellIn TO
        if (this.contractSellInWrapper.contractSellinTotalBaseMap) {
            let contractSellinTotalBase = this.contractSellInWrapper.contractSellinTotalBaseMap[this.contractSellInWrapper.mainNegoScopeId];
            contractSellInFields.forEach(fieldName => {
                let fieldWrapper = {
                    fieldName: fieldName,
                    fieldValue: contractSellinTotalBase[fieldName] || 0,
                    type: "decimal",
                    style: colFieldsStyle[fieldName].style,
                    isEdit: false,
                    isInput: !this.contractSellInWrapper.isAdvancedNS && Object.keys(this.contractSellInWrapper.contractSellinYearBaseMap).length == 0,
                    isUpdated: false,
                }
                fieldWrapper.style += 'font-weight: bold;';
                fieldWrapper.style += 'border-color:' + colFieldsStyle[fieldName].color + ';';
                fieldValues.push(fieldWrapper);
            });
            let sellInRowTotal = {
                key: isSellinValue ? 'SummaryTotalAmount' : 'SummaryTotalQty',
                id: contractSellinTotalBase.Id,
                label: this.labels.LBL_SummaryTotal,
                fieldValues: fieldValues,
                isDetailNS: false,
                isFirstRow: true,
                isYear: false,
                isP1: false,
                isUpdated: false,
                isSellinValue: isSellinValue,
            }
            sellInRows.push(sellInRowTotal);
            if (!this.isMultiYear) {
                if (this.contractSellInWrapper.isAdvancedNS) {
                    Object.keys(this.contractSellInWrapper.contractSellinTotalBaseMap).forEach(nsDetailId => {
                        if (nsDetailId != this.contractSellInWrapper.mainNegoScopeId) {
                            let contractSellinTotalBaseNSDetail = this.contractSellInWrapper.contractSellinTotalBaseMap[nsDetailId];
                            fieldValues = [];
                            contractSellInFields.forEach(fieldName => {
                                let fieldWrapper = {
                                    fieldName: fieldName,
                                    fieldValue: contractSellinTotalBaseNSDetail[fieldName] || 0,
                                    type: "decimal",
                                    style: colFieldsStyle[fieldName].style,
                                    isEdit: false,
                                    isInput: true,
                                    isUpdated: false,
                                }
                                fieldValues.push(fieldWrapper);
                                fieldWrapper.style += 'background-color:white;';
                                fieldWrapper.style += 'color:#7f7f7f;';
                                fieldWrapper.style += 'border-color:' + colFieldsStyle[fieldName].color + ';';
                            });
                            sellInRows.push({
                                key: (isSellinValue ? 'SummaryTotalAmount' : 'SummaryTotalQty') + nsDetailId,
                                parentKey: sellInRowTotal.key,
                                id: contractSellinTotalBaseNSDetail.Id,
                                label: contractSellinTotalBaseNSDetail[API_NAMES.ContractSellIn__c.NegoScope__r].Name,
                                fieldValues: fieldValues,
                                isDetailNS: true,
                                isFirstRow: false,
                                isNSdetail: true,
                                isYear: false,
                                isP1: false,
                                isUpdated: false,
                                isSellinValue: isSellinValue,
                            });
                        }
                    })
                }
            } else {
                this.years.forEach(year => {
                    let contractSellinYearBases = this.contractSellInWrapper.contractSellinYearBaseMap[this.contractSellInWrapper.mainNegoScopeId];
                    let sellInRowYear;
                    if (contractSellinYearBases) {
                        let contractSellinYearBase = contractSellinYearBases.filter(item => item[API_NAMES.ContractSellIn__c.Year__c] == year)[0];
                        if (contractSellinYearBase) {
                            fieldValues = [];
                            contractSellInFields.forEach(fieldName => {
                                let fieldWrapper = {
                                    fieldName: fieldName,
                                    fieldValue: contractSellinYearBase[fieldName] || 0,
                                    type: "decimal",
                                    style: colFieldsStyle[fieldName].style,
                                    isEdit: false,
                                    isInput: !this.contractSellInWrapper.isAdvancedNS,
                                    isUpdated: false,
                                }
                                fieldValues.push(fieldWrapper);
                                if (!this.contractSellInWrapper.isAdvancedNS) {
                                    fieldWrapper.style += 'background-color:white;';
                                    fieldWrapper.style += 'color:#7f7f7f;';
                                    fieldWrapper.style += 'border-color:' + colFieldsStyle[fieldName].color + ';';
                                } else {
                                    fieldWrapper.style += 'font-weight: bold;';
                                    fieldWrapper.style += 'color:#989595;';
                                    fieldWrapper.style += 'background-color:' + colFieldsStyle[fieldName].lightColor + ';';
                                    fieldWrapper.style += 'border-color:' + colFieldsStyle[fieldName].lightColor + ';';
                                }
                            });
                            sellInRowYear = {
                                key: (isSellinValue ? 'SummaryTotalAmount' : 'SummaryTotalQty') + year,
                                parentKey: sellInRowTotal.key,
                                id: contractSellinYearBase.Id,
                                label: year,
                                fieldValues: fieldValues,
                                isDetailNS: false,
                                isFirstRow: false,
                                year: year,
                                isYear: true,
                                isP1: false,
                                isUpdated: false,
                                isSellinValue: isSellinValue,
                            }
                            sellInRows.push(sellInRowYear);
                        }
                    }
                    if (this.contractSellInWrapper.isAdvancedNS) {
                        Object.keys(this.contractSellInWrapper.contractSellinYearBaseMap).forEach(nsDetailId => {
                            if (nsDetailId != this.contractSellInWrapper.mainNegoScopeId) {
                                contractSellinYearBases = this.contractSellInWrapper.contractSellinYearBaseMap[nsDetailId];
                                if (contractSellinYearBases) {
                                    let contractSellinYearBase = contractSellinYearBases.filter(item => item[API_NAMES.ContractSellIn__c.Year__c] == year)[0];
                                    if (contractSellinYearBase) {
                                        fieldValues = [];
                                        contractSellInFields.forEach(fieldName => {
                                            let fieldWrapper = {
                                                fieldName: fieldName,
                                                fieldValue: contractSellinYearBase[fieldName] || 0,
                                                type: "decimal",
                                                style: colFieldsStyle[fieldName].style,
                                                isEdit: false,
                                                isInput: true,
                                                isUpdated: false,
                                            }
                                            fieldValues.push(fieldWrapper);
                                            fieldWrapper.style += 'background-color:white;';
                                            fieldWrapper.style += 'color:#7f7f7f;';
                                            fieldWrapper.style += 'border-color:' + colFieldsStyle[fieldName].color + ';';
                                        });
                                        sellInRows.push({
                                            key: (isSellinValue ? 'SummaryTotalAmount' : 'SummaryTotalQty') + nsDetailId + year,
                                            parentKey: sellInRowYear?.key,
                                            id: contractSellinYearBase.Id,
                                            label: contractSellinYearBase[API_NAMES.ContractSellIn__c.NegoScope__r].Name,
                                            fieldValues: fieldValues,
                                            isDetailNS: true,
                                            isFirstRow: false,
                                            year: year,
                                            isYear: true,
                                            isP1: false,
                                            isUpdated: false,
                                            isSellinValue: isSellinValue,
                                        });
                                    }
                                }
                            }
                        });
                    }
                });
            }
        }
        fieldValues = [];
        contractSellInFields.forEach(fieldName => {
            let fieldWrapper = {
                fieldName: fieldName,
                fieldValue: (this.contractSellInWrapper.contractSellinTotalBaseP1 ? this.contractSellInWrapper.contractSellinTotalBaseP1[fieldName] : 0) || 0,
                type: "decimal",
                style: colFieldsStyle[fieldName].style,
                isEdit: false,
                isInput: false,
                isUpdated: false,
            }
            fieldWrapper.style += 'font-weight: bold;';
            fieldWrapper.style += 'color:#989595;';
            fieldWrapper.style += 'background-color:' + colFieldsStyle[fieldName].lightColor + ';';
            fieldWrapper.style += 'border-color:' + colFieldsStyle[fieldName].lightColor + ';';
            fieldValues.push(fieldWrapper);
        });
        sellInRows.push({
            key: (isSellinValue ? 'SummaryTotalAmountN1' : 'SummaryTotalQtyN1'),
            id: this.contractSellInWrapper.contractSellinTotalBaseP1?.Id,
            label: this.labels.LBL_SummaryTotalN1,
            fieldValues: fieldValues,
            isDetailNS: false,
            isFirstRow: false,
            isYear: false,
            isP1: true,
            isUpdated: false,
            isSellinValue: isSellinValue,
        });
        return sellInRows;
    }

    handleOpenLink() { }

    handleEditContractSellIn(event) {
        const key = event.target.dataset.key;
        const state = event.target.dataset.type ? true : false;
        const sellInCol = this.sellInNamesCols.find(item => item.sellInKey == key);
        const fields = sellInCol.fields;
        if (fields.length == 0)
            return;
        this.contractSellinData.forEach(record => {
            record.sellInRows.forEach(sellInRow => {
                sellInRow.fieldValues.forEach(fieldWrapper => {
                    if (fields.includes(fieldWrapper.fieldName)) {
                        fieldWrapper.isEdit = state;
                        sellInCol.edit = state;
                    }
                });
            });
        });
    }

    handleFieldEdit(event) {
        let key = event.target.dataset.key;
        let fieldName = event.target.dataset.field;
        let value = event.target.value;
        let parentKey = false;
        this.contractSellinData.forEach(record => {
            record.sellInRows.forEach(sellInRow => {
                if (sellInRow.key == key) {
                    let fieldWrapper = sellInRow.fieldValues.find(item => item.fieldName == fieldName);
                    fieldWrapper.fieldValue = value;
                    fieldWrapper.isUpdated = true;
                    sellInRow.isUpdated = true;
                    this.disableSave = false;
                    parentKey = sellInRow.parentKey;
                    if (!this.changesMap.hasOwnProperty(sellInRow.id)) {
                        this.changesMap[sellInRow.id] = {};
                    }
                    this.changesMap[sellInRow.id][fieldName] = value == '' ? null : value;
                }
            });
        });
        if (parentKey) {
            this.calculateTotalValues(parentKey);
        }
        this.contractSellinData = [...this.contractSellinData];
    }

    calculateTotalValues(parentKey) {
        let sellInRowParent;
        let sellInYearsRow = [];
        this.contractSellinData.forEach(record => {
            record.sellInRows.forEach(item => {
                if (item.key == parentKey) {
                    sellInRowParent = item;
                }
                if (item.parentKey == parentKey) {
                    sellInYearsRow.push(item);
                }
            });
        });
        if (sellInRowParent && sellInYearsRow.length > 0) {
            if (!this.changesMap.hasOwnProperty(sellInRowParent.id)) {
                this.changesMap[sellInRowParent.id] = {};
            }
            if (sellInRowParent.isSellinValue) {
                this.contractSellInValueFields.forEach(fieldName => {
                    let fieldWrapper = sellInRowParent.fieldValues.find(item => item.fieldName == fieldName);
                    if (fieldWrapper) fieldWrapper.fieldValue = 0;
                });
            } else {
                this.contractSellInQtyFields.forEach(fieldName => {
                    let fieldWrapper = sellInRowParent.fieldValues.find(item => item.fieldName == fieldName);
                    if (fieldWrapper) fieldWrapper.fieldValue = 0;
                });
            }
            sellInYearsRow.forEach(sellInRow => {
                if (sellInRowParent.isSellinValue) {
                    this.contractSellInValueFields.forEach(fieldName => {
                        let fieldWrapper = sellInRow.fieldValues.find(item => item.fieldName == fieldName);
                        let fieldWrapperParent = sellInRowParent.fieldValues.find(item => item.fieldName == fieldName);
                        fieldWrapperParent.fieldValue += fieldWrapper.fieldValue ? parseFloat(fieldWrapper.fieldValue) : 0;
                        this.changesMap[sellInRowParent.id][fieldName] = fieldWrapperParent.fieldValue;
                    });
                } else {
                    this.contractSellInQtyFields.forEach(fieldName => {
                        let fieldWrapper = sellInRow.fieldValues.find(item => item.fieldName == fieldName);
                        let fieldWrapperParent = sellInRowParent.fieldValues.find(item => item.fieldName == fieldName);
                        fieldWrapperParent.fieldValue += fieldWrapper.fieldValue ? parseFloat(fieldWrapper.fieldValue) : 0;
                        this.changesMap[sellInRowParent.id][fieldName] = fieldWrapperParent.fieldValue;
                    });
                }
            });
            parentKey = sellInRowParent.parentKey;
            if (parentKey) {
                this.calculateTotalValues(parentKey);
            }
        }
    }

    handleSave() {
        this.isLoading = true;
        this.tableHeader.forEach(element => {
            element.edit = false;
            element.focus = false;
        })
        let changesMap = this.changesMap;
        let recordsMap = {};
        Object.keys(changesMap).map(key => {
            let item = JSON.parse(JSON.stringify(changesMap[key]));
            item.Id = key;
            recordsMap[key] = item;
            return item;
        });
        save({ recordsMap: JSON.stringify(recordsMap) })
            .then(result => {
                this.showNotification(this.labels.LBL_Success, 'Success', 'success');
                this.loadData();
                this.isLoading = false;
            }).catch(error => {
                this.isLoading = false;
                this.showNotification(this.labels.LBL_Error, 'Error', 'error');
            })
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
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        }));
    }
}