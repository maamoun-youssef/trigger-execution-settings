import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import initData from '@salesforce/apex/FileDirectorySubTypeSelectorCtrl.initData';

// labels
import LBL_Type from "@salesforce/label/c.LBL_Type";
import LBL_FileDirectorySection_TableSubTitle from "@salesforce/label/c.LBL_FileDirectorySection_TableSubTitle";

export default class FileDirectorySubTypeSelector extends LightningElement {
    @api subType;
    @api recordType;
    @api recordTypeDefaultValue;
    @track subTypes;
    @track selectedType;
    subtypeOptions = [];
    fieldLabel;

    @track labels = {
        LBL_Type,
        LBL_FileDirectorySection_TableSubTitle
    };
    connectedCallback() {
        this.recordType = this.recordTypeDefaultValue;
        this.loadData();
    }

    loadData() {
        initData().then(result => {
            const data = JSON.parse(result);
            this.subTypes = data.SubTypePicklist;
            this.fieldLabel = data.fdLabels;
        }).catch(error => {
            console.error('Error loading data:', error);
        });
    }

    get typeOptions() {
        return Object.keys(this.subTypes || {}).map(key => ({
            label: this.fieldLabel[key],
            value: key
        }));
    }

    get subTypeOptions() {
        return this.subTypes?.[this.selectedType]?.map(key => ({
            label: this.fieldLabel[key],
            value: key
        }));
    }

    handleSelectedType(event) {
        const value = event.target.value;
        this.selectedType = value;
        this.recordType = value;
        this.dispatchEvent(new FlowAttributeChangeEvent('recordType', value));
    }

    handleSelectedSubType(event) {
        const value = event.target.value;
        this.subType = value;
        this.dispatchEvent(new FlowAttributeChangeEvent('subType', value));
    }

}