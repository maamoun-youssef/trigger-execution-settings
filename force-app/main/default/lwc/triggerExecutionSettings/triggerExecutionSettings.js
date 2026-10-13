import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import formulonLibUrl from '@salesforce/resourceUrl/formulonLib';
import { loadScript } from 'lightning/platformResourceLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// Controller Actions
import getObjectNames from '@salesforce/apex/TriggerExecutionSettingsController.getObjectNames';
import initData from '@salesforce/apex/TriggerExecutionSettingsController.initData';
import loadData from '@salesforce/apex/TriggerExecutionSettingsController.loadData';
import save from '@salesforce/apex/TriggerExecutionSettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/TriggerExecutionSettingsController.checkDeploymentStatus';
//Custom Label
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import MSG_Information from "@salesforce/label/c.MSG_Information";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import LBL_TriggerExecutionSettings_InsertField from "@salesforce/label/c.LBL_TriggerExecutionSettings_InsertField"; //LBL_TriggerExecutionSettings_Insert_Field
import LBL_TriggerExecutionSettings_EventType from "@salesforce/label/c.LBL_TriggerExecutionSettings_EventType";
import LBL_TriggerExecutionSettings_FieldName from "@salesforce/label/c.LBL_TriggerExecutionSettings_FieldName";
import LBL_TriggerExecutionSettings_Equation from "@salesforce/label/c.LBL_TriggerExecutionSettings_Equation";
import LBL_EDIT from "@salesforce/label/c.LBL_Edit";
import LBL_DELETE from "@salesforce/label/c.LBL_Delete";
import LBL_TriggerExecutionSettings_AddOperator from "@salesforce/label/c.LBL_TriggerExecutionSettings_AddOperator";
import LBL_TriggerExecutionSettings_CheckSyntax from "@salesforce/label/c.LBL_TriggerExecutionSettings_CheckSyntax";
import LBL_TriggerExecutionSettings_ClassName from "@salesforce/label/c.LBL_TriggerExecutionSettings_ClassName";
import LBL_TriggerExecutionSettings_IsActive from "@salesforce/label/c.LBL_TriggerExecutionSettings_IsActive";
import LBL_TriggerExecutionSettings_Methods from "@salesforce/label/c.LBL_TriggerExecutionSettings_Methods";
import LBL_TriggerExecutionSettings_Formulas from "@salesforce/label/c.LBL_TriggerExecutionSettings_Formulas";
import LBL_TriggerExecutionSettings_NewFormula from "@salesforce/label/c.LBL_TriggerExecutionSettings_NewFormula";
import LBL_TriggerExecutionSettings_EditFormula from "@salesforce/label/c.LBL_TriggerExecutionSettings_EditFormula";
import LBL_TriggerExecutionSettings_EmptyFormula from "@salesforce/label/c.LBL_TriggerExecutionSettings_EmptyFormula";
import LBL_TriggerExecutionSettings_InvalidField from "@salesforce/label/c.LBL_TriggerExecutionSettings_InvalidField";
import LBL_TriggerExecutionSettings_NumericResult from "@salesforce/label/c.LBL_TriggerExecutionSettings_NumericResult";
import LBL_TriggerExecutionSettings_ExternalIdGeneration from "@salesforce/label/c.LBL_TriggerExecutionSettings_ExternalIdGeneration";
import LBL_TriggerExecutionSettings_ExternalIdField from "@salesforce/label/c.LBL_TriggerExecutionSettings_ExternalIdField";
import LBL_TriggerExecutionSettings_Separator from "@salesforce/label/c.LBL_TriggerExecutionSettings_Separator";
import LBL_TriggerExecutionSettings_Fields from "@salesforce/label/c.LBL_TriggerExecutionSettings_Fields";
import LBL_Add_Fields from "@salesforce/label/c.LBL_Add_Fields";
import LBL_TriggerExecutionSettings_NewExternalId from "@salesforce/label/c.LBL_TriggerExecutionSettings_NewExternalId";
import LBL_TriggerExecutionSettings_EditExternalId from "@salesforce/label/c.LBL_TriggerExecutionSettings_EditExternalId";
import LBL_TriggerExecutionSettings_AddNewSettings from "@salesforce/label/c.LBL_TriggerExecutionSettings_AddNewSettings";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_TriggerExecutionSettings from "@salesforce/label/c.LBL_TriggerExecutionSettings";
import LBL_TriggerExecutionSettings_MethodsSubTitle from "@salesforce/label/c.LBL_TriggerExecutionSettings_MethodsSubTitle";
import LBL_TriggerExecutionSettings_FormulasSubTitle from "@salesforce/label/c.LBL_TriggerExecutionSettings_FormulasSubTitle";
import LBL_TriggerExecutionSettings_ExternalIdGenerationSubTitle from "@salesforce/label/c.LBL_TriggerExecutionSettings_ExternalIdGenerationSubTitle";
import LBL_TriggerExecutionSettings_NewMethod from "@salesforce/label/c.LBL_TriggerExecutionSettings_NewMethod";
import LBL_Active from "@salesforce/label/c.LBL_Active";
import LBL_Activate from "@salesforce/label/c.LBL_Activate";
import LBL_Deactivate from "@salesforce/label/c.LBL_Deactivate";
import LBL_Deactivated from "@salesforce/label/c.LBL_Deactivated";

const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';

export default class TriggerExecutionSettings extends LightningElement {
    @track labels = {
        LBL_No_Item_To_Display,
        LBL_Add,
        LBL_Confirm,
        LBL_Save,
        MSG_Information,
        MSG_Deploy_Ended_With_Status,
        MSG_Save_Complete,
        MSG_Deploy_Last_Status,
        LBL_TriggerExecutionSettings_InsertField,
        LBL_TriggerExecutionSettings_EventType,
        LBL_TriggerExecutionSettings_FieldName,
        LBL_TriggerExecutionSettings_Equation,
        LBL_EDIT,
        LBL_DELETE,
        LBL_Cancel,
        LBL_TriggerExecutionSettings_AddOperator,
        LBL_TriggerExecutionSettings_CheckSyntax,
        LBL_TriggerExecutionSettings_ClassName,
        LBL_TriggerExecutionSettings_Methods,
        LBL_TriggerExecutionSettings_Formulas,
        LBL_TriggerExecutionSettings_NewFormula,
        LBL_TriggerExecutionSettings_EditFormula,
        LBL_TriggerExecutionSettings_EmptyFormula,
        LBL_TriggerExecutionSettings_InvalidField,
        LBL_TriggerExecutionSettings_NumericResult,
        LBL_TriggerExecutionSettings_ExternalIdGeneration,
        LBL_TriggerExecutionSettings_ExternalIdField,
        LBL_TriggerExecutionSettings_Separator,
        LBL_TriggerExecutionSettings_Fields,
        LBL_Add_Fields,
        LBL_TriggerExecutionSettings_NewExternalId,
        LBL_TriggerExecutionSettings_EditExternalId,
        LBL_TriggerExecutionSettings_IsActive,
        LBL_TriggerExecutionSettings_AddNewSettings,
        LBL_TriggerExecutionSettings,
        LBL_TriggerExecutionSettings_MethodsSubTitle,
        LBL_TriggerExecutionSettings_FormulasSubTitle,
        LBL_TriggerExecutionSettings_ExternalIdGenerationSubTitle,
        LBL_TriggerExecutionSettings_NewMethod,
        LBL_Previous,
        LBL_Active,
        LBL_Activate,
        LBL_Deactivate,
        LBL_Deactivated
    }
    @track loadingData = false;
    @track objectList = [];
    @track sections = [];
    @track results = {};
    @track records = [];
    @track handlers = [];
    @track formulaEventTypes = [
        { value: 'BEFORE_INSERT', label: 'BEFORE_INSERT' },
        { value: 'BEFORE_UPDATE', label: 'BEFORE_UPDATE' },
        { value: 'BEFORE_UPDATE_INSERT', label: 'BEFORE_UPDATE_INSERT' }
    ];
    seperatorOptions = [{ label: ',', value: ',' }, { label: '-', value: '-' }, { label: '|', value: '|' }, { label: '_', value: '_' }]
    @track methods = [];
    @track displayedObjectList = [];
    @track searchTermObject = '';
    @track selectedObject;
    @track addNewRow = false;
    @track row = {};
    @track addNewFormula = false;
    @track selectedObjectData;
    @track addNewExternalId = false;
    @track expandedSection = null;
    @track showTypeSelector = false;
    @track pendingEventType = null;
    data = {};
    @track draggedIndex = null;
    @track eventIndex = null;
    operatorOptions = [
        { label: '+ Add', value: '+' },
        { label: '- Subtract', value: '-' },
        { label: '* Multiply', value: '*' },
        { label: '/ Divide', value: '/' },
        { label: '^ Exponentiation', value: '^' },
        { label: '( Open Parenthesis', value: '(' },
        { label: ') Close Parenthesis', value: ')' },
        { label: '& Concatenate', value: '&' }
    ];
    @wire(getObjectInfo, { objectApiName: '$selectedObjectName' })
    objectInfo({ data, error }) {
        if (data) {
            const copiedData = JSON.parse(JSON.stringify(data));
            Object.values(copiedData.fields).forEach(field => {
                field.isNumber = field.dataType === 'Double' || field.dataType === 'Percent';
            });
            this.selectedObjectData = copiedData;
            console.log("~ TriggerExecutionSettings ~ objectInfo ~ this.selectedObjectData:", JSON.stringify(this.selectedObjectData))
        } else if (error) {
            console.error('Error loading user object info:', error);
        }
    }

    get fieldOptions() {
        return Object.values(this.selectedObjectData.fields)
            .filter(field => field.apiName != this.row.fieldName && field.dataType != 'Reference')
            .map(field => ({
                label: field.label,
                value: field.apiName,
                dataType: field.dataType
            }));
    }

    get fieldNameOptions() {
        const notAllowed = new Set(this.records
            .flatMap(event => event.formulas || [])
            .map(f => f.fieldName));
        return Object.values(this.selectedObjectData.fields)
            .filter(field => field.calculated == false && field.isNumber == true && (this.row.isEdit ? true : !notAllowed.has(field.apiName)))
            .map(field => ({
                label: field.label,
                value: field.apiName
            }));
    }

    get isPendingAfterEvent() {
        return this.pendingEventType?.startsWith('AFTER_') ?? false;
    }

    get isUpdateInsert() {
        return this.pendingEventType?.startsWith('BEFORE_UPDATE_INSERT') ?? false;
    }

    get selectedObjectName() {
        return this.selectedObject?.objectName || null;
    }

    get externalIdFieldOptions() {
        if (!this.selectedObjectData) return [];
        return Object.values(this.selectedObjectData.fields)
            .filter(field => !!field.externalId)
            .map(field => ({ label: field.label, value: field.apiName }));
    }

    get formatFieldOptions() {
        if (!this.selectedObjectData) return [];
        const selected = new Set(this.row.fields || []);
        return Object.values(this.selectedObjectData.fields)
            .filter(field => field.apiName !== this.row.externalIdField
                && !selected.has(field.apiName))
            .map(field => ({ label: `${field.label} (${field.apiName})`, value: field.apiName }));
    }

    get selectedFormatFields() {
        if (!this.selectedObjectData || !this.row.fields) return [];
        return (this.row.fields || []).map((apiName, index) => ({
            index,
            apiName,
            label: (this.selectedObjectData.fields[apiName] && this.selectedObjectData.fields[apiName].label) || apiName
        }));
    }

    get isExternalIdFieldSelected() {
        return !this.row.externalIdField;
    }

    get showPrevious() {
        return !this.row.isEdit;
    }

    get isFieldNotSelected() {
        return this.row.fieldName == null;
    }

    get activeStatus() {
        const isActive = this.selectedObject?.isActive;
        return {
            buttonLabel: isActive ? this.labels.LBL_Deactivate : this.labels.LBL_Activate,
            buttonVariant: isActive ? 'destructive-text' : 'brand',
            badgeLabel: isActive ? this.labels.LBL_Active : this.labels.LBL_Deactivated,
            badgeClass: 'slds-m-right_xx-small ' + (isActive ? 'slds-theme_success' : 'slds-theme_warning'),
        };
    }

    connectedCallback() {
        this.getObjectNames();
        window.addEventListener('resize', this.changeHeight);
        loadScript(this, formulonLibUrl + '/decimal.js').then(() =>
            loadScript(this, formulonLibUrl + '/formulon.min.js')).then(() => {
            }).catch((error) => {
                console.error('Failed to load Formulon', error);
                this.showNotification('Error', error, 'error', 'dismissable');
            }).catch((error) => {
                console.error('Failed to load Formulon', error);
                this.showNotification('Error', error, 'error', 'dismissable');
            });;

    }

    renderedCallback() {
        if (this.template.querySelector('.main-header') && this.template.querySelector('.main-div')) {
            this.changeHeight();
        }
        for (var elem of this.template.querySelectorAll('.menuItem')) {
            if (!this.selectedObject || elem.dataset.id != this.selectedObject.objectName) {
                elem.setAttribute('aria-current', false);
            } else {
                elem.setAttribute('aria-current', 'page');
            }
        }
    }

    getObjectNames() {
        this.loadingData = true;
        getObjectNames().then((result) => {
            this.objectList = JSON.parse(result);
            this.displayedObjectList = [...this.objectList];
            this.sortObjects();
            this.loadingData = false;
        }).catch(error => {
            console.log('getObjectNames >> ' + error.message);
            console.error(error);
        });
    }

    sortObjects() {
        this.displayedObjectList.sort((a, b) => {
            if (a.objectLabel === undefined) return -1;
            if (b.objectLabel === undefined) return 1;
            let aValue = a.objectLabel.toLowerCase();
            let bValue = b.objectLabel.toLowerCase();
            return ((aValue > bValue) ? 1 : ((bValue > aValue) ? -1 : 0)); // Sort ascending
        });
    }

    searchObject(event) {
        this.searchTermObject = (event.target.value ?? "").trim().toLowerCase();
        if (this.searchTermObject) {
            this.displayedObjectList = this.objectList.filter(item => {
                const name = (item.objectName ?? "").toLowerCase();
                const label = (item.objectLabel ?? "").toLowerCase();
                return name.includes(this.searchTermObject) || label.includes(this.searchTermObject);
            });
        } else {
            this.displayedObjectList = [...this.objectList];
        }
        this.sortObjects();
    }

    ObjectChangeHandler(event) {
        let index = event.currentTarget.dataset.index;
        this.selectedObject = this.displayedObjectList[index];
        this.initData();
    }

    initData() {
        this.loadingData = true;
        this.handlers = [];
        this.methods = [];
        this.data = {};
        this.records = [];
        initData({ objectName: this.selectedObject.objectName }).then((result) => {
            this.results = JSON.parse(result);
            Object.keys(this.results).forEach(className => {
                this.results[className].sort((a, b) => {
                    return ((a > b) ? 1 : ((b > a) ? -1 : 0)); // Sort ascending
                });
            })
            console.log('this.results >>>> ' + JSON.stringify(this.results))
            Object.keys(this.results).forEach(option => {
                this.handlers.push({ value: option, label: option });
            })
            if (this.handlers.length > 0) {
                this.row.classHandlerName = this.handlers[0].value;
            }
            if (this.row.classHandlerName && this.results[this.row.classHandlerName]) {
                let alreadySelectedMethods = this.records.filter(handlerClass => handlerClass.classHandlerName == this.row.classHandlerName)[0]?.events?.filter(event => event.eventName == this.row.eventType)[0]?.methods?.map(method => method.methodName);
                this.results[this.row.classHandlerName].filter(method => !alreadySelectedMethods || !alreadySelectedMethods.includes(method)).forEach(method => {
                    this.methods.push({ value: method, label: method });
                })
            } else {
                this.methods = [];
            }
            this.loadData();
        }).catch(error => {
            this.loadingData = false;
            console.log('initData >> ' + error.message);
            console.error(error);
        });
    }

    loadData() {
        this.loadingData = true;
        this.records = [];
        this.data = {};
        loadData({ objectName: this.selectedObject.objectName }).then((result) => {
            let parsedResult = JSON.parse(result);
            if (parsedResult) {
                for (let item of (parsedResult.methodsExecutionSettingsList || [])) {
                    this.buildData(item, 'Method');
                }
                for (let item of (parsedResult.calculatedFieldSettings || [])) {
                    this.buildData(item, 'Formula');
                }
                for (let item of (parsedResult.externalIdSettings || [])) {
                    this.buildData(item, 'ExtId');
                }
                this.records = Object.values(this.data);
                console.log('this.records :', JSON.stringify(this.records));
            }
            this.selectedObject.isActive = parsedResult?.isActive ?? true;
            this.buildEventSections();
            this.loadingData = false;
        }).catch(error => {
            this.loadingData = false;
            console.log('loadData >> ' + error.message);
            console.error(error);
        });
    }

    buildData(item, property) {
        let event;
        if (!this.data.hasOwnProperty(item.eventType)) {
            event = {
                eventName: item.eventType,
                methods: [],
                formulas: [],
                extIds: [],
            }
            this.data[item.eventType] = event;
        } else {
            event = this.data[item.eventType];
        }
        if (property == 'Method') {
            event.methods.push({ methodName: item.methodName, classHandlerName: item.classHandlerName, isActive: item.isActive ?? true })
        } else if (property == 'Formula') {
            event.formulas.push({ fieldName: item.fieldName, formula: item.formula });
        } else if (property == 'ExtId') {
            event.extIds.push({ externalIdField: item.externalIdField, separator: item.separator, fields: item.fields || [] });
        }
        return event
    }

    buildEventSections() {
        this.sections = [];
        const allTypes = ['BEFORE_INSERT', 'BEFORE_UPDATE', 'BEFORE_DELETE', 'BEFORE_UPDATE_INSERT', 'AFTER_INSERT', 'AFTER_UPDATE', 'AFTER_DELETE', 'AFTER_UNDELETE'];
        this.sections = allTypes.map((eventType, i) => {
            const eventIndex = this.records.findIndex(r => r.eventName === eventType);
            const methods = eventIndex >= 0
                ? this.records[eventIndex].methods.map((m, idx, arr) => ({
                    ...m, methodIdx: idx,
                    rowClass: `slds-grid slds-grid_vertical-align-center item-row slds-p-horizontal_small${idx === 0 ? '' : ' slds-p-top--small'}${idx < arr.length - 1 ? ' slds-border_bottom' : ''}`
                })) : [];
            const formulas = eventIndex >= 0
                ? (this.records[eventIndex].formulas || []).map((f, idx, arr) => ({
                    ...f, formulaIdx: idx,
                    rowClass: `slds-grid slds-grid_vertical-align-center item-row slds-p-horizontal_small slds-p-bottom--x-small${idx === 0 ? '' : ' slds-p-top--small'}${idx < arr.length - 1 ? ' slds-border_bottom' : ''}`
                })) : [];
            const externalIds = eventIndex >= 0
                ? (this.records[eventIndex].extIds || []).map((r, idx, arr) => ({
                    ...r, originalIndex: idx,
                    fields: r.fields.map((field, idx2, arr2) => ({
                        ...field,
                        showSeparator: idx2 < arr2.length - 1,
                        displayValue: `{!${field}}`
                    })),
                    rowClass: `slds-grid slds-grid_vertical-align-center item-row slds-p-horizontal_small slds-p-bottom--x-small${idx === 0 ? '' : ' slds-p-top--small'}${idx < arr.length - 1 ? ' slds-border_bottom' : ''}`
                })) : [];
            const isCollapsed = this.expandedSection !== eventType;
            return {
                eventType, eventIndex,
                methods, formulas, externalIds,
                isEmpty: (methods.length + formulas.length + externalIds.length) === 0,
                methodsCount: methods.length,
                formulasCount: formulas.length,
                externalIdsCount: externalIds.length,
                isCollapsed,
                chevronIcon: isCollapsed ? 'utility:chevronright' : 'utility:chevrondown',
                isLast: i === allTypes.length - 1
            };
        });
    }

    toggleNewSettingsPopup(event) {
        let eventType = event.target.dataset.eventType;
        this.pendingEventType = eventType;
        if (eventType.startsWith('AFTER_')) {
            this.addNewRow = true;
            this.initiateNewSettings(eventType, 'Method');
        } else {
            this.showTypeSelector = true;
        }
    }

    chooseSettingType(event) {
        const type = event.currentTarget.dataset.type;
        this.showTypeSelector = false;
        if (type === 'method') {
            this.initiateNewSettings(this.pendingEventType, 'Method')
            this.addNewRow = true;
        } else if (type === 'formula') {
            this.initiateNewSettings(this.pendingEventType, 'Formula')
            this.addNewFormula = true;
        } else if (type === 'externalId') {
            this.initiateNewSettings(this.pendingEventType, 'ExtId')
            this.addNewExternalId = true;
        }
    }

    initiateNewSettings(eventType, type) {
        this.row = {};
        if (type == 'Method') {
            this.row = {
                eventType: eventType,
                classHandlerName: '',
                methodName: '',
                isActive: true
            }
        } else if (type == 'Formula') {
            this.row = {
                eventType: eventType,
                fieldName: null,
                formula: '',
                isEdit: false
            }
        } else if (type == 'ExtId') {
            this.row = {
                eventType: eventType,
                externalIdField: '',
                separator: '',
                fields: [],
                isEdit: false
            }
        }
    }

    handleToggleActive() {
        this.selectedObject.isActive = !this.selectedObject.isActive;
        this.handleSave();
    }

    handleChange(event) {
        let field = event.target.dataset.field;
        let value = event.target.value;
        if (field == 'formulaHandler' && !this.row.isEdit) {
            this.row.fieldName = event.detail.value;
            return;
        }
        if (field == 'field') {
            if (value == null) return;
            console.log(value);
            this.row.formula += `${value} `;
            event.target.value = null;
            return;
        }
        if (field == 'equation') {
            this.row.formula = value;
            return;
        }
        if (field == 'formulaEventType') {
            this.row.eventType = value;
            return;
        }
        if (field == 'classHandlerName') {
            if (this.row[field] != value) {
                this.row.methodName = '';
            }
        }
        if (field == 'classHandlerName' || field == 'eventType') {
            this.methods = [];
        }
        this.row[field] = value;
        if (field == 'classHandlerName' || field == 'eventType') {
            if (this.row.classHandlerName && this.results[this.row.classHandlerName]) {
                let alreadySelectedMethods = this.records.filter(handlerClass => handlerClass.classHandlerName == this.row.classHandlerName)[0]?.events?.filter(event => event.eventName == this.row.eventType)[0]?.methods?.map(method => method.methodName);
                this.results[this.row.classHandlerName].filter(method => !alreadySelectedMethods || !alreadySelectedMethods.includes(method)).forEach(method => {
                    this.methods.push({ value: method, label: method });
                })
            } else {
                this.methods = [];
            }
        }
    }

    updateData(property) {
        this.buildData(this.row, property);
        this.records = Object.values(this.data);
        this.buildEventSections();
    }

    confirmAddNewSettings(event) {
        let type = event.target.dataset.type;
        if (type == 'Method') {
            if (Object.keys(this.row).every(key => this.row[key] != '')) {
                this.updateData('Method')
                this.methods = [];
            }
        } else if (type == 'Formula') {
            this.handleCheck().then(result => {
                if (!result) return;
                if (this.row.isEdit) {
                    if (this.records[this.row.eventIndex].eventName != this.row.eventType) {
                        this.records[this.row.eventIndex].formulas.splice(this.row.formulaIndex, 1);
                        this.updateData('Formula');
                        return;
                    }
                    this.records[this.row.eventIndex].formulas[this.row.formulaIndex] = this.row;
                    this.buildEventSections();
                } else {
                    this.updateData('Formula')
                }
            });
        } else if (type == 'ExtId') {
            if (this.row.isEdit) {
                if (this.records[this.row.eventIndex].eventName != this.row.eventType) {
                    this.records[this.row.eventIndex].extIds.splice(this.row.extIdIndex, 1);
                    this.updateData('ExtId');
                    this.togglePopup(event);
                    return;
                }
                this.records[this.row.eventIndex].extIds[this.row.extIdIndex] = this.row;
                this.buildEventSections();
            } else {
                this.updateData('ExtId');
            }
        }
        this.togglePopup(event);
    }

    togglePopup(event) {
        let type = event.target.dataset.type;
        if (type == 'Method') {
            this.addNewRow = !this.addNewRow
        } else if (type == 'Formula') {
            this.addNewFormula = !this.addNewFormula;
        } else if (type == 'ExtId') {
            this.addNewExternalId = !this.addNewExternalId;
        }
    }

    handleSave() {
        this.loadingData = true;
        let triggerSettings = {
            objectName: this.selectedObject.objectName,
            methodsExecutionSettingsList: [],
            calculatedFieldSettings: [],
            externalIdSettings: [],
            isActive: this.selectedObject.isActive ?? true,
        }
        for (let item of this.records) {
            for (let method of item.methods) {
                triggerSettings.methodsExecutionSettingsList.push({
                    eventType: item.eventName,
                    classHandlerName: method.classHandlerName,
                    methodName: method.methodName,
                    isActive: method.isActive ?? true
                })
            }
            for (let formula of item.formulas) {
                triggerSettings.calculatedFieldSettings.push({
                    eventType: item.eventName,
                    fieldName: formula.fieldName,
                    formula: formula.formula
                })
            }
            for (let extId of item.extIds) {
                triggerSettings.externalIdSettings.push({
                    eventType: item.eventName,
                    externalIdField: extId.externalIdField,
                    separator: extId.separator,
                    fields: extId.fields,
                });
            }
        }
        save({ triggerSettingsListSerialized: JSON.stringify([triggerSettings]) }).then((result) => {
            this.checkDeployementStatus(result)
        }).catch(error => {
            console.log('loadData >> ' + error.message);
            console.error(error);
        });
    }

    checkDeployementStatus(idDeployment) {
        let self = this;
        let counter = 0;
        let status;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            console.log('fresult >>> ' + fresult);
            let fdone = JSON.parse(fresult).deployResult.done;
            status = JSON.parse(fresult).deployResult.status;
            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        self.loadingData = false;
                        clearInterval(interval);
                        self.dispatchEvent(new ShowToastEvent({
                            title: self.labels.MSG_Information,
                            message: self.labels.MSG_Request_Timed_Out + ' ' + self.labels.MSG_Deploy_Last_Status + ' ' + status,
                            variant: INFO_VARIANT,
                            mode: STICKY_VARIANT
                        }));
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            self.loadingData = false;
                            clearInterval(interval);
                            if (success) {
                                self.showNotification(self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
                            } else {
                                self.showNotification(self.labels.MSG_Information, self.labels.MSG_Deploy_Ended_With_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.loadingData = false;
                self.showNotification(self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
            }
        });
    }

    handleDeleteSettings(event) {
        let eventIndex = event.currentTarget.dataset.eventIndex;
        let itemIndex = event.currentTarget.dataset.methodIndex;
        let eventW = this.records[eventIndex];
        let field = event.currentTarget.dataset.field;
        if (field == 'deleteFormula') {
            eventW.formulas.splice(itemIndex, 1);
        } else if (field == 'deleteMethod') {
            eventW.methods.splice(itemIndex, 1);
        } else if (field == 'deleteExtId') {
            eventW.extIds.splice(itemIndex, 1);
        }
        if ((eventW.methods.length + eventW.formulas.length + eventW.extIds.length) == 0) {
            this.records.splice(eventIndex, 1)
        }
        this.buildEventSections();
    }

    handleDragStart(event) {
        this.eventIndex = parseInt(event.currentTarget.dataset.eventIndex);
        this.draggedIndex = parseInt(event.currentTarget.dataset.index);
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('draggedIndex', this.draggedIndex);
        event.currentTarget.closest('.item-row')?.classList.add('dragging');
    }

    handleDragOver(event) {
        const eventIndex = parseInt(event.currentTarget.dataset.eventIndex);
        if (eventIndex == this.eventIndex) {
            event.preventDefault();
            event.currentTarget.classList.add('drag-over');
        }
    }

    handleDragEnter(event) {
        const eventIndex = parseInt(event.currentTarget.dataset.eventIndex);
        if (eventIndex == this.eventIndex) {
            event.currentTarget.classList.add('drag-over');
        }
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        const fromIndex = parseInt(event.dataTransfer.getData('draggedIndex'));
        const toIndex = parseInt(event.currentTarget.dataset.index);
        const eventIndex = parseInt(event.currentTarget.dataset.eventIndex);
        if (fromIndex === toIndex) return;
        const methodsList = [...this.records[eventIndex].methods];
        const draggedItem = methodsList.splice(fromIndex, 1)[0];
        methodsList.splice(toIndex, 0, draggedItem);
        this.records[eventIndex].methods = methodsList;
        event.currentTarget.classList.remove('drag-over');
        this.template.querySelectorAll('.item-row.dragging').forEach(el => el.classList.remove('dragging'));
        this.draggedIndex = null;
        this.eventIndex = null;
        this.buildEventSections();
    }

    handleDragEnd(event) {
        event.currentTarget.closest('.item-row')?.classList.remove('dragging');
        this.template.querySelectorAll('.item-row.drag-over').forEach(el => el.classList.remove('drag-over'));
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

    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.main-header')) {
            headerHeight = this.template.querySelector('.main-header').getBoundingClientRect().height;
        }
        let tableHeight = window.innerHeight - headerHeight - 160;
        this.template.querySelector('.main-div').style.height = tableHeight + 'px';
        if (this.template.querySelector('.headerBody') && this.template.querySelector('.tableDiv')) {
            let headerBodyHeight = this.template.querySelector('.headerBody').getBoundingClientRect().height;
            this.template.querySelector('.tableDiv').style.height = tableHeight - headerBodyHeight - 30 + 'px';
        }
    }

    handleFormulaChange(event) {
        const value = event.detail.value;
        this.row.formula = value;
        console.log('Formula updated:', this.row.formula);
    }

    handleEdit(event) {
        const eventTypeIndex = event.currentTarget.dataset.eventIndex;
        const itemIndex = event.currentTarget.dataset.methodIndex;
        const type = event.currentTarget.dataset.type;
        this.row = {};
        if (type == 'ExtId') {
            this.row = { ...this.records[eventTypeIndex].extIds[itemIndex], eventType: this.records[eventTypeIndex].eventName, eventIndex: eventTypeIndex, extIdIndex: itemIndex, isEdit: true };
        } else if (type == 'Formula') {
            this.row = { ...this.records[eventTypeIndex].formulas[itemIndex], eventType: this.records[eventTypeIndex].eventName, eventIndex: eventTypeIndex, formulaIndex: itemIndex, isEdit: true };
        } else if (type == 'Method') {
            this.records[eventTypeIndex].methods[itemIndex].isActive = event.detail.checked;
            return;
        }
        this.togglePopup(event);
    }

    handleCheck() {
        return this.validateFormula().then(() => {
            this.showNotification('Success', 'Formula is valid', 'success', 'dismissable');
            return true;
        }).catch(err => {
            this.showNotification('Error', err.message, 'error', 'dismissable');
            return false;
        });
    }

    validateFormula() {
        try {
            const equation = (this.row.formula ?? '').trim();
            if (!equation) throw new Error(this.labels.LBL_TriggerExecutionSettings_EmptyFormula);
            if (!this.row.isEditing) {
                const exists = this.fieldNameOptions?.some(opt => opt.value === this.row.fieldName);
                if (!this.row.fieldName || !exists) throw new Error('Invalid Field Name.');
            }
            // 1) extract if for getting field names
            const allowedVariables = this.fieldOptions.map(f => f.value);
            const usedVariables = window.formulon.extract(equation);
            const forbidden = new Set(['constructor', 'prototype', 'toString', 'eval', 'arguments']);
            for (const v of usedVariables) {
                if (forbidden.has(v)) throw new Error(`${this.labels.LBL_TriggerExecutionSettings_InvalidField} {v}`);
                const isLiteralNull = (v === 'null');
                if (!allowedVariables.includes(v)) {
                    if (isLiteralNull) continue;
                    throw new Error(`${this.labels.LBL_TriggerExecutionSettings_InvalidField} {v}`);
                }
            }
            // 2) syntax check
            const ast = window.formulon.ast(equation);
            console.log('🚀 ~ triggerExecutionSettings.js:683 -> ast: ', JSON.stringify(ast));
            if (ast?.type === 'error') {
                throw new Error(ast.message || 'Invalid formula syntax.');
            }
            // 3) type-check + evaluate 
            const dummyVars = {};
            for (const f of this.fieldOptions) {
                const dataType = this.toFormulonDataType(f.dataType);
                const value =
                    dataType === 'checkbox' ? true :
                        dataType === 'text' ? 'x' :
                            dataType === 'date' ? '2025-01-01' :
                                dataType === 'datetime' ? '2025-01-01T00:00:00Z' : 1;
                dummyVars[f.value] = { type: 'literal', dataType, value, options: {} };
            }
            const result = window.formulon.parse(equation, dummyVars);
            console.log('~ formulaSettings.js:273 -> result: ', JSON.stringify(result));
            if (result?.dataType !== 'number') {
                throw new Error(labels.LBL_TriggerExecutionSettings_NumericResult);
            }
            return Promise.resolve(true);
        } catch (err) {
            return Promise.reject(err);
        }
    }

    handleExternalIdChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        if (field === 'extIdField') {
            this.row = { ...this.row, externalIdField: value, fields: []};
        } else if (field === 'extIdEventType') {
            this.row = { ...this.row, eventType: value };
        } else if (field === 'extIdSeparator') {
            this.row = { ...this.row, separator: value };
        } else if (field === 'formatFieldSelect') {
            if (value) {
                this.row = {
                    ...this.row,
                    fields: [...(this.row.fields || []), value]
                };
            }
        }
    }

    removeFormatField(event) {
        const index = parseInt(event.currentTarget.dataset.index);
        const newFields = [...this.row.fields];
        newFields.splice(index, 1);
        this.row = { ...this.row, fields: newFields };
    }

    toFormulonDataType(sfType) {
        const t = String(sfType || '').trim().toLowerCase();
        const map = {
            string: 'text',
            textarea: 'text',
            picklist: 'text',
            multipicklist: 'text',
            email: 'text',
            phone: 'text',
            url: 'text',
            id: 'text',
            boolean: 'checkbox',
            date: 'date',
            datetime: 'datetime',
            time: 'time',
            double: 'number',
            percent: 'number',
            currency: 'number',
            integer: 'number',
            long: 'number',
            decimal: 'number'
        };
        return map[t] ?? 'text';
    }

    toggleSection(event) {
        const eventType = event.currentTarget.dataset.eventType;
        this.expandedSection = this.expandedSection === eventType ? null : eventType;
        this.buildEventSections();
    }

    closeTypeSelector() {
        this.showTypeSelector = false;
        this.pendingEventType = null;
    }

    previousPopUp() {
        this.addNewFormula = false;
        this.addNewRow = false;
        this.addNewExternalId = false;
        this.showTypeSelector = true;
    }
}