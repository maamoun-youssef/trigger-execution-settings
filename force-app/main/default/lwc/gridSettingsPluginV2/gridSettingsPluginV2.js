import { LightningElement, api, track, wire } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import initData from "@salesforce/apex/GridSettingsPluginCmpControllerV2.initData";
import loadData from "@salesforce/apex/GridSettingsPluginCmpControllerV2.loadData";
import getTemplates from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getTemplates";
import attachFileToRecords from "@salesforce/apex/GridSettingsPluginCmpControllerV2.attachFileToRecords";
import getFieldDependencies from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getFieldDependencies";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import GridSettings from '@salesforce/resourceUrl/GridSettings';
import { toastWarning, toastError, toastSuccess, Labels, incrementFormat } from "c/gridSettingsHelper";
import { NavigationMixin } from 'lightning/navigation';
import xlsx from "@salesforce/resourceUrl/xlsxLib";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class GridSettingsPluginV2 extends NavigationMixin(LightningElement) {
    @api applyNewDesign;
    @api templateName;
    @api objectApiName;
    @api recordId;
    @api displayNewButton;
    @api displayCloneButton;
    @api displayNewInlineButton;
    @api nameAsURL;
    @api allowExport;
    @api allowImport;
    @api includeInListView;
    @api displayListViewActions;
    @api readOnly;
    @api actions;
    @api partialSave;
    @api showCurrency;
    @api showCurrencyAsSymbol;
    @api useRecordIsoCurrency;
    @api displayShowHideColumns;
    @api refreshViewAfterSave;
    @api numberFixedColumns;
    @api filterOnNoneDisplayedFields;
    @api allowDelete;
    @api allowOpenRecord;
    @api allowFilter;
    @api isReadOnly;
    @api showSubTotal;
    @api enableMassUpdate;
    @api saveSuccessMessage;
    @api labelNewInlineButton;
    @api cmpHeight;
    @api quickActions;
    @api pluginIcon;

    @track numberOfFixedColumns = 0;
    @track selectedActions = [];
    @track initDataWrapper = {
        prefix: '',
        errorMessages: [],
        gridSettingsManager: undefined
    }
    @track loadDataWrapper = {
        relationshipName: '',
        records: [],
        total: 0,
    }
    @track records = [];
    @track displayedFields = [];
    @track isLoading = false;
    @track pageNumber = 1;
    @track pageSize = '25';
    
    @track sortDirection;//event
    sortFieldApi;

    @track WireVariables = {
        picklistValues: true,
    };
    @track headerLabels = {
        objectLabel : '',
        layoutLabel : '',
        iconName : '',
        layoutSlogan : ''
    };
    @track showHideColumns = false;
    @track actionFlows = [];
    @track tableLoading = false;

    Labels = Labels;
    pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];
    
    // selected records for mass update or actions
    @track selectedRecordIds = [];
    @track selectedRecordsIds = [];
    get isAllSelected() {
        return this.records && this.records.length && this.records.every(item => item.isSelected);
    };
    get showSelectRecords() {
        return this.enableMassUpdate || ( this.records && this.records.length && this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.actions && this.initDataWrapper.gridSettingsManager.actions.screenFlows && this.initDataWrapper.gridSettingsManager.actions.screenFlows.filter(flow => flow.hasRecordIds).length > 0);
    };

   /*  // Wire to fetch all picklist values by record type and store them in a map (fieldApiName → picklist metadata)
    @wire(getPicklistValuesByRecordType, { objectApiName: objectApiName, recordTypeId: '012000000000000AAA' })
    picklistValuesMethod({ error, data }) {
        if (data) {
            console.log("data1111", data)
            this.availablePicklistValues = data.picklistFieldValues;
             this.availablePicklistValues[fieldName] = {};
            for (let key of Object.keys(result)) {
                this.availablePicklistValues[fieldName][key] = result[key];
            }
            this.WireVariables.picklistValues = true;
            this.init();
        } else if (error) {
            console.log('ERROR');
        }
    } */

    // Ensures all wire data is ready before initializing component data.
    init() {
        if (Object.values(this.WireVariables).every(it => it)) {
            this.initData();
        }
    }

    //Getters 
    get hasMenu() {
        return (this.loadDataWrapper?.records?.length > 0 && (this.allowDelete || this.displayShowHideColumns || this.allowExport || this.allowImport || (this.displayListViewActions && this.selectedActions?.length > 0))) || (((this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows) || []).filter(f => f.value && f.displayType && f.displayType === 'Action')).length > 0;
    }
    get showFirstDivider() {
        return (this.allowDelete || this.displayShowHideColumns) && this.displayListViewActions && this.selectedActions?.length > 0;
    }
    get showSecondDivider() {
        return (this.allowExport || this.allowImport) && this.displayListViewActions && this.selectedActions?.length > 0;
    }
    get hasPagination() {
        return (this.initDataWrapper?.gridSettingsManager ? this.loadDataWrapper?.total > this.initDataWrapper?.gridSettingsManager?.Default_Page_Size : true) && !(this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'tree');
    }
    get previousDisabled() {
        return this.pageNumber == 1;
    }
    get nextDisabled() {
        let noOfRecords = this.loadDataWrapper.total > 10000 ? Math.ceil((10000 / this.pageSize)) : Math.ceil((this.loadDataWrapper.total / this.pageSize));
        return this.pageNumber >= noOfRecords;
    }
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.loadDataWrapper.total ? this.pageNumber * pageSize + 1 - pageSize : this.loadDataWrapper.total - this.loadDataWrapper.records.length) + '-' + (this.pageNumber * pageSize > this.loadDataWrapper.total ? this.loadDataWrapper.total : this.pageNumber * pageSize) + ' ' + Labels.LBL_Of + ' ' + this.loadDataWrapper.total;
    }

    connectedCallback() {
        this.applyNewDesign = !this.applyNewDesign || this.applyNewDesign == 'false' ? false : true;
        this.includeInListView = !this.includeInListView || this.includeInListView == 'false' ? false : true;
        this.displayListViewActions = !this.displayListViewActions || this.displayListViewActions == 'false' ? false : true;
        this.displayNewButton = !this.displayNewButton || this.displayNewButton == 'false' ? false : true;
        this.displayNewInlineButton = !this.displayNewInlineButton || this.displayNewInlineButton == 'false' ? false : true;
        this.displayCloneButton = !this.displayCloneButton || this.displayCloneButton == 'false' ? false : true;
        this.allowDelete = !this.allowDelete || this.allowDelete == 'false' ? false : true;
        this.displayShowHideColumns = !this.displayShowHideColumns || this.displayShowHideColumns == 'false' ? false : true;
        this.allowImport = !this.allowImport || this.allowImport == 'false' ? false : true;
        this.allowExport = !this.allowExport || this.allowExport == 'false' ? false : true;
        this.allowFilter = !this.allowFilter || this.allowFilter == 'false' ? false : true;
        this.allowOpenRecord = !this.allowOpenRecord || this.allowOpenRecord == 'false' ? false : true;
        this.nameAsURL = !this.nameAsURL || this.nameAsURL == 'false' ? false : true;
        this.showCurrency = !this.showCurrency || this.showCurrency == 'false' ? false : true;
        this.showCurrencyAsSymbol = !this.showCurrencyAsSymbol || this.showCurrencyAsSymbol == 'false' ? false : true;
        this.useRecordIsoCurrency = !this.useRecordIsoCurrency || this.useRecordIsoCurrency == 'false' ? false : true;
        this.showSubTotal = !this.showSubTotal || this.showSubTotal == 'false' ? false : true;
        this.isReadOnly = !this.isReadOnly || this.isReadOnly == 'false' ? false : true;
        this.enableMassUpdate = !this.enableMassUpdate || this.enableMassUpdate == 'false' ? false : true;
        this.refreshViewAfterSave = !this.refreshViewAfterSave || this.refreshViewAfterSave == 'false' ? false : true;
        this.partialSave = !this.partialSave || this.partialSave == 'false' ? false : true;
        this.filterOnNoneDisplayedFields = !this.filterOnNoneDisplayedFields || this.filterOnNoneDisplayedFields == 'false' ? false : true;
        this.readOnly = !this.readOnly || this.readOnly == 'false' ? false : true;
        this.actions = !this.actions || this.actions == 'false' ? false : true;
        //
        this.tableLoading = true;
        this.enableMassUpdate = ((this.enableMassUpdate || this.allowDelete) && !this.isReadOnly) || (this.displayListViewActions && this.selectedActions?.length > 0);
        this.displayCloneButton = this.displayCloneButton && !this.isReadOnly;
        this.allowImport = this.allowImport && !this.isReadOnly;
        this.allowDelete = this.allowDelete && !this.isReadOnly;
        this.displayNewButton = this.displayNewButton && !this.isReadOnly;
        this.displayNewInlineButton = this.displayNewInlineButton && !this.isReadOnly;
        this.numberOfFixedColumns = this.numberFixedColumns != null && this.numberFixedColumns >= 0 && this.numberFixedColumns < 7 ? this.numberFixedColumns : 0;
        window.addEventListener('resize', this.handleResize);
        loadScript(this, ExcelJSURL).then(() => {
            console.log('load exceljs success');
        }).catch(error => {
            console.log('load exceljs failedd');
            console.log(error);
        });
        loadScript(this, xlsx + '/js-xlsx-master/dist/jszip.js').then(() => {
            loadScript(self, xlsx + '/js-xlsx-master/dist/xlsx.js').then(() => {
                console.log('jszip loaded');
            }).catch(error => {
                toastError(self, error)
                console.log('error: ' + error);
            });
        }).catch(error => {
            console.log('error: ' + error);
        });
        Promise.all([
            loadStyle(this, GridSettings + '/customStyle.css'),
        ]).then(() => { }).catch(error => {
            console.log("Error " + error.body.message);
        });
        this.initData();
    }

    initData() {
        if (this.templateName) {
            initData({
                recordId: this.recordId,
                templateName: this.templateName
            }).then(result => {
                this.initDataWrapper = JSON.parse(result);
                this.headerLabels.objectLabel = this.initDataWrapper.gridSettingsManager.objectLabel ?? '';
                this.headerLabels.layoutLabel = this.initDataWrapper.gridSettingsManager.layoutLabel ?? '';
                this.headerLabels.layoutSlogan = this.initDataWrapper.gridSettingsManager.layoutSlogan ?? '';
                this.headerLabels.iconName = this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.iconName && this.initDataWrapper.gridSettingsManager.iconSection
                ? this.initDataWrapper.gridSettingsManager.iconSection + ':' + this.initDataWrapper.gridSettingsManager.iconName 
                : 'standard:orders'; 
                this.selectedActions.push(this.initDataWrapper.gridSettingsManager.actions);
                this.actionFlows = ((this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows) || []).filter(f => f.value && f.displayType && f.displayType === 'Action')
                this.buildDisplayedFields();
                console.log("TEST_TEST", JSON.stringify(this.selectedActions))
            });
        }
    }

    // Builds the grid column definitions (displayed fields) from Apex data.
    buildDisplayedFields() {
        try {
            this.displayedFields = [];
            for (let field of (this.initDataWrapper.gridSettingsManager.GRID_FIELDS || [])) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.isNumberField,
                    isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    isText: field.stringFieldType == 'STRING',
                    isMultiPicklist: field.stringFieldType == 'MULTIPICKLIST',
                    isCurrency: field.stringFieldType == 'CURRENCY',
                    isPercent: field.stringFieldType == 'PERCENT',
                    isURL: field.stringFieldType == 'URL',
                    isNameField: field.fieldName.toLowerCase() == 'name',
                    link: '',
                    scale: field.scale,
                    step: '',
                    isInputField: field.isInputField,
                    style: field.style,
                    headerStyle: field.stringHeaderStyle,
                    pickListValues: field.pickListValues,
                    isSortable: field.isSortable,
                    isDefaultSortable: field.isDefaultSortable,
                    isFilterable: field.isFilterable,
                    isEncrypted: field.isEncrypted,
                    isMassUpdate: field.isMassUpdate && field.isInputField && this.enableMassUpdate,
                    filterValue: '',
                    sortedField: false,
                    picklistColorsMap: field.picklistColorsMap,
                    nameAsURL: (this.nameAsURL && field.fieldName.toLowerCase() == "name"),
                }
                if (field.isPicklist) {
                    field.pickListValues.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                }
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.scale) {
                    const result = 1 / Math.pow(10, fieldWrapper.scale);
                    fieldWrapper.step = result.toFixed(fieldWrapper.scale);
                }
                this.displayedFields.push(fieldWrapper);
            }
            this.firstThStyle = (this.displayedFields[0].headerStyle ? this.displayedFields[0].headerStyle : '') + 'text-align: center;';
            this.loadData();
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    // Calls Apex loadData to fetch table rows.
    loadData() {
        try {
            this.records = [];
            this.isLoading = true;
                loadData({
                    gridSettingsManagerSerialized: JSON.stringify(this.initDataWrapper.gridSettingsManager),
                    recordId: this.recordId,
                    objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                    pageSize: this.pageSize,
                    pageNumber: this.pageNumber,
                    filters: JSON.stringify(this.filters),
                    sortedFieldName: this.sortFieldApi,
                    defaultSortDirection: this.sortDirection
                }).then(result => {
                    this.loadDataWrapper = JSON.parse(result);
                    this.records = this.buildData(this.loadDataWrapper.records);
                    this.tableLoading = false;
                }).catch(error => {
                    this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                    console.log('loadData: %c' + error.message, 'color : red');
                    console.log('loadData: %c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                })
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
        }
    }

    // Builds and formats the data rows for the grid display.
    buildData(data) {
        try {
            let records = [];
            for (let item of data) {
                let buildDataWrapper = {
                    Name: item.Name,
                    Id: item.Id,
                    isSelected: this.selectedRecordIds.includes(item.Id),
                    link: '/' + item.Id,
                    values: [],
                    rowColor: '',
                    firstTdStyle: '',
                    lastTdStyle: '',
                    nameURL: '/' + item.Id,
                }
                for (let field of this.displayedFields) {
                    let fieldWrapper = {
                        Id: item.Id,
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldType: field.fieldType,
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
                        isMultiPicklist: field.isMultiPicklist,
                        isCurrency: field.isCurrency,
                        isPercent: field.isPercent,
                        isURL: field.isURL,
                        isNameField: field.isNameField,
                        style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                        headerStyle: field.headerStyle,
                        isSortable: field.isSortable,
                        isDefaultSortable: field.isDefaultSortable,
                        isFilterable: field.isFilterable,
                        isEncrypted: field.isEncrypted,
                        isMassUpdate: field.isMassUpdate,
                        filterValue: '',
                        sortedField: false,
                        picklistColorsMap: field.picklistColorsMap,
                        CurrencyExist: item['CurrencyIsoCode'] && this.useRecordIsoCurrency ? true : false,
                        CurrencyIsoCode: item['CurrencyIsoCode'],
                        nameAsURL: item.Id && field.nameAsURL,
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
                            label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                        })
                        buildDataWrapper.rowColor += field.picklistColorsMap && fieldWrapper.fieldValue !== '' && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue) && field.picklistColorsMap[fieldWrapper.fieldValue] !== '' ? field.picklistColorsMap[fieldWrapper.fieldValue] : '';
                    }
                    buildDataWrapper.values.push(fieldWrapper);
                }
                records.push(buildDataWrapper);
            }
            this.isLoading = false;
            return records;
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
        }
    }

    // events
    // Handles individual row checkbox changes.
    toggleSelectedRecords(event) {
        console.log('toggleSelectedRecords event');
        let index = event.currentTarget.dataset.index;
        let item = this.records[index];
        item.isSelected = !item.isSelected;
        if (item.isSelected) {
            this.selectedRecordIds.push(item.Id);
        } else {
            this.selectedRecordIds.splice(index, 1);
        }
    }
    // Selects or deselects all checkboxes in the table.
    toggleAllSelected(event) {
        console.log('toggleAllSelected event');
        const checked = event.detail.checked;
        this.records.forEach(item => {
            item.isSelected = checked;
            if (checked) {
                this.selectedRecordIds.push(item.Id);
            } else {
                this.selectedRecordIds = [];
            }
        });
    }

    showHideColumns() {
        this.showHideColumns = !this.showHideColumns;
    }
    handleActionsChange(event) {}
    exportExcel() {}
    handleOpenImport() {}
    handlePageSize(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.tableLoading = true;
        this.loadData();
    }
    handleChangePage(event) {
        this.tableLoading = true;
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.loadDataWrapper.total > 10000 ? Math.ceil((10000 / this.pageSize)) : Math.ceil((this.loadDataWrapper.total / this.pageSize));
            }
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }
    /* buildDisplayedFields() {
        console.log("buildDisplayedFields")
        let gridFields = this.initDataWrapper.gridSettingsManager.GRID_FIELDS || [];
        let masterFields = [];
        let gridFieldsName = [];
        for (let field of gridFields) {
            if (field.defaultType == 'master' && field.defaultValue) {
                masterFields.push(field.defaultValue.split(".")[1]);
            }
            // if (field.stringFieldType == 'PICKLIST') {
            //     const promise = this.getPicklistValuesByRecordTypeId(field.fieldName);
            //     this.apexMethodPromises.push(promise); // Store the promise
            // }
            if (field.controllerName != null) {
                this.picklistRelationshipMap[field.controllerName] = field.fieldName;
                const promise = this.getFieldDependencies(field.controllerName, field.fieldName);
                this.apexMethodPromises.push(promise); // Store the promise
            }
            if (!field.isHidden) {
                gridFieldsName.push(field.fieldName);
            }
            if (field.showInTotal && field.isNumberField) {
                this.aggregationFields.push({ fieldName: field.fieldName, aggType: field.totaltype });
            }
        }
        if (masterFields.length != 0) {
            getMasterInfoData({ recordId: this.recordId, masterObjectApiName: this.initDataWrapper.gridSettingsManager.Master_OBJECT_NAME, fieldsName: masterFields }).then(result => {
                this.masterObjectInfo = result;
            });
        }
        //default page size
        if (!this.pageSize) {
            this.pageSize = '' + this.initDataWrapper.gridSettingsManager.Default_Page_Size;
        }
        // get totals
        this.handelGetTotalAggregation().then((result) => {
            console.log("handelGetTotalAggregation")
            let filterableFields = this.initDataWrapper.gridSettingsManager.FILTERS || [];
            let savedLocalGrid;
            if (result && localStorage.getItem(this.templateName)) {
                let cachedData = JSON.parse(localStorage.getItem(this.templateName));
                savedLocalGrid = cachedData.map(field => field.fieldName);
            }
            let fieldIndex = 0;
            for (let field of gridFields) {
                if (field.stringFieldType == 'INTEGER') {
                    this.integers.push(field.fieldName);
                }
                field.isId = field.stringFieldType == 'ID';
                field.isText = field.stringFieldType == 'STRING';
                field.isTextArea = field.stringFieldType == 'TEXTAREA';
                field.isBoolean = field.stringFieldType == 'BOOLEAN';
                field.isDate = field.stringFieldType == 'DATE';
                field.isDateTime = field.stringFieldType == 'DATETIME';
                field.isMultiPicklist = field.stringFieldType == 'MULTIPICKLIST';
                field.isPicklist = field.stringFieldType == 'PICKLIST';
                if (field.isPicklist && !field.pickListValues.some(item => item.value === '')) {
                    field.pickListValues.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                }
                if (field.isBoolean) {
                    let options = [{ label: this.Labels.LBL_True, value: 'true' }, { label: this.Labels.LBL_False, value: 'false' }];
                    field.pickListValues = options;
                }
                field.isNumber = field.stringFieldType === 'DOUBLE' || field.stringFieldType === 'INTEGER' || field.stringFieldType === 'LONG' || field.stringFieldType === 'CURRENCY' || field.stringFieldType === 'PERCENT';
                field.isCurrency = field.stringFieldType == 'CURRENCY';
                field.isPercent = field.stringFieldType == 'PERCENT';
                field.isUrl = field.stringFieldType == 'URL';
                field.nameAsURL = (this.nameAsURL && field.fieldName.toLowerCase() == "name");
                field.isOnlyNumber = field.isNumber && !field.isPercent && !field.isCurrency;
                field.isSortable = field.isSortable;
                field.isDefaultSortable = field.isDefaultSortable;
                field.total = field.showInTotal && this.aggregationFields.filter(obj => obj.fieldName == field.fieldName).length > '0'
                    ? this.aggregationFields.filter(obj => obj.fieldName == field.fieldName)[0].totalVal == null ? 0 : this.aggregationFields.filter(obj => obj.fieldName == field.fieldName)[0].totalVal
                    : '';
                if (field.clearOnClone) {
                    this.fieldToClearOnClone.push(field.fieldName);
                }
                if (savedLocalGrid == null || !savedLocalGrid.includes(field.fieldName)) {
                    field.iconStyle = '';
                    if (field.headerStyle && field.headerStyle.color != '') {
                        field.iconStyle += '--slds-c-icon-color-foreground: ' + field.headerStyle.color + ' !important;--slds-c-icon-color-foreground-default: ' + field.headerStyle.color + ' !important;';
                    }
                    field.headerStyle = field.headerStyle?.style + (field.nonConditional?.widthStyle ? field.nonConditional?.widthStyle : '');
                    if (field.isDefaultSortable && !this.sortDirection) {
                        this.sortDirection = field.defaultSortDirection;
                        this.sortFieldApi = field.fieldName;
                    }
                    field.sortedField = field.fieldName == this.sortFieldApi;
                    field.fieldLabel = (field.newLabel && field.newLabel != '' ? field.newLabel : field.fieldLabel).toUpperCase();
                    field.color = field.nonConditional?.textStyle?.color;
                    field.isId = field.stringFieldType == 'ID';
                    field.isText = field.stringFieldType == 'STRING' || field.stringFieldType == 'PHONE' || field.stringFieldType == 'FAX' || field.stringFieldType == 'ADDRESS';
                    field.isTextArea = field.stringFieldType == 'TEXTAREA';
                    field.isBoolean = field.stringFieldType == 'BOOLEAN';
                    field.isDate = field.stringFieldType == 'DATE';
                    field.isDateTime = field.stringFieldType == 'DATETIME';
                    field.isMultiPicklist = field.stringFieldType == 'MULTIPICKLIST';
                    field.isPicklist = field.stringFieldType == 'PICKLIST';
                    if (field.isPicklist && !field.pickListValues.some(item => item.value === '')) {
                        field.pickListValues.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                    }
                    if (field.isBoolean) {
                        let options = [{ label: this.Labels.LBL_True, value: 'true' }, { label: this.Labels.LBL_False, value: 'false' }];
                        field.pickListValues = options;
                    }
                    field.isNumber = field.stringFieldType === 'DOUBLE' || field.stringFieldType === 'INTEGER' || field.stringFieldType === 'LONG' || field.stringFieldType === 'CURRENCY' || field.stringFieldType === 'PERCENT';
                    field.isCurrency = field.stringFieldType == 'CURRENCY';
                    field.isPercent = field.stringFieldType == 'PERCENT';
                    field.isUrl = field.stringFieldType == 'URL';
                    field.isOnlyNumber = field.isNumber && !field.isPercent && !field.isCurrency;
                    field.isRecordType = field.fieldName.toLowerCase() == 'recordtypeid';
                    field.value = '';
                    field.hasChanged = false;
                    field.isFilterable = filterableFields.filter(elt => elt.fieldName == field.fieldName && elt.hasOwnProperty('userFilterable') && elt.userFilterable).length > 0
                        && this.isShowFilterOnColumnHeader;
                    field.isSearchableText = field.stringFieldType == 'STRING' || field.stringFieldType == 'TEXTAREA' || field.stringFieldType == 'REFERENCE';
                    field.isSearchableCheckboxes = field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'BOOLEAN';
                    field.isSearchableInput = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
                    field.isSearchableDateInput = field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME';
                    field.options = filterableFields.filter(elt => elt.fieldName == field.fieldName).length > 0 && field.stringFieldType == 'PICKLIST'
                        ? filterableFields.filter(elt => elt.fieldName == field.fieldName)[0].pickListValues
                        : field.pickListValues;
                    if (this.filtersFieldsMap && this.filtersFieldsMap[field.fieldName]) {
                        let filterData = this.filtersFieldsMap != undefined && this.filtersFieldsMap[field.fieldName]
                            ? this.filtersFieldsMap[field.fieldName]
                            : null;
                        field.filterValue = {
                            values: this.overrideFilter && filterData?.values && filterData.values !== '' ? filterData.values.join('') : '',
                            value1: this.overrideFilter && filterData?.value1 && filterData.value1 !== '' ? filterData.value1 : '',
                            value2: this.overrideFilter && filterData?.value2 && filterData.value2 !== '' ? filterData.value2 : ''
                        };
                        field.hasFilter = (field.filterValue.values != '' || field.filterValue.value1 != '' || field.filterValue.value2 != '')
                            && field.filterValue.userFilterable;
                    }
                    field.popUpStyle = field.isSearchableCheckboxes ? 'max-height:230px;min-height:230px;'
                        : field.isSearchableDateInput || field.isSearchableInput ? 'min-width:260px' : '';

                    if (field.scale) {
                        const result = 1 / Math.pow(10, field.scale);
                        field.step = result.toFixed(field.scale);
                    }
                    this.selectedFields.push(field.fieldName);
                    field.isMassUpdate = field.isMassUpdate && field.isInputField && this.enableMassUpdate;
                    if (field.controllerName) {
                        field.controller = { controllerName: field.controllerName, value: undefined };
                    }
                    field.hasDependentPicklist = false;
                    if (field.controlledByFields && field.controlledByFields.length) {
                        let controlledByFields = [];
                        if (field.isPicklist && (Object.keys(this.picklistRelationshipMap).includes(field.fieldName)
                            || Object.values(this.picklistRelationshipMap).includes(field.fieldName))) {
                            field.hasDependentPicklist = true;
                            let options = [...field.options];
                            options.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                            controlledByFields.push({
                                controlledByName: field.fieldName,
                                controlledByLabel: field.fieldLabel,
                                value: undefined,
                                disabled: true,
                                options: options
                            });
                            if (Object.keys(this.picklistRelationshipMap).includes(field.fieldName)) {
                                let nextField = this.picklistRelationshipMap[field.fieldName];
                                while (nextField) {
                                    let nextOptionField = gridFields.filter(elt => elt.fieldName == nextField).length > 0
                                        && field.stringFieldType == 'PICKLIST'
                                        ? gridFields.filter(elt => elt.fieldName == nextField)[0]
                                        : {};
                                    let nextOptions = [];
                                    if (nextOptionField.pickListValues != null) {
                                        nextOptions = [...nextOptionField.pickListValues];
                                    }
                                    nextOptions.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                                    let nextOptionLabel = nextOptionField.fieldLabel;
                                    controlledByFields.push({
                                        controlledByName: nextField,
                                        controlledByLabel: nextOptionLabel,
                                        value: undefined,
                                        disabled: true,
                                        options: nextOptions
                                    });
                                    nextField = this.picklistRelationshipMap[nextField];
                                }
                            }
                            if (Object.values(this.picklistRelationshipMap).includes(field.fieldName)) {
                                let indexField = Object.values(this.picklistRelationshipMap).indexOf(field.fieldName);
                                let prevField = Object.keys(this.picklistRelationshipMap)[indexField];

                                while (prevField) {
                                    let prevOptionField = gridFields.filter(elt => elt.fieldName == prevField).length > 0
                                        && field.stringFieldType == 'PICKLIST'
                                        ? gridFields.filter(elt => elt.fieldName == prevField)[0]
                                        : {};
                                    let prevOptions = [];
                                    if (prevOptionField.pickListValues != null) {
                                        prevOptions = [...prevOptionField.pickListValues];
                                    }
                                    prevOptions.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                                    let prevOptionLabel = prevOptionField.fieldLabel;
                                    controlledByFields.unshift({
                                        controlledByName: prevField,
                                        controlledByLabel: prevOptionLabel,
                                        value: undefined,
                                        disabled: true,
                                        options: prevOptions
                                    });
                                    indexField = Object.values(this.picklistRelationshipMap).indexOf(prevField);
                                    prevField = indexField != -1 ? Object.keys(this.picklistRelationshipMap)[indexField] : null;
                                }
                            }
                            controlledByFields[0].disabled = false;
                        }
                        field.controlledByFields = controlledByFields;
                    }
                    this.selectedGridFields.push(field);
                    this.selectedGridFieldsMap[field.fieldName] = field;
                }
                this.selectedGridFields.forEach(f => {
                    if (f.fieldName == field.fieldName) {
                        let filterData = this.filtersFieldsMap != undefined && this.filtersFieldsMap[field.fieldName]
                            ? this.filtersFieldsMap[field.fieldName]
                            : null;
                        f.filterValue = {
                            values: filterData?.values && filterData.values !== '' ? filterData.values.join('') : '',
                            value1: filterData?.value1 && filterData.value1 !== '' ? filterData.value1 : '',
                            value2: filterData?.value2 && filterData.value2 !== '' ? filterData.value2 : ''
                        };
                        f.hasFilter = f.filterValue.values != '' || f.filterValue.value1 != '' || f.filterValue.value2 != '';
                    }
                });
                if (this.initDataWrapper.gridSettingsManager?.groupedField) {
                    this.selectedGridFields = this.selectedGridFields.filter(
                        (fld) => fld.fieldName != this.initDataWrapper.gridSettingsManager?.groupedField
                    );
                }
                field.fieldIndex = fieldIndex;
                fieldIndex++;
            }
            this.loadData();
        });

    } */

    /* getFieldDependencies(controllerField, fieldName) {
        return getFieldDependencies({
            objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
            controllingField: controllerField,
            dependentField: fieldName
        }).then((result) => {
            this.dependentPicklistMap[fieldName] = {};
            for (let key of Object.keys(result)) {
                this.dependentPicklistMap[fieldName][key] = result[key];
            }
        }).catch((apexError) => {
            console.error(apexError);
        });
    } */

    // handleTreeLoad() {
    //     console.log("handleTreeLoad")
    // }

    /* handelGetTotalAggregation() {
        return new Promise((resolve, reject) => {
            if (this.aggregationFields.length > 0) {
                getTotalAggregation(
                    {
                        recordId: this.recordId,
                        aggregationFields: JSON.stringify(this.aggregationFields),
                        objectApiName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                        masterObjectApiName: this.initDataWrapper.gridSettingsManager.Master_OBJECT_NAME,
                        metadataDeveloperName: this.templateName
                    })
                    .then(result => {
                        this.aggregationFields = JSON.parse(result);
                        resolve(true);
                    }).catch(error => {
                        console.log("Error " + error.body.message);
                    });
            } else {
                resolve(true);
            }
        });
    } */
   /*  getPicklistValuesByRecordTypeId(fieldName) {
        return getPicklistValuesByRecordTypeId({
            objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
            fieldName: fieldName
        }).then((result) => {
            this.availablePicklistValues[fieldName] = {};
            for (let key of Object.keys(result)) {
                this.availablePicklistValues[fieldName][key] = result[key];
            }
        }).catch((apexError) => {
            console.error(apexError);
        });
    } */


    handleResize = () => this.setSticky();

    setSticky() {
        let fixedSticky = this.displayCloneButton && this.enableMassUpdate ? 2 : this.displayCloneButton || this.enableMassUpdate ? 1 : 0;
        if (this.numberOfFixedColumns != null && this.numberOfFixedColumns >= 0) {
            var headRows = this.template.querySelectorAll('.initial-table thead tr');
            let top = 0;
            for (let index = 0; headRows && index < headRows.length; index++) {
                let childrens = headRows[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < (this.numberOfFixedColumns + fixedSticky)) {
                        childrens[index2].style.zIndex = 6;
                        childrens[index2].style.left = left + 'px ';
                        left += childrens[index2].offsetWidth;

                    } else {
                        childrens[index2].style.zIndex = index == 0 ? 5 : 4;
                        childrens[index2].style.left = 'unset';
                    }
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.top = top + 'px';
                }
                top += headRows[index].offsetHeight;
            }
            var rows = this.template.querySelector('.initial-table') ? this.template.querySelector('.initial-table tbody').rows : [];
            for (let index = 0; rows && index < rows.length; index++) {
                let childrens = rows[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < (this.numberOfFixedColumns + fixedSticky)) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = 3;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].classList.add('stickyTD');
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.left = 'unset';
                        childrens[index2].style.zIndex = 0;
                        childrens[index2].classList.remove('stickyTD');
                    }
                }
            }
        }
    }
    
    // Shows a standard Lightning toast notification.
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

}