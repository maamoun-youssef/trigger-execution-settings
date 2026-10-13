import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Custom Labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_GLStickersSettings from "@salesforce/label/c.LBL_GLStickersSettings";
import LBL_NegoScope_Settings from "@salesforce/label/c.LBL_NegoScope_Settings";
import LBL_Product_Settings from "@salesforce/label/c.LBL_Product_Settings";
import LBL_myOrgSettings from "@salesforce/label/c.LBL_myOrgSettings";
import LBL_myOrg from "@salesforce/label/c.LBL_myOrg";
import LBL_BUListManagerSettings from "@salesforce/label/c.LBL_BUListManagerSettings";

export default class MyOrgSettings extends LightningElement {
    //BOOLEANS
    loadingData = false;
    //OBJECTS
    @track labels = {
        LBL_Save,
        LBL_Success,
        LBL_Error,
        LBL_GLStickersSettings,
        LBL_NegoScope_Settings,
        LBL_Product_Settings,
        LBL_myOrgSettings,
        LBL_myOrg,
        LBL_BUListManagerSettings,
    }
    //STRINGS
    @track mainPanelHeight;

    connectedCallback() {
        Promise.all([
        ]).then(() => {
            console.log('loading style success');
        }).catch(error => {
            console.log('error loading style');
        });
        window.addEventListener('resize', this.changeHeight);
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `.slds-vertical-tabs__nav-item.slds-is-active {background: white;color: #806BBF;height: 60px;width: 230px;}.slds-vertical-tabs__nav-item.slds-is-active .slds-icon { --slds-c-icon-color-foreground: #806BBF;} `;
        tabStyle.innerText += `.slds-vertical-tabs__nav-item {background: #806BBF;height: 60px;width: 230px;border-bottom: 2px solid white; }.slds-vertical-tabs__nav-item .slds-icon { --slds-c-icon-color-foreground: white;}.slds-vertical-tabs__link {color: white;font-size: 14px;height: 60px; font-weight: 600;}.slds-vertical-tabs__link:hover {background: #806BBF }`;
        tabStyle.innerText += `.slds-vertical-tabs__nav-item:hover {background: white;color: #806BBF;}.slds-vertical-tabs__nav-item:hover .slds-icon { --slds-c-icon-color-foreground: #806BBF; }.slds-vertical-tabs__nav-item a:hover,.slds-vertical-tabs__nav-item a:focus {color: #806BBF; background: white; }`;
        tabStyle.innerText += `.slds-vertical-tabs {border-radius: 0px 0px 0px 5px; border: none; }.slds-vertical-tabs__left-icon { --slds-c-icon-color-foreground-default: white;}lightning-tab-bar { width: 230px; background: #806BBF;}`;
        document.body.appendChild(tabStyle);
        const tabStyleHover = document.createElement('style');
        tabStyleHover.innerText = `.tab-set-style a:hover { color: #806BBF;background-color: white;text-decoration: none;}.tab-set-style a:hover .slds-icon {--slds-c-icon-color-foreground: #806BBF;}.tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a { color: #806BBF; font-weight: 600;}.tab-set-style .slds-vertical-tabs__nav-item.slds-is-active .slds-icon { --slds-c-icon-color-foreground: #806BBF;}.tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover {color: #806BBF;}.tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover .slds-icon {  --slds-c-icon-color-foreground: #806BBF; } .slds-tabs_default__item:hover .slds-tabs_default__link { color: black;}`;
        document.body.appendChild(tabStyleHover);
    }
    renderedCallback() {
        if (this.template.querySelector('.header')) {
            this.changeHeight();
        }
    }
    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.header') != null) {
            headerHeight = this.template.querySelector('.header').getBoundingClientRect().height;
        }
        let mainPanelHeight = window.innerHeight - headerHeight - 130;
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px';
    };

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}