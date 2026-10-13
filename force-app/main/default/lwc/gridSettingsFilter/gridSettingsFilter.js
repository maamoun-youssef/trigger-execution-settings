import { LightningElement, track, api } from 'lwc';
import { Labels } from "c/gridSettingsHelper";
import popupTemplate from './gridSettingsFilterPopup.html';
import panelTemplate from './gridSettingsFilterPanel.html';

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class GridSettingsFilter extends LightningElement {
    @api isPopup
    @api confirmEvent;
    @api cancelEvent;
    @api numberOfFixedColumns;
    @api fixedColumnsEvent;
    @api objectName;
    @api fields = [];
    @api panelHeight;
    @api isShowFilter;
    fieldsToFilterMap = {};
    Label = Labels;
    get isBigObject() {
        return this.objectName != null && this.objectName != '' && this.objectName.endsWith('__b');
    }
    get fixedColumnsOptions() {
        return [
            { label: '0', value: 0 },
            { label: '1', value: 1 },
            { label: '2', value: 2 },
            { label: '3', value: 3 },
            { label: '4', value: 4 },
            { label: '5', value: 5 },
            { label: '6', value: 6 },
        ];
    }
    @track fieldsToFilter = [];
    @track multilevelFields = [];
    @track advancedClass = 'slds-summary-detail';
    @api refreshPanelHeight(newHeight) {
        this.panelHeight = newHeight;
        this.changeHeight();
    }
    render() {
        return (this.isPopup == 'true') ? popupTemplate : panelTemplate;
    }
    connectedCallback() {
        this.populateFiltersMap(JSON.parse(this.fields));
        window.addEventListener('resize', this.changeHeight);
    }

    renderedCallback() {
        this.changeHeight();
    }
    changeHeight = () => this.setTableDimension();

    setTableDimension() {
        if (this.panelHeight) {
            this.panelHeight = '' + this.panelHeight;
            var height = parseInt(this.panelHeight.match(/height:\s*(\d+)px/)[1]);
            var minHeight = parseInt(this.panelHeight.match(/min-height:\s*(\d+)px/)[1]);
            let filterFooter = this.template.querySelector('.filterFooter').getBoundingClientRect().height;
            this.template.querySelector('.filterBody').style.height = (height - 1.8 * filterFooter) + 'px';
            this.template.querySelector('.filterBody').style.minHeight = (minHeight - 1.8 * filterFooter) + 'px';
        }
    }
    get hasFields() {
        // return this.fieldsToFilter && this.fieldsToFilter.length > 0;
        return (this.isPopup != 'true') ? this.fieldsToFilter && this.fieldsToFilter.length > 0 && this.fieldsToFilter.some(item => item.hasOwnProperty('userFilterable') && item.userFilterable) : this.fieldsToFilter && this.fieldsToFilter.length > 0;
    }
    get hasAdvancedFields() {
        // return false;
        return false && ((this.isPopup != 'true') ? this.multilevelFields && this.multilevelFields.length > 0 && this.multilevelFields.some(item => item.hasOwnProperty('userFilterable') && item.userFilterable) : this.multilevelFields && this.multilevelFields.length > 0);
    }
    populateFiltersMap(fields) {
        for (let field of fields) {
            let fieldToFilter = {};
            if (SUPPORTED_TYPES.includes(field.stringFieldType)
                || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
                || field.hasOwnProperty('userFilterable')) {
                fieldToFilter.fieldLabel = field.fieldLabel;
                fieldToFilter.fieldName = field.fieldName;
                fieldToFilter.stringFieldType = field.stringFieldType;
                fieldToFilter.isMultiLevel = field.isMultiLevel;
                if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
                if (field.stringFieldType === 'ID') {
                    if (field.values) fieldToFilter.displayVal = field.values.join(';');
                    fieldToFilter.isId = true;
                }
                if (field.stringFieldType === 'STRING') {
                    fieldToFilter.isText = true;
                }
                if (field.stringFieldType === 'REFERENCE') {
                    fieldToFilter.isReference = true;
                }
                if (field.stringFieldType === 'BOOLEAN') {
                    fieldToFilter.isCheckboxGroup = true;
                    let options = [{ label: this.Label.LBL_True, value: 'true' }, { label: this.Label.LBL_False, value: 'false' }];
                    fieldToFilter.options = options;
                }
                if (field.pickListValues
                    && (field.stringFieldType === 'PICKLIST' || field.stringFieldType === 'MULTIPICKLIST'
                        || field.stringFieldType === 'COMBOBOX'
                        || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues.length > 1))) {
                    fieldToFilter.isCheckboxGroup = true;
                    let options = [];
                    options = field.pickListValues;
                    fieldToFilter.options = options;
                }
                if (field.stringFieldType === 'DOUBLE' || field.stringFieldType === 'INTEGER' || field.stringFieldType === 'LONG'
                    || field.stringFieldType === 'CURRENCY' || field.stringFieldType === 'PERCENT') {
                    fieldToFilter.isNumber = true;
                    fieldToFilter.formatter = '';
                    fieldToFilter.step = '';
                    if (field.stringFieldType === 'DOUBLE') {
                        fieldToFilter.formatter = 'decimal';
                        fieldToFilter.step = 0.01;
                    }
                    if (field.stringFieldType === 'CURRENCY') {
                        fieldToFilter.formatter = 'currency';
                        fieldToFilter.step = 0.01;
                    }
                    if (field.stringFieldType === 'PERCENT') {
                        fieldToFilter.formatter = 'percent-fixed';
                        fieldToFilter.step = 0.01;
                    }
                }
                if (field.stringFieldType === 'DATE' || field.stringFieldType === 'DATETIME') {
                    fieldToFilter.isDate = true;
                }
                if (field.stringFieldType === 'TIME') {
                    fieldToFilter.isTime = true;
                }
                if (SUPPORTED_VALUES_TYPES.includes(field.stringFieldType)
                    || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
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
                //list to display
                if (Object.keys(fieldToFilter).length !== 0) {
                    this.fieldsToFilterMap[fieldToFilter.fieldName] = fieldToFilter;
                }
            }
        }
        this.populateLists(this.fieldsToFilterMap);
    }
    populateLists(filtersMap) {
        if (Object.keys(filtersMap).length !== 0) {
            this.fieldsToFilter = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //get record type field
            var recordTypeField = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === false && filtersMap[fieldName].stringFieldType === 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //add record type fields always to the top
            if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
            this.multilevelFields = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === true)
                .map(fieldName => { return filtersMap[fieldName]; });
            // console.log('fieldsToFilter=' + JSON.stringify(this.fieldsToFilter));
            // console.log('multilevelFields=' + JSON.stringify(this.multilevelFields));
        }
    }
    setSelectedValues(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var modeValue = event.target.dataset.mode;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field.values = [];
            if (modeValue === 'multiple') {
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
        /*
            [{ "fieldName": "api name", value1: '',  value2: '' }]
            ------------------------------------
            [{ "fieldName": "api name", values: [ ] }]
        */
        let selection = [];
        try {
            selection = Object.keys(this.fieldsToFilterMap)
                .filter(fieldName =>
                (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
                    (this.fieldsToFilterMap[fieldName].values &&
                        (this.fieldsToFilterMap[fieldName].values.length > 1
                            || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                    || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
                    || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
                .map(fieldName => {
                    let item = {};
                    item.fieldName = fieldName;
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
                        item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
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
        } catch (error) {
            console.log(error);
        }
        const confirmEvent = new CustomEvent(this.confirmEvent, {
            detail: { value: JSON.stringify(selection) },
        });
        this.dispatchEvent(confirmEvent);
    }
    closeFilter() {
        if (this.cancelEvent) {
            const cancelEvent = new CustomEvent(this.cancelEvent);
            this.dispatchEvent(cancelEvent);
        }
    }
    toggleAdvanced(e) {
        if (this.advancedClass === 'slds-summary-detail') {
            this.advancedClass = 'slds-summary-detail slds-is-open';
        } else {
            this.advancedClass = 'slds-summary-detail';
        }
    }
    handleStickycolumnChanged(event) {
        this.numberOfFixedColumns = Number(event.target.value);
        const fixedColumnsEvent = new CustomEvent(this.fixedColumnsEvent, {
            detail: { value: this.numberOfFixedColumns },
        });
        this.dispatchEvent(fixedColumnsEvent);
    }
}