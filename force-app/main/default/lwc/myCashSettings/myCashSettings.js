import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Apex
import loadInvoiceSettings from "@salesforce/apex/MyCashSettingsController.loadInvoiceSettings";
import saveInvoiceSettings from "@salesforce/apex/MyCashSettingsController.saveInvoiceSettings";
import checkDeploymentStatus from "@salesforce/apex/MyCashSettingsController.checkDeploymentStatus";
// Custom labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import MSG_Request_Timed_Out from "@salesforce/label/c.MSG_Request_Timed_Out";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import LBL_VATsettings from "@salesforce/label/c.LBL_VATsettings";
import LBL_myCashsettings from "@salesforce/label/c.LBL_myCashsettings";
import LBL_myCash from "@salesforce/label/c.LBL_myCash";
import LBL_TabVATRateByCateg from "@salesforce/label/c.LBL_TabVATRateByCateg";
import LBL_TabVATRate from "@salesforce/label/c.LBL_TabVATRate";
import LBL_InvoiceNumberingRules_Settings from "@salesforce/label/c.LBL_InvoiceNumberingRules_Settings";
import LBL_Invoice_Stg_General_Settings from "@salesforce/label/c.LBL_Invoice_Stg_General_Settings";
import LBL_InvoiceNumberPrefixFormula from "@salesforce/label/c.LBL_InvoiceNumberPrefixFormula";
import LBL_InvoiceAutonumberLength from "@salesforce/label/c.LBL_InvoiceAutonumberLength";
import LBL_InvGensettings from "@salesforce/label/c.LBL_InvGensettings";
import LBL_Vat_Set_Up from "@salesforce/label/c.LBL_Vat_Set_Up";
import LBL_InvoiceMng_settings from "@salesforce/label/c.LBL_InvoiceMng_settings";
import LBL_InvoiceDeletionRules_Settings from "@salesforce/label/c.LBL_InvoiceDeletionRules_Settings";
import LBL_InvoiceValidationRules_Settings from "@salesforce/label/c.LBL_InvoiceValidationRules_Settings";
// Objects
import BusinessUnit__c from "@salesforce/schema/BusinessUnit__c";
// FIELDS
import BU_NAME from "@salesforce/schema/BusinessUnit__c.Name";
import Code__c from "@salesforce/schema/BusinessUnit__c.Code__c";

import Invoice_OBJECT from '@salesforce/schema/Invoice__c';

const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const classPrefix = `${PREFIX ? PREFIX.toLowerCase().replace(/__/gi, '') + '-' : 'c-'}my-cash-settings`;
export default class MyCashSettings extends LightningElement {
    //BOOLEANS
    loadingData = false;
    @track isSaveDisabled = false;
    //OBJECTS
    @track labels = {
        LBL_InvoiceValidationRules_Settings,
        LBL_Save,
        MSG_Deploy_Ended_With_Status,
        MSG_Save_Complete,
        MSG_Deploy_Last_Status,
        MSG_Request_Timed_Out,
        LBL_Info,
        LBL_Success,
        LBL_Error,
        LBL_VATsettings,
        LBL_myCashsettings,
        LBL_myCash,
        LBL_TabVATRateByCateg,
        LBL_TabVATRate,
        LBL_InvoiceNumberingRules_Settings,
        LBL_Invoice_Stg_General_Settings,
        LBL_InvoiceNumberPrefixFormula,
        LBL_InvoiceAutonumberLength,
        LBL_InvGensettings,
        LBL_InvoiceMng_settings,
        LBL_Vat_Set_Up,
        LBL_InvoiceDeletionRules_Settings,
    }
    @track API_NAMES = {
        InvoiceSettings__mdt: {}
    }
    @track fieldLabelMap = {};
    @track invoiceSettings = {};
    @track buInfo;
    @track buId;
    //STRINGS
    @track mainPanelHeight;
    @track numberPrefixFormula = '';
    @track autonumLength = 6;
    minLeftPad = 5;
    maxLeftPad = 50;
    @track formulaValidationMsg = '';
    @track autoNumberExampleMsg = '';
    // wire
    @wire(getObjectInfo, { objectApiName: BusinessUnit__c })
    buInfo;
    // getters
    get isLoadedObjectInfo() {
        return this.buInfo.data;
    }
    get isBUSelected() {
        return this.buId;
    }
    displayInfo = {
        primaryField: BU_NAME.fieldApiName,
        additionalFields: [Code__c.fieldApiName],
    };

    connectedCallback() {
        Promise.all([]).then(() => {
            console.log('loading style success');
        }).catch(error => {
            console.log('error loading style');
        });
        window.addEventListener('resize', this.changeHeight);
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                background: white;
                color: #806BBF;
                height: 60px;
                width: 230px;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active:hover {
                background: white;
                color: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item {
                background: #806BBF;
                height: 60px;
                width: 230px;
                border-bottom: 2px solid white;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item .slds-icon {
                --slds-c-icon-color-foreground: white;
            }
            ${classPrefix} .slds-vertical-tabs__link {
                color: white;
                font-size: 14px;
                height: 60px;
                font-weight: 600;
            }
            ${classPrefix} .slds-vertical-tabs__link:hover {
                background: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item:hover {
                background: white;
                color: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item a:hover,
            ${classPrefix} .slds-vertical-tabs__nav-item a:focus {
                color: #806BBF;
                background: white;
            }
            ${classPrefix} .slds-vertical-tabs {
                border-radius: 0px 0px 0px 5px;
                border: none;
            }
            ${classPrefix} .slds-vertical-tabs__left-icon {
                --slds-c-icon-color-foreground-default: white;
            }
            ${classPrefix} lightning-tab-bar {
                width: 230px;
                background: #806BBF;
                height: auto;
            }
            ${classPrefix} .slds-vertical-tabs__nav {
            width: var(--lwc-sizeXSmall, 12rem);
            border-right: var(--lwc-borderWidthThin, 1px) solid var(--slds-g-color-border-base-1, var(--lwc-colorBorder, rgb(229, 229, 229))); 
            background: var(--slds-g-color-neutral-base-95, var(--lwc-colorBackground, rgb(243, 243, 243)));
            }

            @media screen and (max-width: 980px) {
                ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                ${classPrefix} .slds-vertical-tabs__nav-item {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                ${classPrefix} .slds-vertical-tabs__link {
                    font-size: 13px;
                    font-weight: 400;
                    height: 60px;
                }
                ${classPrefix} lightning-tab-bar {
                    width: 190px;
                }
                ${classPrefix} .slds-vertical-tabs__nav {
                    border-right: none;
                    background: none;
                }
            }
        `;
        document.body.appendChild(tabStyle);
        const tabStyleHover = document.createElement('style');
        tabStyleHover.innerText = `
            ${classPrefix} .tab-set-style a:hover {
                color: #806BBF;
                background-color: white;
                text-decoration: none;
            }
            ${classPrefix} .tab-set-style a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a {
                color: #806BBF;
                font-weight: 600;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover {
                color: #806BBF;
                background: white;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .slds-tabs_default__item:hover .slds-tabs_default__link {
                color: black;
            }
        `;
        document.body.appendChild(tabStyleHover);
        this.loadData();
    }
    renderedCallback() {
        if (this.template.querySelector('.settings-header')) {
            this.changeHeight();
        }
    }
    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.settings-header') != null) {
            headerHeight = this.template.querySelector('.settings-header').getBoundingClientRect().height;
        }
        let mainPanelHeight;
        if (window.innerWidth < 980) {
            mainPanelHeight = window.innerHeight - headerHeight - 170;
        } else {
            mainPanelHeight = window.innerHeight - headerHeight - 120;
        }
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px';
    };
    handleChangeBU(event) {
        try {
            this.buId = event.detail.recordId;
        } catch (exception) {
            console.error(exception);
            showNotification(this, Labels.LBL_Error, exception?.body?.message || exception?.message || exception, 'error');
        }
    }
    //LOAD DATA
    loadData() {
        this.loadingData = true;
        loadInvoiceSettings()
            .then(result => {
                let parsedResult = JSON.parse(result);
                this.afterLoad(parsedResult);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.loadingData = false;
            })
    }
    afterLoad(mainWrapper) {
        try {
            this.invoiceSettings = mainWrapper.invoiceSettings;
            this.numberPrefixFormula = this.invoiceSettings.numberPrefixFormula;
            this.autonumLength = this.invoiceSettings.autonumLength;
            this.autoNumberExampleMsg = 'Ex: ' + "1".padStart(parseInt(this.autonumLength), "0");
            this.formulaValidationMsg = '';
            this.API_NAMES.InvoiceSettings__mdt = {
                objectApiName: PREFIX + 'InvoiceSettings__mdt',
                NumberPrefixFormula__c: PREFIX + 'NumberPrefixFormula__c',
                AutonumLength__c: PREFIX + 'AutonumLength__c',
            };
            this.loadingData = false;
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    //EVENT HANDLERS
    handleSaveInvoiceSettings(event) {
        try {
            this.loadingData = true;
            let metadataItem = {
                numberPrefixFormula: this.numberPrefixFormula,
                autonumLength: this.autonumLength,
            };
            let fieldsValueMap = {
                [this.API_NAMES.InvoiceSettings__mdt.NumberPrefixFormula__c]: metadataItem.numberPrefixFormula,
                [this.API_NAMES.InvoiceSettings__mdt.AutonumLength__c]: metadataItem.autonumLength,
            };
            saveInvoiceSettings({ invoiceSettingsJSON: JSON.stringify(this.invoiceSettings), fieldsValueMapJSON: JSON.stringify(fieldsValueMap) })
                .then(result => {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.errorMessage) {
                        this.formulaValidationMsg = parsedResult.errorMessage;
                        this.loadingData = false;
                        return;
                    }
                    let jobId = parsedResult.jobId;
                    if (jobId) {
                        this.checkDeployementStatus(jobId);
                    }
                }).catch(error => {
                    this.loadingData = false;
                    console.log('error: ', error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                });
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleEditInvoiceSettings(event) {
        try {
            //let value = event.currentTarget.value.trim();
            let value = event.target.value;
            let field = event.target.dataset.field;
            if (field == 'numberPrefixFormula') {
                value = value.trim();
            } else if (field == 'autonumLength') {
                if (value && parseInt(value) >= this.minLeftPad && parseInt(value) <= this.maxLeftPad) {
                    this.autoNumberExampleMsg = 'Ex: ' + "1".padStart(parseInt(value), "0");
                } else {
                    this.autoNumberExampleMsg = '';
                }
                this.isSaveDisabled = !event.target.checkValidity();
            }
            this[field] = value;
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    checkDeployementStatus(idDeployment) {
        try {
            let counter = 0;
            let status;
            checkDeploymentStatus({
                'idDeployment': idDeployment,
            }).then(fresult => {
                let fdone = JSON.parse(fresult).deployResult.done;
                status = JSON.parse(fresult).deployResult.status;
                let success = JSON.parse(fresult).deployResult.success;
                if (!fdone) {
                    let interval = setInterval(() => {
                        if (counter > 10) {
                            this.loadingData = false;
                            clearInterval(interval);
                            this.showNotification(this.labels.LBL_Error, this.labels.MSG_Request_Timed_Out + ' ' + this.labels.MSG_Deploy_Last_Status + ' ' + status);
                        }
                        checkDeploymentStatus({
                            'idDeployment': idDeployment,
                        }).then(result => {
                            let done = JSON.parse(result).deployResult.done;
                            success = JSON.parse(result).deployResult.success;
                            status = JSON.parse(result).deployResult.status;
                            if (done) {
                                this.loadingData = false;
                                clearInterval(interval);
                                if (success) {
                                    this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                                    this.loadData();
                                } else {
                                    this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                                }
                            }
                        });
                        counter++;
                    }, 5000);
                } else {
                    this.loadingData = false;
                    if (success) {
                        this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                        this.loadData();
                    } else {
                        this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                    }
                }
            });
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    //NOTIFICATIONS
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    //NOTIFICATIONS
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
            duration: 3000
        });
        this.dispatchEvent(evt);
        setTimeout(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable',
                duration: 1
            }));
        }, 5000);
    }
}