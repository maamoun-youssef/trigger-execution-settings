import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LBL_FieldSelectorInput_AllResources from '@salesforce/label/c.LBL_FieldSelectorInput_AllResources';
import LBL_FieldSelectorInput_NoFieldsMatch from '@salesforce/label/c.LBL_FieldSelectorInput_NoFieldsMatch';
import LBL_FieldSelectorInput_SearchField from '@salesforce/label/c.LBL_FieldSelectorInput_SearchField';
import LBL_True from '@salesforce/label/c.LBL_True';
import LBL_False from '@salesforce/label/c.LBL_False';

const TYPE_ICON = {
    Address: 'utility:location', AnyType: 'utility:custom_apps', Base64: 'utility:attach', Boolean: 'utility:check',
    Combobox: 'utility:picklist_type', Currency: 'utility:currency', Date: 'utility:date_input', DateTime: 'utility:date_time',
    Double: 'utility:number_input', Email: 'utility:email', EncryptedString: 'utility:lock', Id: 'utility:key',
    Integer: 'utility:number_input', Location: 'utility:location', Long: 'utility:number_input', MultiPicklist: 'utility:picklist_type',
    Percent: 'utility:percent', Phone: 'utility:phone_portrait', Picklist: 'utility:picklist_type', Reference: 'utility:record_lookup', String: 'utility:text',
    TextArea: 'utility:textarea', Time: 'utility:clock', Url: 'utility:link', DEFAULT_ICON: 'utility:custom_apps'
};

export default class FieldSelectorInput extends LightningElement {

    @api objectName;
    @api value;

    @track currentObject;
    FIELDS_CACHE = {}
    @track isLoading = false;
    @track navStack = [];
    previousField = null;
    @track selectedField = null;
    @track isOpen = false;
    @track fields = [];
    @track searchTerm = '';
    @track pickValFieldName;
    labels = {
        LBL_FieldSelectorInput_AllResources,
        LBL_FieldSelectorInput_NoFieldsMatch,
        LBL_FieldSelectorInput_SearchField,
        LBL_True,
        LBL_False
    }
    action = '';
    
    booleanOptions = [
        { label: this.labels.LBL_True, value: 'TRUE' },
        { label: this.labels.LBL_False, value: 'FALSE' }
    ];


    connectedCallback() {
        if (this.objectName) {
            this.loadObject(this.objectName);
        }
        this._boundOutsideClick = (event) => {
            if (!this.isOpen) return;
            const path = event.composedPath ? event.composedPath() : [];
            if (!path.includes(this.template.host)) {
                this.isOpen = false;
                if (!this.selectedField && this.previousField) {
                    this.selectedField = this.previousField;
                    this.loadObject(this.objectName);
                    this.searchTerm = '';
                    this.previousField = null;
                }
            }
        };
        document.addEventListener('click', this._boundOutsideClick);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._boundOutsideClick);
    }

    loadObject(objectName) {
        this.currentObject = objectName;
    }

    @wire(getObjectInfo, { objectApiName: '$currentObject' }) currentObjectInfo({ error, data }) {
        if (data) {
            if (!this.FIELDS_CACHE.hasOwnProperty(this.currentObject)) {
                this.FIELDS_CACHE[this.currentObject] = [];
                // Fill fields
                for (let field of Object.values(data.fields)) {
                    let fieldW = {
                        apiName: field.apiName,
                        label: field.label,
                        type: field.dataType.toLowerCase() === 'reference' ? (field.referenceToInfos && field.referenceToInfos.length > 0 ? field.dataType : 'String') : field.dataType,
                        typeIcon: TYPE_ICON[field.dataType] || TYPE_ICON.DEFAULT_ICON,
                        isReference: field.dataType.toLowerCase() === 'reference' ? (field.referenceToInfos && field.referenceToInfos.length > 0 ? true : false) : false,
                        referenceTo: field.dataType.toLowerCase() === 'reference' && field.referenceToInfos && field.referenceToInfos.length > 0 ? field.referenceToInfos[0].apiName : '',
                        relationshipName: field.relationshipName || null
                    }
                    this.FIELDS_CACHE[this.currentObject].push(fieldW);
                }
                if (this.value && !this.selectedField) {
                    this.buildNavFromPath();
                }
            }
            this.fields = this.FIELDS_CACHE[this.currentObject];
            this.isLoading = false;
        } else if (error) {
            console.error('currentObjectInfo error:', error);
            this.fields = [];
            this.isLoading = false;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: '$pickValFieldName' }) wiredPicklistValues({ error, data }) {
        if (data) {
            const options = data.values.map(option => ({ label: option.label, value: option.value }));
            this.selectedField.picklistValues = this.selectedField.isMultiPicklist ? JSON.stringify(options) : options;
            if (this.action === 'restore') {
                this.dispatchEvent(new CustomEvent('fieldrestore', { detail: { ...this.selectedField } }));
            } else {
                this.dispatchEvent(new CustomEvent('fieldselect', {
                    detail: { ...this.selectedField }
                }));
            }
        } else if (error) {
            console.error('currentObjectInfo error:', error);
            this.isLoading = false;
        }
    }

    get comboboxClass() {
        return [
            'slds-combobox',
            'slds-dropdown-trigger',
            'slds-dropdown-trigger_click',
            this.isOpen ? 'slds-is-open' : ''
        ].join(' ');
    }

    get filteredFields() {
        const term = (this.searchTerm || '').trim().toLowerCase();
        return (!term ? this.fields : this.fields.filter(field => field.label.toLowerCase().includes(term) || field.apiName.toLowerCase().includes(term)));
    }

    handleInputClick(event) {
        event.stopPropagation();
        this.isOpen = true;
    }

    handleSearchInput(event) {
        this.searchTerm = (event.target.value || '').trim().toLowerCase();
    }

    handleBreadcrumbClick(event) {
        event.preventDefault();
        event.stopPropagation();
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        if (idx === -1) {
            this.navStack = [];
            this.loadObject(this.objectName)
        } else {
            this.navStack = this.navStack.slice(0, idx + 1);
            this.loadObject(this.navStack[idx].toObjectName)
        }
        this.searchTerm = '';
        this.inputFocus();
    }

    handleFieldClick(event) {
        event.stopPropagation();
        const index = event.currentTarget.dataset.index;
        let field = this.filteredFields[index];
        if (field.isReference === true && field.referenceTo) {
            this.navStack.push({
                fromObjectName: this.currentObject,
                toObjectName: field.referenceTo,
                fieldLabel: field.label,
                fieldApiName: field.apiName,
                relationshipName: field.relationshipName
            })
            if (this.currentObject != field.referenceTo) {
                this.isLoading = true;
            }
            this.currentObject = field.referenceTo;
            this.searchTerm = '';
            this.inputFocus();
        } else {
            this.selectField(field);
        }
    }

    handleFieldClear(event) {
        event.stopPropagation();
        this.selectedField = null;
        this.navStack = [];
        this.searchTerm = '';
        this.loadObject(this.objectName);
        this.dispatchEvent(new CustomEvent('fieldselect', { detail: {} }));
        this.inputFocus();
    }

    inputFocus() {
        setTimeout(() => {
            this.isOpen = true;
            const input = this.template.querySelector('lightning-input[data-id="searchInput"]');
            if (input) input.focus();
        }, 10);
    }

    buildSelectedField(field, action) {
        this.action = action;
        const pathParts = [...this.navStack.map(n => n.relationshipName), field.apiName];
        const labelParts = [...this.navStack.map(n => n.fieldLabel), field.label];
        const type = field.apiName.toLowerCase() == 'id' ? 'Reference' : field.type;
        this.selectedField = {
            fieldName: pathParts.join('.'),
            fieldLabel: labelParts.join(' > '),
            fieldType: type,
            isPicklist: type === 'Picklist' || type === 'Boolean',
            isMultiPicklist: type === 'MultiPicklist',
            isReference: type === 'Reference',
        };
        if (this.selectedField.isReference) {
            this.selectedField.previousObject = this.navStack.length > 0 ? this.navStack[this.navStack.length - 1].fromObjectName : this.objectName;
            let lastPathField = this.navStack.length > 0 ? this.navStack[this.navStack.length - 1].relationshipName : '';
            this.selectedField.refFieldName = lastPathField.endsWith('__r') ? lastPathField.replace(/__r$/, '__c') : lastPathField + 'Id';
        }
        if (field.type === 'Picklist' || field.type === 'MultiPicklist') {
            this.pickValFieldName = `${this.currentObject}.${field.apiName}`;
        } else if (field.type == 'Boolean') {
            this.selectedField.picklistValues = this.booleanOptions
        } else {
            this.selectedField.picklistValues = [];
        }
    }

    selectField(field) {
        this.isOpen = false;
        this.searchTerm = '';
        this.buildSelectedField(field, 'select');
        if (field.type !== 'Picklist' && field.type !== 'MultiPicklist') {
            this.dispatchEvent(new CustomEvent('fieldselect', {
                detail: { ...this.selectedField }
            }));
        }
    }

    handlePillClick(event) {
        event.stopPropagation();
        this.previousField = this.selectedField;
        this.searchTerm = this.selectedField.fieldName.split('.').at(-1);
        this.selectedField = null;
        this.inputFocus();
    }

    buildNavFromPath() {
        this.navStack = [];
        console.log('Building nav from path:', this.value);
        const relationships = this.value.split('.');
        let type;
        this.currentObject = this.objectName;
        for (const relName of relationships) {
            let cached = this.FIELDS_CACHE[this.currentObject];
            if (!cached) return;
            const field = cached.find(f => f.relationshipName === relName || f.apiName == relName);
            if (!field) return;
            type = field.type;
            if (field.isReference && !this.FIELDS_CACHE.hasOwnProperty(field.referenceTo)) {
                this.currentObject = field.referenceTo;
                return;
            }
            this.navStack.push({
                fromObjectName: this.currentObject,
                toObjectName: field.referenceTo,
                fieldLabel: field.label,
                fieldApiName: field.apiName,
                relationshipName: relName
            });
            this.currentObject = field.referenceTo || this.currentObject;
        }
        this.navStack.splice(-1, 1);
        const field = this.FIELDS_CACHE[this.currentObject].find(f => f.apiName === relationships.at(-1) || f.relationshipName === relationships.at(-1));
        this.buildSelectedField(field, 'restore');
        if (field.type !== 'Picklist' && field.type !== 'MultiPicklist') {
            this.dispatchEvent(new CustomEvent('fieldrestore', {
                detail: { ...this.selectedField }
            }));
        }
    }
}