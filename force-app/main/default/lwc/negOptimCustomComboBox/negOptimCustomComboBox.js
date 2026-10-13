/**
 * @module NegOptimCustomComboBox
 * @description
 * A custom combo box component with filtering. Allows developers to pass in
 * available options and capture user selection.
 *
 * @apiProps
 * @api availableOptions              The array of options to render (label/value pairs).
 * @api selectedOption               The currently selected option's value.
 * @api label                        The label text displayed above the combo box.
 * @api placeHodlder                         The HTML placeHodlder attribute for the combo box.
 */

import { api, LightningElement, track } from 'lwc';
import LBL_Placeholder_Search from '@salesforce/label/c.LBL_Placeholder_Search';
import LBL_No_Items_Found from '@salesforce/label/c.LBL_No_Items_Found';

export default class NegOptimCustomComboBox extends LightningElement {
    @api availableOptions;
    @api selectedOption;
    @api label;
    @api placeHodlder;
    @track options = [];
    @track displayFeilds = false;
    @track searchField;
    // custom labels
    @track labels = {
        LBL_Placeholder_Search,
        LBL_No_Items_Found
    }

    connectedCallback() {
        console.log('availableOptions >>>', this.availableOptions);
        this.selectedOption = this.selectedOption ? this.selectedOption : '';
        this.searchField = (this.selectedOption ? this.selectedOption : (this.placeHodlder ? this.placeHodlder : this.labels.LBL_Placeholder_Search));
        this.buildOptions();
    }

    renderedCallback() {
        this.handleSelectionStyle();
    }

    buildOptions() {
        if (this.availableOptions.length > 0) {
            this.options = this.availableOptions;
        } else {
            // handle options not found
        }
    }

    handleSelectionStyle() {
        this.template?.querySelectorAll('.slds-has-focus')?.forEach(element => {
            element?.classList.remove('slds-has-focus');
        })
        this.template?.querySelector(`[data-value='${this.selectedOption}']`)?.classList.add('slds-has-focus');
    }

    handleInputChange(event) {
        const value = event?.target?.dataset?.value || event?.currentTarget?.dataset?.value;
        this.selectedOption = value;
        console.log('value >>>', {
            details: {
                value: value
            }
        });
        this.handleSelectionStyle();
        // event.details.value = value;
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: value
            }
        }));
        this.toggleVisibility();
        this.searchField = value;
        const input = this.template.querySelector('.search');
        if (input) {
            input.value = '';
        }
        this.options = this.availableOptions;
    }

    handleFilterOptions(event) {
        const value = event.target.value;
        this.selectedOption = value;
        this.options = this.availableOptions.filter(option => {
            return option.label.toLowerCase().includes(value.toLowerCase());
        })
    }

    toggleVisibility() {
        this.displayFeilds = !this.displayFeilds;
        if (!this.displayFeilds) {
            this.template.querySelector('.search')?.blur();
        } else {
            this.template.querySelector('.search')?.focus();
        }
    }

    get isLabelHidden() {
        return this.label === '' || this.label === undefined;
    }
}