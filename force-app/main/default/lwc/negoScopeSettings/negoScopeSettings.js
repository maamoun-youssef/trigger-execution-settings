/**
* @author ULiT
* @date 14-10-2024
* @description NegoScopeSettings
*******************************************************************************************************************************************
*/
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValuesByRecordType, getObjectInfo } from 'lightning/uiObjectInfoApi';
//APEX
import initData from '@salesforce/apex/NegoScopeSettingsController.loadNegoScopeSettings';
import save from '@salesforce/apex/NegoScopeSettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/NegoScopeSettingsController.checkDeploymentStatus';

//OBJECTS
import BRADistributor_OBJECT from '@salesforce/schema/BRADistributor__c';
import PG_OBJECT from '@salesforce/schema/PG__c';
import NegoScope_OBJECT from '@salesforce/schema/NegoScope__c';
// FIELDS
import SetMasterNegoScope__c from '@salesforce/schema/NegoScope__c.SetMasterNegoScope__c';
import ConditionsCaptureLevel__c from '@salesforce/schema/NegoScope__c.ConditionsCaptureLevel__c';
import ContractingLevel__c from '@salesforce/schema/NegoScope__c.ContractingLevel__c';
import ConditionsDispatchLevel__c from '@salesforce/schema/NegoScope__c.ConditionsDispatchLevel__c';
import NegoBaseManagement__c from '@salesforce/schema/NegoScope__c.NegoBaseManagement__c';
import SlabsApplication__c from '@salesforce/schema/NegoScope__c.SlabsApplication__c';
import SellinDeclarationLevel__c from '@salesforce/schema/NegoScope__c.SellinDeclarationLevel__c';
import InvoicingLevel__c from '@salesforce/schema/NegoScope__c.InvoicingLevel__c';
//IMPORTS
import { labels, NEGO_SCOPE_SETTINGS_API } from './properties.js';
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const SUCCESS_VARIANT = 'success';
const INFO_VARIANT = 'info';
const STICKY_VARIANT = 'sticky';
export default class NegoScopeSettings extends LightningElement {
    @track labels = labels;
    @track NEGO_SCOPE_SETTINGS_API = NEGO_SCOPE_SETTINGS_API;
    @track gridSettingsLink = '';

    //BOOLEANS
    @track loading = false;
    @track addCondition = false;
    @track editCaseToggle = false;
    @track editCaseIndex = -1;
    @track selectedCase = {};
    @track selectedCaseInit = {};
    addingNewCondition = false;

    @track negoScopeManagerPGGridOptions = [];
    @track negoScopeManagerBrandGridOptions = [];
    @track negoScopeManagerNegoScopeGridOptions = [];
    @track conditionFieldOptions = [];
    @track relatedFieldOptions = []
    get conditionOptions() {
        return this.conditionFieldOptions;
    }

    guidedModeConfigurationFields = [
        'RecordTypeId',
        SetMasterNegoScope__c.fieldApiName,
        ConditionsCaptureLevel__c.fieldApiName,
        ContractingLevel__c.fieldApiName,
        ConditionsDispatchLevel__c.fieldApiName,
        NegoBaseManagement__c.fieldApiName,
        SlabsApplication__c.fieldApiName,
        SellinDeclarationLevel__c.fieldApiName,
        InvoicingLevel__c.fieldApiName,
    ];
    @track wiresIsDone = {
        picklistValues: false,
        objectInfoNS: false,
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: NegoScope_OBJECT, recordTypeId: '012000000000000AAA' }) picklistValues({ error, data }) {
        if (data) {
            //console.log('data >>> ' + JSON.stringify(data))
        } else if (error) { console.log('ERROR'); }
    }
    // WIRES
    @wire(getObjectInfo, { objectApiName: NegoScope_OBJECT.objectApiName }) objectInfoNS({ error, data }) {
        if (data) {
            let options = [];
            for (let field of Object.keys(data.fields)) {
                if (this.guidedModeConfigurationFields.includes(field)) {
                    if (field == 'RecordTypeId') {
                        options.unshift({ label: data.fields[field].label, value: field });
                    } else {
                        options.push({ label: data.fields[field].label, value: field });
                    }
                }
            }
            this.conditionFieldOptions = options;
            this.wiresIsDone.objectInfoNS = true;
            this.checkWireIsDone();
        } else if (error) {
            console.log('ERROR');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: NegoScope_OBJECT, recordTypeId: '012000000000000AAA' }) picklistValues({ error, data }) {
        if (data) {
            for (let field of Object.keys(data.picklistFieldValues)) {
                if (this.guidedModeConfigurationFields.includes(field)) {
                    let fieldW = {
                        fieldName: field,
                        options: [{ label: labels.LBL_None_Picklist_Value, value: '', }],
                    }
                    for (let pickVal of data.picklistFieldValues[field].values) {
                        fieldW.options.push({ label: pickVal.label, value: pickVal.value })
                    }
                    this.relatedFieldOptions.push(fieldW);
                }
            }
            this.relatedFieldOptions.push({
                fieldName: SetMasterNegoScope__c.fieldApiName,
                options: [
                    { label: labels.LBL_Yes, value: true, },
                    { label: labels.LBL_No, value: false, },
                ],
            });
            this.wiresIsDone.picklistValues = true;
            this.checkWireIsDone();
        } else if (error) { console.log('ERROR'); }
    }

    checkWireIsDone() {
        if (this.wiresIsDone.objectInfoNS && this.wiresIsDone.picklistValues) {
            this.initData();
        }
    }

    //LIFECYCLE
    setPageSize = () => {
        try {
            // //SET PAGE SIZE
            // let mainContainer = this.template.querySelector(".mainContainer");
            // let pageHeader = this.template.querySelector(".pageHeader");
            // let pageBody = this.template.querySelector(".pageBody");
            // if (
            //     mainContainer != null &&
            //     pageHeader != null &&
            //     pageBody != null
            // ) {
            //     pageBody.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - 10 + "px";
            // }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    connectedCallback() {
        this.initData();
         addEventListener('resize', this.setPageSize);
    }

    renderedCallback() {
        try {
            setTimeout(() => {
                this.setPageSize()
            }, 200);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    //LOAD
    initData() {
        try {
            this.loading = true;
            initData().then((result) => {
                let parsedResult = JSON.parse(result);
                this.afterLoad(parsedResult);
            })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    @track mainWrapper = {};
    @track negoScopeSettings = {};
    @track recordTypeMap = {};
    @track recordTypeOptions = [];
    projectDefaultOptions = [{ label: this.labels.LBL_NS_Stg_IsNSProjectDefaultRT_No, value: 'false' }, { label: this.labels.LBL_NS_Stg_IsNSProjectDefaultRT_Yes, value: 'true' }];
    projectSettingsOptions = [{ label: this.labels.LBL_NS_Stg_isNSProjectToRegularOnValidation_No, value: 'false' }, { label: this.labels.LBL_NS_Stg_isNSProjectToRegularOnValidation_Yes, value: 'true' }];
    afterLoad(mainWrapper) {
        try {
            this.gridSettingsLink = '/lightning/n/' + mainWrapper.prefix + 'Grid_Settings_Manager';
            this.NEGO_SCOPE_SETTINGS_API = {
                NegoScopeSettings__mdt: mainWrapper.prefix + 'NSSettings__mdt',
                IsNSProjectActive__c: mainWrapper.prefix + 'IsNSProjectActive__c',
                IsNSManagerGLTabActive__c: mainWrapper.prefix + 'IsNSManagerGLTabActive__c',
                NegoScopeManagerBrandGrid__c: mainWrapper.prefix + 'NegoScopeManagerBrandGrid__c',
                NegoScopeManagerPGGrid__c: mainWrapper.prefix + 'NegoScopeManagerPGGrid__c',
                NegoScopeManagerNSGrid__c: mainWrapper.prefix + 'NegoScopeManagerNSGrid__c',
                IsAdvancedActive__c: mainWrapper.prefix + 'IsAdvancedActive__c',
            }
            //SET UP RECORDTYPES
            let recordTypeMap = {};
            mainWrapper.recordTypes.forEach(rt => {
                recordTypeMap[rt.DeveloperName] = { description: rt.Description, label: rt.Name };
                this.recordTypeOptions.push({ value: rt.DeveloperName, label: rt.Name });
            });
            this.recordTypeMap = recordTypeMap;
            //SET UP NEGO SETTINGS
            this.negoScopeSettings = mainWrapper.negoScopeSettings;
            this.negoScopeSettings.isNSProjectDefaultRT = this.negoScopeSettings.isNSProjectDefaultRT ? 'true' : 'false';
            this.negoScopeSettings.isNSProjectToRegularOnValidation = this.negoScopeSettings.isNSProjectToRegularOnValidation ? 'true' : 'false';
            this.negoScopeSettings.nsManagerGuidedModeConfiguration = this.negoScopeSettings.nsManagerGuidedModeConfiguration;
            this.negoScopeSettings.nsManagerGuidedModeConfiguration.forEach(caseItem => {
                let _fieldValues = caseItem.fieldValues;
                _fieldValues.forEach(field => {
                    field.isCombobox = field.fieldName != SetMasterNegoScope__c.fieldApiName;
                    field.isBoolean = field.fieldName == SetMasterNegoScope__c.fieldApiName;
                    field.fieldValue = field.fieldValue == 'true' ? true : (field.fieldName == SetMasterNegoScope__c.fieldApiName ? false : field.fieldValue);
                    field.fieldLabel = this.conditionFieldOptions.find(fieldOption => fieldOption.value == field.fieldName)?.label;
                    field.fieldOptions = field.fieldName != 'RecordTypeId' ? this.relatedFieldOptions.find(fieldOption => fieldOption.fieldName == field.fieldName)?.options : this.recordTypeOptions;
                    let fieldOption = field.fieldOptions.find(it => it.value == field.fieldValue);
                    if (fieldOption) {
                        field.displayValue = fieldOption.label;
                    }
                });
                caseItem.fieldValues = [];
                [
                    'RecordTypeId',
                    SetMasterNegoScope__c.fieldApiName,
                    ContractingLevel__c.fieldApiName,
                    ConditionsCaptureLevel__c.fieldApiName,
                    ConditionsDispatchLevel__c.fieldApiName,
                    SlabsApplication__c.fieldApiName,
                    NegoBaseManagement__c.fieldApiName,
                    SellinDeclarationLevel__c.fieldApiName,
                    InvoicingLevel__c.fieldApiName,
                ].forEach(_field => {
                    try {
                        let field = this.conditionFieldOptions.find(item => item.value == _field);
                        caseItem.fieldValues.push(
                            _fieldValues.find(__field => __field.fieldName == _field) ||
                            {
                                fieldName: field.value,
                                fieldLabel: field.label,
                                displayValue: '',
                                fieldValue: field.value == SetMasterNegoScope__c.fieldApiName ? false : '',
                                isCombobox: field.value != SetMasterNegoScope__c.fieldApiName,
                                isBoolean: field.value == SetMasterNegoScope__c.fieldApiName,
                                fieldOptions: field.value != 'RecordTypeId' ? this.relatedFieldOptions?.find(fieldOption => fieldOption.fieldName == field.value)?.options : this.recordTypeOptions
                            });
                    } catch (error) {
                        console.log('%c' + error.message ? error.message : error.body?.message);
                        console.log('ERROR >>>>>>>>>>>>>> : ', error);
                    }
                });
            })
            //SET UP OPTIONS
            this.negoScopeSettingsLayoutsMap = mainWrapper.negoScopeSettingsLayoutsMap;
            let brandGridOptions = []
            let pgGridOptions = []
            let negoScopeGridOptions = []
            if (this.negoScopeSettingsLayoutsMap) {
                for (let objectName in this.negoScopeSettingsLayoutsMap) {
                    if (objectName == BRADistributor_OBJECT.objectApiName) {
                        for (let option in this.negoScopeSettingsLayoutsMap[objectName]) {
                            brandGridOptions.push({
                                label: this.negoScopeSettingsLayoutsMap[objectName][option].label,
                                value: this.negoScopeSettingsLayoutsMap[objectName][option].value
                            });
                        }
                    }
                    if (objectName == PG_OBJECT.objectApiName) {
                        for (let option in this.negoScopeSettingsLayoutsMap[objectName]) {
                            pgGridOptions.push({
                                label: this.negoScopeSettingsLayoutsMap[objectName][option].label,
                                value: this.negoScopeSettingsLayoutsMap[objectName][option].value
                            });
                        }
                    }
                    if (objectName == NegoScope_OBJECT.objectApiName) {
                        for (let option in this.negoScopeSettingsLayoutsMap[objectName]) {
                            negoScopeGridOptions.push({
                                label: this.negoScopeSettingsLayoutsMap[objectName][option].label,
                                value: this.negoScopeSettingsLayoutsMap[objectName][option].value
                            });
                        }
                    }
                }
            }
            this.negoScopeManagerBrandGridOptions = brandGridOptions;
            this.negoScopeManagerPGGridOptions = pgGridOptions;
            this.negoScopeManagerNegoScopeGridOptions = negoScopeGridOptions;
            this.setlabels(mainWrapper.fieldsMap);
            this.mainWrapper = mainWrapper;
            this.loading = false;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }


    setlabels(fieldsMap) {
        let settingsApiName = this.NEGO_SCOPE_SETTINGS_API.NegoScopeSettings__mdt.replace('__c', '__mdt');
        this.labels.NegoScopeSettings__mdt.IsNSProjectActiveLabel = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.IsNSProjectActive__c].label;
        this.labels.NegoScopeSettings__mdt.IsNSManagerGLTabActiveLabel = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.IsNSManagerGLTabActive__c].label;
        this.labels.NegoScopeSettings__mdt.brandGridLabel = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.NegoScopeManagerBrandGrid__c].label;
        this.labels.NegoScopeSettings__mdt.brandGridHelpText = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.NegoScopeManagerBrandGrid__c].inlineHelpText;
        this.labels.NegoScopeSettings__mdt.productGridLabel = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.NegoScopeManagerPGGrid__c].label;
        this.labels.NegoScopeSettings__mdt.productGridHelpText = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.NegoScopeManagerPGGrid__c].inlineHelpText;
        this.labels.NegoScopeSettings__mdt.negoScopeGridLabel = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.NegoScopeManagerNSGrid__c].label;
        this.labels.NegoScopeSettings__mdt.negoScopeGridHelpText = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.NegoScopeManagerNSGrid__c].inlineHelpText;
        this.labels.NegoScopeSettings__mdt.IsAdvancedActiveLabel = fieldsMap[settingsApiName][this.NEGO_SCOPE_SETTINGS_API.IsAdvancedActive__c].label;
    }
    brandGridInfoOpen = false;
    handleToggleBrandGridInfo() {
        this.brandGridInfoOpen = !this.brandGridInfoOpen;
        if (this.brandGridInfoOpen) {
            this.pgGridInfoOpen = false;
            this.negoScopeGridInfoOpen = false;
        }
    }
    pgGridInfoOpen = false;
    handleTogglePGGridInfo() {
        this.pgGridInfoOpen = !this.pgGridInfoOpen;
        if (this.pgGridInfoOpen) {
            this.brandGridInfoOpen = false;
            this.negoScopeGridInfoOpen = false;
        }
    }
    negoScopeGridInfoOpen = false;
    handleToggleNegoScopeGridInfo() {
        this.negoScopeGridInfoOpen = !this.negoScopeGridInfoOpen;
        if (this.negoScopeGridInfoOpen) {
            this.pgGridInfoOpen = false;
            this.brandGridInfoOpen = false;
        }
    }
    handleFieldEdits(event) {
        try {
            let fieldName = event.target.dataset.field;
            console.log('fieldName: ' + fieldName)
            let value = event.detail.checked ?? event.target.value;
            console.log('value: ' + value)
            this.negoScopeSettings[fieldName] = value;
            console.log('this.negoScopeSettings: ' + JSON.stringify(this.negoScopeSettings))
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    handleCaseEdits(event) {
        try {
            let fieldName = event.target.dataset.field;
            let index = event.target.dataset.index;
            let value = event.target.value;
            this.negoScopeSettings.nsManagerGuidedModeConfiguration[index][fieldName] = value;
            console.log('this.negoScopeSettings: ' + JSON.stringify(this.negoScopeSettings))
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleSave() {
        this.loading = true;
        let nonRTSelected = false;
        this.negoScopeSettings.nsManagerGuidedModeConfiguration.forEach(caseItem => {
            let rtField = caseItem.fieldValues.find(field => field.fieldName == 'RecordTypeId');
            nonRTSelected = !rtField || !rtField.fieldValue;
            if (nonRTSelected) {
                this.showNotification(this.labels.LBL_Error, this.labels.MSG_RT_Field_Required, 'error', 'sticky');
                this.loading = false;
                return;
            }
        })
        if (!nonRTSelected) {
            let recordToSave = {};
            console.log('this.negoScopeSettings: ' + JSON.stringify(this.negoScopeSettings))
            recordToSave.isNSProjectActive = this.negoScopeSettings.isNSProjectActive;
            recordToSave.isAdvancedActive = this.negoScopeSettings.isAdvancedActive;
            recordToSave.isNSManagerGLTabActive = this.negoScopeSettings.isNSManagerGLTabActive;
            recordToSave.isNSProjectDefaultRT = this.negoScopeSettings.isNSProjectDefaultRT == 'true';
            recordToSave.isNSProjectToRegularOnValidation = this.negoScopeSettings.isNSProjectToRegularOnValidation == 'true';
            recordToSave.negoScopeManagerBrandGrid = this.negoScopeSettings.negoScopeManagerBrandGrid;
            recordToSave.negoScopeManagerPGGrid = this.negoScopeSettings.negoScopeManagerPGGrid;
            recordToSave.negoScopeManagerNSGrid = this.negoScopeSettings.negoScopeManagerNSGrid;
            recordToSave.nsManagerGuidedModeConfiguration = this.negoScopeSettings.nsManagerGuidedModeConfiguration;
            recordToSave.isMultipartyActive = this.negoScopeSettings.isMultipartyActive;
            console.log('recordToSave: ' + JSON.stringify(recordToSave))
            save({
                negoScopeSettingsJson: JSON.stringify(recordToSave)
            }).then(result => {
                console.log('handleSave result: ' + result)
                let jobIds = result;
                this.checkDeployementStatus(jobIds);
            }).catch(error => {
                this.loading = false;
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                console.error('Error saving settings:', error);
            });
        }
    }

    checkDeployementStatus(idDeployment) {
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
                        self.loading = false;
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
                            self.loading = false;
                            clearInterval(interval);
                            if (success) {
                                this.newNameConfigurationsList = [];
                                this.isDefaultContractModelEditMode = false;
                                this.newConditionManagerPageConfigurationsList = [];
                                self.dispatchEvent(new ShowToastEvent({
                                    title: self.labels.LBL_Save,
                                    message: self.labels.MSG_Save_Complete,
                                    variant: SUCCESS_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            } else {
                                self.dispatchEvent(new ShowToastEvent({
                                    title: self.labels.MSG_Information,
                                    message: self.labels.MSG_Deploy_Ended_With_Status + ' ' + status,
                                    variant: INFO_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.loading = false;
                this.newNameConfigurationsList = [];
                this.isDefaultContractModelEditMode = false;
                this.newConditionManagerPageConfigurationsList = [];
                self.dispatchEvent(new ShowToastEvent({
                    title: self.labels.LBL_Save,
                    message: self.labels.MSG_Save_Complete,
                    variant: SUCCESS_VARIANT,
                    mode: STICKY_VARIANT
                }));
            }
        });
    }

    handleChangeCase(event) {
        let field = event.target.dataset.field;
        this.selectedCase[field] = event.detail.value;
    }

    togglePopup() {
        this.addCondition = !this.addCondition;
        if (this.editCaseIndex != 0) {
            let row = {
                caseName: this.selectedCaseInit.caseName,
                caseTitle: this.selectedCaseInit.caseTitle,
                caseDescription: this.selectedCaseInit.caseDescription,
                fieldValues: this.selectedCaseInit.fieldValues
            };
            this.negoScopeSettings.nsManagerGuidedModeConfiguration[this.editCaseIndex] = row;
            this.editCaseIndex = -1;
        }
    }

    confirmCase() {
        let valueAlreadyExist = this.negoScopeSettings.nsManagerGuidedModeConfiguration.findIndex(caseItem => caseItem.caseName.toLowerCase() == this.selectedCase.caseName.toLowerCase());
        console.log('valueAlreadyExist >>> ' + valueAlreadyExist)
        console.log('this.editCaseIndex >>> ' + this.editCaseIndex)
        if (valueAlreadyExist != -1) {
            if (this.editCaseIndex == -1 || (this.editCaseIndex != -1 && valueAlreadyExist != this.editCaseIndex)) {
                this.showNotification(this.labels.LBL_Error, this.labels.MSG_Case_Name_Already_Exist, 'error', 'sticky')
                return;
            }
        }
        this.selectedCase.fieldValues.forEach(field => {
            let fieldOption = field.fieldOptions.find(it => it.value == field.fieldValue);
            if (fieldOption) {
                field.displayValue = fieldOption.label;
            }
        });
        let row = {
            caseName: this.selectedCase.caseName,
            caseTitle: this.selectedCase.caseTitle,
            caseDescription: this.selectedCase.caseDescription,
            fieldValues: this.selectedCase.fieldValues
        };
        if (this.editCaseIndex != 0) {
            this.negoScopeSettings.nsManagerGuidedModeConfiguration[this.editCaseIndex] = row;
        } else {
            this.negoScopeSettings.nsManagerGuidedModeConfiguration.push(row);
        }
        this.editCaseIndex = -1;
        this.selectedCase = {};
        this.selectedCaseInit = {};
        this.togglePopup();
    }
    handleRelatedFieldChange(event) {
        let targetIndex = event.target.dataset.targetIndex;
        let value = event.detail.hasOwnProperty('checked') ? event.detail.checked : event.detail.value;
        this.selectedCase.fieldValues[targetIndex].fieldValue = value;
        let fieldOption = this.selectedCase.fieldValues[targetIndex]?.fieldOptions.find(it => it.value == this.selectedCase.fieldValues[targetIndex].fieldValue);
        if (fieldOption) {
            this.selectedCase.fieldValues[targetIndex].displayValue = fieldOption.label;
        }
    }
    handleDeleteCase(event) {
        let index = event.target.dataset.index;
        this.negoScopeSettings.nsManagerGuidedModeConfiguration.splice(index, 1);
    }
    handleEditCase(event) {
        let index = event.target.dataset.index;
        this.editCaseIndex = index;
        this.selectedCase = this.negoScopeSettings.nsManagerGuidedModeConfiguration[index];
        this.selectedCaseInit = JSON.parse(JSON.stringify(this.selectedCase));
        this.addCondition = !this.addCondition;
    }
    handleAddNewCase(event) {
        this.selectedCase = { fieldValues: [] };
        [
            'RecordTypeId',
            SetMasterNegoScope__c.fieldApiName,
            ContractingLevel__c.fieldApiName,
            ConditionsCaptureLevel__c.fieldApiName,
            ConditionsDispatchLevel__c.fieldApiName,
            SlabsApplication__c.fieldApiName,
            NegoBaseManagement__c.fieldApiName,
            SellinDeclarationLevel__c.fieldApiName,
            InvoicingLevel__c.fieldApiName,
        ].forEach(_field => {
            let field = this.conditionFieldOptions?.find(item => item.value == _field);
            this.selectedCase.fieldValues.push({
                fieldName: field?.value,
                fieldLabel: field?.label,
                displayValue: '',
                fieldValue: '',
                isCombobox: field?.value != SetMasterNegoScope__c.fieldApiName,
                isBoolean: field?.value == SetMasterNegoScope__c.fieldApiName,
                fieldOptions: field?.value != 'RecordTypeId' ? this.relatedFieldOptions?.find(fieldOption => fieldOption.fieldName == field?.value)?.options : this.recordTypeOptions
            });
        });
        this.togglePopup();
    }
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}