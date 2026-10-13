import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import ASD__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import BU__OBJECT from '@salesforce/schema/BusinessUnit__c';
// Custom Labels
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Sales_Cannibalization from "@salesforce/label/c.LBL_Sales_Cannibalization";
import LBL_TypeHR from "@salesforce/label/c.LBL_TypeHR";
import LBL_DescriptionHR from "@salesforce/label/c.LBL_DescriptionHR";
import LBL_API from "@salesforce/label/c.LBL_API";
import LBL_Std_Perc from "@salesforce/label/c.LBL_Std_Perc";
import LBL_Client_Perc from "@salesforce/label/c.LBL_Client_Perc";
import MSG_SC_not_Generated_or_Configured from "@salesforce/label/c.MSG_SC_not_Generated_or_Configured";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_IN from "@salesforce/label/c.LBL_IN";
import LBL_OUT from "@salesforce/label/c.LBL_OUT";
// CUSTOM Fields
import t_SalesCannibalizationRates__c from "@salesforce/schema/BusinessUnit__c.t_SalesCannibalizationRates__c";
//Static resources
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';

export default class SalesCannibalizationManager extends LightningElement {
    @api recordId;
    @track loading = true;
    picklistValues = [];
    recordData = {};
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }

    @track labels = {
        BULabel: '',
        LBL_Success,
        LBL_Error,
        MSG_Successfully_Saved,
        LBL_Sales_Cannibalization,
        LBL_TypeHR,
        LBL_DescriptionHR,
        LBL_API,
        LBL_Std_Perc,
        LBL_Client_Perc,
        MSG_SC_not_Generated_or_Configured,
        LBL_Save,
        LBL_IN,
        LBL_OUT,
    }

    @wire(getRecord, { recordId: "$recordId", fields: [t_SalesCannibalizationRates__c], }) buData({ error, data }) {
        if (data) {
            this.recordData = data.fields;
            this.buildData();
        } else if (error) {
            console.log('ERROR');
        }
    }
    //WIRES
    @wire(getObjectInfo, { objectApiName: BU__OBJECT.objectApiName }) objectInfoBU({ error, data }) {
        if (data) {
            this.labels.BULabel = data.label;
        } else if (error) {
            console.log('ERROR');
        }
    }
    @track records = [];
    buildData() {
        console.log(this.recordData[t_SalesCannibalizationRates__c.fieldApiName].value)
        this.records = this.recordData[t_SalesCannibalizationRates__c.fieldApiName].value ? JSON.parse(this.recordData[t_SalesCannibalizationRates__c.fieldApiName].value) : [];
        this.records.forEach(item => {
            item.typeHRLabel = item.typeHR == 'IN' ? this.labels.LBL_IN : this.labels.LBL_OUT;
            item.style = "background-color: " + (item.typeHR == 'IN' ? '#e8f3e8' : '#f8e4f6')
        })
        this.loading = false;
        console.log('this.records >>>> ' + JSON.stringify(this.records))
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style >> ' + error)
        });
    }

    handleChange(event) {
        let index = event.target.dataset.index;
        let property = event.target.dataset.property;
        let value = event.target.value;
        this.records[index][property] = value;
    }

    handleSave() {
        this.loading = true;
        let fields = {};
        fields['Id'] = this.recordId;
        let jsonArray = [...this.records];
        jsonArray.forEach(item => {
            delete item.typeHRLabel;
            delete item.style;
        })
        fields[t_SalesCannibalizationRates__c.fieldApiName] = JSON.stringify(jsonArray);
        console.log(JSON.stringify(jsonArray))
        updateRecord({ fields }).then(() => {
            this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
            this.loading = false;
        }).catch((error) => {
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
        });
    }

    // show notification 
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