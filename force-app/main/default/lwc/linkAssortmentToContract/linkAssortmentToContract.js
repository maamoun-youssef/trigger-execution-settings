import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import MSG_Link_AS_to_Contract_Introduction_Msg from "@salesforce/label/c.MSG_Link_AS_to_Contract_Introduction_Msg";
import MSG_Link_AS_to_Contract_Status_Msg from "@salesforce/label/c.MSG_Link_AS_to_Contract_Status_Msg";
import LBL_Change_Contract from "@salesforce/label/c.LBL_Change_Contract";
import LBL_Update_Price from "@salesforce/label/c.LBL_Update_Price";
import MSG_Batch_Executed from "@salesforce/label/c.MSG_Batch_Executed";

import Contract__c from "@salesforce/schema/Assortment_BU__c.Contract__c";
import ContractASS__c from "@salesforce/schema/Assortment__c.Contract__c";
import PWF__c from "@salesforce/schema/Assortment__c.PWF__c";

import loadData from '@salesforce/apex/LinkAssortmentToContractCtrl.loadData';
import updateAssortment from '@salesforce/apex/LinkAssortmentToContractCtrl.updateAssortment';
import executeSynchroPWF from '@salesforce/apex/LinkAssortmentToContractCtrl.executeSynchroPWF';
export default class LinkAssortmentToContract extends LightningElement {

    @api recordId;
    @track loading = false;
    @track changeContract = false;

    //SET THE Assortment ID
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }

    get colspan() {
        return this.displayedFields.length + 1;
    }
    get contractSelected() {
        return !this.changeContract && this.resultWrapper && this.resultWrapper.currentAssortment && this.resultWrapper.currentAssortment[ContractASS__c.fieldApiName] != null;
    }

    connectedCallback() {
        this.loadData();
    }
    @track labels = {
        LBL_No_Item_To_Display,
        LBL_Confirm,
        MSG_Successfully_Saved,
        MSG_Link_AS_to_Contract_Introduction_Msg,
        MSG_Link_AS_to_Contract_Status_Msg,
        LBL_Change_Contract,
        LBL_Update_Price,
    }
    @track resultWrapper = {};
    @track displayedFields = [];
    @track records = [];
    loadData() {
        this.loading = true;
        this.resultWrapper = {};
        this.records = [];
        this.displayedFields = [];
        loadData({ assortmentId: this.recordId }).then((result) => {
            if (result == '') {
                this.loading = false;
            } else {
                this.resultWrapper = JSON.parse(result);
                console.log('this.resultWrapper >>>> ' + JSON.stringify(this.resultWrapper));
                this.displayedFields = this.resultWrapper.displayedFields;
                this.buildData();
                this.loading = false;
            }
        }).catch(error => {
            this.loading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    buildData() {
        let index = 0;
        for (let pwf of this.resultWrapper.PWFs) {
            let record = {
                Id: pwf.Id,
                Name: pwf.Name,
                index: index,
                link: '/' + pwf.Id,
                contractId: pwf[Contract__c.fieldApiName],
                isChecked: this.resultWrapper.currentAssortment[ContractASS__c.fieldApiName] == pwf[Contract__c.fieldApiName] && pwf.Id == this.resultWrapper.currentAssortment[PWF__c.fieldApiName],
                values: []
            }
            for (let field of this.displayedFields) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isLink: field.fieldName == 'Name' || field.fieldName == Contract__c.fieldApiName.replace('__c', '__r') + '.Name',
                    link: '/' + (field.fieldName == 'Name' ? pwf.Id : pwf[field.fieldName.replace('__r.Name', '__c')])
                }
                let splittedFields = field.fieldName.split('.');
                let fieldValue = pwf[splittedFields[0]];
                for (let index = 1; index < splittedFields.length; index++) {
                    if (fieldValue) {
                        fieldValue = fieldValue[splittedFields[index]];
                    }
                }
                fieldWrapper.fieldValue = fieldValue;
                record.values.push(fieldWrapper);
            }
            this.records.push(record);
            index++;
        }
        console.log('this.records >>> ' + JSON.stringify(this.records))
    }
    selectedPWF = '';
    selectedContract = '';
    handleSelectionContract(event) {
        let index = event.target.dataset.index;
        this.records.forEach(record => {
            if (record.index == index) {
                record.isChecked = true;
                this.selectedPWF = record.Id;
                this.selectedContract = record.contractId;
            } else {
                record.isChecked = false;
            }
        })
    }

    updateAssortment() {
        this.loading = true;
        if (this.selectedContract != null && this.selectedContract != '' && this.selectedPWF != null && this.selectedPWF != '') {
            updateAssortment({ assortmentId: this.recordId, selectedContract: this.selectedContract, selectedPWF: this.selectedPWF }).then((result) => {
                if (result == '') {
                    this.loading = false;
                    this.showNotification('Sucess', MSG_Successfully_Saved, 'sucess', 'dismissible');
                    this.loadData();
                    this.dispatchEvent(new CustomEvent(
                        'closelinkcontractpopup',
                        {
                            detail: {},
                            bubbles: true,
                            composed: true,
                        }
                    ));
                } else {
                    this.showNotification('Error', result, 'error', 'dismissible');
                    this.loading = false;
                }
            }).catch(error => {
                this.loading = false;
                this.showNotification('Error', error, 'error', 'dismissible');
                console.error(error);
            });
        } else {
            this.showNotification('Info', 'No Data Selected', 'info', 'dismissible');
        }
    }

    executeSynchroPWF() {
        this.loading = true;
        executeSynchroPWF({ assortmentId: this.recordId }).then((result) => {
            console.log('HII')
            this.loading = false;
            this.showNotification('Success', MSG_Batch_Executed, 'success', 'dismissible');
            console.log('show toast event')
        }).catch(error => {
            this.loading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    handleChangeContract() {
        this.changeContract = true;
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