/**
 * ComboBoxInput.js
 * Refactored with pluggable render modes
 */
import { LightningElement, api, track } from 'lwc';
import getPicklistOptions from '@salesforce/apex/ComboboxInputController.getPicklistOptions';
//import { RENDER_MODES } from './comboboxInputService'
import LBL_Ok from "@salesforce/label/c.LBL_Ok";

const RENDER_MODES = {
    pills: {
        showPills: true,
        getDisplayValue(component) {
            return component.searchTerm;
        },
        handleSearch(component, event) {
            component.searchTerm = event.target.value || '';
            component.isDropdownOpen = true;
            return component.searchTerm;
        },
        handleFocus(component) {
            component.isDropdownOpen = true;
        },
        handleBlur(component) {
            component.isDropdownOpen = false;
        }
    },
    input: {
        showPills: false,
         getDisplayValue(component) {
            return component.isFocused
                ? component.searchTerm
                : component.selectedLabels.join(', ');
        },
        handleSearch(component, event) {
            const fullText = event.target.value || '';
            const parts = fullText.split(',');
            const lastPart = parts[parts.length - 1];
            component.searchTerm = lastPart.trim();
            component.isDropdownOpen = true;
        },
        handleFocus(component) {
            component.searchTerm = '';
            component.isDropdownOpen = true;
        },
        handleBlur(component) {
            component.isFocused = false;
            component.searchTerm = '';
            component.isDropdownOpen = false;
        }
    }
};
export default class CustomCombobox extends LightningElement {
    @api label;
    @api placeholder = 'Search...';
    @api isMultiSelect = false;
    @api disabled = false;
    @api readOnly = false;
    @api required = false;
    @api helpText = '';
    @api optionRenderMode = 'pills';
    @api showCheckbox = false;
    @api defaultValue;
    @api defaultValues = [];
    @api object; // Object API Name
    @api field;  // Field API Name
    @api
    get options() {
        if (!this.searchTerm) {
            return this._options;
        }
        const term = this.searchTerm.toLowerCase();
        return this._options.filter(opt =>
            opt.label.toLowerCase().includes(term)
        );
    }
    set options(value) {
        this._options = Array.isArray(value) ? [...value] : [];
        this.initializeComponent();
    }
    @api
    get value() {
        const values = Array.from(this.selectedValuesSet);
        return this.isMultiSelect ? values : (values[0] ?? null);
    }
    @track _options = [];
    @track searchTerm = '';
    @track isDropdownOpen = false;
    @track isFocused = false;
    @track hasConfigError = false;
    @track selectedValuesSet = new Set();
    @track Label = {
        LBL_Ok
    };

    /* ===========================
       lifecycle hooks
    ============================ */
    connectedCallback() {
        this.validateInputs();
        if(!this.hasConfigError){
            this.initializeComponent();
        }
    }

    validateInputs() {
        const hasOptions = this._options && this._options.length > 0;
        const hasObjectField = this.object && this.field;
        if (hasOptions && hasObjectField) {
            this.failConfig('Provide either "options" OR "object + field", not both.');
            return;
        }
    }
    initializeComponent() {
        this.normalizeOptions();
        this.applyDefaultSelection();
        this.applyUiState();
        this.dispatchChange();
    }

    failConfig(message) {
        this.hasConfigError = true;
        console.error(`[CustomCombobox CONFIG ERROR]: ${message}`);
    }
    
    normalizeOptions() {
        this._options = this._options
            .filter(opt => opt && opt.value !== undefined)
            .map(opt => ({
                label: opt.label !== undefined ? String(opt.label) : String(opt.value),
                value: opt.value,
                //isSelected: !!opt.isSelected
                isSelected: this.selectedValuesSet.has(String(opt.value))
            }));
    }
    applyDefaultSelection() {
        if (this.isMultiSelect) {
            const defaults = Array.isArray(this.defaultValues) ? this.defaultValues.map(String) : [];
            this._options = this._options.map(opt => ({
                ...opt,
                isSelected: defaults.includes(String(opt.value))
            }));
            this.selectedValuesSet = new Set(defaults);
            this.searchTerm = '';
        } else {
            const defaultVal = this.defaultValue != null ? String(this.defaultValue) : null;
            this._options = this._options.map(opt => ({
                ...opt,
                isSelected: defaultVal && String(opt.value) === defaultVal
            }));
            const selected = this._options.find(opt => opt.isSelected);
            this.selectedValuesSet = defaultVal ? new Set([defaultVal]) : new Set();
            this.searchTerm = selected ? selected.label : '';
        }
    }
    applyUiState() {
        this._options = this._options.map(opt => ({
            ...opt,
            itemClass:
                `slds-media slds-listbox__option ` +
                `slds-listbox__option_plain slds-media_center ` +
                `${opt.isSelected ? 'slds-is-selected' : ''}`
        }));
    }
    /* ===========================
       Event Dispatcher
       ============================ */
    /* -------------------------
       selection management
       ------------------------- */
    get displayOptions() {
        return !this.hasConfigError && this.options.length;
    }
    get dropdownClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${
            this.isDropdownOpen ? 'slds-is-open' : ''
        }`;
    }
    get displayValue() {
        if (!this.isMultiSelect) {
            return this.searchTerm;
        }
        return this.currentMode.getDisplayValue(this);
    }
    handleSelect(event) {
       // if(this.showCheckbox) return;
        const value = event.currentTarget?.dataset?.value;
        this.executeSelection(value);
    }
    executeSelection(value) {
        if (this.disabledState || value == null) return;
        const key = String(value);
        if (this.isMultiSelect) {
            if (this.selectedValuesSet.has(key)) {
                this.selectedValuesSet.delete(key);
            } else {
                this.selectedValuesSet.add(key);
            }
            this._options = this._options.map(opt =>
                String(opt.value) === String(value)
                    ? { ...opt, isSelected: !opt.isSelected }
                    : opt
            );
            this.isDropdownOpen = true;
        } else {
            const clicked = this.selectedValuesSet.has(key);
            if (clicked) return;
            this.selectedValuesSet = new Set([String(value)]);
            this._options = this._options.map(opt => ({
                ...opt,
                isSelected: String(opt.value) === String(value)
            }));
            const selected = this._options.find(opt => opt.isSelected);
            this.searchTerm = selected ? selected.label : '';
            this.isDropdownOpen = false;
        }
        this.applyUiState();
        this.dispatchChange();
    }
    handleSearch(event) {
        if (this.isMultiSelect) {
            this.currentMode.handleSearch?.(this, event);
        } else {
            this.searchTerm = event.target.value || '';
            this.isDropdownOpen = true;
        }
    }

    handleFocus(event) {
        if (this.disabledState) return;
        this.isFocused = true;
        if (this.isMultiSelect) {
            this.currentMode.handleFocus?.(this, event);
        }
    }

    handleBlur(event) {
        const dest = event.relatedTarget;
        if (dest && this.template.contains(dest)) {
            return; 
        }
        setTimeout(() => {
            if (!this.template.activeElement || !this.template.contains(this.template.activeElement)) {
                this.isDropdownOpen = false;
                if (this.isMultiSelect) {
                    this.currentMode.handleBlur?.(this, event);
                } else {
                    this.isDropdownOpen = false;
                }
            }
        }, 150);
    }
    handlePreventBlur(event) {
        event.preventDefault();
    }
    // handleCheckboxClick(event) {
    //     const value = event.currentTarget.dataset.value;
    //     this.executeSelection(value);
    // }
    toggleDropdown() {
        if (this.object && this.field && !this.hasConfigError) {
            getPicklistOptions({
                objectName: this.object,
                fieldName: this.field
            })
                .then(result => {
                    //this.options = result;
                    this._options = result;
                    this.normalizeOptions();
                    this.applyUiState();
                    this.isDropdownOpen = true;
                })
                .catch(error => {
                    console.error(error);
                });
        } else {
            this.isDropdownOpen = true;
        }
    }
    /* -----------------------------
       pills management
    -------------------------------- */
    
    get showPillsMode() {
        return ( this.isMultiSelect && this.currentMode.showPills);
    }
    get selectedPills() {
        return this._options
            .filter(opt => opt.isSelected)
            .map(opt => ({
                label: opt.label,
                name: opt.value
            }));
    }
    handleRemove(event) {
        const valueToRemove = event.detail?.item?.name;
        if (!valueToRemove) return;
        this._options = this._options.map(opt =>
            String(opt.value) === String(valueToRemove)
                ? { ...opt, isSelected: false }
                : opt
        );
        this.selectedValuesSet.delete(String(valueToRemove));
        this.applyUiState();
        this.dispatchChange();
    }
    
    /* ==========================
       Global Events
    ============================ */
    /*========================
        Global getters    
    ==========================*/
    get currentMode() {
        return (
            RENDER_MODES[this.optionRenderMode] || RENDER_MODES.pills
        );
    }
    get disabledState() {
        return this.disabled || this.readOnly;
    }
    get selectedLabels() {
        return this._options
            .filter(opt => opt.isSelected)
            .map(opt => opt.label);
    }
    get hasSelections() {
        //return this._options.some(opt => opt.isSelected)
        return this.selectedValuesSet.size;
    }
    dispatchChange() {
        this.dispatchEvent(
            new CustomEvent('change', {
                detail: {
                    value: this.value
                }
            })
        );
    }
    
}