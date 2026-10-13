import { LightningElement, api, track } from 'lwc';
import LBL_No_Items_Found from "@salesforce/label/c.LBL_No_Items_Found";
import LBL_Placeholder_Search from '@salesforce/label/c.LBL_Placeholder_Search';

export default class NegOptimSearchablePicklist extends LightningElement {
    _options = [];
    _value = '';

    @api placeholder;
    @api disabled = false;
    @api required = false;
    @api helpText = '';
    @api label = '';

    @track isDropdownOpen = false;
    @track isInteractingWithDropdown = false;
    @track searchInput;
    @track displayOptions = [];
    @track searchField;

    labels = { LBL_No_Items_Found , LBL_Placeholder_Search};

    get labelVariant() {
      return this.label != '' ? '' : 'label-hidden';
    }

    @api
    set options(value) {
        // Deep clone to avoid WeakMap issues
        this._options = value ? JSON.parse(JSON.stringify(value)) : [];
        // Initialize dropdown
        this.displayOptions = [...this._options];
        this.updateSearchInput();
    }

    get options() {
        return this._options;
    }

    @api
    get value() {
        return this._value;
    }
    set value(newValue) {
        this._value = newValue;
        this.updateSearchInput();
    }

    connectedCallback() {
        this.updateSearchInput();
        this.searchField = (this.searchInput ? this.searchInput : (this.placeholder ? this.placeholder : this.labels.LBL_Placeholder_Search));
    }

    updateSearchInput() {
        const selectedOption = this._options.find(opt => opt.value === this._value);
        this.searchInput = selectedOption ? selectedOption.label : '';
        this.searchField = this.searchInput;
    }

    handleSearchInput(event) {
        console.log('handleSearchInput called');  
        this.isDropdownOpen = true;
        const searchValue = event.target.value;
        console.log('Search input:', this.searchInput);
        const queryLower = searchValue.trim().toLowerCase();
        this.displayOptions = queryLower
        ? this._options.filter(opt =>
                (opt.label || '').toLowerCase().includes(queryLower) ||
                (opt.value || '').toLowerCase().includes(queryLower)
            )
        : [...this._options];
        if (!searchValue && this._value) {
            this._value = '';
        }
    }

    handleFocus() {
        this.isDropdownOpen = true;
         if (!this.searchInput || this.searchInput.trim() === '') {
        this.displayOptions = [...this._options];
        }
    }

    handleBlur() {
        if (this.isInteractingWithDropdown) return;
        this.isDropdownOpen = false;
    }


    selectOption(event) {
        const selectedValue = event.currentTarget.dataset.value;
        const selectedLabel = event.currentTarget.dataset.label;

        Promise.resolve().then(() => {
            this._value = selectedValue;
            this.searchInput = selectedValue;
            this.isDropdownOpen = false;
            this.isInteractingWithDropdown = false;
            this.dispatchEvent(
                new CustomEvent('change', {
                    detail: { value: selectedValue, label: selectedLabel },
                    bubbles: true,
                    composed: true
                })
            );
        });
    }

    handleDropdownPointerDown() {
        this.template.querySelector('[data-id="myInput"]').focus();
        this.isInteractingWithDropdown = true;
    }

    handleDropdownPointerUp() {
        this.template.querySelector('[data-id="myInput"]').focus();
        this.isInteractingWithDropdown = false;
    }
}