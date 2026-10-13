/**
* @author ULiT
* @date 04-10-2024
* @description ImportSettingsManager
*******************************************************************************************************************************************
*/
import { LightningElement, track, wire } from 'lwc';
import { labels } from './properties.js';
//APEX
import getAllObject from '@salesforce/apex/ImportSettingsController.getAllObject';
import loadAllData from '@salesforce/apex/ImportSettingsController.loadAllData';
import getRelatedObjectExtIdFields from '@salesforce/apex/ImportSettingsController.getRelatedObjectExtIdFields';
import save from '@salesforce/apex/ImportSettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/ImportSettingsController.checkDeploymentStatus';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { showNotification } from 'c/appHelper';
const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';

export default class ImportSettingsManager extends LightningElement {
    @track loadingData = false;
    @track ImportSettings_API = {};
    @track labels = labels;
    @track importSettingsList = [];
    @track initImportSettingsList = [];
    @track objectOptions = [];
    objectNameSet = new Set();
    @track searchTermSettings = '';
    @track selectedImportSettings;
    @track separatorOptions = [];
    fieldsMap = {};
    dataMap = {};
    @track selectedObjectApiName = null;
    @track fieldOptions = [];
    @track addNewRowImportSettings = false;
    @track newImportSettings;
    @track externalIdFieldOptions;
    @track isSaveAs = false;
    @track draggedIndex = null;

    get hasExternalIdFieldOptions() {
        return this.selectedImportSettings?.fields?.some(field => field.isRequired && field.name);
    }

    get isNotPackageMetadata() {
        return !this.selectedImportSettings?.namespacePrefix;
    }

    //LIFECYCLE
    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        this.initData();
    }

    renderedCallback() {
        if (this.template.querySelector('.main-header') && this.template.querySelector('.main-div')) {
            this.changeHeight();
        }
        for (var elem of this.template.querySelectorAll('.menuItem')) {
            if (!this.selectedImportSettings || elem.dataset.id != this.selectedImportSettings.name) {
                elem.setAttribute('aria-current', false);
            } else {
                elem.setAttribute('aria-current', 'page');
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: '$selectedObjectApiName' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            const fields = [];
            const refObjectNames = [];
            const lookupObjectsExtIdMap = {};
            for (let field of Object.values(data.fields)) {
                let fieldW = {
                    name: field.apiName,
                    label: field.label,
                    type: field.dataType?.toLowerCase(),
                    updateable: field.updateable,
                    externalId: field.externalId,
                    referenceTo: field.referenceToInfos?.map(r => r.apiName) || []
                }
                fields.push(fieldW);
                //populate reference objects
                if (fieldW.type === 'reference') {
                    fieldW.referenceTo.forEach(objName => {
                        if (!refObjectNames.includes(objName)) {
                            refObjectNames.push(objName);
                            lookupObjectsExtIdMap[objName] = {};
                        }
                    });
                }
            }
            this.dataMap[this.selectedObjectApiName] = {
                fieldOptions: fields,
                lookupObjectsExtIdMap
            }
            if (refObjectNames.length > 0) {
                getRelatedObjectExtIdFields({ objectNames: refObjectNames })
                    .then(result => {
                        const parsedResult = JSON.parse(result);
                        Object.keys(parsedResult).forEach(objName => {
                            this.dataMap[this.selectedObjectApiName].lookupObjectsExtIdMap[objName] = parsedResult[objName];
                        });
                        this.populateFieldOptions();
                    })
                    .catch(error => {
                        this.loadingData = false;
                        console.log('%c' + error.message ? error.message : error.body?.message);
                        showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
                    });
            } else {
                this.populateFieldOptions();
            }
        } else if (error) {
            this.loadingData = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    populateFieldOptions() {
        // if (this.addNewRowImportSettings) return;
        const objectName = this.selectedImportSettings?.objectName ?? this.selectedObjectApiName;
        const objectData = this.dataMap[objectName];
        this.externalIdFieldOptions = [{ value: '', label: this.labels.LBL_None_Picklist_Value },]
        if (!objectData) return;
        const newFieldsOptions = [];
        objectData.fieldOptions.forEach(field => {
            let row = { value: field.name, label: field.label }
            newFieldsOptions.push(row);
            if (field.externalId) {
                this.externalIdFieldOptions.push(row);
            }
        })
        this.fieldOptions = newFieldsOptions;
        if (this.selectedImportSettings && this.selectedImportSettings.fields) {
            this.selectedImportSettings.fields.forEach((field, index) => {
                const fieldDescribe = objectData.fieldOptions.find(f => f.name === field.name);
                field.isReference = fieldDescribe?.type === 'reference';
                if (field.isReference) {
                    const relatedObjName = fieldDescribe.referenceTo[0];
                    field.relatedObjectFieldOptions = objectData.lookupObjectsExtIdMap[relatedObjName];
                }
                if (!fieldDescribe?.updateable) {
                    field.isAlwaysRequired = true;
                    field.isRequired = true;
                }
                if (!field.isRequired && !field.isReference) {
                    field.referenceExtId = null;
                    field.referenceExtIdOrder = null;
                }
                if (!field.defaultColumn) {
                    field.defaultColumn = this.getExcelColumn(index);
                }
            });
            this.buildExternalIdTemplate();
        }
        this.loadingData = false;
    }

    handleDragStart(event) {
        this.draggedIndex = parseInt(event.currentTarget.dataset.index);
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('draggedIndex', this.draggedIndex);
        event.currentTarget.closest('tr').classList.add('dragging');
    }

    handleDragOver(event) {
        event.preventDefault();
        event.currentTarget.classList.add('drag-over');
    }

    handleDragEnter(event) {
        event.currentTarget.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        const fromIndex = parseInt(event.dataTransfer.getData('draggedIndex'));
        const toIndex = parseInt(event.currentTarget.dataset.index);
        if (fromIndex === toIndex) return;
        const fields = [...this.selectedImportSettings.fields];
        const draggedItem = fields.splice(fromIndex, 1)[0];
        fields.splice(toIndex, 0, draggedItem);
        this.selectedImportSettings.fields = fields;
        event.currentTarget.classList.remove('drag-over');
        this.template.querySelectorAll('tr.dragging').forEach(el => el.classList.remove('dragging'));
        this.draggedIndex = null;
        this.assignRowNumbers();
    }

    handleDragEnd(event) {
        event.currentTarget.closest('tr').classList.remove('dragging');
        this.template.querySelectorAll('tr.drag-over').forEach(el => el.classList.remove('drag-over'));
    }

    handleDeleteImportField(event) {
        const index = event.currentTarget.dataset.index;
        if (index !== undefined) {
            this.selectedImportSettings.fields.splice(index, 1);
            this.assignRowNumbers();
            this.buildExternalIdTemplate();
        }
    }

    //LOAD
    initData() {
        this.loadingData = true;
        try {
            getAllObject().then((result) => {
                let parsedresult = JSON.parse(result);
                this.objectOptions = parsedresult.objectWrapperList.map(item => {
                    this.objectNameSet.add(item.objectName);
                    item.label = item.objectLabel;
                    item.value = item.objectName;
                    return item;
                }).sort((item1, item2) => item1.label.localeCompare(item2.label));
                this.setupInit(parsedresult);
                this.loadAllData();
                this.loadingData = false;
            }).catch(error => {
                console.error('%c' + error.message ? error.message : error.body?.message);
                showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    setupInit(mainWrapper) {
        try {
            this.fieldsMap = mainWrapper.fieldsMap;
            this.ImportSettings_API = {
                objApiName: mainWrapper.prefix + 'ImportSettings__mdt',
                ObjectName__c: mainWrapper.prefix + 'ObjectName__c',
                MasterLabel: mainWrapper.prefix + 'MasterLabel',
                ImportFields__c: mainWrapper.prefix + 'ImportFields__c',
                ExtIdSeparator__c: mainWrapper.prefix + 'ExtIdSeparator__c',
                ShowAdvancedMode__c: mainWrapper.prefix + 'ShowAdvancedMode__c',
                DefaultLoadStartLine__c: mainWrapper.prefix + 'DefaultLoadStartLine__c',
                DefaultSheetNumber__c: mainWrapper.prefix + 'DefaultSheetNumber__c',
                RecordIdLookupField__c: mainWrapper.prefix + 'RecordIdLookupField__c',
                ExternalIdField__c: mainWrapper.prefix + 'ExternalIdField__c',
            }
            //SET UP LABELS
            this.labels.LBL_ObjectName = this.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.ObjectName__c].label;
            this.labels.LBL_ScreenName = this.fieldsMap[this.ImportSettings_API.objApiName].MasterLabel.label;
            this.labels.ShowAdvancedMode__c = this.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.ShowAdvancedMode__c].label;
            this.labels.DefaultLoadStartLine__c = this.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.DefaultLoadStartLine__c].label;
            this.labels.DefaultSheetNumber__c = this.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.DefaultSheetNumber__c].label;
            this.labels.RecordIdLookupField__c = this.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.RecordIdLookupField__c].label;
            this.labels.ExternalIdField__c = this.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.ExternalIdField__c].label;
            //SET UP SEPARATOR OPTIONS
            this.separatorOptions = mainWrapper.fieldsMap[this.ImportSettings_API.objApiName][this.ImportSettings_API.ExtIdSeparator__c].picklistValues;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    loadAllData() {
        this.importSettingsList = [];
        this.initImportSettingsList = [];
        this.loadingData = true;
        try {
            loadAllData().then((result) => {
                this.importSettingsList = JSON.parse(result);
                console.log('importSettingsList >>> ' + JSON.stringify(this.importSettingsList));
                this.initImportSettingsList = [...this.importSettingsList];
                this.sortSettings();
                this.loadingData = false;
            }).catch(error => {
                console.error(error);
                showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    sortSettings() {
        console.log('sortSettings')
        this.importSettingsList.sort((a, b) => {
            if (a.name === undefined) return -1;
            if (b.name === undefined) return 1;
            let aValue = a.name.toLowerCase();
            let bValue = b.name.toLowerCase();
            return ((aValue > bValue) ? 1 : ((bValue > aValue) ? -1 : 0));
        });
    }

    searchSettings(event) {
        this.searchTermSettings = event.target.value;
        if (this.searchTermSettings != '') {
            this.importSettingsList = this.initImportSettingsList.filter(item => item.objectName.toLowerCase().includes(this.searchTermSettings.toLowerCase()) || item.name.toLowerCase().includes(this.searchTermSettings.toLowerCase()));
        } else {
            this.importSettingsList = [...this.initImportSettingsList];
        }
        this.sortSettings();
    }

    assignRowNumbers() {
        if (this.selectedImportSettings && this.selectedImportSettings.fields) {
            this.selectedImportSettings.fields = this.selectedImportSettings.fields.map((field, index) => {
                return { ...field, rowNumber: index + 1 };
            });
        }
    }

    handleChangeImportSettings(event) {
        this.loadingData = true;
        this.fieldOptions = [];
        const selectedImportSettingsName = event.currentTarget.dataset.id;
        this.selectedImportSettings = JSON.parse(JSON.stringify(this.importSettingsList.find(item => item.name === selectedImportSettingsName)));
        this.selectedImportSettings.fields = this.selectedImportSettings.fields.map(f => ({
            ...f,
            isMandatory: !!f.isMandatory,
            allowDefaultValue: !!f.allowDefaultValue
        }));
        this.assignRowNumbers();
        if (this.dataMap[this.selectedImportSettings.objectName]) {
            this.populateFieldOptions();
            this.loadingData = false;
        } else {
            this.selectedObjectApiName = this.selectedImportSettings.objectName;
        }
    }

    getExcelColumn(index) {
        let column = '';
        let num = index + 1; // 1-based index
        while (num > 0) {
            const remainder = (num - 1) % 26;
            column = String.fromCharCode(65 + remainder) + column;
            num = Math.floor((num - 1) / 26);
        }
        return column;
    }

    togglePopupAddImportSettings() {
        this.addNewRowImportSettings = !this.addNewRowImportSettings;
        this.isSaveAs = false;
        if (this.addNewRowImportSettings) {
            this.newImportSettings = {
                objectName: '',
                extIdSeparator: '-',
                defaultLoadStartLine: 2,
                defaultSheetNumber: 1,
                name: '',
                fields: [],
                externalIdField: ''
            };
        }
    }

    handleAddImportSettings() {
        if (!this.newImportSettings.objectName || !this.newImportSettings.name) {
            showNotification(this, this.labels.LBL_Error, this.labels.LBL_ObjectName + ' and ' + this.labels.LBL_ScreenName + ' are required.', 'error');
            return;
        }
        this.addNewImportSettings();
    }

    handleSaveAs() {
        this.isSaveAs = true;
        this.addNewRowImportSettings = true;
        this.newImportSettings = { ...JSON.parse(JSON.stringify(this.selectedImportSettings)), name: '' };
    }

    addNewImportSettings() {
        this.selectedImportSettings = this.newImportSettings;
        this.fieldOptions = this.dataMap[this.selectedImportSettings.objectName].fieldOptions.map(field => ({ value: field.name, label: field.label }));
        this.buildExternalIdTemplate();
        this.handleSave();
        this.togglePopupAddImportSettings();
    }

    handleOnChangeNewImportSettings(event) {
        let field = event.target.dataset.field;
        let value = event.detail.value;
        if(field === 'objectName' && !this.dataMap[value] && this.objectNameSet.has(value)) {
            this.selectedObjectApiName = value;
        }
        this.newImportSettings[field] = value;
    }

    handleAddImportField(event) {
        let self = this;
        let newField = {
            key: `new-${Date.now()}-${Math.random()}`,
            name: '',
            isAdmin: true,
            isUser: true,
            isRequired: false,
            isMandatory: false,
            isAlwaysRequired: false,
            isReference: false,
            allowDefaultValue: false,
            namespacePrefix : '',
            class: 'newRow row',
            defaultColumn: !self.selectedImportSettings.fields?.length ? self.getExcelColumn(0) : self.getExcelColumn(self.selectedImportSettings.fields.length)
        }
        this.selectedImportSettings.fields.push(newField);
        this.assignRowNumbers();
    }

    handleImportEdit(event) {
        let field = event.target.dataset.field;
        let value = event.detail.checked ?? event.detail.value;
        this.selectedImportSettings[field] = value;
        console.log(JSON.stringify(this.selectedImportSettings));
    }

    handleSave() {
        this.loadingData = true;
        try {
            const validNames = new Set((this.dataMap[this.selectedImportSettings.objectName]?.fieldOptions || []).map(f => f.name));
            const invalidFields = (this.selectedImportSettings.fields || []).filter(f => !validNames.has(f.name));
            if (invalidFields.length) {
                throw new Error('Invalid fields: ' + invalidFields.map(f => f.name || '(empty)').join(', '));
            }
            let hasKeyField = this.selectedImportSettings.fields?.some(field => field.isRequired);
            if (!hasKeyField) {
                this.selectedImportSettings.externalIdField = '';
            } else if (hasKeyField && this.selectedImportSettings.externalIdField == '') {
                showNotification(this, this.labels.LBL_Error, this.labels.LBL_Import_Settings_Manager_ExternalIdFieldRequired, 'error');
                this.loadingData = false;
                return;
            }
            console.log('this.selectedImportSettings >>>> ' + JSON.stringify(this.selectedImportSettings))
            save({ importSettingsListJSON: JSON.stringify([this.selectedImportSettings]) }).then((result) => {
                this.loadingData = false;
                this.checkDeployementStatus(result);
            }).catch(error => {
                this.loadingData = false;
                console.error(error);
                showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            this.loadingData = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    checkDeployementStatus(idDeployment) {
        this.loadingData = true;
        let self = this;
        let counter = 0;
        let status;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            let fdone = JSON.parse(fresult).deployResult.done;
            status = JSON.parse(fresult).deployResult.status;
            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        self.loadingData = false;
                        clearInterval(interval);
                        showNotification(self, self.labels.MSG_Information, self.labels.MSG_Request_Timed_Out + ' ' + self.labels.MSG_Deploy_Last_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            self.loadingData = false;
                            self.loadAllData();
                            clearInterval(interval);
                            if (success) {
                                showNotification(self, self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
                            } else {
                                showNotification(self, self.labels.MSG_Information, self.labels.MSG_Deploy_Ended_With_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.loadingData = false;
                self.loadAllData();
                showNotification(self, self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
            }
        });
    }

    handleEditImportField(event) {
        let index = event.target.dataset.index;
        let fieldName = event.target.dataset.field;
        let value = event.detail.checked ?? event.detail.value;
        let field = this.selectedImportSettings.fields[index];
        let objectName = this.selectedImportSettings.objectName;
        let input = event.target;
        if (typeof input.setCustomValidity === 'function') {
            if (fieldName == 'defaultColumn' && !(/^[A-Z]+$/.test(value))) {
                input.setCustomValidity(this.labels.MSG_InvalidExcelColumnOrder);
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        }
        field[fieldName] = value;
        field.class = 'newRow row';
        if (fieldName == 'name') {
            let fieldDescribe = this.dataMap[objectName].fieldOptions.filter(field => field.name == value)[0];
            field.isReference = fieldDescribe?.type == 'reference';
            if (field.isReference) {
                let fieldOptions = this.dataMap[objectName].lookupObjectsExtIdMap[fieldDescribe.referenceTo[0]];
                if (fieldOptions) {
                    field.relatedObjectFieldOptions = Object.keys(fieldOptions).map(fieldName => ({ value: fieldOptions[fieldName].value, label: fieldOptions[fieldName].label }));
                }
                if (!field.referenceExtId) {
                    field.referenceExtId = 'Id';
                }
            }
            if (!fieldDescribe?.updateable) {
                field.isAlwaysRequired = true;
                field.isRequired = true;
                field.allowDefaultValue = false;
            } else {
                field.isAlwaysRequired = false;
                field.isRequired = false;
            }
        }
        if ((fieldName === 'isRequired' && value === true) || field.isAlwaysRequired) {
            field.isAdmin = true;
            field.isUser = true;
        }
        if (!field.isRequired && !field.isReference) {
            field.referenceExtId = null;
            field.referenceExtIdOrder = null;
        }
        console.log('FIELDDDD>>>>>> ' + JSON.stringify(field));
        this.buildExternalIdTemplate();
    }

    get lookupFieldOptions() {
        if (!this.selectedImportSettings || !this.dataMap[this.selectedImportSettings.objectName]) return [];
        const opts = (this.dataMap[this.selectedImportSettings.objectName].fieldOptions || []).filter(field => field.type === 'reference').map(field => ({ value: field.name, label: field.label + ' (' + field.name + ')' }));
        return [{ value: '', label: this.labels.LBL_None_Picklist_Value }, ...opts];
    }

    buildExternalIdTemplate() {
        try {
            let extIdFields = this.selectedImportSettings.fields.filter(field => field.isRequired).sort((a, b) => a.referenceExtIdOrder - b.referenceExtIdOrder);
            let ExtIdList = [];
            console.log('extIdFields>>>> '+ JSON.stringify(extIdFields))
            extIdFields.forEach(field => {
                let fieldName = '';
                if(field.isReference && field.referenceExtId != 'Id') {
                    fieldName = field.name.replace(new RegExp('Id$'), '').replace(new RegExp('__c$'), '__r') + '.' + field.referenceExtId;
                } else {
                    fieldName = field.name;
                }
                ExtIdList.push(fieldName);
            });
            let separator;
            if (this.selectedImportSettings.extIdSeparator == 'No separator') {
                separator = '';
            } else if (this.selectedImportSettings.extIdSeparator == 'Space') {
                separator = ' ';
            } else {
                separator = this.selectedImportSettings.extIdSeparator;
            }
            if (!separator) {
                separator = this.separatorOptions[0].label;
                this.selectedImportSettings.extIdSeparator = this.separatorOptions[0].label;
            }
            this.selectedImportSettings.extIdTemplate = ExtIdList.join(separator);
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleChangeSeparator(event) {
        this.selectedImportSettings.extIdSeparator = event.detail.value;
        this.buildExternalIdTemplate();
    }

    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.main-header')) {
            headerHeight = this.template.querySelector('.main-header').getBoundingClientRect().height;
        }
        let tableHeight = window.innerHeight - headerHeight - 160;
        this.template.querySelector('.main-div').style.height = tableHeight + 'px';
    };
}