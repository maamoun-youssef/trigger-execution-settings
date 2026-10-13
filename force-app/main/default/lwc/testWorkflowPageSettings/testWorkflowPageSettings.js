import { LightningElement, track } from 'lwc';
import { Labels } from './properties.js';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLayoutPagesList from '@salesforce/apex/testWorkflowPageSettingsCtrl.getLayoutPagesList';
export default class TestWorkflowPageSettings extends LightningElement {
    Label = Labels;
    @track Loading = false;
    @track resizeHandler;
    @track bodySize;
    _resizeHandler;
    _pageSized = false;
    @track showTemplate = false;
    @track selectedTemplateName;
    @track isSidebarOpen = true;
    @track layouts = [];
    @track searchTermTemplate = '';
    @track instance = {
        LayoutPages: [],
        name: ''
    }
    connectedCallback() {
        this.Loading = true;
        this.LoadLayoutPages().then(() => {
            this.Loading = false;
        });
    }
    renderedCallback() {
        if (!this._pageSized) {
            this._pageSized = true;
            this._resizeHandler = this.setPageSize.bind(this);
            window.addEventListener('resize', this._resizeHandler);
            setTimeout(() => {
                this.setPageSize();
            }, 100);
        }
    }
    setPageSize() {
        try {
            const mainContainer = this.template.querySelector('.mainContainer');
            const pageHeader = this.template.querySelector('.header');
            const pageBody = this.template.querySelector('.pageBody');
            if (mainContainer && pageHeader && pageBody) {
                const height = mainContainer.offsetHeight - pageHeader.offsetHeight - 16;
                pageBody.style.height = `${height}px`;
                this.bodySize = height;
                // tabsContent.style.height = `${height - 40}px`;
                // tabsContent.style.width = `${width}px`;
            }
        } catch (error) {
            console.log(error);
        }
    }
    LoadLayoutPages() {
        try {
            return getLayoutPagesList().then(result => {
                console.log('----------------------result: ' + JSON.stringify(result));
                this.instance.LayoutPages = result.map(template => ({
                    label: template.MasterLabel,
                    value: template.key,
                    namespacePrefix: template.NamespacePrefix,
                    currentObject: template['ObjectApiName__c'],
                    selected: false,
                    listItemClass: 'slds-split-view__list-item'
                }));
                this.layouts = this.instance.LayoutPages;
                //this.Loading = false;
                return result;
            }).catch(error => {
                this.showNotification(this.Label.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
                this.Loading = false;
                return Promise.reject(error);
            });
        } catch (error) {
            console.log(' error load layout pages: ' + error);
            console.log(' error load layout pages: ' + error.message);
            this.Loading = false;
            return Promise.reject(error);
        }
    }
    TemplateChangeHandler(event) {
        const templateValue = event.currentTarget.dataset.id;
        this.SelectLayoutPage(templateValue);
        // this.templateApiName = event.currentTarget.dataset.id;
        // this.LoadGridLayouts();
    }
    SelectLayoutPage(templateValue) {
        this.Loading = true;
        
        this.instance.LayoutPages = this.instance.LayoutPages.map(layout => ({
            ...layout,
            selected: layout.value === templateValue,
            listItemClass: layout.value === templateValue ? 'slds-split-view__list-item slds-is-selected' : 'slds-split-view__list-item'
        }));
        this.layouts = this.instance.LayoutPages;
        const developerName = templateValue?.includes('__') ? templateValue.split('__').slice(1).join('__') : templateValue;
        this.selectedTemplateName = developerName;
        this.instance.name = developerName;
        this.showTemplate = true;
        this.Loading = false;
    }
    get sidebarClass() {
        return `slds-col ${this.isSidebarOpen ? 'slds-size_1-of-4' : 'slds-hide'} slds-border_right sidebar`;
    }
    get tabContainerClass() {
        return `slds-form_stacked slds-col ${this.isSidebarOpen ? 'slds-size_3-of-4' : 'slds-size_1-of-1'} tabcontainer`;
    }
    get sidebarToggleIcon() {
        return this.isSidebarOpen ? 'utility:chevronleft' : 'utility:chevronright';
    }
    get sidebarToggleTitle() {
        return this.isSidebarOpen ? 'Hide sidebar' : 'Show sidebar';
    }
    get hasLayouts() {
        return this.layouts && this.layouts.length > 0;
    }
    /*
     =====================
      Event Handlers
     =====================
    */
    handleNew() {
        this.showTemplate = false;
        this.selectedTemplateName = null;
        this.instance.name = '';
        this.instance.LayoutPages = this.instance.LayoutPages.map(layout => ({
            ...layout,
            selected: false,
            listItemClass: 'slds-split-view__list-item'
        }));
        this.layouts = this.instance.LayoutPages;
    }
    handleCancel() {
        this.showTemplate = false;
        this.selectedTemplateName = null;
        this.instance.name = '';
        this.instance.LayoutPages = this.instance.LayoutPages.map(layout => ({
            ...layout,
            selected: false,
            listItemClass: 'slds-split-view__list-item'
        }));
        this.layouts = this.instance.LayoutPages;
    }
    handleSave(event) {
        this.showNotification('Success', 'Changes saved successfully ', 'success');
    }
    handleToggleSidebar() {
        this.isSidebarOpen = !this.isSidebarOpen;
    }
    focusTemplateInput() {
        // Handle focus on search input
    }
    searchTemplate(event) {
        this.searchTermTemplate = event.target.value.toLowerCase();
        if (this.searchTermTemplate) {
            this.layouts = this.instance.LayoutPages.filter(layout =>
                layout.label.toLowerCase().includes(this.searchTermTemplate) ||
                layout.currentObject.toLowerCase().includes(this.searchTermTemplate)
            );
        } else {
            this.layouts = this.instance.LayoutPages;
        }
    }
    closeDropdownTemplate() {
        // Handle blur on search input
    }
    openSaveAsPopup() {
        this.showNotification('Info', 'Save As functionality coming soon', 'info');
    }
    /*
     =====================
      private helpers
     =====================
    */
    showNotification(title, message, variant, mode = 'dismissible') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }
}