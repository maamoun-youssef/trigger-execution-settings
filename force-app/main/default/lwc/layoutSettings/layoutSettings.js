import { LightningElement, track } from 'lwc';
import { labels } from './properties.js';
import initData from '@salesforce/apex/LayoutSettingsController.initData';
import getLayoutPagesList from '@salesforce/apex/LayoutSettingsController.getLayoutPagesList';
import saveSettings from '@salesforce/apex/LayoutSettingsController.saveSettings';
import getFields from '@salesforce/apex/LayoutSettingsController.getFields';
import getLayoutPageByDeveloperName from '@salesforce/apex/LayoutSettingsController.getLayoutPageByDeveloperName';
import checkDeploymentStatus from '@salesforce/apex/LayoutSettingsController.checkDeploymentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class LayoutSettings extends LightningElement {
    labels = labels;
    @track Loading = false;
    @track isSidebarOpen = true;
    @track templateName = '';
    @track isNewTemplate = false;
    @track layouts = [];
    @track isLeftOpen = true;
    @track isRightOpen = true;
    @track showTemplate = false;
    @track showObjectDropdown = false;
    @track screenFlowsList = [];
    @track activityObjectFields = [];
    @track taskObjectFields = [];
    @track fileDirectoryData = [];
    @track objectsList = [];
    @track gridSettings = [];
    
    @track normalizedApiName = {
        ObjectApiName__c: 'ObjectApiName__c'
    };
    @track newTemplatePopup = {
        isOpen: false
    }
    @track instance = {
        LayoutPages: [],
        fieldNameOptions: [],
        objectChildRelationship: [],
        objectChildRelationshipOptions: [],
        currentLayout: {
            settings: {
                objectApiName: '',
                type: '',
                label: '',
                description: '',
                isActive: true,
                sectionGroupTab: [],
                sections: []
            },
            settingsWrappers: {
                tabsConfigurationWrapper: []
            }
        }
    }
    tabComponentsOptions = [
        { label: 'grid', value: 'grid' },
        { label: 'page', value: 'page' },
    ];
    /*=======================
        lifecycle hooks
      =======================
     */
    connectedCallback() {
        this.Loading = true;
        this.initData();
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
    disconnectedCallback() {
        if (this._resizeHandler) {
            window.removeEventListener('resize', this._resizeHandler);
        }
    }
    initData() {
        try {
            let self = this;
            initData().then((result) => {
                let parsedResult = JSON.parse(result);
                self.normalizedApiName = {
                    ObjectApiName__c: parsedResult.prefix + 'ObjectApiName__c'
                };
                self.objectsList = parsedResult.objects;
                self.screenFlowsList = parsedResult.screenFlows;
                self.taskObjectFields = parsedResult.taskObjectFields?.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                self.activityObjectFields = parsedResult.activityObjectFields?.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                let gridSettings = parsedResult.gridSettings
                    .map(obj => ({ label: obj.labels, value: obj.QualifiedApiName }));
                this.gridSettings = [...gridSettings];
                this.fileDirectoryData = parsedResult.fileDirectoryData?.map(obj => ({
                    label: obj.label,
                    value: obj.value
                }));
                this.lwcParamsSettingsList = parsedResult.lwcParamsSettingsList || [];
                this.LoadLayoutPages().then(() => {
                    self.Loading = false;
                });
            });
        } catch (error) {
            this.Loading = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    LoadLayoutPages() {
        try {
            return getLayoutPagesList().then(result => {
                console.log('result list:' + JSON.stringify(result));
                this.instance.LayoutPages = result?.map(template => ({
                    label: template.MasterLabel,
                    value: template.key,
                    namespacePrefix: template.NamespacePrefix,
                    currentObject: template[this.normalizedApiName.ObjectApiName__c],
                    selected: false,
                    listItemClass: 'slds-split-view__list-item'
                }));
                this.layouts = this.instance.LayoutPages;
                console.log('layouts list:' + JSON.stringify(this.layouts));
                //this.Loading = false;
                return result;
            }).catch(error => {
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
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
    setPageSize() {
        try {
            const mainContainer = this.template.querySelector('.mainContainer');
            const pageHeader = this.template.querySelector('.header');
            const pageBody = this.template.querySelector('.pageBody');
            const tabsContents = this.template.querySelectorAll('.tabsContent');
            if (mainContainer && pageHeader && pageBody) {
                const height = mainContainer.offsetHeight - pageHeader.offsetHeight - 16;
                pageBody.style.height = `${height}px`;
                tabsContents.forEach(tab => {
                    tab.style.height = `${height - 40}px`;
                });
                // tabsContent.style.height = `${height - 40}px`;
                // tabsContent.style.width = `${width}px`;
            }
        } catch (error) {
            console.log(error);
        }
    }

    /* ============================
       header handlers
       ============================
     */
    handleNew() {
        this.isNewTemplate = true;
        this.newTemplatePopup.isOpen = true;
    }
    handleCancel() {
        this.showTemplate = false;
        this.resetTemplate();
    }
    handlePreview() {
    }
    handlePublish() {
    }
    openSaveAsPopup() {
    }
    openDeleteConfirmationPopup() {
    }
    /* ============================
       layouts list handlers
       ============================
     */
    focusTemplateInput(event) {
        let self = this;
        this.hasLayouts = this.layouts.length > 0;
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            templateOptionsSection.classList.add("slds-is-open");
        }
    }
    searchTemplate(event) {
        this.searchTermTemplate = event.target.value;
        const queryTermTemplate = (event.target.value || '').trim() ? new RegExp((event.target.value || '').toLowerCase().trim()
            .split('*')
            .map(s => s.replace(/[\\^$.*+?()[\]{}|]/g, '\\$&'))
            .join('.*'), 'iu')
            : '';
        this.layouts = queryTermTemplate != '' ? this.instance.LayoutPages.filter(item => {
            let matchesLabel = item.label.match(queryTermTemplate);
            let matchesDevName = item.value.match(queryTermTemplate);
            return (matchesLabel && matchesLabel.length) || (matchesDevName && matchesDevName.length);
        }) : this.instance.LayoutPages?.map(item => item);
        this.hasLayouts = this.layouts.length > 0;
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            templateOptionsSection.classList.add("slds-is-open");
        }
    }
    TemplateChangeHandler(event) {
        const templateValue = event.currentTarget.dataset.id;
        this.SelectLayoutPage(templateValue);
    }
    SelectLayoutPage(templateValue) {
        this.Loading = true;
        this.instance.LayoutPages = this.instance.LayoutPages?.map(layout => ({
            ...layout,
            selected: layout.value === templateValue,
            listItemClass: layout.value === templateValue ? 'slds-split-view__list-item slds-is-selected' : 'slds-split-view__list-item'
        }));
        this.layouts = this.instance.LayoutPages;
        const developerName = templateValue?.includes('__') ? templateValue.split('__').slice(1).join('__') : templateValue;
        getLayoutPageByDeveloperName({ developerName }).then(result => {
            let layout = JSON.parse(result);
            //layout.layoutSettings.fieldsConfiguration =
            this.instance.currentLayout.settingsWrappers.tabsConfigurationWrapper =
                layout.layoutSettings?.components?.map((elt, index) => {
                    return {
                        ...elt,
                        isGridFile: elt?.contentType === 'grid',
                        key: index
                    };
                }) || [];
            this.templateName = developerName;
            this.instance.currentLayout.settings = {
                ...this.instance.currentLayout.settings,
                ...layout.layoutSettings,
                name: this.templateName,
                label: layout.layoutSettings?.label || 'Default Label'
            };
            this.instance.fieldNameOptions = layout.selectedObjectFields.map(field => ({
                label: field.label || field.apiName,
                value: field.apiName
            }));
            this.instance.objectChildRelationship = layout.childRelationships || [];
            this.instance.objectChildRelationshipOptions = (layout.childRelationships || []).map((r) => ({
                label: r.label || `${r.childObjectApiName} · ${r.relationshipApiName}`,
                value: r.relationshipApiName
            }));
            this.instance.objectChildRelationshipOptions.unshift({ label: 'None', value: '' });
            this.showTemplate = true;
            this.isNewTemplate = false;
            this.Loading = false;
        }).catch(error => {
            console.log('error in get layout page by developer name:' + error.message);
            this.showNotification(this.Label.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky')
            this.Loading = false;
        });
    }
    handleToggleSidebar() {
        this.isSidebarOpen = !this.isSidebarOpen;
    }
    /* ============================
       popups handlers
       ============================
     */
    //============ create new template popup
    showallObjects() {
        this.showObjectDropdown = true;
    }
    handleChangeLayoutObject(event) {
        const value = event.target.value ?? event.currentTarget.dataset.value;
        this.instance.currentLayout.settings.objectApiName = value;
        this.showObjectDropdown = false;
        if (!this.newTemplatePopup.isOpen) this.loadFields(value);
    }
    createNewTemplate() {
        this.newTemplatePopup.isOpen = false;
        try {
            const objectApiName = this.instance.currentLayout.settings.objectApiName;
            if (objectApiName) {
                this.handleSave();
                this.showTemplate = true;
                //this.loadFields(objectApiName);
            }
        } catch (error) {
            console.log('error in saving new template: ' + error.message);
            console.log('error in saving new template: ' + error.stack);
        }

    }
    handleCancelNewTemplate() {
        this.newTemplatePopup.isOpen = false;
        this.resetTemplate();
    }
    /* ============================
       selected template handlers
       ============================
     */
    toggleLeft() {
        this.isLeftOpen = !this.isLeftOpen;
    }

    toggleRight() {
        this.isRightOpen = !this.isRightOpen;
    }
    /* ============================
       global handlers
       ============================
     */
    loadFields(objectName) {
        if (!objectName) {
            this.Loading = false;
            this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Object_Should_Be_Filled, 'warning', '');
            return;
        }
        return getFields({ objectName: objectName })
            .then((result) => {
                this.instance.fieldNameOptions = result.fieldList.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                this.instance.objectChildRelationship = result.childRelationships || [];
                //add none option to relationship options
                this.instance.objectChildRelationshipOptions = (result.childRelationships || []).map((r) => ({
                    label: r.label || `${r.childObjectApiName} · ${r.relationshipApiName}`,
                    value: r.relationshipApiName
                }));
                this.instance.objectChildRelationshipOptions.unshift({ label: 'None', value: '' });
                this.Loading = false;
                return result;
            })
            .catch((error) => {
                console.log(this.labels.LBL_Error + JSON.stringify(error));
                return Promise.reject(error);
            });
    }
    handleSave() {
        try {
            this.Loading = true;
            if (this.isNewTemplate) this.templateName = this.instance.currentLayout.settings.label.replace(/\s+/g, '_');
            console.log('------------ this.instance.currentLayout.settings:' + JSON.stringify(this.instance.currentLayout.settings));
            saveSettings({ pageLayoutSettingsJSON: JSON.stringify(this.instance.currentLayout.settings) })
                .then(result => {
                    console.log('handle save:' + JSON.stringify(result));
                    this.checkDeployementStatus(result);
                    //this.SelectLayoutPage(this.templateName);
                }).catch(error => {
                    console.error('Save error:', JSON.stringify(error));
                    console.error('Full error:', error);
                    this.showNotification(this.labels.LBL_Error, error, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.Loading = false;
                })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            this.Loading = false;
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    handlePageLayoutSettingsChange(event) {
        const settingsField = event.currentTarget.dataset.field;
        const type = event.currentTarget.dataset.type;
        const rowIndex = event.currentTarget.dataset.rowindex;
        let value;
        if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
            value = event.target.checked;
        } else {
            value = event.target.value ?? event.currentTarget.dataset.value;
            if (value === 'true' || value === 'false') {
                value = value === 'true';
            }
        }
        if (rowIndex !== undefined) {
            if (type) {
                this.instance.currentLayout.settings[settingsField][rowIndex][type] = value;
            } else {
                this.instance.currentLayout.settings[settingsField][rowIndex] = value;
            }
        } else {
            if (type) {
                this.instance.currentLayout.settings[settingsField][type] = value;
            } else {
                this.instance.currentLayout.settings[settingsField] = value;
            }
        }
        console.log('>>>>>>>>>>>>>>>>>>> label:' + JSON.stringify(this.instance.currentLayout.settings[settingsField]));
    }
    resetTemplate() {
        this.templateName = null;
        this.isNewTemplate = false;
        this.showTemplate = false;
        this.instance = {
            ...this.instance,
            showObjectDropdown: false,
            fieldNameOptions: [],
            currentLayout: {
                settings: {
                    objectApiName: '',
                    type: '',
                    label: '',
                    description: '',
                    isActive: true,
                    sectionGroupTab: [],
                    sections: []
                }
            }
        }
        this.templateFilterCriteriaWrapper = {
            selectedField: null,
            selectedIndex: null,
            currentCriteria: {
                fieldName: '',
                operator: '=',
                value: ''
            }
        }
        this.instance.LayoutPages = this.instance.LayoutPages?.map(layout => ({
            ...layout,
            selected: false,
            listItemClass: 'slds-split-view__list-item'
        }));
        this.layouts = this.instance.LayoutPages;
        this.showTemplate = false;
    }
    checkDeployementStatus(idDeployment) {
        let counter = 0;
        let status;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            let fdone = JSON.parse(fresult).deployResult.done;
            status = JSON.parse(fresult).deployResult.status;
            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        clearInterval(interval);
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Error, '', 'info')
                        this.Loading = false;
                        return;
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            clearInterval(interval);
                            if (success) {
                                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Success, 'success');
                            } else {
                                this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                            }
                            this.Loading = true;
                            this.LoadLayoutPages().then(() => {
                                if (this.templateName) {
                                    this.SelectLayoutPage(this.templateName);
                                }
                            }).catch(() => { });
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Success, 'success')
                this.Loading = true;
                this.LoadLayoutPages().then(() => {
                    if (this.templateName) {
                        this.SelectLayoutPage(this.templateName);
                    }
                }).catch(() => { });
            }
        });
    }
    /* ============================
       GETTERS
       ============================
     */
    get sidebarClass() {
        return `slds-col ${this.isSidebarOpen ? 'slds-size_1-of-4' : 'slds-hide'} slds-border_right sidebar`;
    }
    get tabContainerClass() {
        return `slds-form_stacked slds-col ${(this.isSidebarOpen && !this.showTemplate) ? 'slds-size_3-of-4' : 'slds-size_1-of-1'} tabcontainer`;
    }
    get sidebarToggleIcon() {
        return this.isSidebarOpen ? 'utility:chevronleft' : 'utility:chevronright';
    }
    get sidebarToggleTitle() {
        return this.isSidebarOpen ? 'Hide sidebar' : 'Show sidebar';
    }
    get statusLabel() {
        return this.instance?.currentLayout?.settings?.isActive ? 'Active' : 'Inactive';
    }
    get statusBadgeClass() {
        return this.instance?.currentLayout?.settings?.isActive ? 'status-active' : 'status-inactive';
    }
    get leftSize() {
        return 'slds-col slds-size_2-of-12';
    }
    get rightSize() {
        return 'slds-col slds-size_3-of-12 slds-scrollable--y';
    }
    get middleSize() {
        let size = 12;

        if (this.isLeftOpen) {
            size -= 2;
        }
        if (this.isRightOpen) {
            size -= 3;
        }
        return `slds-col slds-size_${size}-of-12`;
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