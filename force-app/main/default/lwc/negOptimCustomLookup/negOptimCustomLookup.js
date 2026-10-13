import { LightningElement, api, track } from 'lwc';
import getResults from '@salesforce/apex/NegOptimCustomLookupCmpCtrl.getResults';
import LBL_No_Items_Found from "@salesforce/label/c.LBL_No_Items_Found";

export default class negOptimCustomLookup extends LightningElement {
    @api objectName = 'Account';
    @api fieldName = 'Name';
    @api searchTerm = '';
    @api searchFields = [];
    @api label;
    @api labelVariant;
    @api value;
    @api isportal;
    @track labels = {
        LBL_No_Items_Found
    }
    get hasLabel() {
        return this.label && this.label != '';
    }
    get hideSearch() {
        return this.isportal ? "overflow-x: hidden;" : '';
    }
    @track searchRecords = [];
    /*get selectedRecords() {
        return (this.value && JSON.parse(this.value)) || [];
    }*/
    @track selectedRecords = [];
    @track selectedRecord = '';
    @api isRequired = false;
    @api filterToken = [];
    @api iconName = '';
    get hasIcon() {
        return this.iconName != undefined && this.iconName != '';
    }
    @api loadingText = false;
    @api placeHolder;
    @track showPills = false;
    @api isMulti = '';
    eventSent = false;
    get customPaddingStyle() {
        return this.labelVariant == "label-inline" ? 'padding-left: 33%;clear: none;' : ''
    }
    get customStyle() {
        return this.labelVariant == "label-inline" ? 'max-width: unset !important; min-width: unset !important; left: unset !important;float: unset !important;transform: unset !important; width: unset !important;' : '';
    }
    get multiSelect() {
        return this.isMulti && this.isMulti.toLowerCase() == 'true';
    }
    @api selectedEvent;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;
    @track message = 'none received (yet)';
    connectedCallback() {
        this.selectedRecords = (this.value && JSON.parse(this.value)) || [];
    }
    searchField(event) {
        this.eventSent = false;
        var currentText = event.target.value;
        var selectRecId = [];
        if (this.multiSelect) {
            for (let i = 0; i < this.selectedRecords.length; i++) {
                selectRecId.push(this.selectedRecords[i].recId);
            }
        } else {
            // this.selectedRecords = [];
            // selectRecId = [];
            if (currentText === '') {
                this.selectedRecords = [];
                selectRecId = [];
            } else if (this.selectedRecords.length > 0) {
                selectRecId.push(this.selectedRecords[0].recId);
            }
        }
        this.loadingText = true;
        getResults({ ObjectName: this.objectName, fieldName: this.fieldName, searchFields: this.searchFields, value: currentText, selectedRecId: selectRecId, filter: this.filterToken })
            .then(result => {
                this.searchRecords = result;
                this.loadingText = false;
                if (currentText.length > 0 && result.length == 0) {
                    this.messageFlag = true;
                }
                else {
                    this.messageFlag = false;
                }
                this.txtclassname = this.messageFlag || result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            })
            .catch(error => {
                console.log('-------error-------------' + JSON.stringify(error));
                console.log('-------error-------------' + (error || error.body || error.body.message));
                console.log(error);
            });

    }
    closeDropdown() {
        setTimeout(() => {
            this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        }, 200);
    }
    handleblur() {
        setTimeout(() => {
            this.closeDropdown();
            if (!this.eventSent) {
                console.log('handleblur::::');
                let selRecords = this.selectedRecords;
                const selectedEvent = new CustomEvent(this.selectedEvent, { detail: { selRecords }, });
                // Dispatches the event.
                this.dispatchEvent(selectedEvent);
                this.eventSent = true;
            }
        }, 200);
    }

    setSelectedRecord(event) {
        if (!this.eventSent) {
            console.log('setSelectedRecord::::');

            var recId = event.currentTarget.dataset.id;
            var selectName = event.currentTarget.dataset.name;
            let newsObject = { 'recId': recId, 'recName': selectName };
            this.selectedRecord = recId;
            if (!this.multiSelect) {
                this.selectedRecords = [];
            }
            this.selectedRecords.push(newsObject);
            this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            let selRecords = this.selectedRecords;
            this.template.querySelectorAll('lightning-input').forEach(each => {
                if (this.multiSelect) {
                    each.value = '';
                } else {
                    each.value = selectName;
                }
                //each.value = this.isMulti ? '' : each.value;
            });
            const selectedEvent = new CustomEvent(this.selectedEvent, { detail: { selRecords }, });
            // Dispatches the event.
            console.log(selectedEvent);
            this.dispatchEvent(selectedEvent);
            this.eventSent = true;
        }
    }

    removeRecord(event) {
        let selectRecId = [];
        for (let i = 0; i < this.selectedRecords.length; i++) {
            if (event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent(this.selectedEvent, { detail: { selRecords }, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        this.eventSent = true;
    }
}