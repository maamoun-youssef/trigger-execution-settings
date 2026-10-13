import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//APEX
import initData from '@salesforce/apex/SellInStatementManagerController.initData';
import loadData from '@salesforce/apex/SellInStatementManagerController.loadData';
import checkExistingSellInStatements from '@salesforce/apex/SellInStatementManagerController.checkExistingSellInStatements';
import runInitSellInStatementBatch from '@salesforce/apex/SellInStatementManagerController.runInitSellInStatementBatch';
import { checkCompletedBatches } from 'c/appHelper';
//IMPORTS
import { API_NAMES, Labels, PopupSellinFields } from './properties.js';

export default class SellInStatementManager extends LightningElement {
    @track isLoading = false;
    @track pageSize = 50;
    @track pageNumber = 1;
    get yearOptions() {
        let currentYear = new Date().getFullYear();
        return [
            { label: '' + (currentYear + 2), value: '' + (currentYear + 2) },
            { label: '' + (currentYear + 1), value: '' + (currentYear + 1) },
            { label: '' + (currentYear), value: '' + currentYear },
            { label: '' + (currentYear - 1), value: '' + (currentYear - 1) },
            { label: '' + (currentYear) - 2, value: '' + (currentYear - 2) }
        ]
    };
    initDataWrapper;
    @track periodOptions = [];
    @track periodValue = 1;
    labels = { ...Labels }
    totalPagesCount = 0;
    @track fieldsWrapperList = [];
    @track recordsWrapperList;
    @track isAllSelected = false;
    @track openInitSellinPopup = false;
    @track openConfirmationPopup = false;
    @track popupSellinFields;
    @track filterWrapper = {};
    @track sellinStatementConditions = [];
    @track nsConditions = [];
    @track totalNumbOfRecords = 0;
    @track initSellInStatementConfirmationMsg = '';
    @track selectedPeriodNumber;
    selectedPeriodType;
    @track selectedReferenceYear;
    @track sellInStatementAlreadyExistOnPeriod = '';
    @track isSellinStatementEmpty = false;
    negoScopeIds = new Set();
    checkStyle = 'background-color: #08484B;';
    negoScopeHeaderStyle = 'background-color: #08484B;color:white;min-width:100px;';
    sellinHeaderStyle = 'background-color: #14B3BB;color:white;';
    pageSizeOptions = [
        // { label: '5', value: 5, isSelected: false },
        // { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        // { label: '75', value: 75, isSelected: false },
        // { label: '100', value: 100, isSelected: false }
        { label: '250', value: 250, isSelected: false }
    ];
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }
    get pagesBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
    }
    get filterList() {
        let filter = [];
        let NSfilter = [];
        try {
            for (let field in this.filterWrapper) {
                if (this.filterWrapper[field].isSearchable) {
                    let ffilter;
                    if (this.filterWrapper[field].type == 'text' && this.filterWrapper[field].valuesList.length != 0) {
                        ffilter = '(' + this.filterWrapper[field].valuesList.map(item => ` ${field} LIKE '%${item.trim()}%' `).join(' OR ') + ')';
                    } else if (this.filterWrapper[field].type == 'picklist' && this.filterWrapper[field].valuesList.length != 0) {
                        ffilter = '' + field + ' IN (\'' + this.filterWrapper[field].valuesList.join('\', \'') + '\')';
                    } else if (this.filterWrapper[field].type == 'number') {
                        let filter1 = [];
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            // filter1 += '' + field + ' >= ' + this.filterWrapper[field].value1;
                            filter1.push('' + field + ' >= ' + this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            // ffilter += '' + field + ' <= ' + this.filterWrapper[field].value2;
                            filter1.push('' + field + ' <= ' + this.filterWrapper[field].value2);
                        }
                        ffilter = filter1?.join(' AND ');
                    } else if (this.filterWrapper[field].type == 'date') {
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            ffilter += '' + field + ' >= ' + this.filterWrapper[field].value1;
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            ffilter += '' + field + ' <= ' + this.filterWrapper[field].value2;
                        }
                    } else if (this.filterWrapper[field].type == 'datetime') {
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            ffilter += '' + field + ' >= ' + new Date(this.filterWrapper[field].value1).toISOString();
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            ffilter += '' + field + ' <= ' + new Date(this.filterWrapper[field].value2).toISOString();
                        }
                    }
                    if (ffilter) {
                        this.filterWrapper[field].isNS ? NSfilter.push(ffilter) : filter.push(ffilter);
                    }
                }
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
        return { 'NSFilters': NSfilter, 'sellinStatementFilters': filter };
    };
    get colspanDisplayedFields() {
        return this.fieldsWrapperList.length + 1;
    }
    //LIFECYCLE
    connectedCallback() {
        this.init();
        addEventListener('resize', this.setPageSize);
    }
    renderedCallback() {
        this.setPageSize();
    }

    init() {
        this.isLoading = true;
        this.isSellinStatementEmpty = false;
        initData().then(result => {
            let parsedResult = JSON.parse(result);
            this.initDataWrapper = parsedResult;
            if (parsedResult.generationModeIsManual) {
                this.fieldsWrapperList = this.buildFieldWrapper(parsedResult)
                PopupSellinFields.PeriodNumber__c.fieldLabel = this.fieldsWrapperList.find(item => item.fieldName == PopupSellinFields.PeriodNumber__c.fieldName).fieldLabel;
                PopupSellinFields.PeriodType__c.fieldLabel = this.fieldsWrapperList.find(item => item.fieldName == PopupSellinFields.PeriodType__c.fieldName).fieldLabel;
                PopupSellinFields.PeriodType__c.picklistOptions = this.fieldsWrapperList.find(item => item.fieldName == PopupSellinFields.PeriodType__c.fieldName).pickListValues;
                PopupSellinFields.ReferenceYear__c.fieldLabel = this.fieldsWrapperList.find(item => item.fieldName == PopupSellinFields.ReferenceYear__c.fieldName).fieldLabel;
                this.popupSellinFields = { ...PopupSellinFields }
                this.afterLoad();
            } else {
                this.showNotification('', this.labels.MSG_SellInStatementManualInitializationNotAvailable, 'info', 'sticky');
            }
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    buildFieldWrapper(parsedResult) {
        let fieldsList = [];
        parsedResult.negoScopeFields.forEach(field => {
            fieldsList.push({
                fieldLabel: field.fieldLabel,
                fieldName: field.fieldName,
                fieldType: field.fieldType,
                pickListValues: field.pickListValues ? field.pickListValues : [],
                selectedValues: [],
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                _isNumber: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                isReference: field.fieldType == 'REFERENCE' || field.fieldName == 'Name',
                isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isReferenceText: field.fieldType == 'STRING' || field.fieldType == 'REFERENCE',
                isText: field.fieldType == 'STRING' && field.fieldType == 'REFERENCE',
                headerStyle: this.negoScopeHeaderStyle,
                isNSField: true,
                value: null,
            });
        });
        parsedResult.sellinStatementFields.forEach(field => {
            if (field.fieldName == API_NAMES.SellInStatement__c.PeriodNumber__c) {
                field.fieldLabel = this.labels.LBL_Connect_LastPeriodNumberSent;
            } else if (field.fieldName == API_NAMES.SellInStatement__c.PeriodType__c) {
                field.fieldLabel = this.labels.LBL_Connect_LastPeriodTypeSent;
            }
            fieldsList.push({
                fieldLabel: field.fieldLabel,
                fieldName: field.fieldName,
                fieldType: field.fieldType,
                pickListValues: field?.picklistValues ? field?.picklistValues : [],
                selectedValues: [],
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                _isNumber: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                isReference: field.fieldType == 'REFERENCE' || field.fieldName == 'Name',
                isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isReferenceText: field.fieldType == 'STRING' || field.fieldType == 'REFERENCE',
                isText: field.fieldType == 'STRING',
                headerStyle: this.sellinHeaderStyle,
                isNSField: false,
                value: null,
            });
        });
        return fieldsList;
    }
    afterLoad() {
        loadData({
            initDataWrapperJson: JSON.stringify(this.initDataWrapper),
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            sellinStatementConditions: this.sellinStatementConditions,
            nsConditions: this.nsConditions,
            isSellinStatementEmpty: this.isSellinStatementEmpty,
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
            this.totalNumbOfRecords = parsedResult.totalSize;
            this.recordsWrapperList = [...this.buildDataWrapper(parsedResult.records)];
            this.isLoading = false;
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    buildDataWrapper(data) {
        data.forEach(row => {
            row.isSelected = this.isAllSelected ? true : (this.negoScopeIds.has(row.negoScope.Id) ? true : false);
            row.Id = row.negoScope.Id;
            row.columns = [];
            let fields = JSON.parse(JSON.stringify(this.fieldsWrapperList));
            fields.forEach(field => {
                let rowData = field.isNSField ? row.negoScope : row.sellInStatement;
                if (field.isReference) {
                    if (field.fieldName == 'Name') {
                        field.value = rowData[field.fieldName];
                    } else {
                        if (field.fieldName.endsWith('Id')) {
                            field.value = rowData[field.fieldName.replace('Id', '')]?.Name;
                        } else {
                            field.value = rowData[field.fieldName.replace('__c', '__r')]?.Name;
                        }
                    }
                    field.link = '/' + field.value;
                } else if (field.isPicklist) {
                    let found = field.pickListValues.find(item => item.value === rowData[field.fieldName]);
                    field.value = found?.label;
                } else {
                    field.value = rowData[field.fieldName];
                }
            });
            row.columns = JSON.parse(JSON.stringify(fields));;
        });
        return data;
    }
    toggleFilterPanel(event) {
        try {
            let field = event.target.dataset.field;
            this.template.querySelectorAll('[data-filter-field]').forEach(element => {
                if (element.dataset.filterField == field) {
                    element.classList.toggle('slds-hide');
                } else {
                    element.classList.add('slds-hide');
                }
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleChangeFilter(event) {
        try {
            let fieldName = event.target.dataset.field;
            let type = event.target.type;
            let value = event.target.value;
            let number = event.target.dataset.number;
            let isNS = event.target.dataset.nsfield;
            let field = this.fieldsWrapperList.find(field => field.fieldName === fieldName);
            if (!field) return;
            if (field.isReference) {
                if (field.fieldName.endsWith('Id')) {
                    fieldName = field.fieldName.replace('Id', '.Name');
                } else {
                    fieldName = field.fieldName.replace('__c', '__r.Name');
                }
            }
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (type === 'text') {
                let valuesList = (value != null && value !== '') ? value.split(",") : [];
                this.filterWrapper[fieldName].valuesList = valuesList.map(it => it.trim());
                field.isFiltered = valuesList.length !== 0;
                field.fieldSearchValue = value;
            } else if (type === 'number' || type === 'date' || type === 'datetime') {
                if (type === 'datetime') {
                    let selectedDate = new Date(value);
                    if (number === '1') {
                        selectedDate.setUTCHours(0, 0, 0, 0);
                        field.fieldSearchValue1 = selectedDate.toISOString();
                    } else if (number === '2') {
                        selectedDate.setUTCHours(23, 59, 59, 999);
                        field.fieldSearchValue2 = selectedDate.toISOString();
                    }
                    this.filterWrapper[fieldName][`value${number}`] = selectedDate;
                } else {
                    field[`fieldSearchValue${number}`] = value;
                    this.filterWrapper[fieldName][`value${number}`] = value;
                }
                field.isFiltered = (field.fieldSearchValue1 != null && field.fieldSearchValue1 !== '') || (field.fieldSearchValue2 != null && field.fieldSearchValue2 !== '');
            }
            this.filterWrapper[fieldName].type = type;
            this.filterWrapper[fieldName].isNS = isNS == 'true' ? true : false;
            this.filterWrapper[fieldName].isSearchable = true;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handlePicklistChange(event) {
        try {
            let fieldName = event.target.dataset.field;
            let value = event.detail.value;
            let field = this.fieldsWrapperList.find(field => field.fieldName === fieldName);
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (this.filterWrapper[fieldName].valuesList == null) {
                this.filterWrapper[fieldName].valuesList = [];
            }
            this.filterWrapper[fieldName].type = 'picklist';
            if (field) {
                field.isFiltered = value.length != 0;
                field.selectedValues = value;
                this.filterWrapper[fieldName].isSearchable = true;
            }
            this.filterWrapper[fieldName].valuesList = value;
            this.filterWrapper[fieldName].isNS = false;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleApplyFilters(event) {
        try {
            this.isLoading = true;
            this.sellinStatementConditions = [...this.filterList.sellinStatementFilters];
            this.nsConditions = [...this.filterList.NSFilters];
            // this.pageNumber = 1;
            this.afterLoad()
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    resetFilters() {
        try {
            this.filterWrapper = {};
            this.fieldsWrapperList.forEach(field => {
                if (field.isReferenceText) {
                    field.fieldSearchValue = '';
                } else if (field._isNumber || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                if (field.isFiltered) {
                    field.isFiltered = false;
                }
            });
            this.isLoading = true;
            this.sellinStatementConditions = [];
            this.nsConditions = [];
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    loadSellinStatementEmpty() {
        try {
            this.filterWrapper = {};
            this.fieldsWrapperList.forEach(field => {
                if (field.isReferenceText) {
                    field.fieldSearchValue = '';
                } else if (field._isNumber || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                if (field.isFiltered) {
                    field.isFiltered = false;
                }
            });
            this.isLoading = true;
            this.isSellinStatementEmpty = !this.isSellinStatementEmpty;
            this.sellinStatementConditions = [];
            this.nsConditions = [];
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleOpenInitSellinPopup(event) {
        this.sellInStatementAlreadyExistOnPeriod = '';
        let foundIndex = this.recordsWrapperList.findIndex(item => item.isSelected);
        if (foundIndex == -1) {
            this.showNotification(this.labels.LBL_Error, this.labels.MSG_NoRowSelected, 'error', 'dismissable');
        } else {
            this.openInitSellinPopup = true;
        }
    }
    handleBatchFieldsEdit(event) {
        let field = event.target.dataset.field;
        let value = event.detail.value;
        if (field == API_NAMES.SellInStatement__c.PeriodNumber__c) {
            this.selectedPeriodNumber = value;
        }
        if (field == API_NAMES.SellInStatement__c.PeriodType__c) {
            this.selectedPeriodType = value;
            this.periodOptions = [];
            let index = 1;
            this.periodValue = 1;
            switch (this.selectedPeriodType) {
                case ('Month'):
                    index = 12;
                    break;
                case ('Semester'):
                    index = 2;
                    break;
                case ('Trimester'):
                    index = 4;
                    break;
            }
            for (let i = 1; i <= index; i++) {
                this.periodOptions.push({ label: '' + i, value: '' + i });
            }
        }
        if (field == API_NAMES.SellInStatement__c.ReferenceYear__c) {
            this.selectedReferenceYear = value;
        }
    }
    handleGenerateSellinStatement() {
        this.sellInStatementAlreadyExistOnPeriod = '';
        const allValid = [
            ...this.template.querySelectorAll('.requiredField'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            checkExistingSellInStatements({
                negoScopeIds: [...this.negoScopeIds],
                year: this.selectedReferenceYear,
                periodType: this.selectedPeriodType,
                periodNumber: this.selectedPeriodNumber,
            }).then(result => {
                if (result != '') {
                    this.sellInStatementAlreadyExistOnPeriod = this.labels.MSG_SellInStatementAlreadyExistOnPeriod.replace('{0}', result);
                    this.loading = false;
                } else {
                    this.openInitSellinPopup = false;
                    let periodTypeLabel = this.popupSellinFields.PeriodType__c.picklistOptions.find(item => item.value == this.selectedPeriodType).label;
                    this.initSellInStatementConfirmationMsg = this.labels.MSG_InitSellInStatementConfirmation.replace('{0}', this.selectedReferenceYear).replace('{1}', periodTypeLabel).replace('{2}', this.selectedPeriodNumber);
                    this.openConfirmationPopup = true;
                }
            }).catch(error => {
                console.log(error);
                this.loading = false;
            });
        }
    }
    handleConfirmInitSellin(event) {
        this.openConfirmationPopup = false;
        this.isLoading = true;
        this.handleRunInitSellInStatementBatch();
    }
    handleClosePopup() {
        this.openInitSellinPopup = false;
        this.openConfirmationPopup = false;
    }
    handleRunInitSellInStatementBatch() {
        runInitSellInStatementBatch({
            negoScopeIds: [...this.negoScopeIds],
            year: this.selectedReferenceYear,
            periodType: this.selectedPeriodType,
            periodNumber: this.selectedPeriodNumber,
        }).then(batchId => {
            if (batchId != null) {
                checkCompletedBatches(this, batchId).then(result => {
                    this.afterLoad();
                }).catch(error => {
                    console.error(error);
                });
            } else {
                this.afterLoad();
            }
        }).catch(error => {
            console.log(error);
            this.loading = false;
        });
    }
    handeSelectRecord(event) {
        try {
            let index = event.target.dataset.index;
            let selectall = event.target.dataset.selectall;
            let value = event.target.checked;
            if (selectall) {
                this.isAllSelected = value;
                this.recordsWrapperList.forEach(element => {
                    element.isSelected = value;
                    this.negoScopeIds.add(element.Id)
                });
                if (!this.isAllSelected) {
                    this.negoScopeIds.clear();
                }
            } else {
                value ? this.negoScopeIds.add(this.recordsWrapperList[index].Id) : this.negoScopeIds.delete(this.recordsWrapperList[index].Id)
                this.recordsWrapperList[index].isSelected = value;
            }
        } catch (error) {
            console.error('error: ' + error);
        }
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
            this.afterLoad();
        } catch (error) {
            console.error(error)
        }
    }
    handleChangePageSize(event) {
        try {
            this.pageSize = parseInt(event.target.value);
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value == this.pageSize;
            }
            this.pageNumber = 1;
            this.afterLoad();
        }
        catch (error) {
            console.error('error: ' + error);
        }
    }

    setPageSize = () => {
        try {
            const mainContainer = this.template.querySelector(".mainContainer");
            const pageHeader = this.template.querySelector(".header");
            const pageBodyDiv = this.template.querySelector(".bodyDiv");
            const footerDiv = this.template.querySelector(".footerDiv");
            if (mainContainer && pageHeader && pageBodyDiv && footerDiv) {
                const windowHeight = window.innerHeight;
                const headerHeight = pageHeader.offsetHeight;
                const FooterHeight = footerDiv.offsetHeight;
                const remainingHeight = windowHeight - headerHeight - FooterHeight - 150;
                pageBodyDiv.style.height = remainingHeight + "px";
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    };  
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
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        }));
    }


}