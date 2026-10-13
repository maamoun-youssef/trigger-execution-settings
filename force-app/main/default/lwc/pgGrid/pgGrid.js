/**
* @author ULiT
* @date 25-05-2024
* @description ProductPgGrid
*******************************************************************************************************************************************
*/
import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
//APEX
import getData from "@salesforce/apex/PGGridController.getData";
import initData from "@salesforce/apex/PGGridController.initData";
import saveData from "@salesforce/apex/PGGridController.saveData";
//OBJECTS
import PG__OBJECT from '@salesforce/schema/PG__c';
import SUPPLIER__OBJECT from '@salesforce/schema/Supplier__c';
import PRODUCT__OBJECT from '@salesforce/schema/Product2';
//LABELS
import LBL_Add from "@salesforce/label/c.LBL_Add";
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
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import Search from "@salesforce/label/c.Search";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_None from "@salesforce/label/c.LBL_None";
import LBL_PG_Grid_Title from "@salesforce/label/c.LBL_PG_Grid_Title";
import LBL_Global_PG_Grid_Title from "@salesforce/label/c.LBL_Global_PG_Grid_Title";
import LBL_PG_Grid_SubTitle from "@salesforce/label/c.LBL_PG_Grid_SubTitle";
import LBL_Global_PG_Grid_SubTitle from "@salesforce/label/c.LBL_Global_PG_Grid_SubTitle";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
//STATIC RESSOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
export default class ProductPgsGrid extends LightningElement {
    //API
    @api recordId;
    @api templateName;
    //labels
    @track labels = {
        LBL_Error,
        MSG_No_Changes_To_Save,
        Search,
        LBL_Reset,
        LBL_Filter,
        LBL_Success,
        LBL_Edit,
        LBL_No_Record_To_Display,
        LBL_PG_Grid_Title: LBL_PG_Grid_Title,
        LBL_PG_Grid_SubTitle: LBL_PG_Grid_SubTitle,
        LBL_Global_PG_Grid_Title,
        LBL_Global_PG_Grid_SubTitle,
        LBL_Add,
        LBL_Save,
        LBL_Cancel,
        LBL_First,
        LBL_Last,
        LBL_Previous,
        LBL_Next,
        LBL_Of,
        LBL_None_Picklist_Value,
        LBL_None,
        // LBL_Record_Type,
        SupplierFieldLabel: '',
    }
    @track filters = {
        productRT: '',
        globalSearchValue: '',
        dynamic: '',
    }
    @track productRTs = [];
    //TRACK variables
    @track displayedFields = [];
    @track priceFields = [];
    @track sortField = '';
    @track sortDirection = 'DESC';
    @track isSortASC = false;
    @track isProduct = false;
    @track records = [];
    @track PGToUpdateMap = {};
    @track noOfRecords = 0;
    //Variables
    isLoading = true;
    isEditMode = false;
    isFilterOpen = false;
    sortFieldApi = '';
    // PAGINATION Variables
    @track pageSize = '25';
    pageNumber = 1;
    pageCount = 0;

    @wire(getObjectInfo, { objectApiName: PRODUCT__OBJECT.objectApiName }) objectInfoProduct({ error, data }) {
        if (data) {
            var recordtypeinfo = data.recordTypeInfos;
            var uiCombobox = [];
            uiCombobox.push({ label: LBL_None, value: '' });
            for (var eachRecordtype in recordtypeinfo) {
                if (recordtypeinfo.hasOwnProperty(eachRecordtype) && !recordtypeinfo[eachRecordtype].master) {
                    uiCombobox.push({ label: recordtypeinfo[eachRecordtype].name, value: recordtypeinfo[eachRecordtype].recordTypeId })
                }
            }
            this.productRTs = uiCombobox;
        } else if (error) {
            console.log('ERROR');
        }
    }

    setnumberOfFixedColumns() {
        // Sticky / Fixed columns for first Table
        if (this.template.querySelector('.main-table')) {
            let tableTrs = this.template.querySelector('.main-table').rows;
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = 5;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
        }
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });
        this.initData();
        window.addEventListener('resize', this.changeHeight);
    }

    changeHeight = () => {
        try {
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBody = this.template.querySelector(".pageBody");
            let pageFooter = this.template.querySelector(".footerDiv");
            if (pageHeader && pageFooter && pageBody) {
                pageBody.style.height = (this.recordId ? (window.innerHeight - pageHeader.offsetHeight - pageFooter.offsetHeight - 10) / 2 : window.innerHeight - pageHeader.offsetHeight - pageFooter.offsetHeight - 10) + "px";
                if (this.template.querySelector(".filter-panel")) {
                    this.template.querySelector(".filter-panel").style.height = (this.recordId ? (window.innerHeight - pageHeader.offsetHeight - pageFooter.offsetHeight - 10) / 2 : window.innerHeight - pageHeader.offsetHeight - pageFooter.offsetHeight - 10) + "px";
                }
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    };

    renderedCallback() {
        this.setnumberOfFixedColumns();
        this.changeHeight();
    }

    API_NAMES = {
        Supplier__c: {
            objectApiName: SUPPLIER__OBJECT.objectApiName,
        },
        PG__c: {
            objectApiName: PG__OBJECT.objectApiName,
        },
    }

    @track gridSettings = {};
    @track prefix = '';
    fieldsToFilterMap = {};
    @track fieldsToFilter = [];

    initData() {
        initData({ recordId: this.recordId, gridSettingsName: this.templateName }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result);
                this.gridSettings = parsedResult.gridSettingsManagerPG;
                this.prefix = parsedResult.prefix;
                this.populateFiltersMap(this.gridSettings.FILTERS);
                if (this.gridSettings.Default_Page_Size) {
                    this.pageSize = this.gridSettings.Default_Page_Size + '';
                }
                if (parsedResult.objectLabel != '') {
                    this.labels.LBL_PG_Grid_Title = this.labels.LBL_PG_Grid_Title.replace('{0}', parsedResult.objectLabel)
                    this.labels.LBL_PG_Grid_SubTitle = this.labels.LBL_PG_Grid_SubTitle.replace('{0}', parsedResult.objectLabel)
                }
                console.log('this.gridSettings. >>>> ' + JSON.stringify(this.gridSettings))
                this.buildDisplayedFields();
            }
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }

    //LOAD
    loadData() {
        this.records = [];
        try {
            this.isLoading = true;
            let filteredFields = this.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
            getData({
                recordId: this.recordId,
                fields: JSON.stringify(this.gridSettings.ALL_FIELDS),
                filters: JSON.stringify(this.filters),
                filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
                pageNumber: this.pageNumber,
                pageSize: this.pageSize,
                sortField: this.sortField,
            }).then((result) => {
                let parsedresult = JSON.parse(result);
                this.noOfRecords = parsedresult.numberOfRecords;
                this.pageCount = Math.ceil(parsedresult.numberOfRecords / this.pageSize);
                console.log('parsedresult.records: ' + JSON.stringify(parsedresult.records))
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

    buildDisplayedFields() {
        for (let field of this.gridSettings.GRID_FIELDS) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                isNameField: field.fieldName == 'Name',
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                isHTMLFormatted: field.isHTMLFormatted,
                link: '',
                scale: field.scale,
                step: '',
                isInputField: field.isInputField,
                style: field.style,
                headerStyle: field.headerStyle?.style,
                pickListValues: field.pickListValues,
                isSortable: field.isSortable,
                isFilterable: field.isFilterable,
                isEncrypted: field.isEncrypted,
                filterValue: '',
                sortedField: false,
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
        console.log('this.displayedFields >>>> ' + JSON.stringify(this.displayedFields))
        this.loadData();
    }

    handleChangeSortField(event) {
        this.isLoading = true;
        let fieldName = event.target.dataset.field;
        if (this.sortFieldApi.startsWith(fieldName)) {
            if (this.sortDirection == 'ASC') {
                this.sortDirection = 'DESC';
            } else {
                this.sortDirection = 'ASC';
            }
        } else {
            this.sortDirection = 'ASC';
        }
        this.isSortASC = this.sortDirection == 'ASC'
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
        })
        this.loadData();
    }

    buildData(data) {
        let records = [];
        for (let item of data) {
            let PgW = {
                Name: item.Name,
                Id: item.Id,
                link: '/' + item.Id,
                values: [],
                histories: [],
                showHistories: false,
                hasHistories: false,
            }
            let fieldIndex = 0;
            for (let field of this.displayedFields) {
                if (field.isInputField && this.PGToUpdateMap.hasOwnProperty(item.Id)) {
                    let obj = this.PGToUpdateMap[item.Id];
                    if (obj.hasOwnProperty(field.fieldName)) {
                        item[field.fieldName] = obj[field.fieldName];
                    }
                }
                let fieldWrapper = {
                    Id: item.Id,
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: '',
                    fieldOutputValue: '',
                    isNumberField: field.isNumberField,
                    isReference: field.isReference,
                    isNameField: field.isNameField,
                    isDate: field.isDate,
                    isDateTime: field.isDateTime,
                    isPicklist: field.isPicklist,
                    isBoolean: field.isBoolean,
                    isTextarea: field.isTextarea,
                    isText: field.isText,
                    isHTMLFormatted: field.isHTMLFormatted,
                    link: field.fieldName == 'Name' ? '/' + item.Id : '',
                    link: '',
                    scale: field.scale,
                    step: field.step,
                    isInputField: field.isInputField,
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
                // if (fieldWrapper.fieldValue) {
                //     let width = fieldWrapper.fieldValue.length * 4 < 120 ? 120 : fieldWrapper.fieldValue.length * 4;
                //     fieldWrapper.style += 'width:' + width + 'px;min-width:' + width + 'px;max-width:' + width + 'px;';
                // }
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
                if (fieldIndex == 0) {
                    fieldWrapper.first = true;
                }
                fieldIndex++;
                PgW.values.push(fieldWrapper);
            }
            if (item[this.prefix + 'PGPGReference__r'] && item[this.prefix + 'PGPGReference__r'].totalSize != 0) {
                PgW.hasHistories = true;
                PgW.histories = this.buildData(item[this.prefix + 'PGPGReference__r'].records);
            }
            records.push(PgW);
        }
        this.isLoading = false;
        return records;
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

    handleSearchPG(event) {
        const searchTerm = event.target.value;
        this.displayedFields.forEach(field => {
            if (field.isFilterable && !field.isNumberField && !field.isDate && !field.isDateTime && !field.isBoolean) {
                field.filterValue = searchTerm;
            }
        });
        this.loadData();
    }

    handleEnterKeyPress(event) {
        // Check if the Enter key was pressed
        if (event.keyCode === 13) {
            this.handleSearchPG(event);
        }
    }

    handleChangeSearch(event) {
        let field = event.target.dataset.field;
        this.filters[field] = event.target.value;
    }

    showHistories(event) {
        let index = event.target.dataset.index;
        this.records[index].showHistories = !this.records[index].showHistories;
    }

    // PAGINATION Variables
    changePageSizeHandler(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.loadData();
    }

    handlePrevious() {
        try {
            this.pageNumber--;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleNext() {
        try {
            this.pageNumber++;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleFirst() {
        try {
            this.pageNumber = 1;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleLast() {
        try {
            this.pageNumber = this.pageCount;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    // GETTERS
    get pageRecordCount() {
        if (this.noOfRecords == 0) {
            return '0';
        }
        let pageSize = parseInt(this.pageSize)
        let firstPart = (this.pageNumber * pageSize) + 1 - pageSize;
        let string = '' + firstPart;
        string += '-'
        if ((this.pageNumber * pageSize) > this.noOfRecords) {
            string += this.noOfRecords;
        } else {
            string += this.pageNumber * pageSize;
        }
        return string;
    }

    get pageSizeOptions() {
        return [
            { label: '5', value: '5' },
            { label: '10', value: '10' },
            { label: '25', value: '25' },
            { label: '50', value: '50' },
            { label: '75', value: '75' },
            { label: '100', value: '100' }];
    }

    get nextDisabled() {
        return ((this.pageNumber >= this.pageCount || this.tableLoading));
    }

    get previousDisabled() {
        return ((this.pageNumber <= 1 || this.tableLoading));
    }

    get lastDisabled() {
        return ((this.pageNumber == this.pageCount || this.tableLoading || this.pageCount == 0));
    }

    get firstDisabled() {
        return ((this.pageNumber == 1 || this.tableLoading));
    }

    //EVENT HANDLERS
    toggleEditMode() {
        this.isEditMode = !this.isEditMode;
    }

    handleCancelEditMode() {
        this.PGToUpdateMap = {};
        this.isEditMode = !this.isEditMode;
    }

    //EDIT AND SAVE
    handleFieldEdits(event) {
        let id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let value = event.target.value;
        let obj;
        if (this.PGToUpdateMap.hasOwnProperty(id)) {
            obj = this.PGToUpdateMap[id];
        } else {
            obj = {
                attributes: {
                    type: PG__OBJECT.objectApiName,
                },
                Id: id
            };
        }
        obj[field] = value;
        this.PGToUpdateMap[id] = obj;
    }

    handleSave() {
        if (!this.PGToUpdateMap || Object.keys(this.PGToUpdateMap).length == 0) {
            this.showNotification(this.labels.MSG_No_Changes_To_Save, '', 'info');
            return;
        }
        saveData({
            recordsToUpsertJSON: JSON.stringify(Object.values(this.PGToUpdateMap))
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error');
            }
            this.isLoading = false;
            this.isEditMode = false;
            this.pageNumber = 1;
            this.loadData();
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

    //MISC
    showNotification(title, message, variant) {
        console.log('title: ' + title)
        console.log('message: ' + message)
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
}