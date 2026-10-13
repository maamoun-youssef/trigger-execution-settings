/**
* @author ULiT
* @date 30-10-2024
* @description 
*******************************************************************************************************************************************
*/
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//APEX
import initData from '@salesforce/apex/ProductSettingsController.loadProductSettings';
import save from '@salesforce/apex/ProductSettingsController.save';

//OBJECTS 
import PriceListDetail__c from '@salesforce/schema/PriceListDetail__c';
import Product2 from '@salesforce/schema/Product2';
//IMPORTS
import { labels, PRODUCT_SETTINGS_API } from './properties.js';

export default class ProductSettings extends LightningElement {
    // TRACK VARIABLES
    @track labels = labels;
    @track PRODUCT_SETTINGS_API = PRODUCT_SETTINGS_API;
    //BOOLEANS
    @track loading = false;
    @track gridSettingsLink = '';
    @track productRecordTypesOptions = [];
    @track mainWrapper = {};
    @track productSettings = {};
    @track PLDGridOptions = [];
    @track priceListManagerProductGridOptions = [];
    @track importSettingsOptionsProduct = [];
    // VARIABLES
    PLDInfoOpen = false;
    productGridInfoOpen = false;

    connectedCallback() {
        this.initData();
    }
    //LOAD
    initData() {
        try {
            this.loading = true;
            initData().then((result) => {
                let parsedResult = JSON.parse(result);
                this.afterLoad(parsedResult);
            })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    afterLoad(mainWrapper) {
        try {
            this.gridSettingsLink = '/lightning/n/' + mainWrapper.prefix + 'Grid_Settings_Manager';
            //SET UP RECORDTYPES
            let productRecordTypesOptions = [];
            mainWrapper.productRecordTypes.forEach(rt => {
                productRecordTypesOptions.push({
                    label: rt.Name,
                    value: rt.Id
                });
            });
            this.productRecordTypesOptions = productRecordTypesOptions;
            //SET UP NEGO SETTINGS
            this.productSettings = mainWrapper.productSettings;
            //SET UP OPTIONS
            this.productSettingsLayoutsMap = mainWrapper.productSettingsLayoutsMap;
            let PLDGridOptions = []
            let productGridOptions = []
            if (this.productSettingsLayoutsMap) {
                for (let objectName in this.productSettingsLayoutsMap) {
                    if (objectName == PriceListDetail__c.objectApiName) {
                        for (let option in this.productSettingsLayoutsMap[objectName]) {
                            PLDGridOptions.push({
                                label: this.productSettingsLayoutsMap[objectName][option].label,
                                value: this.productSettingsLayoutsMap[objectName][option].value
                            });
                        }
                    }
                    if (objectName == Product2.objectApiName) {
                        for (let option in this.productSettingsLayoutsMap[objectName]) {
                            productGridOptions.push({
                                label: this.productSettingsLayoutsMap[objectName][option].label,
                                value: this.productSettingsLayoutsMap[objectName][option].value
                            });
                        }
                    }
                }
            }
            this.PLDGridOptions = PLDGridOptions;
            this.priceListManagerProductGridOptions = productGridOptions;


            //SET UP IMPORT SETTINGS
            this.importSettingsOptionsProduct = Array.isArray(mainWrapper.importSettingsList) ? mainWrapper.importSettingsList : [];         

            // //SET UP LABELS
            let productSettingsFields = mainWrapper.fieldsMap[PRODUCT_SETTINGS_API.ProductSettings__c];
            this.labels.productRecordTypesHelpText = productSettingsFields[PRODUCT_SETTINGS_API.ProductRecordTypes__c].inlineHelpText;
            this.labels.numberOfUnitChargesHelpText = productSettingsFields[PRODUCT_SETTINGS_API.NumberOfUnitCharges__c].inlineHelpText;
            this.labels.numberOfUnitChargesLabel = productSettingsFields[PRODUCT_SETTINGS_API.NumberOfUnitCharges__c].label;
            this.labels.isAutoNumberProductNameHelpText = productSettingsFields[PRODUCT_SETTINGS_API.IsAutoNumberProductName__c].label;
            this.labels.autoNumberPrefixLabel = productSettingsFields[PRODUCT_SETTINGS_API.AutoNumberPrefix__c].label;
            this.labels.priceListManagerPLDGridLabel = productSettingsFields[PRODUCT_SETTINGS_API.PriceListManagerPLDGrid__c].label;
            this.labels.priceListManagerPLDGridHelpText = productSettingsFields[PRODUCT_SETTINGS_API.PriceListManagerPLDGrid__c].inlineHelpText;
            this.labels.priceListManagerProductGridLabel = productSettingsFields[PRODUCT_SETTINGS_API.PriceListManagerProductGrid__c].label;
            this.labels.priceListManagerProductGridHelpText = productSettingsFields[PRODUCT_SETTINGS_API.PriceListManagerProductGrid__c].inlineHelpText;
            this.labels.isPriceListDataUpdatePGsLabel = productSettingsFields[PRODUCT_SETTINGS_API.IsPriceListDataUpdatePGs__c].label;
            this.labels.isPriceListDataUpdatePGsHelpText = productSettingsFields[PRODUCT_SETTINGS_API.IsPriceListDataUpdatePGs__c].inlineHelpText;
            this.mainWrapper = mainWrapper;
            this.loading = false;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleFieldEdits(event) {
        try {
            let fieldName = event.target.dataset.field;
            let value = event.detail.checked ?? event.target.value;
            this.productSettings[fieldName] = value;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleSave() {
        this.loading = true;
        save({
            productSettingsJson: JSON.stringify(this.productSettings)
        }).then(result => {
            if (result == 'SUCCESS') {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'sticky')
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error', 'sticky')
            }
            this.loading = false;
        }).catch(error => {
            this.loading = false;
            this.showNotification(this.labels.LBL_Error, error.body.message, 'error', 'sticky')
            console.error('Error saving settings:', error);
        });
    }

    handleTogglePLDInfo() {
        this.PLDInfoOpen = !this.PLDInfoOpen;
        if (this.PLDInfoOpen) {
            this.productGridInfoOpen = false;
        }
    }
    handleToggleProductGridInfo() {
        this.productGridInfoOpen = !this.productGridInfoOpen;
        if (this.productGridInfoOpen) {
            this.PLDInfoOpen = false;
        }
    }
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