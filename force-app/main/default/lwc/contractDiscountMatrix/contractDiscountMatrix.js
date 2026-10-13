import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

//APEX
import initData from "@salesforce/apex/ContractDiscountMatrixController.initData";
import loadData from "@salesforce/apex/ContractDiscountMatrixController.loadData";
import save from "@salesforce/apex/ContractDiscountMatrixController.save";
import deleteConditions from "@salesforce/apex/ContractDiscountMatrixController.deleteConditions";
//STATIC RESOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { labels, API_NAMES } from './properties.js';

export default class ContractDiscountMatrixController extends NavigationMixin(LightningElement) {
    @api recordId;
    @api gridLayout;
    @track labels = { ...labels }
    @track isLoading = true;
    @track isFilterOpen = false;
    @track isEditMode = false;
    @track isReadOnly = false;
    @track mainData = {};
    @track initialRecords = [];
    @track records = [];
    @track bannerValues = [];
    @track displayedFields = [];
    @track conditionsToUpdateMap = {};
    @track newRecords = [];
    @track noOfRecords = 0;
    @track pageNumber = 1;
    @track pageSize = '25';
    @track selectedRecordIds = [];
    @track firstThStyle = '';
    @track headerData = {
        headerValue: '',
        objectLabel: '',
    }
    @track WireVariables = {
        objectInfoCD: false,
        contractPicklistValues: false
    }
    @track popups = {
        deletePopup: {
            isOpen: false,
            idsToDelete: [],
            togglePopup(event) {
                this.popups.deletePopup.isOpen = !this.popups.deletePopup.isOpen;
                if (this.popups.deletePopup.isOpen) {
                    let type = event.target.dataset.type;
                    if (type == 'Single') {
                        let id = event.target.dataset.id;
                        this.popups.deletePopup.idsToDelete.push(id)
                    } else {
                        this.popups.deletePopup.idsToDelete = this.selectedRecordIds;
                    }
                } else {
                    this.popups.deletePopup.idsToDelete = [];
                }
            },
        }
    }

    filters = {
        dynamic: ''
    }

    //Variables
    API_NAMES = API_NAMES;
    originalValuesById = {};

    // Called after the template is rendered; adjusts grid height to fit window.
    renderedCallback() {
        if (this.template.querySelector('.main-panel')) {
            this.changeHeight();
        }
    }

    //GETTERS
    // Returns the icon name for the header based on grid settings.
    get iconName() {
        return this.mainData && this.mainData.gridSettingsManager && this.mainData.gridSettingsManager.iconName && this.mainData.gridSettingsManager.iconSection ? this.mainData.gridSettingsManager.iconSection + ':' + this.mainData.gridSettingsManager.iconName : 'standard:orders';
    }

    // Checks whether a master (banner) section should be displayed.
    get hasMaster() {
        return this.mainData.gridSettingsManager && this.mainData.gridSettingsManager.hasMaster;
    }

    // Determines if the Save button should be shown.
    get showSave() {
        return this.isEditMode || ((Object.keys(this.conditionsToUpdateMap).length > 0) || (this.newRecords.length > 0));
    }

    get hasFilterSettingsFields() {
        return this.mainData && this.mainData.gridSettingsManager && this.mainData.gridSettingsManager.gridLayout && this.mainData.gridSettingsManager.gridLayout.Filters__c && JSON.parse(this.mainData.gridSettingsManager.gridLayout.Filters__c).some(filter => filter.userFilterable === true);
    }

    get stringifiedFilters() {
        return this.mainData && this.mainData.gridSettingsManager && this.mainData.gridSettingsManager.FILTERS ? JSON.stringify(this.mainData.gridSettingsManager.FILTERS) : '[]';
    }

    @wire(CurrentPageReference)
    pageRef;

    // Loads object metadata for Contract_Discount__c and starts initialization.
    @wire(getObjectInfo, { objectApiName: API_NAMES.Contract_Discount__c.objectApiName }) objectInfoCD({ error, data }) {
        if (data) {
            this.headerData.objectLabel = data.label;
            this.WireVariables.objectInfoCD = true;
            this.init();
        }
    }

    // Wire to fetch all picklist values by record type and store them in a map (fieldApiName → picklist metadata)
    @wire(getPicklistValuesByRecordType, { objectApiName: API_NAMES.Contract__c.object, recordTypeId: '012000000000000AAA' })
    picklistValuesParent({ error, data }) {
        if (data) {
            this.contractPicklistValuesMap = data.picklistFieldValues;
            this.WireVariables.contractPicklistValues = true;
            this.init();
        } else if (error) {
            console.log('ERROR');
        }
    }

    // Ensures all wire data is ready before initializing component data.
    init() {
        if (Object.values(this.WireVariables).every(it => it)) {
            this.initData();
        }
    }

    // Runs when component loads; loads external CSS and sets resize listener.
    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });
        window.addEventListener('resize', this.changeHeight);
    }

    // Calls Apex initData to load grid setup and banner data.
    initData() {
        this.isLoading = true;
        if (this.pageRef && this.recordId == null) {
            const { state } = this.pageRef;
            this.recordId = state.c__recordId;
        }
        initData({
            recordId: this.recordId,
            gridLayout: this.gridLayout
        }).then(result => {
            this.mainData = JSON.parse(result);
            console.log('this.mainData>>> ' + JSON.stringify(this.mainData))
            this.pageSize = parseInt(this.mainData.gridSettingsManager.Default_Page_Size);
            let bannerRecord = this.mainData.bannerRecord ? JSON.parse(this.mainData.bannerRecord) : {};
            document.title = 'CDM - ' + bannerRecord.Name;
            this.isReadOnly = this.mainData.gridSettingsManager.isReadOnly;
            this.buildDisplayedFields();
            if (this.mainData.bannerRecord) {
                this.buildBannerData(bannerRecord);
            }
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('initData %c' + error.message, 'color : red');
            console.log('initData %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    // Builds the banner (master) section fields from Apex data.
    buildBannerData(record) {
        try {
            this.bannerValues = [];
            for (let field of this.mainData.gridSettingsManager.BANNER_FIELDS) {
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
                    link: '',
                    scale: field.scale,
                    step: '',
                    pickListValues: field.pickListValues,
                    fieldValue: record[field.fieldName],
                }
                if (fieldWrapper.isReference) {
                    fieldWrapper.fieldValue = record[field.fieldName.replace(/__c$/, '__r')]?.Name;
                    fieldWrapper.link = '/' + record[field.fieldName];
                }
                if (fieldWrapper.isPicklist) {
                    const picklist = this.contractPicklistValuesMap?.[fieldWrapper.fieldName];
                    if (picklist) {
                        const found = picklist.values.find(value => value.value == record[fieldWrapper.fieldName]);
                        if (found) {
                            fieldWrapper.fieldValue = found.label;
                        }
                    }
                }
                this.bannerValues.push(fieldWrapper);
            }
            this.headerData.headerValue = this.bannerValues && this.bannerValues.length > 0 ? this.bannerValues[0].fieldValue : record.Name;
            if (this.bannerValues.length) {
                this.bannerValues.splice(0, 1);
            }
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildBannerData: %c' + error.message, 'color : red');
            console.log('buildBannerData: %c' + error.body?.message, 'color : red');
        }
    }

    // Builds the grid column definitions (displayed fields) from Apex data.
    buildDisplayedFields() {
        try {
            this.displayedFields = [];
            for (let field of this.mainData.gridSettingsManager.GRID_FIELDS) {
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
                    link: '',
                    scale: field.scale,
                    step: '',
                    isInputField: field.isInputField,
                    style: field.style,
                    headerStyle: field.stringHeaderStyle,
                    pickListValues: field.pickListValues,
                    isSortable: field.isSortable,
                    isFilterable: field.isFilterable,
                    isEncrypted: field.isEncrypted,
                    filterValue: '',
                    sortedField: false,
                    picklistColorsMap: field.picklistColorsMap,
                }
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
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
                this.displayedFields.push(fieldWrapper);
            }
            this.firstThStyle = (this.displayedFields[0].headerStyle ? this.displayedFields[0].headerStyle : '') + 'text-align: center;';
            this.loadData();
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    // Calls Apex loadData to fetch table rows.
    loadData() {
        try {
            this.records = [];
            this.isLoading = true;
            try {
                loadData({
                    recordId: this.recordId,
                    gridSettings: JSON.stringify(this.mainData.gridSettingsManager),
                    pageNumber: this.pageNumber,
                    pageSize: this.pageSize,
                    filters: JSON.stringify(this.filters),
                }).then(result => {
                    let parsedResult = JSON.parse(result);
                    this.noOfRecords = parsedResult.totalSize;
                    this.labels.LBL_Condition_Manager_Count_and_OrderBY = this.noOfRecords ? this.labels.LBL_Condition_Manager_Count_and_OrderBY.replace('{0}', this.noOfRecords) : '';
                    this.records = this.buildData(parsedResult.records);
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
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
        }
    }

    // Builds and formats the data rows for the grid display.
    buildData(data) {
        try {
            let records = [];
            for (let item of data) {
                let conditionWrapper = {
                    Name: item.Name,
                    Id: item.Id,
                    isSelected: this.selectedRecordIds.includes(item.Id),
                    link: '/' + item.Id,
                    values: [],
                    rowColor: '',
                    firstTdStyle: '',
                    lastTdStyle: '',
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
                        link: '',
                        scale: field.scale,
                        step: field.step,
                        isInputField: field.isInputField,
                        pickListValues: [],
                        style: (field.style ? field.style : '') + 'word-wrap: break-word;',
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
                        conditionWrapper.rowColor += field.picklistColorsMap && fieldWrapper.fieldValue !== '' && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue) && field.picklistColorsMap[fieldWrapper.fieldValue] !== '' ? field.picklistColorsMap[fieldWrapper.fieldValue] : '';
                    }
                    conditionWrapper.values.push(fieldWrapper);
                }
                this.originalValuesById[conditionWrapper.Id] = {};
                this.applyRowStyle(conditionWrapper);
                records.push(conditionWrapper);
            }
            this.isLoading = false;
            return records;
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
        }
    }

    applyRowStyle(conditionWrapper) {
        if (conditionWrapper.values && conditionWrapper.values.length > 0) {
            for (const fieldWrapper of conditionWrapper.values) {
                if (this.originalValuesById.hasOwnProperty(conditionWrapper.Id)) {
                    this.originalValuesById[conditionWrapper.Id][fieldWrapper.fieldName] = fieldWrapper.fieldValue;
                }
                if (conditionWrapper.rowColor !== '') {
                    fieldWrapper.style = this.setStyleProp(fieldWrapper.style, 'background-color', conditionWrapper.rowColor)
                }
            }
            conditionWrapper.firstTdStyle = this.getStyleProp(conditionWrapper.values[0].style, 'background-color');
            conditionWrapper.lastTdStyle = this.getStyleProp(conditionWrapper.values[conditionWrapper.values.length - 1].style, 'background-color');
        }
    }

    setStyleProp(style, prop, value) {
        const regex = new RegExp(`${prop}\\s*:\\s*[^;]+`, 'i');
        if (regex.test(style)) {
            return style.replace(regex, `${prop}: ${value}`);
        }
        return style + `${prop}: ${value};`;
    }

    getStyleProp(style, prop) {
        const regex = new RegExp(`${prop}\\s*:\\s*([^;]+)`, 'i');
        const match = style.match(regex);
        return match ? (prop + ':' + match[1].trim() + ';') : null;
    }

    //Header Actions
    // Toggles between edit and view mode in the grid.
    toggleEditMode() {
        this.isEditMode = !this.isEditMode;
        if (this.isEditMode) {
            this.initialRecords = JSON.parse(JSON.stringify(this.records))
        } else {
            this.records = JSON.parse(JSON.stringify(this.initialRecords))
            this.conditionsToUpdateMap = {};
        }
    }

    // Opens or closes the right-side filter panel.
    toggleFilter() {
        this.template.querySelector('.filterPanel').classList.toggle('slds-hide');
    }

    // Saves all new and modified records to the server.
    handleSave() {
        try {
            this.isLoading = true;
            if (!this.newRecords.length && !Object.keys(this.conditionsToUpdateMap || {}).length) {
                this.showNotification(this.labels.LBL_Warning, this.labels.MSG_No_Changes_To_Save, 'warning');
                this.isLoading = false;
                return;
            }
            save({
                recordsToUpdate: JSON.stringify(Object.values(this.conditionsToUpdateMap)),
                recordsToInsert: JSON.stringify(this.newRecords)
            }).then(result => {
                if (result == 'SUCCESS') {
                    this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                    this.newRecords = [];
                    this.conditionsToUpdateMap = {};
                    this.isEditMode = false;
                    this.originalValuesById = {};
                    this.pageNumber = 1;
                    this.loadData();
                } else {
                    this.showNotification(this.labels.LBL_Error, result, 'error');
                    this.isLoading = false;
                }
            }).catch(error => {
                this.showNotification('Error', error?.body?.message || error?.message || 'Save failed', 'error');
                this.isLoading = false;
            })
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    // Navigate back to the record page.
    handleCancel() {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Navigation error:', error);
            this.showNotification(this.labels.LBL_Error, 'Unable to navigate to the record view.', 'error');
        }
    }

    // Selects or deselects all checkboxes in the table.
    toggleAllSelected(event) {
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

    // Handles individual row checkbox changes.
    toggleSelectedRecords(event) {
        let index = event.currentTarget.dataset.index;
        let item = this.records[index];
        item.isSelected = !item.isSelected;
        if (item.isSelected) {
            this.selectedRecordIds.push(item.Id);
        } else {
            this.selectedRecordIds.splice(index, 1);
        }
    }

    // Deletes selected rows using Apex and refreshes the grid.
    confirmDeleteConditions() {
        this.isLoading = true;
        deleteConditions({ recordIds: this.selectedRecordIds || [] })
            .then((result) => {
                if (result == 'SUCCESS') {
                    this.popups.deletePopup.isOpen = false;
                    this.selectedRecordIds = [];
                    this.loadData();
                } else {
                    this.showNotification(this.labels.LBL_Error, result, 'error');
                    this.isLoading = false;
                }
            }).catch(error => {
                this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.isLoading = false;
            });
    }

    // Handle inline edit of a field in the data table
    handleFieldEdits(event) {
        const recordIndex = event.target.dataset.index;
        const fieldName = event.target.dataset.field;
        let newValue = event.detail == null
            ? (event.target.value == null ? event.target.checked : event.target.value)
            : (event.detail.value == null ? event.detail.checked : event.detail.value);
        newValue = (Array.isArray(newValue) ? newValue[0] : newValue) || null;
        const record = this.records[recordIndex];
        let object;
        if (this.conditionsToUpdateMap.hasOwnProperty(record.Id)) {
            object = this.conditionsToUpdateMap[record.Id];
        } else {
            object = {
                attributes: { type: this.API_NAMES.Contract_Discount__c.objectApiName },
                Id: record.Id
            };
        }
        let field = this.displayedFields.find(field => field.fieldName === fieldName);
        if (field.picklistColorsMap && newValue !== '' && field.picklistColorsMap.hasOwnProperty(newValue)) {
            record.rowColor = field.picklistColorsMap[newValue];
        }
        this.applyRowStyle(record);
        const originalValue = this.originalValuesById[record.Id][fieldName];
        if (originalValue !== newValue) {
            object[fieldName] = newValue;
        } else {
            if (object.hasOwnProperty(fieldName)) {
                delete object[fieldName];
            }
            const hasAnyChange = Object.keys(object).some(key => key !== 'attributes' && key !== 'Id');
            if (!hasAnyChange) {
                delete this.conditionsToUpdateMap[record.Id];
                return;
            }
        }
        this.conditionsToUpdateMap[record.Id] = object;
    }

    applyFilter(event) {
        console.log('hiiii applyFilter')
        this.filters.dynamic = event.detail.dynamicFilters;
        console.log('this.filters.dynamic >> ' + JSON.stringify(this.filters.dynamic))
        this.toggleFilter();
        this.loadData();
    }

    // Calculates dynamic table height and applies it to layout.
    changeHeight = () => this.setTableDimension();

    // Sets table and filter panel height based on window size.
    setTableDimension() {
        let header = this.template.querySelector('.pageHeader');
        let master = this.template.querySelector('.masterStyle');
        let body = this.template.querySelector('.main-panel');
        let CountAndOrderBYSection = this.template.querySelector('.CountAndOrderBYSection');
        // measure the instructions card (if shown)
        let instr = this.template.querySelector('.instructions-card');
        let instrHeight = instr ? instr.getBoundingClientRect().height : 0;
        let baseHeight;
        if (header && body) {
            let headerHeight = header.getBoundingClientRect().height;
            baseHeight = window.innerHeight - headerHeight - instrHeight - (3 * 45);
            if (master) {
                let masterHeight = master.getBoundingClientRect().height;
                baseHeight -= masterHeight;
            }
            if (CountAndOrderBYSection) {
                let CountAndOrderBYSectionHeight = CountAndOrderBYSection.getBoundingClientRect().height;
                baseHeight -= CountAndOrderBYSectionHeight;
            }
            body.style.height = baseHeight + 'px';
        }
        let minHeight = 300;
        let bodyHeight = parseFloat(baseHeight);
        if (this.template.querySelector('.filterPanel')) {
            this.template.querySelector('.filterPanel').style.height = bodyHeight + 'px';
            this.template.querySelector('.filterPanel').style.minHeight = minHeight + 'px';
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