import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// Services
import initData from '@salesforce/apex/BUListManagerCmpController.initData';
import loadBURecord from '@salesforce/apex/BUListManagerCmpController.loadBURecord';
import getBUList from '@salesforce/apex/BUListManagerCmpController.getBUList';
import saveBU from '@salesforce/apex/BUListManagerCmpController.saveBU';
import selectOnlyRespectBUs from '@salesforce/apex/BUListManagerCmpController.selectOnlyRespectBUs';

// OBJECTS
import BusinessUnit_OBJECT from '@salesforce/schema/BusinessUnit__c';
// bu FIELDS
import Supplier__c from '@salesforce/schema/BusinessUnit__c.Supplier__c';
import t_BUAttributes__c from '@salesforce/schema/BusinessUnit__c.t_BUAttributes__c';

//IMPORTS
import LBL_PA_Field from '@salesforce/label/c.LBL_PA_Field';
import LBL_PA_Value from '@salesforce/label/c.LBL_PA_Value';
import LBL_PA_ISNULL from '@salesforce/label/c.LBL_PA_ISNULL';
import LBL_PA_ISBLANK from '@salesforce/label/c.LBL_PA_ISBLANK';
import LBL_PA_IS_NOT_NULL from '@salesforce/label/c.LBL_PA_IS_NOT_NULL';
import LBL_PA_IS_NOT_BLANK from '@salesforce/label/c.LBL_PA_IS_NOT_BLANK';
import LBL_PA_EQUALS from '@salesforce/label/c.LBL_PA_EQUALS';
import LBL_PA_NOT_EQUALS from '@salesforce/label/c.LBL_PA_NOT_EQUALS';
import LBL_PA_CONTAINS from '@salesforce/label/c.LBL_PA_CONTAINS';
import LBL_PA_DOESNT_CONTAIN from '@salesforce/label/c.LBL_PA_DOESNT_CONTAIN';
import MSG_BUListManager_Condition_X_Not_Exist_In_Filter_Logic from "@salesforce/label/c.MSG_BUListManager_Condition_X_Not_Exist_In_Filter_Logic";
import MSG_BUListManager_Invalid_Token_X_Found from "@salesforce/label/c.MSG_BUListManager_Invalid_Token_X_Found";
import MSG_BUListManager_Unmatched_Closing_Parenthesis from "@salesforce/label/c.MSG_BUListManager_Unmatched_Closing_Parenthesis";
import MSG_BUListManager_Unmatched_Opening_Parenthesis from "@salesforce/label/c.MSG_BUListManager_Unmatched_Opening_Parenthesis";
import MSG_BUListManager_Consecutive_Numbers_Found_XY from "@salesforce/label/c.MSG_BUListManager_Consecutive_Numbers_Found_XY";
import MSG_BUListManager_Consecutive_Operators_Found_XY from "@salesforce/label/c.MSG_BUListManager_Consecutive_Operators_Found_XY";
import MSG_BUListManager_Operator_Before_Closing_Parenthesis from "@salesforce/label/c.MSG_BUListManager_Operator_Before_Closing_Parenthesis";
import MSG_BUListManager_Filter_Logic_Invalid from "@salesforce/label/c.MSG_BUListManager_Filter_Logic_Invalid";
import MSG_BUListManager_Misplaced_Parenthesis from "@salesforce/label/c.MSG_BUListManager_Misplaced_Parenthesis";
import LBL_And from "@salesforce/label/c.LBL_And";
import LBL_Or from "@salesforce/label/c.LBL_Or";
import { labels } from './properties.js';

const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const SUCCESS_VARIANT = 'success';
const INFO_VARIANT = 'info';
// Global Constants
const Operations = {
    SUM: 'SUM',
    AVG: 'AVG',
    COUNT: 'COUNT',
    ISNULL: 'ISNULL',
    ISNOTNULL: 'ISNOTNULL',
    ISBLANK: 'ISBLANK',
    ISNOTBLANK: 'ISNOTBLANK',
    EQUALS: 'EQUALS',
    NOTEQUALS: 'NOTEQUALS',
    BETWEEN: 'BETWEEN',
    GREATER: 'GREATER',
    GREATER_OR_EQUALS: 'GREATER_OR_EQUALS',
    LESS: 'LESS',
    LESS_OR_EQUALS: 'LESS_OR_EQUALS',
    CONTAINS: 'CONTAINS',
    NOTCONTAINS: 'NOTCONTAINS',
};
const OPERATORS_BY_TYPE = {
    STRING: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: Operations.NOTCONTAINS },
        //'startsWith',
        //'endsWith',
        { label: LBL_PA_ISBLANK, value: Operations.ISBLANK },
        { label: LBL_PA_IS_NOT_BLANK, value: Operations.ISNOTBLANK }
    ],
    TEXTAREA: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: Operations.NOTCONTAINS },
        { label: LBL_PA_ISBLANK, value: Operations.ISBLANK },
        { label: LBL_PA_IS_NOT_BLANK, value: Operations.ISNOTBLANK }
    ],
    BOOLEAN: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS }
    ],
    NUMBER: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        { label: 'GREATER', value: Operations.GREATER },
        { label: 'LESS', value: Operations.LESS },
        { label: 'GREATER OR EQUALS', value: Operations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    PERCENT: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        { label: 'GREATER', value: Operations.GREATER },
        { label: 'LESS', value: Operations.LESS },
        { label: 'GREATER OR EQUALS', value: Operations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    CURRENCY: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: 'GREATER', value: Operations.GREATER },
        { label: 'LESS', value: Operations.LESS },
        { label: 'GREATER OR EQUALS', value: Operations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    DATE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        { label: 'GREATER', value: Operations.GREATER },
        { label: 'LESS', value: Operations.LESS },
        { label: 'GREATER OR EQUALS', value: Operations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    DATETIME: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: 'GREATER', value: Operations.GREATER },
        { label: 'LESS', value: Operations.LESS },
        { label: 'GREATER OR EQUALS', value: Operations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    PICKLIST: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        //'in',
        //'notIn',
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    MULTIPICKLIST: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        //'includes',
        //'excludes',
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    REFERENCE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOTEQUALS },
        //'in',
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    EMAIL: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    PHONE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ]
};
export default class buListManager extends NavigationMixin(LightningElement) {
    /* VARIABLES */
    @track labels = {
        ...labels,
    }
    API_NAMES = {
        BusinessUnit__c: {
            objectApiName: BusinessUnit_OBJECT.objectApiName,
            t_BUAttributes__c: t_BUAttributes__c.fieldApiName,
            Supplier__c: Supplier__c.fieldApiName,
            Supplier__r: Supplier__c.fieldApiName.replace(/__c$/, '__r'),
        },
    }

    booleanOptions = [
        { label: this.labels.LBL_True, value: 'TRUE' },
        { label: this.labels.LBL_False, value: 'FALSE' }
    ];
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '20', value: '20' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];
    buFields = [];
    buFieldAPIs = [];
    picklistValues = {};
    selectedIndex = '';
    selectedLevel = '';
    isLoading = true;
    originalCheckboxMap = {};
    /* API */
    @api recordId;
    @api layout;
    @api isNewBU = false;
    /* Track */
    @track bu = {};
    @track isBUSearched = false;
    @track selectedBUIds = [];
    @track loading = false;
    @track disableSave = false;
    @track displayedBUFields = [];
    @track activeTab;

    @track buLinkMng = {
        buLinkToDelete: [],
        buLinkToAdd: [],
        loading: false,
        displayedFields: [],
        data: [],
        totalNumbOfRecords: 0,
        pageSize: '50',
        pageNumber: 1,
        get previousDisabled() {
            return (this.pageNumber <= 1);
        },
        get nextDisabled() {
            let pageSize = parseInt(this.pageSize);
            return (this.pageNumber >= Math.ceil(this.totalNumbOfRecords / pageSize));
        },
        get pagesBadge() {
            let pageSize = parseInt(this.pageSize);
            return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + 'of' + ' ' + this.totalNumbOfRecords;
        },
    }
    @track selectedLevel = '0';
    @track searchString = '';
    @track selectedRecord = {};
    @track displayedFields = [];
    @track buAttributes = [];
    @track buAttributesLogicFilter = '';
    @track showBUAttributesLogicFilter = false;
    @track objectBUInfo = {
        fieldsLabel: {},
        fieldsInlineHelpText: {},
        fieldsAPI: {},
        picklistOptions: {},
        fieldsValue: {},
    };
    @track buAttributeFields = [];
    @track popUp = {
        confirmationDelete: {
            isOpen: false,
            title: 'Confirmation',
            closeModal() {
                this.popUp.confirmationDelete.isOpen = false;
            },
            submitDetails() {
                try {
                    this.popUp.confirmationDelete.isOpen = false;
                    this.getBUListData();
                } catch (e) {
                    console.log('error: ' + e);
                }
            }
        },
        configuration: {
            isOpen: false,
            title: 'Sections Configuration',
            toggleModal() {
                this.popUp.configuration.isOpen = !this.popUp.configuration.isOpen;
            },
            submitDetails() {
                this.popUp.configuration.isOpen = false;
            }
        },
    }
    @track totalWidth = 0;
    @track initWrapper = {};
    @track mainPanelHeight = '';
    @track noDataHeight = '';
    @track noDataImageStyle = '';
    /* WIRES */
    @wire(getObjectInfo, { objectApiName: BusinessUnit_OBJECT }) getBUInfo({ data, error }) {
        if (data) {
            this.buFieldAPIs = data.fields;
            this.buAttributeFields = [];
            for (let field of Object.values(data.fields)) {
                if (field.filterable) {
                    this.buAttributeFields.push({
                        label: field.label,
                        value: field.apiName,
                        fieldType: field.dataType,
                        referenceToInfos: field.referenceToInfos,
                        isReference: field.dataType === 'Reference',
                        referenceObjectApiName: field.referenceToInfos?.[0]?.apiName || '',
                        relationshipName: field.relationshipName || '',
                    });
                }
            }
            this.initData();
        } else if (error) {
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    connectedCallback() {
        this.loading = true;
        window.addEventListener('resize', this.changeHeight);
    }

    handleBUFieldRestore(event) {
        const index = event.target.dataset.index;
        const selectedField = event.detail;
        if (!selectedField?.fieldName || index == null) return;
        const fieldType = selectedField.fieldType;
        this.buAttributes[index] = {
            ...this.buAttributes[index],
            ...selectedField,
            operationsOptions: this.getOperationsBySubFieldType(fieldType),
            buFieldsType: this.buAttributeFields.filter(f => f.fieldType === fieldType),
        };
        this.buAttributes = [...this.buAttributes];
    }

    renderedCallback() {
        if (this.template.querySelector('.header')) {
            this.changeHeight();
        }
    }

    handleChangeSelectedCase(event) {
        let value = event.target.dataset.value;
        this.selectedCase = value;
    }

    @track nsFirstTdHeaderStyle = '';
    initData() {
        this.buLinkMng.displayedFields = [];
        initData({
            buId: this.recordId,
            layout: this.layout,
        }).then(result => {
            this.initWrapper = JSON.parse(result);
            this.buFields = this.initWrapper.buFields;
            this.activeTab = this.initWrapper.buFields.length > 0 ? 'BU' : 'BULink';
            // BU Fields
            for (let field of this.initWrapper.gridSettingsManagerBUList.GRID_FIELDS) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.isNumberField,
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
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
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime
                    && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
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
                this.buLinkMng.displayedFields.push(fieldWrapper);
            }
            this.loadBURecord();
        }).catch(error => {
            console.log('ERROR: >> ' + error.message);
            console.log('ERROR: >> ' + error.body?.message);
        });
    }

    loadBURecord() {
        this.loading = true;
        this.selectedBUIds = [];
        this.buLinkMng.buLinkToAdd = [];
        this.buLinkMng.buLinkToDelete = [];
        this.originalCheckboxMap = {};
        loadBURecord({
            buId: this.recordId,
            buFields: this.buFields,
        }).then(result => {
            this.mainWrapper = JSON.parse(result);
            this.bu = this.mainWrapper.bu;
            // get BU Fields
            if (this.buFields.length > 0) {
                this.buildBUInfoFields();
            }
            if (!this.isNewBU) {
                // get BU Attributes
                this.buAttributes = [];
                this.buAttributesLogicFilter = '';
                if (this.bu.hasOwnProperty(t_BUAttributes__c.fieldApiName) && this.bu[t_BUAttributes__c.fieldApiName] != '') {
                    this.buAttributes = JSON.parse(this.bu[t_BUAttributes__c.fieldApiName]).buAttributes;
                    this.buAttributesLogicFilter = JSON.parse(this.bu[t_BUAttributes__c.fieldApiName]).logicFilter;
                    if (this.buAttributesLogicFilter && this.buAttributesLogicFilter != '') {
                        this.buAttributesLogicFilter = this.buAttributesLogicFilter.replaceAll('AND', LBL_And).replaceAll('OR', LBL_Or);
                    }
                    this.showBUAttributesLogicFilter = this.buAttributesLogicFilter != '';
                }
                let index = 1;
                if (this.buAttributes && this.buAttributes.length > 0) {
                    this.buAttributes.forEach(item => {
                        item.index = index;
                        item.buFieldsType = item.fieldName && item.fieldName.length > 0 ? this.buAttributeFields.filter(f => f.fieldType == item.fieldName[0].fieldType) : '';
                        item.disableValue = ['ISNULL', 'ISBLANK', 'ISNOTNULL', 'ISNOTBLANK'].includes(item.operation);
                        item.class = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click buFieldsCombobox' + index;
                        index++;
                    })
                }
                // HANDLE BU List
                this.selectedBUIds = this.mainWrapper.selectedBUIds;
                this.getBUListData();
            }
            this.loading = false;
        }).catch(error => {
            console.log('ERROR: >> ' + error.message);
            console.log('ERROR: >> ' + error.body?.message);
        });
    }

    toggleFilterLogic() {
        this.showBUAttributesLogicFilter = !this.showBUAttributesLogicFilter;
        if (!this.showBUAttributesLogicFilter) {
            this.buAttributesLogicFilter = '';
        } else {
            this.buAttributesLogicFilter = '';
            let indexes = [];
            for (let index = 1; index <= this.buAttributes.length; index++) {
                indexes.push(index);
            }
            this.buAttributesLogicFilter = indexes.join(' ' + LBL_And + ' ');
        }
    }

    validateFilterLogic(filterLogic, conditionsArray) {
        const operators = [LBL_And, LBL_And.toUpperCase(), LBL_And.toLowerCase(), LBL_Or, LBL_Or.toUpperCase(), LBL_Or.toLowerCase()];
        const validNumbers = conditionsArray.map((_, index) => (index + 1).toString()); // e.g., ['1', '2', '3']
        const regex = new RegExp("\\d+|" + LBL_And + "|" + LBL_And.toUpperCase() + "|" + LBL_And.toLowerCase() + "|" + LBL_Or + "|" + LBL_Or.toUpperCase() + "|" + LBL_Or.toLowerCase() + "|\\(|\\)", "g");
        // Tokenize: match numbers, operators, and parentheses
        const tokens = filterLogic.match(regex);

        if (!tokens) {
            return MSG_BUListManager_Filter_Logic_Invalid;
        }
        let stack = [];
        let lastToken = null;
        let usedNumbers = new Set();

        for (let i = 0; i < tokens.length; i++) {
            let token = tokens[i];

            if (validNumbers.includes(token)) {
                // Track used conditions
                usedNumbers.add(token);

                // Number validation
                if (lastToken && validNumbers.includes(lastToken)) {
                    return MSG_BUListManager_Consecutive_Numbers_Found_XY;
                }
            } else if (operators.includes(token)) {
                // Operator validation
                if (!lastToken || operators.includes(lastToken) || lastToken === "(") {
                    return MSG_BUListManager_Consecutive_Operators_Found_XY;
                }
            } else if (token === "(") {
                // Opening parenthesis
                stack.push(token);
                if (lastToken && (validNumbers.includes(lastToken) || lastToken === ")")) {
                    return MSG_BUListManager_Misplaced_Parenthesis;
                }
            } else if (token === ")") {
                // Closing parenthesis
                if (stack.length === 0) {
                    return MSG_BUListManager_Unmatched_Closing_Parenthesis
                }
                stack.pop();
                if (lastToken && operators.includes(lastToken)) {
                    return MSG_BUListManager_Operator_Before_Closing_Parenthesis;
                }
            } else {
                return MSG_BUListManager_Invalid_Token_X_Found.replace('{0}', token + '');
            }

            lastToken = token;
        }

        // Final validation: No trailing operators and balanced parentheses
        if (operators.includes(lastToken)) {
            return `Error: Expression cannot end with an operator ('${lastToken}').`;
        }
        if (stack.length > 0) {
            return MSG_BUListManager_Unmatched_Opening_Parenthesis
        }

        // Check if all conditions exist in filterLogic
        for (let num of validNumbers) {
            if (!usedNumbers.has(num)) {
                return MSG_BUListManager_Condition_X_Not_Exist_In_Filter_Logic.replace('{0}', num + '');
            }
        }
        return true;
    }

    handleChangeLogicFilter(event) {
        this.buAttributesLogicFilter = event.target.value;
    }

    saveBUInfo() {
        try {
            this.disableSave = true;
            this.loading = true;
            let buAttributesJS = [];
            if (this.buAttributes) {
                this.buAttributes.forEach((item, index) => {
                    if (item.fieldName == '') {
                        throw new Error(`${this.labels.LBL_BUListManager_BU_Field} ${index + 1} cannot be empty`);
                    }
                    if (item.operation == '') {
                        throw new Error(`${this.labels.LBL_BUListManager_Operator} for field ${index + 1} cannot be empty`);
                    }
                    let newItem = {
                        fieldName: item.fieldName,
                        fieldLabel: item.fieldLabel,
                        operationType: item.operationType,
                        isField: item.isField,
                        operation: item.operation,
                        fieldValue: item.fieldValue,
                        isDisabled: item.isDisabled,
                    }
                    buAttributesJS.push(newItem);
                });
            }
            let filterLogicValidated = true;
            if (this.showBUAttributesLogicFilter) {
                filterLogicValidated = this.validateFilterLogic(this.buAttributesLogicFilter, buAttributesJS);
            }
            if (filterLogicValidated != true) {
                throw new Error(filterLogicValidated);
                //this.showNotification(this.labels.LBL_Error, filterLogicValidated, ERROR_VARIANT);
            } else {
                let buAttributesLogicFilter = this.buAttributesLogicFilter.replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND').replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
                let buAttribute = {
                    logicFilter: buAttributesLogicFilter,
                    buAttributes: buAttributesJS,
                }
                console.log('this.buLinkMng.buLinkToDelete >>> ' + JSON.stringify(this.buLinkMng.buLinkToDelete))
                saveBU({
                    buJSON: JSON.stringify(this.bu),
                    buAttributesJSON: JSON.stringify(buAttribute),
                    buLinkListToDeleteJSON: JSON.stringify(this.buLinkMng.buLinkToDelete),
                    buLinkListToAddJSON: JSON.stringify(this.buLinkMng.buLinkToAdd),
                    buFields: this.displayedBUFields.filter(field => field.isInputField).map(field => field.fieldName),
                }).then(result => {
                    this.bu = JSON.parse(result);
                    if (this.isNewBU) {
                        this.isNewBU = false;
                        this.recordId = this.bu.Id;
                    }
                    this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, SUCCESS_VARIANT);
                    this.disableSave = false;
                    this.selectedBUIds = [];
                    this.buLinkMng.buLinkToAdd = [];
                    this.buLinkMng.buLinkToDelete = [];
                    this.originalCheckboxMap = {};
                    this.getBUListData();
                }).catch(error => {
                    this.disableSave = false;
                    this.loading = false;
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                    console.log(error);
                });
            }

        } catch (error) {
            this.disableSave = false;
            this.loading = false;
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            console.log(error);
        }
        this.loading = false;
    }

    /********************* SECTION BU INFO *********************/
    buildBUInfoFields() {
        this.displayedBUFields = [];
        for (let fieldName of this.buFields) {
            if (!this.buFieldAPIs[fieldName] && fieldName.includes('.')) {
                let fieldWrapper = {
                    fieldName: fieldName,
                    fieldLabel: fieldLabel,
                    isInputField: false,
                    fieldValue: this.bu[fieldName],
                    isNameField: fieldName == 'Name',
                }
                let values = fieldWrapper.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let item = index == 0 ? this.bu : fieldWrapper.fieldValue;
                    fieldWrapper.fieldValue = item[values[index]];
                }
                this.displayedBUFields.push(fieldWrapper);
            } else {
                let field = this.buFieldAPIs[fieldName];
                let fieldWrapper = {
                    fieldName: field.apiName,
                    fieldLabel: field.label,
                    isInputField: field.updateable,
                    fieldType: field.dataType,
                    isNameField: fieldName == 'Name',
                    isNumberField: field.dataType == 'Currency' || field.dataType == 'Percent' || field.dataType == 'Number',
                    isReference: field.dataType == 'Reference',
                    isDate: field.dataType == 'Date',
                    isDateTime: field.dataType == 'DateTime',
                    isPicklist: field.dataType == 'Picklist',
                    isBoolean: field.dataType == 'Boolean',
                    isTextarea: field.dataType == 'TextArea',
                    isText: field.dataType != 'TextArea' && field.dataType != 'Currency' && field.dataType != 'Percent' && field.dataType != 'Number' && field.dataType != 'Reference' && field.dataType != 'Date' && field.dataType != 'DateTime' && field.dataType != 'Picklist' && field.dataType != 'Boolean',
                    isHTMLFormatted: field.isHTMLFormatted,
                    style: field.style,
                    fieldValue: this.bu[field.apiName],
                    picklistOptions: [],
                    scale: field.scale,
                    step: field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                    linkStyle: '',
                }
                if (fieldWrapper.isPicklist) {
                    fieldWrapper.picklistOptions.unshift({
                        label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                    })
                }
                this.displayedBUFields.push(fieldWrapper);
            }
        }
    }

    handleFieldEdits(event) {
        let fieldName = event.target.dataset.field;
        let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        this.bu[fieldName] = (Array.isArray(value) ? value[0] : value);
    }

    openDropDownFilter(event) {
        let fieldName = event.target.dataset.field;
        let tabname = event.target.dataset.tabname;
        let dropDpwnElt = this.template.querySelector('[data-' + (tabname ? tabname + '-' : '') + 'filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
    }

    /***************** Section BU List *****************/
    getBUListData() {
        console.log('getBUListData')
        this.buLinkMng.loading = true;
        this.buLinkMng.data = [];
        this.originalCheckboxMap = {};
        let filteredFields = this.buLinkMng.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
        let buAttributesLogicFilter = this.buAttributesLogicFilter.replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND').replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
        let buAttribute = {
            logicFilter: buAttributesLogicFilter,
            buAttributes: this.buAttributes,
        }
        getBUList({
            buJSON: JSON.stringify(this.bu),
            pageNumber: this.buLinkMng.pageNumber,
            pageSize: this.buLinkMng.pageSize,
            filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
            filterAttrJSON: JSON.stringify(buAttribute),
        }).then(result => {
            this.buLinkMng.data = [];
            this.mainWrapper.data = JSON.parse(result);
            for (let item of this.mainWrapper.data.buList) {
                let itemRow = this.buildBUWrapper(item);
                let isSelected = this.buLinkMng.buLinkToDelete.includes(item.bu.Id) ? false : this.buLinkMng.buLinkToAdd.includes(item.bu.Id) ? true : item.selected;
                this.originalCheckboxMap[item.bu.Id] = item.selected;
                let backgroundColor = this.buLinkMng?.buLinkToDelete.includes(item.bu.Id) ? this.buLinkMng?.buLinkToAdd.includes(item.bu.Id) ? '' : 'background-color:#f3d4cf' : this.buLinkMng?.buLinkToAdd.includes(item.bu.Id) ? 'background-color:#daf2d0' : '';
                this.buLinkMng.data.push({ Id: item.bu.Id, selected: isSelected, values: itemRow, isUnFiltered: item.isUnFiltered, backgroundColor: this.originalCheckboxMap.hasOwnProperty(item.bu.Id) ? this.originalCheckboxMap[item.bu.Id] == isSelected ? '' : backgroundColor : '' });
            }
            if (this.selectedBUIds.length > 0) {
                this.buLinkMng.data.forEach(item => {
                    if (this.selectedBUIds.includes(item.Id)) {
                        item.selected = true;
                    }
                });
            }
            this.buLinkMng.totalNumbOfRecords = this.mainWrapper.data.totalNumbOfRecords;
            this.buLinkMng.loading = false;
        }).catch(error => {
            console.log('ERROR: ' + error.message);
            console.log('ERROR: ' + error.body?.message);
            this.buLinkMng.loading = false;
        });
    }

    buildBUWrapper(item) {
        let itemRow = [];
        for (let field of this.buLinkMng.displayedFields) {
            let fieldWrapper = {
                Id: item.bu.Id,
                key: item.bu.Id + '' + field.fieldName,
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
                isHTMLFormatted: field.isHTMLFormatted,
                isText: field.isText,
                link: "/" + item.bu.Id,
                scale: field.scale,
                step: field.step,
                isInputField: field.isInputField,
                pickListValues: [],
                style: field.style ? field.style : '',
            }
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let val = index == 0 ? item.bu : fieldWrapper.fieldValue;
                if (val) {
                    if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                        fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                        fieldWrapper.link = '/' + val[values[index]];
                    } else {
                        fieldWrapper.fieldValue = val[values[index]];
                    }
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
            itemRow.push(fieldWrapper);
        }
        return itemRow;
    }

    handleEnterKeyPress(event) {
        // Check if the Enter key was pressed
        if (event.keyCode === 13) {
            this.isBUSearched = true;
            this.handleSearchBU(event);
        }
    }
    handleBUChange() {
        this.isBUSearched = false;
    }

    handleSearchBUBlur(event) {
        // Check if the Enter key was pressed
        if (!this.isBUSearched) {
            this.handleSearchBU(event);
        }
    }
    handleSearchBU(event) {
        this.buLinkMng.loading = true;
        const searchTerm = event.target.value;
        this.buLinkMng.data = [];
        this.buLinkMng.displayedFields.forEach(field => {
            if (field.isFilterable) {
                field.filterValue = searchTerm;
            }
        });
        this.getBUListData();
    }
    // PAGINATION METHODS
    changePageSizeHandler(event) {
        let tabname = event.currentTarget.dataset.foottab;
        this.buLinkMng.pageSize = event.target.value;
        this.buLinkMng.pageNumber = 1;
        this.getBUListData();
    }
    handleFirst(event) {
        this.buLinkMng.pageNumber = 1;
        this.getBUListData();
    }
    handlePrevious(event) {
        this.buLinkMng.pageNumber--;
        this.getBUListData();
    }
    handleNext(event) {
        this.buLinkMng.pageNumber++;
        this.getBUListData();
    }
    handleLast(event) {
        let tabname = event.currentTarget.dataset.foottab;
        let pageSize = parseInt(this.buLinkMng.pageSize);
        this.buLinkMng.pageNumber = Math.ceil(this.buLinkMng.totalNumbOfRecords / pageSize);
        this.getBUListData();
    }
    get colspanLength() {
        return this.buLinkMng.displayedFields.length + 1;
    }
    get isAllBUSelected() {
        return this.buLinkMng.data.length > 0 && this.buLinkMng.data.every(item => item.selected);
    }

    handleSelectAllBU(event) {
        let checked = event.target.checked;
        this.mainWrapper.data.allBUIdList.forEach(buId => {
            if (checked) {
                if (!this.buLinkMng.buLinkToAdd.includes(buId)) {
                    this.buLinkMng.buLinkToAdd.push(buId);
                }
                if (this.buLinkMng.buLinkToDelete.includes(buId)) {
                    this.buLinkMng.buLinkToDelete.splice(this.buLinkMng.buLinkToDelete.indexOf(buId), 1);
                }
                if (!this.selectedBUIds.includes(buId)) {
                    this.selectedBUIds.push(buId);
                }
            } else {
                if (this.buLinkMng.buLinkToAdd.includes(buId)) {
                    this.buLinkMng.buLinkToAdd.splice(this.buLinkMng.buLinkToAdd.indexOf(buId), 1);
                }
                if (!this.buLinkMng.buLinkToDelete.includes(buId)) {
                    this.buLinkMng.buLinkToDelete.push(buId);
                }
                if (this.selectedBUIds.includes(buId)) {
                    this.selectedBUIds.splice(this.selectedBUIds.indexOf(buId), 1);
                }
            }
        });
        this.buLinkMng.data.forEach(item => {
            item.selected = checked;
            if (checked) {
                item.backgroundColor = this.originalCheckboxMap[item.Id] ? '' : 'background-color:#daf2d0';
            } else {
                item.backgroundColor = this.originalCheckboxMap[item.Id] ? 'background-color:#f3d4cf' : '';
            }
        });
        this.buLinkMng.data = [...this.buLinkMng.data];
    }

    handleSelectBU(event) {
        //this.selectedBUIds = [];
        let checked = event.target.checked;
        let buid = event.target.dataset.buid;
        if (checked) {
            if (!this.buLinkMng.buLinkToAdd.includes(buid)) {
                this.buLinkMng.buLinkToAdd.push(buid);
            }
            if (this.buLinkMng.buLinkToDelete.includes(buid)) {
                const deleteIndex = this.buLinkMng.buLinkToDelete.indexOf(buid);
                this.buLinkMng.buLinkToDelete.splice(deleteIndex, 1);
            }
        } else {
            if (this.buLinkMng.buLinkToAdd.includes(buid)) {
                const addIndex = this.buLinkMng.buLinkToAdd.indexOf(buid);
                this.buLinkMng.buLinkToAdd.splice(addIndex, 1);
            }
            if (!this.buLinkMng.buLinkToDelete.includes(buid)) {
                this.buLinkMng.buLinkToDelete.push(buid);
            }
        }
        if (checked) {
            if (!this.selectedBUIds.includes(buid)) {
                this.selectedBUIds.push(buid);
            }
        } else {
            if (this.selectedBUIds.includes(buid)) {
                const addIndex = this.selectedBUIds.indexOf(buid);
                this.selectedBUIds.splice(addIndex, 1);
            }
        }
        this.buLinkMng.data.forEach(element => {
            if (element.Id == buid) {
                element.selected = checked;
                if (checked) {
                    if (this.originalCheckboxMap[buid]) {
                        element.backgroundColor = '';
                    } else {
                        element.backgroundColor = 'background-color:#daf2d0';
                    }
                } else {
                    if (this.originalCheckboxMap[buid]) {
                        element.backgroundColor = 'background-color:#f3d4cf';
                    } else {
                        element.backgroundColor = '';
                    }
                }
            }
        })
    }
    selectOnlyRespectBUs() {
        this.buLinkMng.loading = true;
        let filteredFields = this.buLinkMng.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
        let buAttributesLogicFilter = this.buAttributesLogicFilter.replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND').replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
        let buAttribute = {
            logicFilter: buAttributesLogicFilter,
            buAttributes: this.buAttributes,
        }
        selectOnlyRespectBUs({
            buJSON: JSON.stringify(this.bu),
            filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
            filterAttrJSON: JSON.stringify(buAttribute),
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.buLinkMng.buLinkToAdd = parsedResult.busToAdd;
            this.buLinkMng.buLinkToDelete = parsedResult.busToDelete;
            for (let element of this.buLinkMng.data) {
                element.selected = this.buLinkMng.buLinkToAdd.includes(element.Id);
                if (this.buLinkMng.buLinkToAdd.includes(element.Id)) {
                    if (this.originalCheckboxMap[element.Id]) {
                        element.backgroundColor = '';
                    } else {
                        element.backgroundColor = 'background-color:#daf2d0';
                    }
                } else {
                    console.log('NOT CHECKED::: ' + element.Id);
                    if (this.originalCheckboxMap[element.Id]) {
                        element.backgroundColor = 'background-color:#f3d4cf';
                    } else {
                        element.backgroundColor = '';
                    }
                }
            }
            this.buLinkMng.loading = false;
        }).catch(error => {
            console.log(error);
        })
    }
    //Used to read filter value
    handleChangeBUFilter(event) {
        let fieldName = event.target.dataset.field;
        let field = this.buLinkMng.displayedFields.filter(element => element.fieldName == fieldName);
        if (field.length > 0) {
            field[0].filterValue = event.detail.value;
        }
    }
    //handle filter search
    handleApplyBUFilters(event) {
        console.log('handleApplyBUFilters')
        this.buLinkMng.loading = true;
        let fieldName = event.target.dataset.field;
        let tabname = event.target.dataset.tabname;
        this.buLinkMng.data = [];
        let dropDpwnElt = this.template.querySelector('[data-' + (tabname ? tabname + '-' : '') + 'filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        this.getBUListData();
    }
    /**************** Section buAttribute  ****************/
    get typesOptions() {
        return [{ label: LBL_PA_Field, value: 'Field' },
        { label: LBL_PA_Value, value: 'Value' },
        ];
    }

    createEmptyBUAttribute(index) {
        return {
            fieldName: '',
            fieldLabel: '',
            fieldType: '',
            operationType: 'Field',
            isField: true,
            operation: '',
            fieldValue: '',
            disableValue: false,
            picklistValues: [],
            operationsOptions: [],
            isPicklist: false,
            isMultiPicklist: false,
            isReference: false,
            class: `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click buFieldsCombobox${index}`,
        };
    }
    handleAddBUAttribute() {
        this.buAttributes.push(this.createEmptyBUAttribute(this.buAttributes.length));
        this.buAttributes.forEach((item, i) => item.index = i + 1);
    }

    removeBUAttribute(event) {
        let index = event.target.dataset.index;
        this.buAttributes.splice(index, 1);
        let prodAttributeIndex = 1;
        this.buAttributes.forEach(item => {
            item.index = prodAttributeIndex;
            prodAttributeIndex++;
        })
    }
    handleChangeBUAttribute(event) {
        try {
            let index = event.target.dataset.index;
            let field = event.target.dataset.field;
            let value = event.detail.checked != null ? event.detail.checked : event.detail.value;
            if (Array.isArray(value) && field === 'lookup') {
                value = value.length > 0 ? value[0] : null;
            }
            let buAttribute = this.buAttributes[index];
            console.log(JSON.stringify(buAttribute));
            if (field !== 'lookup') {
                buAttribute[field] = value;
            }
            if (buAttribute.fieldName) {
                if (!buAttribute.fieldName.includes('.')) {
                    let fieldName = this.buAttributeFields.filter(item => item.value == buAttribute.fieldName);
                    if (fieldName && fieldName.length > 0) {
                        buAttribute.buFieldsType = this.buAttributeFields.filter(item => item.fieldType == fieldName[0].fieldType);
                        buAttribute.fieldLabel = fieldName[0].label;
                    }
                } else {
                    const fieldType = buAttribute.fieldType;
                    if (fieldType) {
                        buAttribute.buFieldsType = this.buAttributeFields.filter(item => item.fieldType == fieldType);
                    }
                }
            }
            if (field === 'operation') {
                buAttribute.disableValue = false;
                if (['ISNULL', 'ISBLANK', 'ISNOTNULL', 'ISNOTBLANK'].includes(value)) {
                    buAttribute.disableValue = true;
                    buAttribute.fieldValue = '';
                }
            }
            if (field === 'operationType') {
                buAttribute.isField = value === 'Field';
            }
            if (field === 'lookup') {
                buAttribute.fieldValue = value;
            }
            this.buAttributes = [...this.buAttributes];
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    }

    handleBUFieldSelect(event) {
        const index = event.target.dataset.index;
        const selectedField = event.detail;
        if (!selectedField.fieldName) {
            this.buAttributes = this.buAttributes.map((attr, i) => i == index ? { ...this.createEmptyBUAttribute(i), index: attr.index } : attr);
            return;
        }
        let buAttribute = { ...this.buAttributes[index], ...selectedField };
        buAttribute.operation = '';
        buAttribute.fieldValue = '';
        buAttribute.disableValue = false;
        buAttribute.operationsOptions = this.getOperationsBySubFieldType(selectedField.fieldType);
        buAttribute.buFieldsType = this.buAttributeFields.filter(f => f.fieldType === selectedField.type);
        this.buAttributes[index] = buAttribute;
        this.buAttributes = [...this.buAttributes];
    }

    getSubFieldInputType(dataType) {
        if (!dataType) return 'text';
        const t = dataType.toLowerCase();
        if (t === 'double' || t === 'integer' || t === 'currency' || t === 'percent' || t === 'long') return 'number';
        if (t === 'date') return 'date';
        if (t === 'datetime') return 'datetime';
        if (t === 'boolean') return 'checkbox';
        return 'text';
    }

    getOperationsBySubFieldType(dataType) {
        if (!dataType) return this.getDefaultStringOperations();
        const t = dataType.toUpperCase();
        return OPERATORS_BY_TYPE[t];
    }

    getDefaultStringOperations() {
        return [
            { label: LBL_PA_ISNULL, value: 'ISNULL' },
            { label: LBL_PA_IS_NOT_NULL, value: 'ISNOTNULL' },
            { label: LBL_PA_EQUALS, value: 'EQUALS' },
            { label: LBL_PA_NOT_EQUALS, value: 'NOTEQUALS' },
            { label: LBL_PA_CONTAINS, value: 'CONTAINS' },
            { label: LBL_PA_DOESNT_CONTAIN, value: 'NOTCONTAINS' },
        ];
    }

    handleChangeMultiPicklistValues(event) {
        try {
            try {
                let values = [];
                event.detail.selOptions.forEach(item => {
                    values.push(item.value);
                });
                let index = event.target.dataset.index;
                let buAttribute = this.buAttributes[index];
                buAttribute.fieldValue = JSON.stringify(values);
                let test = JSON.parse(JSON.stringify(values));

                test.forEach(item => { console.log(' >>>> ' + item) });
                console.log(buAttribute.fieldValue)
                console.log(test)
                this.buAttributes = [...this.buAttributes];
            } catch (e) {
                console.log('ERROR: ' + e);
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }
    /**************** End Of Section  ****************/
    handleTabClick(event) {
        this.changeHeight();
    }

    handleCancel(event) {
        let redirectId = this.recordId;
        if (redirectId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: redirectId,
                    actionName: 'view'
                },
                state: {
                    //nooverride: '1'
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: BusinessUnit_OBJECT.objectApiName,
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                }
            })
            //history.back();
            /*var url = window.location.href;
            var value = url.substr(0, url.lastIndexOf('/') + 1);
            window.history.back();
            return false;*/
        }
    }
    changeHeight = () => {
        let headerHeight = 0;
        let tabBodyHeight = 0;
        let cardBodyHeight = 0;
        if (this.template.querySelector('.header')) {
            headerHeight = this.template.querySelector('.header').getBoundingClientRect().height;
        }
        let activePanel = this.template.querySelector('.slds-show .main-panel');
        if (activePanel) {
            tabBodyHeight = activePanel.getBoundingClientRect().top;
        }
        let mainPanelHeight = window.innerHeight - tabBodyHeight - 13;
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px; overflow-y: auto;';
        let divTables = this.template.querySelectorAll('.divTable');
        if (divTables) {
            divTables.forEach(divTable => {
                divTable.style.height = window.innerHeight - divTable.getBoundingClientRect().top - (this.template.querySelector('.pagination') ? this.template.querySelector('.pagination').getBoundingClientRect().height : 0) - 20 + 'px';
                //divTable.style.width = divTable.parentElement.getBoundingClientRect().width - 20 + 'px';
                });
        }
        this.noDataHeight = 'height:' + (mainPanelHeight - 150) + 'px;';
        this.noDataImageStyle = 'height:' + mainPanelHeight / 2 + 'px;width:' + window.innerHeight / 3 + 'px;';
        // let buLinksTableContent = this.template.querySelectorAll('.buLinksTableContent');
        // let strictHeader = this.template.querySelector('.strictbuLinkSectionHeader');
        // let linkHeader = this.template.querySelector('.buLinkSectionHeader');
        // if (buLinksTableContent && header && strictHeader) {
        //     buLinksTableContent.forEach(table => {
        //         table.style.height =
        //             (mainPanelHeight
        //                 - headerHeight
        //                 - (strictHeader ? strictHeader.getBoundingClientRect().height : 0)
        //                 - (linkHeader ? linkHeader.getBoundingClientRect().height : 0)
        //                 + 40) + 'px';
        //     });
        // }
    };

    showNotification(title, message, variant, dissmissable) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: (dissmissable ? 'pester' : (ERROR_VARIANT == variant ? 'sticky' : 'pester'))
        });
        self.dispatchEvent(evt);
    }

    resolveFieldType(fieldName) {
        if (!fieldName) return null;
        if (!fieldName.includes('.')) {
            const match = this.buAttributeFields.find(p => p.value === fieldName);
            return match ? match.fieldType : '';
        }
        const splittedFields = fieldName.split('.');
        const relationshipField = splittedFields[0];
        const refField = this.buAttributeFields.find(p => p.relationshipName === relationshipField);
        if (!refField?.referenceObjectApiName) return null;
        const refObjectName = refField.referenceObjectApiName;
        return null;
    }
}