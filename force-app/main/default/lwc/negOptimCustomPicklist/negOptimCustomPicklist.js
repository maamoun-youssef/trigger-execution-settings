import { LightningElement, api, track } from 'lwc';
import LBL_All from "@salesforce/label/c.LBL_All";
import LBL_Ok from "@salesforce/label/c.LBL_Ok";

export default class NegOptimCustomPicklist extends LightningElement {
    @api placeholder;
    @api label;
    @api selectedValues = '';
    @api options;
    @api selectedEvent;
    @api showAllOption;
    @api disabled = false;
    @track optionsList = [];
    @track allSelected;
    @track selectedOptions = [];
    @track variantLabel = '';
    @track Label = {
        LBL_All,
        LBL_Ok
    };
    @track searchTerm = '';
    @track filteredOptionsList = [];
    @track showSelectedLabels = true;
    get selectedLabels() {
        return this.optionsList.filter(item => { return item.isSelected && item.value != 'all' }).map(item => { return item.label }).join(', ');
    }

    connectedCallback() {
        let self = this;
        if (!this.label) {
            this.variantLabel = 'label-hidden';
        }
        self.selectedOptions = (self.selectedValues && self.selectedValues != "" && JSON.parse(self.selectedValues)) || [];
        if (self.options && self.options != "") {
            JSON.parse(self.options).forEach(item => {
                let newOption = {
                    label: item.label,
                    value: item.value,
                    toggle(event) {
                        newOption.isSelected = !newOption.isSelected;
                        if (!newOption.isSelected) {
                            self.allSelected = false;
                        }
                        self.handleSelectedChanged();
                    },
                    isSelected: self.selectedOptions.includes('all') || self.selectedOptions.includes(item.value)
                };
                self.optionsList.push(newOption);
            });
            self.optionsList = self.optionsList?.sort((it1, it2) => `${it1?.label}`?.localeCompare(`${it2?.label}`));
            if (self.showAllOption && self.showAllOption.toLowerCase() == 'true') {
                let selectAllOption = {
                    label: self.Label.LBL_All,
                    value: "all",
                    toggle(event) {
                        selectAllOption.isSelected = !selectAllOption.isSelected;
                        if (selectAllOption.isSelected) {
                            self.allSelected = true;
                            self.handleSelectedChanged();
                        } else {
                            self.allSelected = false;
                            self.selectedOptions = [];
                            self.optionsList.forEach(option => {
                                if (option.isSelected && option.value != 'all') {
                                    option.isSelected = false;
                                }
                            });
                        }
                    },
                    isSelected: self.selectedOptions.includes('all')
                }
                self.optionsList.push(selectAllOption);
            }
            self.filteredOptionsList = [...self.optionsList];
        }
    }

    get selectedLabels() {
        if (!this.showSelectedLabels) {
            return '';
        }
        const optionsList = this.optionsList
            .filter(item => item.isSelected && item.value != 'all')
            .map(item => item.label)
            .join(', ');
        return optionsList;
    }

    handleSelectedChanged() {
        if (this.allSelected) {
            this.optionsList.forEach(option => {
                if (!option.isSelected) {
                    option.isSelected = true;
                }
            });
        }
        this.selectedOptions = this.optionsList.filter(option => {
            if (option.isSelected && option.value != 'all') {
                return option;
            }
        }).map(item => item.value);
        if (!this.allSelected) {
            this.optionsList = this.optionsList.filter(option => {
                if (option.value == 'all') {
                    option.isSelected = false;
                }
                return option;
            });
        }
        if (this.selectedOptions.length === this.optionsList.length - 1) {
            let allOption = this.optionsList.find(item => item.value == "all");
            if (allOption) {
                allOption.isSelected = true;
            }
        }

    }
    handleOpenPicklistDropdown() {
        this.showSelectedLabels = false;
        this.template.querySelector('.picklistOptionsDropdown').classList.remove('slds-hide');
        this.template.querySelector('.picklistContainer')?.focus();
    }
    handleConfirmSelection() {
        this.showSelectedLabels = true;
        this.handleClosePicklist();
        let selOptions = this.optionsList.filter(item => this.selectedOptions.includes(item.value));
        const selectedEvent = new CustomEvent(this.selectedEvent, { detail: { selOptions }, });
        this.dispatchEvent(selectedEvent);
    }
    handleClosePicklist() {
        this.template.querySelector('.picklistOptionsDropdown').classList.add('slds-hide');
        this.searchTerm = '';
        this.filteredOptionsList = [...this.optionsList];
        this.showSelectedLabels = true;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        if (!this.searchTerm) {
            this.filteredOptionsList = this.optionsList;
        } else {
            this.filteredOptionsList = this.optionsList.filter(item => {
                if (item.value === 'all') return false;
                return item.label.toLowerCase().includes(this.searchTerm);
            });
        }
    }

}