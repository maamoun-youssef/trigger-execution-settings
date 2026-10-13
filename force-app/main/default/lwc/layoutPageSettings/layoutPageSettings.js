import { LightningElement, track } from 'lwc';
import { Labels, FilterOperations, FIELD_TYPE_CONFIG } from './properties.js';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initData from '@salesforce/apex/LayoutPageSettingsController.initData';
import getLayoutPagesList from '@salesforce/apex/LayoutPageSettingsController.getLayoutPagesList';
import getLayoutPageByDeveloperName from '@salesforce/apex/LayoutPageSettingsController.getLayoutPageByDeveloperName';
import getFields from '@salesforce/apex/LayoutPageSettingsController.getFields';
import getRelatedObjectFields from '@salesforce/apex/LayoutPageSettingsController.getRelatedObjectFields';
import saveSettings from '@salesforce/apex/LayoutPageSettingsController.saveSettings';
import checkDeploymentStatus from '@salesforce/apex/LayoutPageSettingsController.checkDeploymentStatus';
const OPERATIONS_WITHOUT_VALUE = [
    FilterOperations.ISNULL,
    FilterOperations.ISBLANK,
    FilterOperations.ISNOTNULL,
    FilterOperations.ISNOTBLANK,
];
export default class LayoutPageSettings extends LightningElement {
    Label = Labels;
    @track Loading = false;
    @track resizeHandler;
    _resizeHandler;
    _pageSized = false;
    @track templateName = null;
    @track isNewTemplate = false;
    @track showTemplate = false;
    @track showSaveAsMenu = false;
    @track isSidebarOpen = true;
    @track saveAsTemplateName = '';
    @track layouts = [];
    @track hasLayouts = true;
    @track searchTermTemplate = '';
    @track normalizedApiName = {
        ObjectApiName__c: 'ObjectApiName__c'
    };
    @track taskObjectFields = [];
    @track activityObjectFields = [];
    @track gridSettings = [];
    @track lwcParamsSettingsList = [];
    @track fileDirectoryData = [];
    @track iconOptions = [
        {
            label: this.Label.LBL_StaticResource,
            value: 'true'
        },
        {
            label: this.Label.LBL_Field,
            value: 'false'
        }
    ];
    _toRadioString(value) {
        return value === true ? 'true' : 'false';
    }
    rowOptions = [
        { label: '3 rows', value: 3 },
        { label: '4 rows', value: 4 },
        { label: '5 rows', value: 5 },
        { label: '6 rows', value: 6 }
    ];

    fieldCountOptions = [
        { label: '1 Field', value: 1 },
        { label: '2 Fields', value: 2 },
        { label: '3 Fields', value: 3 }
    ];
    redirectionOptions = [
        { label: 'grid', value: 'grid' },
        { label: 'page', value: 'page' },
    ];
    MANAGE_TEMPLATE_FILTER_ACTIONS = {
        FIELD_PICKER: 'fieldPicker',
        SELECT_CRITERIA: 'selectCriteria',
        CRITERIA_FIELD_CHANGE: 'criteriaFieldChange',
        ADD_CRITERIA: 'addCriteria',
        EDIT_CRITERIA: 'editCriteria',
        DELETE_CRITERIA: 'deleteCriteria',
        FILTER_LOGIC_CHANGE: 'filterLogicChange'
    }
    @track instance = {
        LayoutPages: [],
        objectsList: [],
        showObjectDropdown: false,
        fieldNameOptions: [],
        objectChildRelationship: [],
        objectChildRelationshipOptions: [],
        // selectedRelatedObjectFields : [],
        // selectedRelatedObjectFieldsOptions : [],
        screenFlowsList: [],
        currentLayout: {
            settings: {
                name: "",
                label: "",
                objectApiName: "",
                source: "",
                tabs: [],
                actionButtons: [],
                fieldsConfiguration: [],
                nbOfRows: 0,
                isFlowMode: false,
                selectedFlow: "",
                newTaskFlow: "",
                topLeftCornerFields: [],
                taskFields: [],
                bottomLeftCornerFields: [],
                topRightCornerFields: [],
                statusField: "",
                activityFields: [],
                headerField: {
                    fieldName: "",
                    isReadOnly: false,
                    isMandatory: false,
                    showHeaderField: true
                },
                relatedInformations: [],
                topLeftCornerLogo1: {
                    value: "",
                    isStaticRessource: true
                },
                topLeftCornerLogo2: {
                    value: "",
                    isStaticRessource: true
                },
                bottomLeftCornerLogo1: {
                    value: "",
                    isStaticRessource: true
                },
                bottomLeftCornerLogo2: {
                    value: "",
                    isStaticRessource: true
                },
                statusIcon: {
                    value: "",
                    isStaticRessource: true
                },
                activityRightIcon: {
                    value: "",
                    isStaticRessource: true
                },
                activityLeftIcon: {
                    value: "",
                    isStaticRessource: true
                },
                templateFilterCriteria: []
            },
            settingsWrappers: {
                templateCriteriaDisplayWrapper: [],
                actionButtonsWrapper: [],
                fieldsConfigurationSettingWrapper: [],
                tabsConfigurationWrapper: [],
                relatedInformationsWrapper: []
            }
        }
    }
    @track templateFilterCriteriaWrapper = {
        selectedField: null,
        selectedIndex: null,
        currentCriteria: {
            fieldName: '',
            operator: '=',
            value: ''
        }
    }
    @track newTemplatePopup = {
        isOpen: false
    }
    @track popups = {
        tabParams: {
            title: '',
            tab: {},
            isOpen: false,
            params: [],
            gridSettingsLayouts: [],
            handleTabParamChange: (event) => {
                let index = event.currentTarget.dataset.index;
                let param = this.popups.tabParams.params[index];
                param.value = !param.isBoolean ? event.detail.value : event.detail.checked;
            },
            close: (event) => {
                this.popups.tabParams.params = [];
                this.popups.tabParams.tab = {};
                this.popups.tabParams.isOpen = false;
            },
            confirm: (event) => {
                const params = this.popups.tabParams.params;
                const tab = this.popups.tabParams.tab;
                let isValid = true;
                params.forEach(param => {
                    if (param.required) {
                        const value = param.value;
                        if (
                            (param.isString && (!value || value.trim() === '')) ||
                            (param.isInteger && (value === null || value === undefined || value === '')) ||
                            (param.isBoolean && typeof value !== 'boolean')
                        ) {
                            isValid = false;
                        }
                    }
                });
                if (!isValid) {
                    this.showNotification(
                        this.Label.LBL_Error,
                        this.Label.MSG_Fill_Required_Fields,
                        'error',
                        'sticky'
                    );
                    return;
                }
                if (!tab.params) {
                    tab.params = {};
                }
                if (this.instance.currentLayout.settings.objectApiName) {
                    tab.params.objectApiName = this.instance.currentLayout.settings.objectApiName;
                }
                params.forEach(param => {
                    tab.params[param.name] = param.value === '' ? '' : param.value;
                });
                this.popups.tabParams.params = [];
                this.popups.tabParams.tab = {};
                this.popups.tabParams.isOpen = false;
            },
            open: (event) => {
                let index = event.currentTarget.dataset.index;
                let tab = this.instance.currentLayout.settings.tabs[index];

                let target;
                if (tab.contentType == "grid") {
                    target = "gridSettingsPlugin"
                }
                else if (tab.contentType == "page") {
                    target = "fileDirectoryManager"
                }
                let paramsSettings = this.lwcParamsSettingsList?.find(it => it.name == target);
                let params = paramsSettings?.paramSetting;
                if (params) {
                    if (tab.contentType == "grid") {
                        params = JSON.parse(JSON.stringify(params.filter(it => !['objectApiName', 'templateName']?.includes(it.name))));
                    }
                    params.forEach((param, index) => {
                        param[`is${param.type}`] = true;
                        if (param.getDataSourceList) {
                            param.datasourceList = Object.keys(param.getDataSourceList).map(value => ({ value: value, label: param.getDataSourceList[value] }));
                            param.isCombobox = param.datasourceList.length ? true : false;
                        }
                        param.paramKey = `param-${index}`;
                        param.required = param.required === 'true' || param.required === true;
                        // param.value = param.isBoolean ? param.defaultValue === 'true' :
                        //     (param.isInteger && +param.defaultValue ? +param.defaultValue : param.defaultValue);
                        if (param.isBoolean) {
                            param.value = param.defaultValue === true || param.defaultValue === 'true';
                        } else if (param.isInteger) {
                            param.value = Number(param.defaultValue);
                        } else {
                            param.value = param.defaultValue;
                        }
                    });
                    if (tab?.params) {
                        Object.keys(tab.params).forEach(name => {
                            let param = params.find(it => it.name == name);
                            if (param) {
                                const value = tab.params[name];
                                if (param.isBoolean) {
                                    param.value = value === true || value === 'true';
                                } else if (param.isInteger) {
                                    param.value = value !== null && value !== undefined && value !== ''
                                        ? Number(value)
                                        : null;
                                } else {
                                    param.value = value;
                                }
                            }
                        });
                    }
                    this.popups.tabParams.params = params;
                    this.popups.tabParams.tab = tab;
                    this.popups.tabParams.isOpen = true;
                } else {
                    this.showNotification(this.Label.LBL_Error, this.Label.Msg_NoInputParams, 'error');
                }
            },
        },
        relatedInformations: {
            isOpen: false,
            filters: [],
            groupByFields: [],
            relatedInformationRowIndex: null
        }
    }

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
                self.instance.objectsList = parsedResult.objects;
                self.instance.screenFlowsList = parsedResult.screenFlows;
                self.taskObjectFields = parsedResult.taskObjectFields.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                self.activityObjectFields = parsedResult.activityObjectFields.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                let gridSettings = parsedResult.gridSettings
                    .map(obj => ({ label: obj.Label, value: obj.QualifiedApiName }));
                this.gridSettings = [...gridSettings];
                this.fileDirectoryData = parsedResult.fileDirectoryData.map(obj => ({
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
            this.showNotification(this.Label.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    LoadLayoutPages() {
        try {
            return getLayoutPagesList().then(result => {
                this.instance.LayoutPages = result.map(template => ({
                    label: template.MasterLabel,
                    value: template.key,
                    namespacePrefix: template.NamespacePrefix,
                    currentObject: template[this.normalizedApiName.ObjectApiName__c],
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
    handleTabActive() {
        setTimeout(() => {
            this.setPageSize();
        }, 50);
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
        }) : this.instance.LayoutPages.map(item => item);
        this.hasLayouts = this.layouts.length > 0;
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            templateOptionsSection.classList.add("slds-is-open");
        }
    }
    TemplateChangeHandler(event) {
        const templateValue = event.currentTarget.dataset.id;
        this.SelectLayoutPage(templateValue);
        // this.templateApiName = event.currentTarget.dataset.id;
        // this.LoadGridLayouts();
        this.closeDropdownTemplate();
    }
    closeDropdownTemplate(event) {
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            setTimeout(() => {
                templateOptionsSection.classList.remove("slds-is-open");
            }, 200);
        }
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
        getLayoutPageByDeveloperName({ developerName }).then(result => {
            let layout = JSON.parse(result);
            //layout.layoutSettings.fieldsConfiguration =
            this.templateName = developerName;
            this.instance.currentLayout.settingsWrappers.fieldsConfigurationSettingWrapper =
                layout.layoutSettings?.fieldsConfiguration?.map((row, rowIndex) => {
                    return {
                        rowKey: rowIndex,
                        rowNumber: rowIndex + 1,
                        fields: row.map((field, colIndex) => {
                            return {
                                ...field,
                                fieldKey: colIndex
                            };
                        }),
                        fieldsNumber: row.length,
                        expanded: false
                    };
                });
            this.instance.currentLayout.settingsWrappers.tabsConfigurationWrapper =
                layout.layoutSettings?.tabs?.map((elt, index) => {
                    return {
                        ...elt,
                        isGridFile: elt?.contentType === 'grid',
                        key: index
                    };
                }) || [];
            this.instance.currentLayout.settingsWrappers.actionButtonsWrapper = layout.layoutSettings?.actionButtons?.map((elt, index) => {
                return {
                    ...elt,
                    key: index
                };
            }) || [];
            this.instance.currentLayout.settingsWrappers.relatedInformationsWrapper = layout.layoutSettings?.relatedInformations?.map((elt, index) => {
                return {
                    ...elt,
                    key: index
                };
            }) || [];
            this.instance.currentLayout.settingsWrappers.templateCriteriaDisplayWrapper = layout.layoutSettings?.templateFilterCriteria?.map(
                (criteria, index) => ({
                    rowKey: index,
                    listIndex: index,
                    expression: `${criteria.fieldName} ${criteria.operator} ${criteria.value}`
                })
            );
            this.instance.currentLayout.settings = {
                ...this.instance.currentLayout.settings,
                ...layout.layoutSettings,
                name: this.templateName,
                label: layout.layoutSettings?.name || 'Default Label'
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
    /*
        =======================
         UI events handlers
        =======================
     */
    /* ---------- Header handlers ---------- */
    handleNew() {
        this.isNewTemplate = true;
        this.newTemplatePopup.isOpen = true;
    }

    handleToggleSidebar() {
        this.isSidebarOpen = !this.isSidebarOpen;
    }
    handleCancel() {
        this.showTemplate = false;
        this.resetTemplate();
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
    saveAsTemplateNameChangeHandler(event) {
        this.saveAsTemplateName = event.detail.value;
    }
    openSaveAsPopup() {
        this.showSaveAsMenu = true;
    }
    cancelSaveAs() {
        this.saveAsTemplateName = '';
        this.showSaveAsMenu = false;
    }
    saveAsNewTemplateName() {
        //check if name already exist in an exisitng template
        try {
            const saveAsName = (this.saveAsTemplateName || '').trim();
            if (this.layouts.some(template => (template.label || '').toLowerCase() === saveAsName.toLowerCase())) {
                //open confirmation modal to confirm if user want to overwrite the existing template
                this.showNotification(this.Label.LBL_PageLayoutSettings_NewTemplateNameAlreadyExist, this.Label.MSG_PageLayoutSettings_TemplateNameAlreadyExist, 'error', 'sticky');
                return;
            }
            this.Loading = true;
            this.showSaveAsMenu = false;
            let newTemplate = structuredClone(this.instance.currentLayout.settings);
            newTemplate.name = this.saveAsTemplateName;
            saveSettings({ pageLayoutSettingsJSON: JSON.stringify(newTemplate) }).then(result => {
                this.templateName = this.saveAsTemplateName;
                this.saveAsTemplateName = '';
                this.checkDeployementStatus(result);
                // actual reload will happen once deployment finishes
            }).catch(error => {
                console.error('Save cloned template error:', error.message ? error.message : error.body?.message);
                this.showNotification(this.Label.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
            });
        } catch (error) {
            console.error('Save As New Template Name error:', error.message ? error.message : error.body?.message);
            this.showNotification(this.Label.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    /* --------- tabs handlers ----------*/
    //tab 1 general information
    showallObjects() {
        this.instance.showObjectDropdown = true;
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

    handleChangeLayoutObject(event) {
        const value = event.target.value ?? event.currentTarget.dataset.value;
        this.instance.currentLayout.settings.objectApiName = value;
        this.instance.showObjectDropdown = false;
        if (!this.newTemplatePopup.isOpen) this.loadFields(value);
    }
    //relatedinformation tab
    handleRelatedInformationsRelationshipChange(event) {
        const value = event.detail?.value ?? '';
        const index = Number(event.currentTarget.dataset.index);
        let relatedInformation = { ...this.instance.currentLayout.settings.relatedInformations[index] };
        let relatedInformationWrapper = { ...this.instance.currentLayout.settingsWrappers.relatedInformationsWrapper[index] };
        try {
            relatedInformation.parentRelationshipApiName = value;
            relatedInformationWrapper.parentRelationshipApiName = value;
            const rel = (this.instance.objectChildRelationship || []).find(
                (r) => r.relationshipApiName && r.relationshipApiName.toLowerCase() === (value || '').toLowerCase()
            );
            if (rel) {
                relatedInformation.objectApiName = rel.childObjectApiName;
                relatedInformationWrapper.objectApiName = rel.childObjectApiName;
            } else {
                relatedInformation.objectApiName = '';
                relatedInformationWrapper.objectApiName = '';
            }
            relatedInformation.filters = [];
            relatedInformationWrapper.filters = [];
            this.instance.currentLayout.settings.relatedInformations[index] = relatedInformation;
            this.instance.currentLayout.settingsWrappers.relatedInformationsWrapper[index] = relatedInformationWrapper;
        } catch (error) {
            console.error('Error handling relationship change:', error);
            console.error('Error handling relationship change:', error.message);
        }
    }
    openRelatedInformationsPopup(event) {
        let index = Number(event.currentTarget.dataset.index);
        const relatedConfig = this.instance.currentLayout.settings.relatedInformations[index];
        this.popups.relatedInformations.filters = (relatedConfig.filters || []).map((item, index) => {
            const operator = item.operator || '';
            return {
                rowKey: `flt-${index}`,
                fieldName: item.fieldName || '',
                operator,
                value: item.value ?? '',
                inputType: 'text',
                fieldType: '',
                isPicklist: false,
                isMultiPicklist: false,
                isReference: false,
                picklistValues: [],
                previousObject: '',
                refFieldName: '',
                operationsOptions: FIELD_TYPE_CONFIG.getInitialValueByType(''),
                disableValue: OPERATIONS_WITHOUT_VALUE.includes(operator)
            }
        });
        this.popups.relatedInformations.relatedInformationRowIndex = index;
        this.popups.relatedInformations.objectApiName = relatedConfig.objectApiName;
        this.popups.relatedInformations.isOpen = true;
    }
    handleRelatedInformationBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = Number(event.currentTarget.dataset.index);
        let relatedInformations = [...this.instance.currentLayout.settings.relatedInformations];
        let relatedInformationsWrapper = [...this.instance.currentLayout.settingsWrappers.relatedInformationsWrapper];
        switch (action) {
            case 'delete':
                // Code to execute if expression === value1
                relatedInformations.splice(index, 1);
                relatedInformationsWrapper.splice(index, 1);
                this.instance.currentLayout.settings.relatedInformations = relatedInformations;
                this.instance.currentLayout.settingsWrappers.relatedInformationsWrapper = relatedInformationsWrapper;
                break;
            case 'add':
                // Code to execute if expression === value2
                if (this.instance.currentLayout.settings.relatedInformations.length > 5) {
                    this.showNotification(this.Label.MSG_Warning, this.Label.MSG_Max_Button_Limit_Reached, 'warning', '');
                    return;
                }
                relatedInformations.push({ filters: [], label: "", objectApiName: "", parentRelationshipApiName: "" });
                relatedInformationsWrapper.push({ "key": relatedInformationsWrapper.length, filters: [], label: "", objectApiName: "", parentRelationshipApiName: "" });
                this.instance.currentLayout.settings.relatedInformations = relatedInformations;
                this.instance.currentLayout.settingsWrappers.relatedInformationsWrapper = relatedInformationsWrapper;
                break;
            default:
        }
    }
    handleRelatedInformationsFilterRows(event) {
        let action = event.currentTarget.dataset.action;
        let rowindex = event.currentTarget.dataset.rowindex;
        let filters = [...this.popups.relatedInformations.filters];
        const index = this.popups.relatedInformations.filters.length;
        switch (action) {
            case 'delete':
                filters.splice(rowindex, 1);
                break;
            case 'add':
                filters.push({
                    rowKey: `flt-${index}`,
                    fieldName: '',
                    operator: '',
                    value: '{recordId}',
                    inputType: 'text',
                    fieldType: '',
                    isPicklist: false,
                    isMultiPicklist: false,
                    isReference: false,
                    picklistValues: [],
                    previousObject: '',
                    refFieldName: '',
                    operationsOptions: [],
                    disableValue: true
                });
                break;
            default:
        }
        this.popups.relatedInformations.filters = filters;
    }
    addRelatedInformationsFilterRow() {
        try {
            this.popups.relatedInformations.filters = [
                ...this.popups.relatedInformations.filters,
                {
                    rowKey: `flt-${index}`,
                    fieldName: '',
                    operator: '',
                    value: '{recordId}',
                    inputType: 'text',
                    fieldType: '',
                    isPicklist: false,
                    isMultiPicklist: false,
                    isReference: false,
                    picklistValues: [],
                    previousObject: '',
                    refFieldName: '',
                    operationsOptions: [],
                    disableValue: true
                }
            ];
        } catch (error) {
            console.log('error in adding new filter row:' + error);
            console.log('error in adding new filter row:' + error.message);
        }

    }
    handleRelatedInformationsFieldSelect(event) {
        const index = Number(event.currentTarget.dataset.index);
        const selectedField = event.detail;
        const filter = { ...this.popups.relatedInformations.filters[index] };
        if (!selectedField?.fieldName) {
            filter.fieldName = '';
            filter.fieldType = '';
            filter.isPicklist = false;
            filter.isMultiPicklist = false;
            filter.isReference = false;
            filter.picklistValues = [];
            filter.previousObject = '';
            filter.refFieldName = '';
            filter.inputType = 'text';
            filter.operationsOptions = FIELD_TYPE_CONFIG.getOperatorsByType('');
        } else {
            const fieldType = selectedField.fieldType || '';
            const isMultiPicklist = fieldType === 'MultiPicklist';
            filter.fieldName = selectedField.fieldName;
            filter.fieldType = fieldType;
            filter.isReference = !!selectedField.isReference;
            filter.isMultiPicklist = isMultiPicklist;
            filter.isPicklist = !!selectedField.isPicklist && !isMultiPicklist;
            filter.picklistValues = Array.isArray(selectedField.picklistValues) ? selectedField.picklistValues : JSON.parse(selectedField.picklistValues || '[]');
            filter.previousObject = selectedField.previousObject || '';
            filter.refFieldName = selectedField.refFieldName || '';
            filter.inputType = FIELD_TYPE_CONFIG.getInputTypeByType(fieldType);
            filter.operationsOptions = FIELD_TYPE_CONFIG.getOperatorsByType(fieldType);
        }
        filter.value = '';
        filter.operator = '';
        filter.disableValue = false;
        this.popups.relatedInformations.filters[index] = filter;
        // this.popups.relatedInformations.filters = [
        //     ...this.popups.relatedInformations.filters
        // ];
    }
    handleRelatedInformationsFieldRestore(event) {
        const index = Number(event.currentTarget.dataset.index);
        const selectedField = event.detail || {};
        //check the list and find the field returned and change the type of the row based on the incomming data
        const filter = { ...this.popups.relatedInformations.filters[index] };
        if (selectedField?.fieldName) {
            const fieldType = selectedField.fieldType || '';
            const isMultiPicklist = fieldType === 'MultiPicklist';
            filter.fieldName = selectedField.fieldName;
            filter.fieldType = fieldType;
            filter.isReference = !!selectedField.isReference;
            filter.isMultiPicklist = isMultiPicklist;
            filter.isPicklist = !!selectedField.isPicklist && !isMultiPicklist;
            filter.picklistValues = Array.isArray(selectedField.picklistValues) ? selectedField.picklistValues : JSON.parse(selectedField.picklistValues || '[]');
            filter.previousObject = selectedField.previousObject || '';
            filter.refFieldName = selectedField.refFieldName || '';
            filter.inputType = FIELD_TYPE_CONFIG.getInputTypeByType(fieldType);
            filter.operationsOptions = FIELD_TYPE_CONFIG.getOperatorsByType(fieldType);
            filter.disableValue = OPERATIONS_WITHOUT_VALUE.includes(filter.operator);
        }

        this.popups.relatedInformations.filters[index] = filter;
    }
    getFilterValueInputType(fieldType) {
        if (!fieldType) {
            return 'text';
        }
        const type = fieldType.toLowerCase();
        if (type === 'double' || type === 'integer' || type === 'currency' || type === 'percent' || type === 'long') {
            return 'number';
        }
        if (type === 'date') {
            return 'date';
        }
        if (type === 'datetime') {
            return 'datetime';
        }
        if (type === 'boolean') {
            return 'checkbox';
        }
        return 'text';
    }
    handleRelatedInformationsFilterChange(event) {
        const index = Number(event.currentTarget.dataset.index);
        const field = event.currentTarget.dataset.field;
        let value = event.detail?.value ?? event.target.value;
        if (field === 'value' && event.target.type === 'checkbox') {
            value = event.target.checked;
        }
        const filter = { ...this.popups.relatedInformations.filters[index] };
        filter[field] = value;
        if (field === 'operator') {
            filter.disableValue = false;
            if (OPERATIONS_WITHOUT_VALUE.includes(value)) {
                filter.disableValue = true;
                filter.value = '';
            }
        }
        this.popups.relatedInformations.filters[index] = filter;
        this.popups.relatedInformations.filters = [...this.popups.relatedInformations.filters];
    }
    confirmRelatedInformationsPopup(event) {
        let index = Number(event.currentTarget.dataset.index);
        try {
            this.instance.currentLayout.settings.relatedInformations[index].filters = this.popups.relatedInformations.filters
                .filter(item => {
                    if (!item.fieldName || !item.operator) {
                        return false;
                    }
                    if (OPERATIONS_WITHOUT_VALUE.includes(item.operator)) {
                        return true;
                    }
                    return item.value !== '';
                }).map(item => ({ fieldName: item.fieldName, operator: item.operator, value: item.value, fieldType: item.fieldType }));
            this.closeRelatedInformationsPopup();
        } catch (error) {
            console.log('error in confirm related information popup :' + error.message);
        }

    }
    closeRelatedInformationsPopup() {
        this.popups.relatedInformations.isOpen = false;
        this.popups.relatedInformations.filters = [];
        this.popups.relatedInformations.groupByFields = [];
        this.popups.relatedInformations.objectApiName = [];
        this.popups.relatedInformations.relatedInformationRowIndex = null;
    }
    //fields configuration
    handleFieldsConfigurationChange(event) {
        const type = event.currentTarget.dataset.type;
        const colIndex = event.currentTarget.dataset.colindex;
        const rowIndex = event.currentTarget.dataset.rowindex;
        let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        try {
            if (rowIndex !== undefined && colIndex !== undefined) {
                if (type === 'fieldName' && value) {
                    const fieldsConfiguration = this.instance.currentLayout.settings.fieldsConfiguration || [];
                    const isDuplicate = fieldsConfiguration.some((row, rIndex) =>
                        row.some((field, cIndex) =>
                            field.fieldName === value && (String(rIndex) !== String(rowIndex) || String(cIndex) !== String(colIndex))
                        )
                    );
                    if (isDuplicate) {
                        const previousValue = this.instance.currentLayout.settings.fieldsConfiguration[rowIndex]?.[colIndex]?.fieldName || '';
                        if (event.target && event.target.value !== undefined) {
                            event.target.value = previousValue;
                        }
                        this.showNotification(this.Label.MSG_Warning, this.Label.MSG_PageLayoutSettings_FieldAlreadySelected, 'warning', '');
                        return;
                    }
                }
                this.instance.currentLayout.settings.fieldsConfiguration[rowIndex][colIndex][type] = value;
                this.instance.currentLayout.settingsWrappers.fieldsConfigurationSettingWrapper[rowIndex].fields[colIndex][type] = value;
            }
        } catch (error) {
            console.error(error);
            console.log(error.message);
        }
    }
    handleRowsChange(event) {
        const action = event.currentTarget.dataset.action;
        const rowIndex = event.currentTarget.dataset.rowindex;
        let wrapperRows = [...this.instance.currentLayout.settingsWrappers.fieldsConfigurationSettingWrapper];
        let fieldsConfiguration = [...this.instance.currentLayout.settings.fieldsConfiguration];
        try {
            switch (action) {
                case 'add':
                    if (wrapperRows.length >= 6) return;
                    wrapperRows.push({
                        rowKey: wrapperRows.length,
                        rowNumber: wrapperRows.length + 1,
                        fields: [{ isReadOnly: false, isMandatory: false, fieldName: '', fieldKey: 0 }],
                        fieldsNumber: 1,
                        expanded: false
                    });
                    fieldsConfiguration.push([{ isReadOnly: false, isMandatory: false, fieldName: '' }]);
                    break;
                case 'delete':
                    const index = wrapperRows.findIndex(row => String(row.rowKey) === String(rowIndex));
                    if (index === -1) { return; }
                    wrapperRows.splice(index, 1);
                    fieldsConfiguration.splice(index, 1);
                    for (let i = index; i < wrapperRows.length; i++) {
                        wrapperRows[i].rowKey = i;
                        wrapperRows[i].rowNumber = i + 1;
                    }
                    break;
                case 'toggle':
                    wrapperRows = wrapperRows.map(row => {
                        if (String(row.rowKey) === String(rowIndex)) {
                            return {
                                ...row,
                                expanded: !row.expanded
                            };
                        }
                        return row;
                    });
                    break;
                default:
                    return;
            }
            this.instance.currentLayout.settings.nbOfRows = wrapperRows.length;
            this.instance.currentLayout.settingsWrappers.fieldsConfigurationSettingWrapper = wrapperRows;
            this.instance.currentLayout.settings.fieldsConfiguration = fieldsConfiguration;
        } catch (error) {
            console.log('error in ');
        }
    }
    handleFieldCountChange(event) {
        const rowIndex = event.currentTarget.dataset.rowindex;
        const count = parseInt(event.detail.value, 10);
        let wrapperRows = [...this.instance.currentLayout.settingsWrappers.fieldsConfigurationSettingWrapper];
        let fieldsConfiguration = [...this.instance.currentLayout.settings.fieldsConfiguration];
        let fields = [...wrapperRows[rowIndex].fields];
        if (count > fields.length) {
            for (let i = fields.length; i < count; i++) {
                fields.push({
                    "isReadOnly": false,
                    "isMandatory": false,
                    "fieldName": "",
                    "fieldKey": i
                });
                fieldsConfiguration[rowIndex].push({ isReadOnly: false, isMandatory: false, fieldName: "" });
            }
        } else if (count < fields.length) {
            fields = fields.slice(0, count);
            fieldsConfiguration[rowIndex] = fieldsConfiguration[rowIndex].slice(0, count);
        }
        wrapperRows[rowIndex].fields = fields;
        wrapperRows[rowIndex].fieldsNumber = count;
        this.instance.currentLayout.settingsWrappers.fieldsConfigurationSettingWrapper = wrapperRows;
        this.instance.currentLayout.settings.fieldsConfiguration = fieldsConfiguration;
    }

    handleConfigActionBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = Number(event.currentTarget.dataset.index);
        let actionButtons = [...this.instance.currentLayout.settings.actionButtons];
        let actionButtonsWrapper = [...this.instance.currentLayout.settingsWrappers.actionButtonsWrapper];
        switch (action) {
            case 'delete':
                // Code to execute if expression === value1
                actionButtons.splice(index, 1);
                actionButtonsWrapper.splice(index, 1);
                this.instance.currentLayout.settings.actionButtons = actionButtons;
                this.instance.currentLayout.settingsWrappers.actionButtonsWrapper = actionButtonsWrapper;
                break;
            case 'add':
                // Code to execute if expression === value2
                if (this.instance.currentLayout.settings.actionButtons.length > 5) {
                    this.showNotification(this.Label.MSG_Warning, this.Label.MSG_Max_Button_Limit_Reached, 'warning', '');
                    return;
                }
                actionButtons.push({ "label": "", "flow": "", "color": "#B0CD6B" });
                actionButtonsWrapper.push({ "key": actionButtonsWrapper.length, "label": "", "flow": "", "color": "#B0CD6B" });
                this.instance.currentLayout.settings.actionButtons = actionButtons;
                this.instance.currentLayout.settingsWrappers.actionButtonsWrapper = actionButtonsWrapper;
                break;
            default:
        }
    }
    //tabs configuration
    handleChangeRedirectiontabsSettings(event) {
        let value = event.target.value;
        let index = event.target.dataset.rowindex;
        this.instance.currentLayout.settings.tabs[index].contentType = value;
        this.instance.currentLayout.settingsWrappers.tabsConfigurationWrapper[index].contentType = value;
        this.instance.currentLayout.settingsWrappers.tabsConfigurationWrapper[index].isGridFile = (value === 'grid');
    }
    handleCollectionRowChange(event) {
        const settingsField = event.currentTarget.dataset.field;
        const settingsWrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = event.currentTarget.dataset.rowindex;
        let value = event.target.value ?? event.currentTarget.dataset.value;
        this.instance.currentLayout.settings[settingsField][rowIndex][type] = value;
        this.instance.currentLayout.settingsWrappers[settingsWrapper][rowIndex][type] = value;
    }
    handleConfigTabBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = event.currentTarget.dataset.rowindex;
        let tabs = [...this.instance.currentLayout.settings.tabs];
        let tabsWrapper = [...this.instance.currentLayout.settingsWrappers.tabsConfigurationWrapper];
        let rowsCount = tabs.length;
        switch (action) {
            case 'delete':
                // Code to execute if expression === value1
                tabs.splice(index, 1);
                tabsWrapper.splice(index, 1);
                break;
            case 'add':
                // Code to execute if expression === value2
                if (rowsCount > 8) {
                    this.showNotification(this.Label.MSG_Warning, this.Label.MSG_Max_Tab_Limit_Reached, 'warning', '');
                    return;
                }
                tabs.push({ label: '', content: '', contentType: '' });
                tabsWrapper.push({ label: '', content: '', contentType: '', key: rowsCount, isGridFile: false });

                break;
            default:
        }
        this.instance.currentLayout.settings.tabs = tabs;
        this.instance.currentLayout.settingsWrappers.tabsConfigurationWrapper = tabsWrapper;
    }
    handleSave() {
        try {
            this.Loading = true;
            if (this.isNewTemplate) this.templateName = this.instance.currentLayout.settings.name.replace(/\s+/g, '_');
            saveSettings({ pageLayoutSettingsJSON: JSON.stringify(this.instance.currentLayout.settings) })
                .then(result => {
                    this.checkDeployementStatus(result);
                    //this.SelectLayoutPage(this.templateName);
                }).catch(error => {
                    console.error('Save error:', JSON.stringify(error));
                    console.error('Full error:', error);
                    this.showNotification(this.Label.LBL_Error, error, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.Loading = false;
                })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            this.Loading = false;
            this.showNotification(this.Label.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    //template filter settings
    handleManageTemplateFilterActions(event) {
        const action = event.currentTarget.dataset.action;
        const wrapper = this.templateFilterCriteriaWrapper;
        try {
            switch (action) {
                case this.MANAGE_TEMPLATE_FILTER_ACTIONS.FIELD_PICKER: {
                    const detail = event.detail;
                    let parsedOptions = [];
                    parsedOptions = FIELD_TYPE_CONFIG.getOperatorsByType(detail.inputType);
                    wrapper.currentCriteria = {
                        ...wrapper.currentCriteria,
                        fieldName: detail.fieldPath,
                        value: ''
                    };
                    wrapper.selectedField = {
                        fieldPath: detail.fieldPath,
                        inputType: detail.inputType,
                        isPicklist: detail.isPicklist,
                        options: parsedOptions,
                        picklistValues: detail.isPicklist ? detail.options : null,
                        showValueInput: !OPERATIONS_WITHOUT_VALUE.includes(wrapper.currentCriteria.operator),
                    };
                    this.templateFilterCriteriaWrapper = { ...wrapper };
                    break;
                }
                case this.MANAGE_TEMPLATE_FILTER_ACTIONS.CRITERIA_FIELD_CHANGE: {
                    const fieldName = event.target.dataset.field;
                    let value;
                    if (event.target.type === 'checkbox') {
                        value = event.detail?.checked ?? event.target.checked;
                    } else {
                        value = event.detail?.value ?? event.target.value;
                    }
                    wrapper.currentCriteria = {
                        ...wrapper.currentCriteria,
                        [fieldName]: value
                    };
                    if (fieldName === 'operator') {
                        wrapper.selectedField.showValueInput = !OPERATIONS_WITHOUT_VALUE.includes(value);
                        if (!wrapper.selectedField.showValueInput) {
                            wrapper.currentCriteria.value = '';
                        }
                    }
                    this.templateFilterCriteriaWrapper = { ...wrapper };
                    break;
                }
                case this.MANAGE_TEMPLATE_FILTER_ACTIONS.ADD_CRITERIA: {
                    const current = wrapper.currentCriteria;
                    if (!current.fieldName) {
                        return;
                    }
                    const criteriaList = [
                        ...this.instance.currentLayout.settings.templateFilterCriteria,
                        { ...current }
                    ];
                    this.instance.currentLayout.settings.templateFilterCriteria = [
                        ...this.instance.currentLayout.settings.templateFilterCriteria,
                        { ...current }
                    ];
                    this.instance.currentLayout.settingsWrappers.templateCriteriaDisplayWrapper = [
                        ...this.instance.currentLayout.settingsWrappers.templateCriteriaDisplayWrapper,
                        {
                            rowKey: `criteria_${criteriaList.length - 1}`,
                            listIndex: criteriaList.length - 1,
                            expression: `${current.fieldName} ${current.operator} ${current.value}`
                        }
                    ];
                    wrapper.currentCriteria = {
                        fieldName: '',
                        operator: '=',
                        value: ''
                    };
                    wrapper.selectedField = null;
                    wrapper.selectedIndex = null;
                    this.templateFilterCriteriaWrapper = { ...wrapper };
                    break;
                }
                case this.MANAGE_TEMPLATE_FILTER_ACTIONS.SELECT_CRITERIA: {
                    const index = Number(event.target.value);
                    const criteria = this.instance.currentLayout.settings.templateFilterCriteria[index];
                    if (!criteria) {
                        return;
                    }
                    wrapper.currentCriteria = { ...criteria };
                    wrapper.selectedIndex = index;
                    this.templateFilterCriteriaWrapper = { ...wrapper };
                    const fieldPicker = this.template.querySelector('[data-id="fieldPicker"]');
                    if (fieldPicker && criteria.fieldName) {
                        console.log('Loading field into picker:', criteria.fieldName);
                        fieldPicker.retrieveFieldSelection(criteria.fieldName);
                    }
                    break;
                }
                case this.MANAGE_TEMPLATE_FILTER_ACTIONS.EDIT_CRITERIA: {
                    if (wrapper.selectedIndex == null) {
                        return;
                    }
                    let criteriaList = [...this.instance.currentLayout.settings.templateFilterCriteria];
                    criteriaList[wrapper.selectedIndex] = {
                        ...wrapper.currentCriteria
                    };
                    this.instance.currentLayout.settings.templateFilterCriteria = criteriaList;
                    this.instance.currentLayout.settingsWrappers.templateCriteriaDisplayWrapper = criteriaList.map((criteria, index) => ({
                        rowKey: `criteria_${index}`,
                        listIndex: index,
                        expression: `${criteria.fieldName} ${criteria.operator} ${criteria.value}`
                    }));
                    this.templateFilterCriteriaWrapper = { ...wrapper };
                    break;
                }
                case this.MANAGE_TEMPLATE_FILTER_ACTIONS.DELETE_CRITERIA: {
                    if (wrapper.selectedIndex === null) {
                        return;
                    }
                    let criteriaList = [...this.instance.currentLayout.settings.templateFilterCriteria];
                    criteriaList.splice(wrapper.selectedIndex, 1);
                    this.instance.currentLayout.settings.templateFilterCriteria = criteriaList;
                    this.instance.currentLayout.settingsWrappers.templateCriteriaDisplayWrapper = criteriaList.map((criteria, index) => ({
                        rowKey: `criteria_${index}`,
                        listIndex: index,
                        expression: `${criteria.fieldName} ${criteria.operator} ${criteria.value}`
                    }));
                    wrapper.currentCriteria = {
                        fieldName: '',
                        operator: '=',
                        value: ''
                    };
                    wrapper.selectedField = null;
                    wrapper.selectedIndex = null;
                    this.templateFilterCriteriaWrapper = { ...wrapper };
                    break;
                }
                default:
                    break;
            }
        } catch (error) {
            console.log('error manage template filter actions:' + error);
            console.log('error manage template filter actions:' + error.message);
        }
    }
    fieldPickerLoadingHandler(event) {
        this.Loading = event.detail.isLoading;
    }
    /**
       ====================
        private methods
       =====================
    */
    loadFields(objectName) {
        if (!objectName) {
            this.Loading = false;
            this.showNotification(this.Label.MSG_Warning, this.Label.MSG_Object_Should_Be_Filled, 'warning', '');
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
                console.log(this.Label.LBL_Error + JSON.stringify(error));
                return Promise.reject(error);
            });
    }
    resetTemplate() {
        this.templateName = null;
        this.isNewTemplate = false;
        this.instance = {
            ...this.instance,
            showObjectDropdown: false,
            fieldNameOptions: [],
            currentLayout: {
                settings: {
                    name: "",
                    label: "",
                    objectApiName: "",
                    source: "",
                    tabs: [],
                    actionButtons: [],
                    fieldsConfiguration: [],
                    nbOfRows: 0,
                    isFlowMode: false,
                    selectedFlow: "",
                    newTaskFlow: "",
                    topLeftCornerFields: [],
                    taskFields: [],
                    bottomLeftCornerFields: [],
                    topRightCornerFields: [],
                    statusField: "",
                    activityFields: [],
                    headerField: {
                        fieldName: "",
                        isReadOnly: false,
                        isMandatory: false,
                        showHeaderField: true
                    },
                    relatedInformations: [],
                    topLeftCornerLogo1: { value: "", isStaticRessource: true },
                    topLeftCornerLogo2: { value: "", isStaticRessource: true },
                    bottomLeftCornerLogo1: { value: "", isStaticRessource: true },
                    bottomLeftCornerLogo2: { value: "", isStaticRessource: true },
                    statusIcon: { value: "", isStaticRessource: true },
                    activityRightIcon: { value: "", isStaticRessource: true },
                    activityLeftIcon: { value: "", isStaticRessource: true },
                    templateFilterCriteria: []
                },
                settingsWrappers: {
                    templateCriteriaDisplayWrapper: [],
                    actionButtonsWrapper: [],
                    fieldsConfigurationSettingWrapper: [],
                    tabsConfigurationWrapper: [],
                    relatedInformationsWrapper: []
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
        this.instance.LayoutPages = this.instance.LayoutPages.map(layout => ({
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
                        this.showNotification(this.Label.LBL_Error, this.Label.MSG_Error, '', 'info')
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
                                this.showNotification(this.Label.LBL_Success, this.Label.MSG_Success, 'success');
                            } else {
                                this.showNotification(this.Label.LBL_Info, this.Label.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
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
                this.showNotification(this.Label.LBL_Success, this.Label.MSG_Success, 'success')
                this.Loading = true;
                this.LoadLayoutPages().then(() => {
                    if (this.templateName) {
                        this.SelectLayoutPage(this.templateName);
                    }
                }).catch(() => { });
            }
        });
    }
    /* ==========================
        getters
       ==========================
     */
    get topLeftCornerLogo1Value() {
        return this._toRadioString(this.instance.currentLayout.settings.topLeftCornerLogo1?.isStaticRessource);
    }
    get topLeftCornerLogo2Value() {
        return this._toRadioString(this.instance.currentLayout.settings.topLeftCornerLogo2?.isStaticRessource);
    }
    get bottomLeftCornerLogo1Value() {
        return this._toRadioString(this.instance.currentLayout.settings.bottomLeftCornerLogo1?.isStaticRessource);
    }
    get bottomLeftCornerLogo2Value() {
        return this._toRadioString(this.instance.currentLayout.settings.bottomLeftCornerLogo2?.isStaticRessource);
    }
    get statusIconValue() {
        return this._toRadioString(this.instance.currentLayout.settings.statusIcon?.isStaticRessource);
    }
    get activityLeftIconValue() {
        return this._toRadioString(this.instance.currentLayout.settings.activityLeftIcon?.isStaticRessource);
    }
    get activityRightIconValue() {
        return this._toRadioString(this.instance.currentLayout.settings.activityRightIcon?.isStaticRessource);
    }
    get disableSaveAs() {
        if (!this.instance.currentLayout.settings.name || this.instance.currentLayout.settings.name.trim() === '' || this.isNewTemplate || !this.instance.currentLayout.settings.objectApiName) {
            return true;
        }
        return false;
    }
    get saveAsButtonDisabled() {
        const saveAsName = (this.saveAsTemplateName || '').trim();
        return !saveAsName ? true : false;
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
    /*
     =====================
      private helpers
     =====================
    */
    showNotification(title, message, variant, mode = 'dismissible') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }
}