import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import loadData from '@salesforce/apex/PageSettingsPluginController.loadData';
import getFlowVariables from '@salesforce/apex/PageSettingsPluginController.getFlowVariables';
import { componentMap } from './importLWC.js';

// USER
import userId from '@salesforce/user/Id';
import UserContactFIELD from '@salesforce/schema/User.ContactId';
import LBL_Error from "@salesforce/label/c.LBL_Error";

import Invoice_OBJECT from '@salesforce/schema/Invoice__c';

const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const camelToKebab = (str) => {
    return str.replace(/([A-Z])/g, (match) => `-${match.toLowerCase()}`);
};
export default class PageSettingsPluginThemeList extends LightningElement {

    @api selectedSectionIndex;
    @api templateName;
    @api selectedThemeIndex;
    @api recordId;
    @track currentSectionSettings;
    @track pageSettings = {};
    @track isLoading = false;
    @track mainPanelHeight;
    @track gridSettingsPluginHeight;
    @track activeTheme;
    @track isPortal = false;

    @track labels = {
        LBL_Error,
    }
    @track WireVariables = {
        getPageReference: false,
        getRecord: false,
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                this.selectedSectionIndex = pageRef.state.c__selectedSectionIndex != null ? pageRef.state.c__selectedSectionIndex : this.selectedSectionIndex;
                this.templateName = pageRef.state.c__templateName != null ? pageRef.state.c__templateName : this.templateName;
                this.selectedThemeIndex = pageRef.state.c__selectedThemeIndex != null ? pageRef.state.c__selectedThemeIndex : this.selectedThemeIndex;
                this.activeTheme = this.selectedThemeIndex;
                this.WireVariables.getPageReference = true;
                this.init();
            }
        } catch (error) {
            this.handleError(error, 'getPageReference');
        }
    }

    @wire(getRecord, { recordId: userId, fields: [UserContactFIELD] }) currentUserInfo({ error, data }) {
        if (data) {
            this.isPortal = data.fields.ContactId.value ? true : false;
            this.WireVariables.getRecord = true;
            this.init();
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `.slds-vertical-tabs__nav-item.slds-is-active{background :#238591; color: white; height: 60px; width: 230px; text-decoration:none;}`;
        tabStyle.innerText += `.slds-vertical-tabs__nav-item{background : #1BB7B0; height: 60px; width: 230px; right: 40px; }`;
        tabStyle.innerText += `.slds-vertical-tabs {border-radius: 0px 0px 0px 5px; border: none} `;
        tabStyle.innerText += `.slds-vertical-tabs__left-icon { --slds-c-icon-color-foreground-default: white;}`;
        tabStyle.innerText += `.slds-vertical-tabs__nav-item.slds-is-active .slds-icon {--slds-c-icon-color-foreground: white;}`;
        tabStyle.innerText += `.slds-vertical-tabs__link { color: white; font-size: 14px; height: 60px; text-decoration: none;}`;
        tabStyle.innerText += `.slds-vertical-tabs__nav-item.slds-is-active .slds-vertical-tabs__link { color: white;}`;
        tabStyle.innerText += `.slds-vertical-tabs__link:hover { text-decoration: none; background-color: #1BB7B0; color: white;}`;
        tabStyle.innerText += `.slds-vertical-tabs__nav-item.slds-is-active .slds-vertical-tabs__link:hover {color: white; text-decoration:none; background-color: #238591;}`;
        // tabStyle.innerText += 'lightning-tab-bar { width: 230px; margin: 10px; background: #1BB7B0; border-radius: 10px; padding-top: 10px; text-decoration:none; color: white; height: fit-content; padding-bottom: 10px;}';
        tabStyle.innerText += `lightning-tab-bar { width: 230px; background: #1BB7B0; text-decoration:none; color: white; height: fit-content;}`;
        document.body.appendChild(tabStyle);
        const tabStyleHover = document.createElement('style');
        document.body.appendChild(tabStyleHover);
    }

    //LIFECYCLE
    init() {
        if (this.WireVariables.getPageReference && this.WireVariables.getRecord) {
            this.loadData();
        }
    }

    componentMap = {};

    loadData() {
        this.isLoading = true;
        try {
            console.log('this.templateName >>> ' + this.templateName)
            loadData({ templateName: this.templateName }).then((result) => {
                this.pageSettings = JSON.parse(result);
                console.log('this.pageSettings >> ' + JSON.stringify(this.pageSettings))
                let sectionIndex = 0;
                this.pageSettings?.sections?.forEach(section => {
                    if (sectionIndex == this.selectedSectionIndex) {
                        section.themes = this.pageSettings.themes.filter(theme => theme.isActive && theme.sectionIndex == sectionIndex && (this.isPortal ? theme.isPortalDisplay : theme.isInternalDisplay));
                        let themeIndex = 0;
                        section.themes?.forEach(theme => {
                            theme.isURL = theme.redirectionType == 'URL';
                            theme.isGrid = theme.redirectionType == 'Grid';
                            theme.isLWC = theme.redirectionType == 'Page';
                            theme.isFlow = theme.redirectionType == 'Flow';
                            theme.lwcCmp = theme.isGrid || theme.isLWC;
                            theme.props = { ...theme.params };
                            if (theme.isLWC) {
                                theme.icon = 'utility:matrix';
                                theme.props['recordId'] = this.recordId;
                            } else if (theme.isGrid) {
                                theme.props['pluginIcon'] = theme.icon;
                                theme.props['recordId'] = this.recordId;
                                theme.icon = 'utility:table';
                                theme.props['templateName'] = theme.props['templateName'] || theme.redirection;
                                theme.props['applyNewDesign'] = theme.props['applyNewDesign'] || true;
                                theme.props['cmpHeight'] = theme.props['cmpHeight'] || this.gridSettingsPluginHeight;
                            } else if (theme.isURL) {
                                theme.icon = 'utility:new_window';
                            } else if (theme.isFlow) {
                                theme.icon = 'utility:flow';
                            }
                            themeIndex++;
                        })
                        this.currentSectionSettings = section;
                        if (this.activeTheme == null || this.activeTheme > this.currentSectionSettings.themes.length) {
                            this.activeTheme = 0;
                        }

                    }
                    sectionIndex++;
                })
                this.isLoading = false;
            }).catch(error => {
                this.isLoading = false;
                console.error(error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            this.isLoading = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleChangeActiveTab(event) {
        this.activeTheme = event.target.value;
        let index = event.target.dataset.index;
        let theme = this.currentSectionSettings.themes[index];
        this.loadLWC(theme);
    }

    loadLWC(theme) {
        if (theme.isLWC) {
            const loader = componentMap[theme.redirection];
            if (loader) {
                loader().then(({ default: ctor }) => {
                    theme.cmp = ctor;
                    theme.cmpIsReady = true;
                }).catch(console.error);
            } else {
                console.warn(`Component "${theme.redirection}" not found`);
            }
        } else if (theme.isGrid) {
            const loader = componentMap['gridSettingsPlugin'];
            if (loader) {
                loader().then(({ default: ctor }) => {
                    theme.cmp = ctor;
                    theme.cmpIsReady = true;
                }).catch(console.error);
            } else {
                console.warn(`Component "${theme.redirection}" not found`);
            }
        } else if (theme.isURL) {
            window.open(theme.redirection);
        } else if (theme.isFlow) {
            theme.flowVariables = [];
            theme.flowInfoIsReady = false;
            getFlowVariables({ flowApiName: theme.redirection }).then((result) => {
                let flowVariables = JSON.parse(result);
                let variableExist = flowVariables.filter(variable => variable.isInput && variable.name == 'recordId')
                if (variableExist && variableExist.length > 0) {
                    theme.flowVariables = [{
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    }];
                    theme.flowInfoIsReady = true;
                } else {
                    theme.flowInfoIsReady = true;
                }
            });
        }
    }

    handleFlowStatusChange(event) {
        //TODO : store the output values (event.detail.outputVariables)
        if (event.detail.status === "ERROR") {
            this.showNotification(this.labels.LBL_Error, event.detail.status, 'error', 'sticky');
        }
    }

    replaceCapsWithHyphenLower(str) {
        return str.replace(/([A-Z])/g, (match) => '-' + match.toLowerCase());
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
        this.gridSettingsPluginHeight = mainPanelHeight - 100 + 'px';
    };
    //MISC
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