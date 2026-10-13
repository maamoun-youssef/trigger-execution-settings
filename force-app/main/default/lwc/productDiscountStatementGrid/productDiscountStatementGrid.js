import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import initData from "@salesforce/apex/ProductDiscountStatementGridController.initData";
import loadData from "@salesforce/apex/ProductDiscountStatementGridController.loadData";
import save from "@salesforce/apex/ProductDiscountStatementGridController.save";
//OBJECTS
import ProductDiscountStatement__OBJECT from '@salesforce/schema/ProductDiscountStatement__c';
import RT__OBJECT from '@salesforce/schema/RecordType';
//STATIC RESSOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
//LABELS
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import Search from "@salesforce/label/c.Search";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_No_Templates_Selected_as_List_View from "@salesforce/label/c.LBL_No_Templates_Selected_as_List_View";
import LBL_Create_PDS from "@salesforce/label/c.LBL_Create_PDS";
import LBL_Open_PDS_Matrix from "@salesforce/label/c.LBL_Open_PDS_Matrix";
import LANG from "@salesforce/i18n/lang";
const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class ProductDiscountStatementGrid extends NavigationMixin(LightningElement) {

    //API Variables
    // record-page context
    @api recordId;
    @api pdsGridSettingsTemplate;
    @api flowApiName;
    @track pdsGridSettingsTemplateLabel;
    @track labels = {
        LBL_Error,
        Search,
        LBL_Reset,
        LBL_Apply,
        LBL_Filter,
        LBL_Success,
        LBL_Edit,
        LBL_No_Record_To_Display,
        LBL_Save,
        LBL_Cancel,
        LBL_First,
        LBL_Last,
        LBL_Previous,
        LBL_Next,
        LBL_Of,
        LBL_None_Picklist_Value,
        MSG_No_Changes_To_Save,
        LBL_No_Templates_Selected_as_List_View,
        LBL_Create_PDS,
        LBL_Open_PDS_Matrix,
        RTLabel: ''
    }
    isLoading = true;
    isPortal = false;
    @track readOnlyView = true;
    @track openFlow = false;
    @track gridSettings = {};
    @track communityPDSMatrixURL = '';
    @track prefix = '';
    isFilterOpen = false;
    fieldsToFilterMap = {};
    @track fieldsToFilter = [];
    @track filters = {
        globalSearchValue: '',
        dynamic: '',
    }
    @track displayedFields = [];
    // PAGINATION Variables
    @track pageSize = 25;
    pageNumber = 1;
    pageCount = 0;
    totalPagesCount = 0;
    totalRecords = 0;
    @track records = [];
    @track PDSToUpdateMap = {};
    @track sortField = '';
    @track sortDirection = 'DESC';
    @track isSortASC = false;
    sortFieldApi = '';


    @wire(getObjectInfo, { objectApiName: RT__OBJECT.objectApiName }) objectInfoRT({ error, data }) {
        if (data) {
            this.labels.RTLabel = data.label;
            this.initData();
        } else if (error) {
            console.log('ERROR');
        }
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });
    }

    submitSearchKeyPressHandler(event) {
        if (this.filters.globalSearchValue && (event.which == 13 || event.keyCode == 13)) {
            this.pageNumber = 1;
            this.loadData();
            event.target.blur();
        }
    }

    handleChangeSearch(event) {
        this.filters.globalSearchValue = event.target.value;
        this.loadData();
    }

    handleChangeSortField(event) {
        this.isLoading = true;
        let fieldName = event.target.dataset.field;
        if (this.sortFieldApi.startsWith(fieldName)) {
            this.sortDirection = (this.sortDirection == 'ASC') ? 'DESC' : 'ASC';
        } else {
            this.sortDirection = 'ASC';
        }
        this.isSortASC = this.sortDirection == 'ASC';
        this.sortField = fieldName + ' ' + this.sortDirection + ' NULLS ' + (this.isSortASC ? 'FIRST' : 'LAST');
        this.sortFieldApi = fieldName;
        this.displayedFields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.sortedField = true;
                if (field.isReference && field.fieldName.endsWith('__c')) {
                    this.sortField = fieldName.replace('__c', '__r.Name') + ' ' + this.sortDirection + ' NULLS ' + (this.isSortASC ? 'FIRST' : 'LAST');
                }
            } else {
                field.sortedField = false;
            }
        });
        this.loadData();
    }

    applyDefaultSortFromGrid() {
        const defaultSortedColumn = (this.displayedFields || []).find(col => col.defaultSortDirection);
        if (!defaultSortedColumn) return;
        const resolvedSortDirection = String(defaultSortedColumn.defaultSortDirection || 'ASC').toUpperCase();
        this.sortDirection = resolvedSortDirection;
        this.isSortASC = (resolvedSortDirection === 'ASC');
        this.sortFieldApi = defaultSortedColumn.fieldName;
        this.displayedFields = this.displayedFields.map(col => ({
            ...col,
            sortedField: col.fieldName === defaultSortedColumn.fieldName
        }));
        const orderByFieldApi = (defaultSortedColumn.isReference && defaultSortedColumn.fieldName.endsWith('__c'))
            ? defaultSortedColumn.fieldName.replace('__c', '__r.Name')
            : defaultSortedColumn.fieldName;
        this.sortField = `${orderByFieldApi} ${resolvedSortDirection} NULLS ${this.isSortASC ? 'FIRST' : 'LAST'}`;
    }

    initData() {
        this.isLoading = true;
        initData({ PDSGridSettingsTemplate: this.pdsGridSettingsTemplate }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result);
                this.isPortal = parsedResult.currentSession.SessionType == 'ChatterNetworks';
                this.gridSettings = parsedResult.gridSettingsManagerPDS;
                this.communityPDSMatrixURL = parsedResult.communityPDSMatrixURL;
                this.pdsGridSettingsTemplateLabel = this.gridSettings.layoutLabel;
                this.prefix = parsedResult.prefix;
                this.populateFiltersMap(this.gridSettings.FILTERS);
                if (this.gridSettings.Default_Page_Size) {
                    this.pageSize = parseInt(this.gridSettings.Default_Page_Size);
                }
                this.pageSizeOptions.forEach(element => element.isSelected = element.value == this.pageSize);
                this.buildDisplayedFields();
                this.applyDefaultSortFromGrid();
                this.loadData();
            }
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }

    buildDisplayedFields() {
        this.displayedFields = [];
        let self = this;
        const WRAP_STYLE = 'white-space: normal; overflow-wrap: anywhere; word-break: break-word;';
        for (let field of this.gridSettings.GRID_FIELDS) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldName.toLowerCase() == 'recordtypeid' ? this.labels.RTLabel : field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                isYear: field.fieldName.includes('Year'),
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                isNameField: field.fieldName == 'Name' && (!this.isPortal || (this.isPortal && this.communityPDSMatrixURL)),
                link: '',
                scale: field.scale,
                step: '',
                get isInputField() {
                    //console.log(field.fieldLabel + ':::isInputField4:::' + (field.isInputField && !self.readOnlyView));
                    return field.isInputField && !self.readOnlyView;
                },
                style: field.style || '',
                headerStyle: (field.stringHeaderStyle || '') + WRAP_STYLE,
                pickListValues: field.pickListValues,
                picklistColorsMap: field.picklistColorsMap,
                isSortable: field.isSortable,
                isFilterable: field.isFilterable,
                isEncrypted: field.isEncrypted,
                filterValue: '',
                sortedField: false,
            }
            if (fieldWrapper.isNameField) {
                fieldWrapper.iconHeaderStyle = (fieldWrapper.headerStyle || '') + 'border-left: none;';
            }
            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
            if (fieldWrapper.isNumberField) {
                fieldWrapper.style += 'text-align:right;';
                // keep numbers from wrapping for readability
                fieldWrapper.style += 'white-space: nowrap;';
            }
            // apply wrapping to text-like columns (text, textarea, picklist labels, references shown as names)
            if (!fieldWrapper.isNumberField) {
                fieldWrapper.style += WRAP_STYLE;
            }
            if (fieldWrapper.scale) {
                let step = '.';
                for (let i = 0; i < fieldWrapper.scale; i++) {
                    if (i == fieldWrapper.scale - 1) {
                        step += '1';
                        break;
                    }
                    step += '0';
                }
                fieldWrapper.step = step;
            }
            fieldWrapper.defaultSortDirection = field.defaultSortDirection;
            this.displayedFields.push(fieldWrapper);
        }
        console.log('this.displayedFields >>>> ' + JSON.stringify(this.displayedFields))
    }

    get lastThStyle() {
        return this.displayedFields && this.displayedFields.length > 0 ? this.displayedFields[this.displayedFields.length - 1].headerStyle : '';
    }

    //LOAD
    loadData() {
        this.records = [];
        try {
            this.isLoading = true;
            loadData({
                recordId: this.recordId,
                gridSettingsSerialized: JSON.stringify(this.gridSettings),
                filters: JSON.stringify(this.filters),
                pageNumber: this.pageNumber,
                pageSize: this.pageSize,
                sortField: this.sortField,
                language: LANG
            }).then((result) => {
                let parsedresult = JSON.parse(result);
                this.totalRecords = parsedresult.totalSize;
                this.totalPagesCount = Math.ceil((parsedresult.totalSize / this.pageSize));
                this.pageCount = Math.ceil(parsedresult.numberOfRecords / this.pageSize);
                if (result) {
                    this.records = this.buildData(parsedresult.records);
                }
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.error(error.message)
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    buildData(data) {
        let self = this;
        let records = [];
        for (let item of data) {
            let PDSWrapper = {
                Name: item.Name,
                Id: item.Id,
                link: '/' + item.Id,
                values: [],
                screenURL: '/apex/NegoptimNavigator?c__componentName=c:ProductDiscountStatementMatrix&a__recordId=' + item.Id,
                rowColor: '',
                lastTdStyle: '',
                iconTdStyle: ''
            }
            if (this.isPortal && this.communityPDSMatrixURL) {
                PDSWrapper.screenURL = this.communityPDSMatrixURL + '?c__recordId=' + item.Id;
            }
            for (let field of this.displayedFields) {
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
                    isYear: field.isYear,
                    isHTMLFormatted: field.isHTMLFormatted,
                    link: '',
                    isNameField: field.isNameField,
                    scale: field.scale,
                    step: field.step,
                    get isInputField() {
                        return field.isInputField && !self.readOnlyView;
                    },
                    pickListValues: [],
                    style: field.style ? field.style : '',
                }
                let values = field.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let val = index == 0 ? item : fieldWrapper.fieldValue;
                    if (val) {
                        if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                            fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                            fieldWrapper.link = '/' + val[values[index]];
                        } else {
                            fieldWrapper.fieldValue = val[values[index]];
                        }
                    }
                }
                if (fieldWrapper.isPicklist) {
                    console.log('::: PICKLIST1::::' + fieldWrapper.fieldName);
                    console.log('::: PICKLIST2::::', field.pickListValues);
                    for (let pickVal of field.pickListValues) {
                        fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                        if (fieldWrapper.fieldValue == pickVal.value) {
                            fieldWrapper.fieldOutputValue = pickVal.label;
                            if (!PDSWrapper.rowColor && field.picklistColorsMap) {
                                let configuredColor = field.picklistColorsMap[fieldWrapper.fieldValue];
                                if (configuredColor && configuredColor.trim() !== '') {
                                    configuredColor = configuredColor.trim();
                                    PDSWrapper.rowColor = configuredColor.includes(':')
                                        ? (configuredColor.endsWith(';') ? configuredColor : configuredColor + ';')
                                        : `background-color:${configuredColor};`;
                                }
                            }
                        }
                    }
                    fieldWrapper.pickListValues.unshift({
                        label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                    })
                }
                PDSWrapper.values.push(fieldWrapper);
            }
            if (PDSWrapper.rowColor) {
                PDSWrapper.values = PDSWrapper.values.map(cell => {
                    if (!/background-color\s*:/i.test(cell.style || '')) {
                        cell.style = (cell.style || '') + PDSWrapper.rowColor;
                    }
                    return cell;
                });
                PDSWrapper.lastTdStyle = PDSWrapper.rowColor;
                PDSWrapper.iconTdStyle = 'border-left: none;' + (PDSWrapper.rowColor || '');
            }
            records.push(PDSWrapper);
        }
        this.isLoading = false;
        return records;
    }
    // Open product Discount statement matrix
    openScreen(event) {
        let URL = event.target.dataset.url;
        console.log('URL: ' + URL)
        window.open(URL);
    }

    toggleFlow() {
        this.openFlow = !this.openFlow;
    }

    handleFlowStatusChange(event) {
        //TODO : store the output values (event.detail.outputVariables)
        if (event.detail.status === "FINISHED") {
            this.showNotification('SUCCESS', this.labels.LBL_Success, 'SUCCESS')
            this.toggleFlow();
            // Look for flow’s output variable (flow is SCREEN_Product_Discount_Statement_Creation and newly created output variable is createdPdsId)
            if (event.detail.outputVariables) {
                for (let outputVar of event.detail.outputVariables) {
                    if (outputVar.name === 'output_createdPDSId') {
                        const newPdsId = outputVar.value;
                        // Build destination URL
                        const matrixUrl = this.isPortal && this.communityPDSMatrixURL
                            ? `${this.communityPDSMatrixURL}?c__recordId=${newPdsId}`
                            : `/apex/${this.prefix}NegoptimNavigator`
                            + `?c__componentName=${this.prefix ? this.prefix.replace('__', ':') : 'c:'}`
                            + `ProductDiscountStatementMatrix`
                            + `&a__recordId=${newPdsId}`;
                        // Redirect
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: { url: matrixUrl }
                        });
                        break;
                    }
                }
            }
        }
        if (event.detail.status === "ERROR") {
            this.showNotification('ERROR', this.labels.LBL_Error, 'ERROR')
        }
    }

    //EVENT HANDLERS
    toggleEditMode() {
        this.readOnlyView = !this.readOnlyView;
    }

    handleCancelEditMode() {
        this.PDSToUpdateMap = {};
        this.readOnlyView = true;
        this.hasChanges = false;
    }

    @track hasChanges = false;
    //EDIT AND SAVE
    handleFieldEdits(event) {
        let id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let value = event.target.value;
        let obj;
        if (this.PDSToUpdateMap.hasOwnProperty(id)) {
            obj = this.PDSToUpdateMap[id];
        } else {
            obj = {
                attributes: {
                    type: ProductDiscountStatement__OBJECT.objectApiName,
                },
                Id: id
            };
        }
        obj[field] = value;
        this.PDSToUpdateMap[id] = obj;
        this.hasChanges = true;
    }

    handleSave() {
        if (!this.PDSToUpdateMap || Object.keys(this.PDSToUpdateMap).length == 0) {
            this.showNotification(this.labels.MSG_No_Changes_To_Save, '', 'info');
            return;
        }
        save({
            recordsToUpsertJSON: JSON.stringify(Object.values(this.PDSToUpdateMap))
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error');
            }
            this.isLoading = false;
            this.readOnlyView = true;
            this.pageNumber = 1;
            this.loadData();
            this.hasChanges = false;
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }

    populateFiltersMap(fields) {
        this.fieldsToFilterMap = {};
        for (let field of fields) {
            let fieldToFilter = {};
            if (SUPPORTED_TYPES.includes(field.stringFieldType)
                || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
                || field.hasOwnProperty('userFilterable')) {
                fieldToFilter.fieldLabel = field.fieldLabel;
                fieldToFilter.fieldName = field.fieldName;
                fieldToFilter.stringFieldType = field.stringFieldType;
                fieldToFilter.isMultiLevel = field.hasOwnProperty('isMultiLevel') ? field.isMultiLevel : false;
                if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
                if (field.stringFieldType == 'ID') {
                    if (field.values) fieldToFilter.displayVal = field.values.join(';');
                    fieldToFilter.isId = true;
                }
                fieldToFilter.isText = field.stringFieldType == 'STRING';
                fieldToFilter.isReference = field.stringFieldType == 'REFERENCE';
                fieldToFilter.isCheckboxGroup = field.stringFieldType == 'BOOLEAN' || ((field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'RECORDTYPE') && (field.pickListValues && field.pickListValues.length > 1));
                if (fieldToFilter.isCheckboxGroup) {
                    fieldToFilter.options = field.stringFieldType == 'BOOLEAN' ? [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }] : field.pickListValues;
                }
                fieldToFilter.isNumber = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
                if (fieldToFilter.isNumber) {
                    if (field.stringFieldType == 'DOUBLE') {
                        fieldToFilter.formatter = 'decimal';
                    }
                    if (field.stringFieldType == 'CURRENCY') {
                        fieldToFilter.formatter = 'currency';
                    }
                    if (field.stringFieldType == 'PERCENT') {
                        fieldToFilter.formatter = 'percent-fixed';
                    }
                    let step = '.';
                    for (let i = 0; i < field.scale; i++) {
                        if (i == field.scale - 1) {
                            step += '1';
                            break;
                        }
                        step += '0';
                    }
                    fieldToFilter.step = step;
                }
                fieldToFilter.isDate = field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME';
                fieldToFilter.isTime = field.stringFieldType == 'TIME';
                if (field.hasOwnProperty('isEncrypted')) {
                    fieldToFilter.isEncrypted = field.isEncrypted;
                }
                if (SUPPORTED_VALUES_TYPES.includes(field.stringFieldType)
                    || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
                    if (field.values) {
                        if (fieldToFilter.isText || fieldToFilter.isReference) {
                            fieldToFilter.value = (field.values[0]) ? field.values[0] : '';
                            fieldToFilter.values = field.values;
                        } else {
                            fieldToFilter.values = field.values;
                        }
                    } else {
                        fieldToFilter.values = '';
                    }
                }
                if (SUPPORTED_RANGE_TYPES.includes(field.stringFieldType)) {
                    fieldToFilter.value1 = (field.value1) ? field.value1 : '';
                    fieldToFilter.value2 = (field.value2) ? field.value2 : '';
                }
                if (Object.keys(fieldToFilter).length !== 0) {
                    this.fieldsToFilterMap[fieldToFilter.fieldName] = fieldToFilter;
                }
            }
        }
        this.populateLists(this.fieldsToFilterMap);
    }

    populateLists(filtersMap) {
        this.fieldsToFilter = [];
        if (Object.keys(filtersMap).length !== 0) {
            this.fieldsToFilter = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //get record type field
            var recordTypeField = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType == 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //add record type fields always to the top
            if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
            this.multilevelFields = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel == true)
                .map(fieldName => { return filtersMap[fieldName]; });
            this.fieldsToFilter.forEach(item => {
                if (item.isText || item.isReference) {
                    item.value = item.values.length != 0 ? item.values[0] : '';
                }
            })
        }
    }

    setSelectedValues(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var modeValue = event.target.dataset.mode;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field.values = [];
            if (modeValue == 'multiple') {
                let withoutSpace = value.replaceAll(' ', '');
                field.displayVal = withoutSpace;
                let idList = withoutSpace.split(';');
                for (let id of idList) {
                    if (id !== '') {
                        field.values.push(id);
                    }
                }
            } else {
                field.values = (Array.isArray(value)) ? value : [value];
            }
            this.fieldsToFilterMap[fieldName] = field;
            this.populateLists(this.fieldsToFilterMap);
        }
    }

    setSelectedRangeValue(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var rangeValue = event.target.dataset.range;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field[rangeValue] = value;
            this.fieldsToFilterMap[fieldName] = field;
            this.populateLists(this.fieldsToFilterMap);
        }
    }

    confirmFilter() {
        let selection = [];
        try {
            selection = Object.keys(this.fieldsToFilterMap).filter(fieldName =>
            (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
                (this.fieldsToFilterMap[fieldName].values &&
                    (this.fieldsToFilterMap[fieldName].values.length > 1
                        || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
                || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
                .map(fieldName => {
                    let item = {};
                    item.fieldName = fieldName;
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('stringFieldType')) {
                        item.stringFieldType = this.fieldsToFilterMap[fieldName].stringFieldType;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
                        item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('isEncrypted')) {
                        item.isEncrypted = this.fieldsToFilterMap[fieldName].isEncrypted;
                    }
                    if (this.fieldsToFilterMap[fieldName].values &&
                        (this.fieldsToFilterMap[fieldName].values.length > 1
                            || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== ''))) {
                        item.values = this.fieldsToFilterMap[fieldName].values;
                        return item;
                    }
                    if (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '') {
                        item.value1 = this.fieldsToFilterMap[fieldName].value1;
                    }
                    if (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '') {
                        item.value2 = this.fieldsToFilterMap[fieldName].value2;
                    }
                    return item;
                }).filter(item => (item.hasOwnProperty('values') || item.hasOwnProperty('value1') || item.hasOwnProperty('value2') || item.hasOwnProperty('userFilterable')));
            this.filters.dynamic = JSON.stringify(selection);
            this.loadData();
        } catch (error) {
            console.log(error);
        }
    }

    handleReset() {
        this.filters.productRT = '';
        this.filters.dynamic = '';
        this.loadData();
    }

    handleChangePageSize(event) {
        this.pageSize = parseInt(event.target.value);
        // for (let option of this.pageSizeOptions) {
        //     option.isSelected = option.value == this.pageSize;
        // }
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

    //GETTERS
    get pageSizeOptions() {
        return [
            { label: '5', value: 5, isSelected: false },
            { label: '10', value: 10, isSelected: false },
            { label: '25', value: 25, isSelected: false },
            { label: '50', value: 50, isSelected: false },
            { label: '75', value: 75, isSelected: false },
            { label: '100', value: 100, isSelected: false }];
    }

    get previousDisabled() {
        return (this.pageNumber <= 1);
    }

    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.totalRecords ? this.pageNumber * pageSize + 1 - pageSize : this.totalRecords - this.records.length) + '-' + (this.pageNumber * pageSize > this.totalRecords ? this.totalRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalRecords;
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

}