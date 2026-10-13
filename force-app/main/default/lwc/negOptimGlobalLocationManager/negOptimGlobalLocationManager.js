//**
/* @author ULiT
/* @date 29-07-2024
/* @description 
/*******************************************************************************************************************************************
/*/
import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Toast from 'lightning/toast';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import GLOBAL_LOCATION_OBJECT from '@salesforce/schema/GlobalLocation__c';
import {
    subscribe,
    unsubscribe,
    onError
} from 'lightning/empApi';
//OBJECTS
import GlobalLocation__c from '@salesforce/schema/GlobalLocation__c';
import Supplier__c from '@salesforce/schema/Supplier__c';
import GL_Supplier__c from '@salesforce/schema/GlobalLocation__c.Supplier__c';
import GL_BusinessUnit__c from '@salesforce/schema/GlobalLocation__c.BusinessUnit__c';
import GL_Status__c from '@salesforce/schema/GlobalLocation__c.Status__c';
import GL_Functions__c from '@salesforce/schema/GlobalLocation__c.Functions__c';
import GL_Name from '@salesforce/schema/GlobalLocation__c.Name';
import GL_GLN__c from '@salesforce/schema/GlobalLocation__c.GLN__c';
import GL_LongName__c from '@salesforce/schema/GlobalLocation__c.LongName__c';
import GL_CompanyName__c from '@salesforce/schema/GlobalLocation__c.CompanyName__c';
import GL_Country__c from '@salesforce/schema/GlobalLocation__c.Country__c';
import GL_ReferenceLanguage__c from '@salesforce/schema/GlobalLocation__c.ReferenceLanguage__c';
import GL_StatusBDate__c from '@salesforce/schema/GlobalLocation__c.StatusBDate__c';
import GL_StatusEdate__c from '@salesforce/schema/GlobalLocation__c.StatusEdate__c';
// LABELS
import LBL_Add_GL from "@salesforce/label/c.LBL_Add_GL";
import LBL_Title_Global_Location from "@salesforce/label/c.LBL_Title_Global_Location";
import LBL_Inactive from "@salesforce/label/c.LBL_Inactive";
import LBL_Active_GL from "@salesforce/label/c.LBL_Active_GL";
import LBL_All from "@salesforce/label/c.LBL_All";
//APEX
import getData from "@salesforce/apex/NegOptimGlobalLocationManagerCtrl.getData";
import saveData from "@salesforce/apex/NegOptimGlobalLocationManagerCtrl.saveData";
import upsertGlobalLocation from "@salesforce/apex/NegOptimGlobalLocationManagerCtrl.upsertGlobalLocation";

    const showNotification = (self, title, message, variant, mode) => {
    Toast.show({
        label: title,
        message: message,
        variant: variant,
        mode: mode
    }, self);
}

export default class NegOptimGlobalLocationManager extends NavigationMixin(LightningElement) {
    @track labels = {
        LBL_Add_GL,
        LBL_Title_Global_Location,
        LBL_Inactive,
        LBL_Active_GL,
        LBL_All
    };
    @api selectMode = 'false';
    //editMode;
    @track isLoading = false;
    @track globalLocations;
    @track globalLocationsAll;
    @track stickersSettings;
    @api supplierId;
    @api recordId;
    @api businessUnit;
    @track readOnly;
    @track objectApiName;
    @track prefix;
    subscription = {};
    @track channelName;
    createdRecord = false;

    @track showModal = false;
    @track modalMode = 'create';
    @track defaultSupplierValue;
    @track editRecordId;
    @track modalFields = [];

    glObjectApiName = GlobalLocation__c.objectApiName;
    nameField = GL_Name.fieldApiName;
    glnField = GL_GLN__c.fieldApiName;
    longNameField = GL_LongName__c.fieldApiName;
    companyNameField = GL_CompanyName__c.fieldApiName;
    supplierField = GL_Supplier__c.fieldApiName;
    businessUnitField = GL_BusinessUnit__c.fieldApiName;
    countryField = GL_Country__c.fieldApiName;
    referenceLanguageField = GL_ReferenceLanguage__c.fieldApiName;
    functionsField = GL_Functions__c.fieldApiName;
    statusField = GL_Status__c.fieldApiName;
    statusBDateField = GL_StatusBDate__c.fieldApiName;
    statusEdateField = GL_StatusEdate__c.fieldApiName;

    @track fieldsMetadata = {};
    objectPicklistFieldValues = {};
    @wire(getPicklistValuesByRecordType, { objectApiName: GLOBAL_LOCATION_OBJECT, recordTypeId: '012000000000000AAA' })
    picklistValuesByRecordType({ data, error }) {
        this.objectPicklistFieldValues = data?.picklistFieldValues;
    }
    @wire(getObjectInfo, { objectApiName: GLOBAL_LOCATION_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            const fields = data.fields;
            const metadata = {};
            for (let fieldName in fields) {
                const field = fields[fieldName];
                metadata[field.apiName] = field;
            }
            this.fieldsMetadata = metadata;
        } else if (error) {
            console.error(error);
        }
    }

    async initializeFields(mode = 'create', recordId = null) {
        const isEditMode = mode === 'edit';
        this.modalFields = [
            { fieldApiName: this.nameField, disabled: false },
            { fieldApiName: this.glnField, disabled: false },
            { fieldApiName: this.longNameField, disabled: false },
            { fieldApiName: this.companyNameField, disabled: false },
            { fieldApiName: this.supplierField, value: this.defaultSupplierValue, disabled: true },
            { fieldApiName: this.businessUnitField, disabled: false },
            { fieldApiName: this.countryField, disabled: false },
            { fieldApiName: this.referenceLanguageField, disabled: false },
            { fieldApiName: this.functionsField, disabled: false },
            { fieldApiName: this.statusField, disabled: false },
            { fieldApiName: this.statusBDateField, disabled: false },
            { fieldApiName: this.statusEdateField, disabled: false }
        ];
        this.modalMode = mode;
        this.editRecordId = recordId;
        this.formData = {
            [GL_Supplier__c.fieldApiName]: this.defaultSupplierValue
        };

        try {
            this.modalFields = [
                {
                    fieldApiName: this.nameField,
                    value: '',
                    disabled: false,
                    isString: true
                },
                {
                    fieldApiName: this.glnField,
                    value: '',
                    disabled: false,
                    isString: true
                },
                {
                    fieldApiName: this.longNameField,
                    value: '',
                    disabled: false,
                    isString: true
                },
                {
                    fieldApiName: this.companyNameField,
                    value: '',
                    disabled: false,
                    isString: true
                },
                {
                    fieldApiName: this.supplierField,
                    // value: this.defaultSupplierValue || '',
                    value: this.defaultSupplierValue,
                    disabled: true,
                    isLookup: true
                },
                {
                    fieldApiName: this.businessUnitField,
                    value: '',
                    disabled: false,
                    isLookup: true
                },
                {
                    fieldApiName: this.countryField,
                    value: '',
                    disabled: false,
                    isLookup: true
                },
                {
                    fieldApiName: this.referenceLanguageField,
                    value: '',
                    disabled: false,
                    isPicklist: true,
                },
                {
                    fieldApiName: this.functionsField,
                    value: [],
                    disabled: false,
                    isMultiPicklist: true,
                },
                {
                    fieldApiName: this.statusField,
                    value: '',
                    disabled: false,
                    isPicklist: true,
                },
                {
                    fieldApiName: this.statusBDateField,
                    value: '',
                    disabled: false,
                    isDate: true
                },
                {
                    fieldApiName: this.statusEdateField,
                    value: '',
                    disabled: false,
                    isDate: true
                }
            ].map(it => {
                it.label = this.fieldsMetadata[it.fieldApiName]?.label || it.label;
                it.options = this.objectPicklistFieldValues?.[it.fieldApiName]?.values;
                it.isLookup = this.fieldsMetadata[it.fieldApiName]?.dataType == 'Reference';
                if (it.isLookup) {
                    it.objectApiName = this.fieldsMetadata[it.fieldApiName].referenceToInfos[0].apiName;
                }
                return it;
            });
            if (isEditMode && recordId) {
                const record = this.globalLocationsAll.find(gl => gl.Id === recordId);
                if (record) {
                    this.modalFields.forEach(field => {
                        if ((field.fieldApiName === this.functionsField) && record[field.fieldApiName]) {
                            field.value = record[field.fieldApiName].split(';');
                        } else {
                            field.value = record[field.fieldApiName] || field.value;
                        }
                        this.formData[field.fieldApiName] = field.value;
                    });
                }
            }
        } catch (error) {
            console.error('Error initializing fields:', error);
            // this.showNotification('Error', 'Failed to load field metadata', 'error');
            showNotification(this, 'Error', 'Failed to load field metadata', 'error', 'dismissable');
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event?.detail?.value || event?.target?.value;
        this.formData[fieldName] = value;
        const field = this.modalFields.find(f => f.fieldApiName === fieldName);
        if (field) {
            field.value = value;
        }
    }

    //LOAD
    loadData() {
        this.isLoading = true;
        //this.editMode = this.selectMode === 'false';
        getData({
            recordId: this.recordId
        }).then((result) => {
            this.afterload(result);
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            // this.showNotification('Error', error.body?.message, 'error');
            showNotification(this, 'Error', error.body?.message, 'error', 'dismissable');
        });
    }

    afterload(result) {
        let data = JSON.parse(result);
        this.defaultSupplierValue = data.supplierId || this.recordId;;
        this.picklistLabelsMap = data.picklistLabelsMap;
        this.fieldsMap = data.fieldsMap;
        this.objectApiName = data.objectName;
        this.dataPosition = [];
        this.prefix = data.prefix;
        // this.readOnly = data.isPortalUser;
        this.readOnly = data.isPortalUser && !data.isOrgAdmin;
        this.isOrgAdmin = data.isOrgAdmin;
        this.channelName = '/data/' + this.prefix + 'GlobalLocation__ChangeEvent';
        let status = GL_Status__c.fieldApiName;
        let functionsStr = GL_Functions__c.fieldApiName;
        let translatedFunction = [];

        for (let key in this.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + functionsStr]) {
            translatedFunction.push({ value: key, label: this.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + functionsStr][key] })
        }
        let functionColorMap = {
            'Administrative': '#78BAFC',  // Darker blue
            'InvoiceTo': '#ff7575',      // Darker red
            'DeliverTo': '#ffffa4',      // Duller yellow
            'OrderTo': '#bdffbd',        // Darker green
            'PaidTo': '#ffc890',         // Darker orange
            'InvoiceBy': '#ffb7db',      // Darker pink
            'DeliverBy': '#ffadff',      // Darker magenta
            'OrderBy': '#cd9bff',        // Darker purple
            'PaidBy': '#a0dcdc'          // Duller cyan
        };
        this.stickersSettings = data.stickerSettings;
        data.globalLocations.sort((a, b) => {
            if (a[status] === 'Open' && b[status] !== 'Open') {
                return -1; // 'Open' should come first
            }
            if (a[status] !== 'Open' && b[status] === 'Open') {
                return 1; // 'Open' should come first
            }
            return 0; // They are equal, no sorting needed
        });
        data.globalLocations.forEach(element => {
            element.Status__c = element[status];
            element.Functions__c = element[functionsStr];
            let tempStickerSettings = this.stickersSettings.map(pair =>
                pair.map(fieldName => ({ fieldName }))
            );;
            element?.Status__c == 'Open' ? element.color = 'green' : element.color = 'grey';
            element?.Status__c == 'Open' ? element.currentstatus = 'active' : element.currentstatus = 'inactive';
            element.isActivated = element.currentstatus == 'active';
            element?.Status__c == 'Open' ? element.statusDivStyle = 'background: #E8F3E8; color: #8cc58a;' : element.statusDivStyle = 'background:#f3e8e8;color: #ba0517;';
            let functionColorList = [];
            if (element.Functions__c) {
                if (element.Functions__c.includes('Administrative')) {
                    let obj = {};
                    functionColorMap['Administrative'] != '#FFFF00' ?
                        obj.divStyle = ' background: ' + functionColorMap['Administrative'] + ';' :
                        obj.divStyle = ' background: ' + functionColorMap['Administrative'] + ';';
                    let found = translatedFunction.find(el => el.value === 'Administrative');
                    obj.functionText = found.label;
                    functionColorList.push(obj)
                }
                if (element.Functions__c.includes('InvoiceTo')) {
                    let obj = {};
                    functionColorMap['InvoiceTo'] != '#FFFF00' ?
                        obj.divStyle = ' background: ' + functionColorMap['InvoiceTo'] + ';' :
                        obj.divStyle = ' background: ' + functionColorMap['InvoiceTo'] + ';';
                    let found = translatedFunction.find(el => el.value === 'InvoiceTo');
                    obj.functionText = found.label;
                    functionColorList.push(obj)
                }
                if (element.Functions__c.includes('DeliverTo')) {
                    let obj = {};
                    functionColorMap['DeliverTo'] != '#FFFF00' ?
                        obj.divStyle = ' background: ' + functionColorMap['DeliverTo'] + ';' :
                        obj.divStyle = ' background: ' + functionColorMap['DeliverTo'] + ';';
                    let found = translatedFunction.find(el => el.value === 'DeliverTo');
                    obj.functionText = found.label;
                    functionColorList.push(obj)
                }
            }
            element.Functions__c?.split(';').sort().forEach(item => {
                if (item != 'Administrative' && item != 'InvoiceTo' && item != 'DeliverTo' && functionColorList.length < 3) {
                    let obj = {};
                    functionColorMap[item] != '#FFFF00' ?
                        obj.divStyle = ' background: ' + functionColorMap[item] + ';' :
                        obj.divStyle = ' background: ' + functionColorMap[item] + ';';
                    let found = translatedFunction.find(el => el.value === item);
                    obj.functionText = found.label;
                    functionColorList.push(obj)
                }
            });
            element.functionColorList = functionColorList;
            tempStickerSettings.forEach(pair => {
                pair.forEach(obj => {
                    if (obj.fieldName && obj.fieldName != '') {
                        obj.value = element[obj.fieldName];
                        obj.label = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].label;
                        this.buildFieldWrapper(element, obj);
                    }
                });
            });
            element.stickersSettingsData = tempStickerSettings;
        });
        this.globalLocations = data.globalLocations;
        this.globalLocationsAll = JSON.parse(JSON.stringify(this.globalLocations));
        this.isLoading = false;
    }

    buildFieldWrapper(element, obj) {
        obj.hasField = obj && obj.fieldName && obj.fieldName != '';
        obj.fieldLabel = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].label;
        obj.fieldValue = element[obj.fieldName];
        obj.scale = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].scale;
        obj.isEmail = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'email';
        obj.isPhone = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'phone';
        obj.isNumberField = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'number';
        obj.isReference = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'reference';
        obj.isDate = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'date' || this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'datetime';
        obj.isPicklist = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'picklist';
        obj.isBoolean = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'boolean';
        obj.isText = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'string';
        obj.type = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type;
        obj.isRequired = !this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].nillable && this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type != 'boolean';
        if (this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'reference') {
            obj.link = '/' + obj.fieldValue;
            if (obj.fieldName.endsWith('Id')) {
                let fieldName = obj.fieldName.replace('Id', '');
                let output = element[fieldName]?.Name;
                obj.fieldValue = output;
            } else {
                obj.fieldValue = element[obj.fieldName.replace('__c', '__r')]?.Name;
            }
            obj.referenceTo = this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].referenceTo[0];
            obj.recordIdValue = element[obj.fieldName];
        }
        if (this.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'picklist') {
            obj.fieldOutputValue = this.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + obj.fieldName][field.fieldValue];
            let options = [];
            for (let key in this.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + obj.fieldName]) {
                options.push({ label: key, value: this.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + obj.fieldName][key] })
            }
            field.fieldOptions = options;
        }
    }

    showActiveGlobalLocations(event) {
        this.globalLocations = this.globalLocationsAll.filter(element => element.Status__c == 'Open');
    }
    showInactiveGlobalLocations(event) {
        this.globalLocations = this.globalLocationsAll.filter(element => element.Status__c != 'Open');

    }
    showAllGlobalLocations(event) {
        this.globalLocations = JSON.parse(JSON.stringify(this.globalLocationsAll));

    }


    filterMode = 'All'
    toggleActive(event) {
        let activeBtn = this.template.querySelector('.active-btn');
        if (this.filterMode == 'Active') {
            this.filterMode = 'All';
            activeBtn.style.backgroundColor = 'white';
            activeBtn.style.color = '#8cc58a';
            this.showAllGlobalLocations(event);
        } else {
            this.filterMode = 'Active';
            activeBtn.style.backgroundColor = '#8cc58a';
            activeBtn.style.color = 'white';
            let inactiveBtn = this.template.querySelector('.inactive-btn');
            inactiveBtn.style.backgroundColor = 'white';
            inactiveBtn.style.color = '#ba0517';
            this.showActiveGlobalLocations(event);
        }
    }
    toggleInactive(event) {
        let inactiveBtn = this.template.querySelector('.inactive-btn');
        if (this.filterMode == 'Inactive') {
            this.filterMode = 'All';
            inactiveBtn.style.backgroundColor = 'white';
            inactiveBtn.style.color = '#ba0517';
            this.showAllGlobalLocations(event);
        } else {
            this.filterMode = 'Inactive';
            inactiveBtn.style.backgroundColor = '#ba0517';
            inactiveBtn.style.color = 'white';
            let activeBtn = this.template.querySelector('.active-btn');
            activeBtn.style.backgroundColor = 'white';
            activeBtn.style.color = '#8cc58a';
            this.showInactiveGlobalLocations(event);
        }
    }

    async createNewRecord() {
        // if (this.objectApiName == Supplier__c.objectApiName) {
        //     this.defaultSupplierValue = this.recordId;
        // } else {
        //     this.defaultSupplierValue = null;
        // }
        await this.initializeFields('create');
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.editRecordId = null;
        this.modalMode = 'create';
        this.formData = {};
    }

    handleModalSubmit() {
        let isValid = true;
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-dual-listbox');
        inputs.forEach(input => {
            const field = this.modalFields.find(f => f.fieldApiName === input.dataset.field);
            if (field && field.required && !this.formData[field.fieldApiName]) {
                isValid = false;
                input.setCustomValidity('This field is required');
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        });

        if (!isValid) {
            // this.showNotification('Error', 'Please fill in all required fields', 'error');
            showNotification(this, 'Error', 'Please fill in all required fields', 'error', 'dismissable');
            return;
        }

        let glData = {
            [GL_Supplier__c.fieldApiName]: this.defaultSupplierValue,
        };
        if (this.modalMode === 'edit' && this.editRecordId) {
            glData.Id = this.editRecordId;
        }
        this.modalFields.forEach(field => {
            const value = this.formData[field.fieldApiName];
            if (field.isMultiPicklist && Array.isArray(value)) {
                glData[field.fieldApiName] = value.join(';');
            } else {
                glData[field.fieldApiName] = value;
            }
        });

        this.isLoading = true;
        console.log("🚀 ~ NegOptimGlobalLocationManager ~ handleModalSubmit ~ glData:", glData);
        console.log("JSON.stringify(glData)", JSON.stringify(glData));
        upsertGlobalLocation({ globalLocationJson: JSON.stringify(glData) })
            .then((result) => {
                const response = JSON.parse(result);
                this.showModal = false;
                this.editRecordId = null;
                this.formData = {};
                this.createdRecord = true;
                // this.showNotification('Success', response.message, 'success');
                showNotification(this, 'Success', response.message, 'success', 'dismissable');
                this.loadData();
            })
            .catch((error) => {
                console.error('Error saving Global Location:', error);
                // this.showNotification('Error', error.body?.message || 'An error occurred', 'error');
                showNotification(this, 'Error', error.body?.message || 'An error occurred', 'error', 'dismissable');
                this.isLoading = false;
            });
    }

    get modalTitle() {
        return this.modalMode === 'create' ? this.labels.LBL_Add_GL : 'Edit Global Location';
    }

    handleCheckGl(event) {
        try {
            const selectedGlId = event.detail.value;
            const checkGLEvent = new CustomEvent('checkgl', {
                detail: {
                    value: selectedGlId
                }
            });
            //Dispatch Event
            this.dispatchEvent(checkGLEvent);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');

        }
    }

    async handleEditSticker(event) {
        try {
            let stickerId = event.detail.value;
            if (stickerId) {
                await this.initializeFields('edit', stickerId);
                this.showModal = true;
            }
        } catch (err) {
            console.error(err);
        }
    }

    switchStickerStatus(event) {
        try {
            let stickerId = event.detail.stickerid;
            let index = event.detail.index;
            let currentstatus = event.detail.currentstatus;
            // If the user clicks "OK", proceed with the action
            let toDeactivate;
            // Add your logic to switch the status here
            if (currentstatus == 'active') {
                this.globalLocations[index].Status__c = 'Closed';
                this.globalLocations[index].statusDivStyle = 'background:#f3e8e8;color: #ba0517;';
                this.globalLocations[index].currentstatus = 'inactive';
                toDeactivate = true;
            } else {
                this.globalLocations[index].Status__c = 'Open';
                this.globalLocations[index].statusDivStyle = 'background: #E8F3E8; border-color: #8cc58a;';
                this.globalLocations[index].Status__c = 'Active';
                this.globalLocations[index].statusDivStyle = 'background: #E8F3E8; color: #8cc58a;';
                this.globalLocations[index].currentstatus = 'active';
                toDeactivate = false;
            }
            saveData({
                // supplierId: this.recordId,
                supplierId: this.defaultSupplierValue,
                globalLocationId: stickerId,
                toDeactivate: toDeactivate
            }).then((result) => {
                this.createdRecord = true;
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                // this.showNotification('Error', error.body?.message, 'error');
                showNotification(this, 'Error', error.body?.message, 'error', 'dismissable');
            });
        } catch (err) {
            console.error(err);
        }
    }

    //LIFECYCLE
    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBodyDiv = this.template.querySelector(".tile-container");
            if (pageHeader != null && mainContainer != null && pageBodyDiv != null) {
                pageBodyDiv.style.height = mainContainer.style.height - pageHeader.offsetHeight - 10 + "px";
            }

        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    // Handles subscribe button click
    handleSubscription() {
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            this.loadData();
        };
        if (this.channelName) {
            // Invoke subscribe method of empApi. Pass reference to messageCallback
            subscribe(this.channelName, -1, messageCallback.bind(this)).then((response) => {
                // Response contains the subscription information on subscribe call
                this.subscription = response;
            });
        }
        onError(error => {
            console.error('Server Error--->' + JSON.stringify(error));
        });
    }
    connectedCallback() {
        this.loadData();
    }
    disconnectedCallback() {
        if (this.channelName) {
            unsubscribe(this.subscription, response => {
                console.log('Unsubscribed Channel');
            });
        }
        this.createdRecord = false;
    }
    renderedCallback() {
        this.handleSubscription();
        try {
            // setTimeout(() => {
            this.setPageSize();
            // }, 200);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');

        }
    }
    // showNotification(title, message, variant) {
    //     const evt = new ShowToastEvent({
    //         title: title,
    //         message: message,
    //         variant: variant,
    //         mode: 'dismissable',
    //         duration: 3000
    //     });
    //     this.dispatchEvent(evt);
    //     /*setTimeout(() => {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: title,
    //             message: message,
    //             variant: variant,
    //             mode: 'dismissable',
    //             duration: 1
    //         }));
    //     }, 5000);*/
    // }

}