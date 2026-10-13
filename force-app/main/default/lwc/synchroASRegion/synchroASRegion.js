import { LightningElement, track, api, wire } from 'lwc';

import MSG_Synchro_AS_region_Intro_Label from "@salesforce/label/c.MSG_Synchro_AS_region_Intro_Label";
import LBL_BU_Name from "@salesforce/label/c.LBL_BU_Name";
import LBL_Respect_AS_Region_position from "@salesforce/label/c.LBL_Respect_AS_Region_position";
import LBL_AS_region_already_exist from "@salesforce/label/c.LBL_AS_region_already_exist";
import LBL_No_BU_Region_Found from "@salesforce/label/c.LBL_No_BU_Region_Found";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_No from "@salesforce/label/c.LBL_No";
import MSG_Synchro_AS_Region_Confirmation_Msg from "@salesforce/label/c.MSG_Synchro_AS_Region_Confirmation_Msg";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { loadStyle } from "lightning/platformResourceLoader";

import loadData from '@salesforce/apex/SynchroASRegionCtrl.loadData';
//Static resources
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';

export default class SynchroASRegion extends LightningElement {

    @api recordId;
    @track loading = false;
    @track confirmationPopup = false;
    @track records = [];

    @track labels = {
        MSG_Synchro_AS_region_Intro_Label,
        LBL_BU_Name,
        LBL_Respect_AS_Region_position,
        LBL_AS_region_already_exist,
        LBL_No_BU_Region_Found,
        LBL_Confirm,
        LBL_Yes,
        LBL_No,
        MSG_Synchro_AS_Region_Confirmation_Msg,
    }

    connectedCallback() {
        this.loadData();
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style >> ' + error)
        });
    }

    loadData() {
        this.loading = true;
        this.records = [];
        loadData({ assortmentId: this.recordId }).then((result) => {
            if (result == '') {
                this.loading = false;
            } else {
                this.records = JSON.parse(result);
                this.records.forEach(item => {
                    item.isChecked = true;
                    item.isRespectAsRegion = false;
                })
                this.loading = false;
            }
        }).catch(error => {
            this.loading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    handleSelectionBU(event) {
        let field = event.target.dataset.field;
        console.log(field)
        let index = event.target.dataset.rowindex;
        console.log(index)
        this.records[index][field] = event.detail.checked;
    }

    executeSynchro() {

    }
    togglePopup() {
        this.confirmationPopup = !this.confirmationPopup
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