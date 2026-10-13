import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getFields from '@salesforce/apex/PageLayoutSettingsCtrl.getFields';
import getChildRelationships from '@salesforce/apex/PageLayoutSettingsCtrl.getChildRelationships';
import loadData from '@salesforce/apex/PageLayoutSettingsCtrl.loadData';
import saveSettings from '@salesforce/apex/PageLayoutSettingsCtrl.saveSettings';
import checkDeploymentStatus from '@salesforce/apex/PageLayoutSettingsCtrl.checkDeploymentStatus';
import Task from '@salesforce/schema/Task';
import TMPActivityObject from '@salesforce/schema/TMP_Activity__c';
import { Labels } from './properties.js';
import {
    FilterOperations,
    getDefaultStringOperations,
    getOperationsBySubFieldType,
} from './filterOperations.js';

const classPrefix = 'c-page-layout-settings';

const OPERATIONS_WITHOUT_VALUE = [
    FilterOperations.ISNULL,
    FilterOperations.ISBLANK,
    FilterOperations.ISNOTNULL,
    FilterOperations.ISNOTBLANK,
];

export default class pageLayoutSettings extends LightningElement {
    @track labels = Labels;
    @track customObjects = [];
    @track searchedObjects = [];
    @track screenFlowOptions = [];
    @track gridSettings = [];
    @track fieldsConfiguration = [];
    @track topLeftCornerFields = [];
    @track bottomLeftCornerFields = [];
    @track topRightCornerFields = [];
    @track topRightCornerFields2 = [];
    @track fieldsPerRowList = [];
    @track fieldNameOptions = [];
    @track fieldNameTMPOptions = [];
    @track taskNameOptions = [];
    @track selectedTaskFields = [];
    @track objectFields = [];
    @track relatedInformationsFilterFields = [];
    @track childRelationships = [];
    @track pageLayoutSettingsList = [];
    @track fileDirectoryData = [];
    @track buttons = []
    @track tabs = []
    @track iconOptions = [
        { label: this.labels.LBL_StaticResource, value: true },
        { label: this.labels.LBL_Field, value: false }
    ];
    @track templateName = '';
    @track selectedFlow = '';
    @track icon1 = '';
    @track icon2 = '';
    @track logo1 = '';
    @track logo2 = '';
    @track rightIcon1 = '';
    @track rightIcon2 = '';
    @track rightIcon3 = '';
    @track selectedNewFlow = '';
    @track selectedFile = '';
    @track selectedpageLayoutSettingsName = '';
    @track selectedPageSettings;
    @track lwcParamsSettingsList;
    @track selectedObject;
    @track rowsPerTemplate;
    @track isFlowMode = false;
    @track showObjectDropdown = false;
    @track showGridSettingsModal = false;
    @track newFieldsConfiguration = false;
    @track addNewPageLayout = false;
    @track isLoading = false;
    mainPanelHeight;
    @track headerField = { fieldName: '', isMandatory: false, isReadOnly: false, showHeaderField: true };
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
                        this.labels.LBL_Error,
                        this.labels.MSG_Fill_Required_Fields,
                        'error',
                        'sticky'
                    );
                    return;
                }
                if (!tab.params) {
                    tab.params = {};
                }
                if (this.selectedPageSettings.objectApiName) {
                    tab.params.objectApiName = this.selectedPageSettings.objectApiName;
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
                let tab = this.selectedPageSettings.tabs[index];
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
                        params = JSON.parse(JSON.stringify(params.filter(it => !['objectApiName', 'templateName'].includes(it.name))));
                    }
                    params.forEach(param => {
                        param[`is${param.type}`] = true;
                        if (param.getDataSourceList) {
                            param.datasourceList = Object.keys(param.getDataSourceList).map(value => ({ value: value, label: param.getDataSourceList[value] }));
                            param.isCombobox = param.datasourceList.length ? true : false;
                        }
                        param.required = param.required === 'true' || param.required === true;
                        param.value = param.isBoolean ? param.defaultValue === 'true' :
                            (param.isInteger && +param.defaultValue ? +param.defaultValue : param.defaultValue);
                    });
                    if (tab?.params) {
                        Object.keys(tab?.params).forEach(name => {
                            let param = params.find(it => it.name == name);
                            if (param) {
                                param.value = param.isBoolean ? tab?.params[name] == 'true' : (param.isInteger && +tab?.params[name] ? +tab?.params[name] : tab?.params[name]);
                            }
                        })
                    }
                    params.forEach((param, index) => {
                        param.paramKey = `param-${index}`;
                    });
                    this.popups.tabParams.params = params;
                    this.popups.tabParams.tab = tab;
                    this.popups.tabParams.isOpen = true;
                } else {
                    this.showNotification(this.labels.LBL_Error, this.labels.Msg_NoInputParams, 'error');
                }
            },
        },
        relatedInformations: {
            isOpen: false,
            filters: [],
        }
    }

    rowOptions = [
        { label: '3 rows', value: '3' },
        { label: '4 rows', value: '4' },
        { label: '5 rows', value: '5' },
        { label: '6 rows', value: '6' }
    ];
    ensureItemKeys() {
        if (!this.selectedPageSettings) {
            return;
        }
        this.selectedPageSettings.actionButtons = (this.selectedPageSettings.actionButtons || []).map((btn, index) => ({
            ...btn,
            buttonKey: btn?.buttonKey || `btn-${index}-${btn?.flow || ''}-${btn?.label || ''}`
        }));
        this.selectedPageSettings.tabs = (this.selectedPageSettings.tabs || []).map((tab, index) => ({
            ...tab,
            tabKey: tab?.tabKey || `tab-${index}-${tab?.contentType || ''}-${tab?.label || ''}`
        }));
    }

    fieldCountOptions = [
        { label: '1 Field', value: '1' },
        { label: '2 Fields', value: '2' },
        { label: '3 Fields', value: '3' }
    ];

    get showNewFieldConfig() {
        return (!this.addNewPageLayout && this.newFieldsConfiguration) || this.addNewPageLayout
    }

    get redirectionOptions() {
        return [
            { label: 'grid', value: 'grid' },
            { label: 'page', value: 'page' },
        ]
    }

    get pageLayoutSettingsOptions() {
        const options = this.pageLayoutSettingsList?.map(item => ({
            label: `${item.name}`,
            value: item.name
        })) || [];
        return this.sortByLabel(options);
    }

    get isGridFile() {
        return this.selectedFile === 'grid';
    }

    get isGridContentType() {
        return (this.selectedPageSettings?.tabs || []).some(tab => tab.contentType === 'grid');
    }

    get relationshipFieldOptions() {

        const rows = (this.childRelationships || []).map((r) => ({
            label: r.label || `${r.childObjectApiName} · ${r.relationshipApiName}`,
            value: r.relationshipApiName
        }));
        return this.addClearOptions(this.sortByLabel(rows));
    }

    get relatedInformationsFilterObjectName() {
        const childObjectApiName = this.childRelationships.find(
            item => item.relationshipApiName === this.selectedPageSettings?.relatedInformations?.parentRelationshipApiName
        )?.childObjectApiName;
        if (childObjectApiName) {
            return childObjectApiName;
        }
        return this.selectedPageSettings?.objectApiName || '';
    }

    connectedCallback() {
        this.isLoading = true;
        window.addEventListener('resize', this.changeHeight);
        this.injectVerticalTabStyles();
        this.initData();
    }

    injectVerticalTabStyles() {
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                background: white;
                color: #806BBF;
                height: 60px;
                width: 230px;
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
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active:hover {
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
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.changeHeight);
    }

    renderedCallback() {
        if (this.template.querySelector('.settings-header')) {
            this.changeHeight();
        }
    }

    changeHeight = () => {
        let headerHeight = 0;
        const headerEl = this.template.querySelector('.settings-header');
        if (headerEl) {
            headerHeight = headerEl.getBoundingClientRect().height;
        }
        let toolbarHeight = 0;
        const toolbarEl = this.template.querySelector('.page-toolbar');
        if (toolbarEl) {
            toolbarHeight = toolbarEl.getBoundingClientRect().height;
        }
        const offset = window.innerWidth < 980 ? 170 : 120;
        const mainPanelHeight = window.innerHeight - headerHeight - toolbarHeight - offset;
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px';
    };

    addClearOptions(options) {
        const base = Array.isArray(options) ? options : [];
        return [
            { label: 'None', value: '' },
            ...base
        ];
    }

    initData() {
        loadData().then(result => {
            let parsedResult = JSON.parse(result);
            this.pageLayoutSettingsList = parsedResult.pageLayoutSettingsList;
            this.lwcParamsSettingsList = parsedResult.lwcParamsSettingsList || [];
            this.screenFlowOptions = [];
            parsedResult.screenFlows.forEach(flow => {
                this.screenFlowOptions.push({ label: flow.FlowLabel, value: flow.ApiName });
            });
            this.screenFlowOptions = this.addClearOptions(this.screenFlowOptions);
            this.customObjects = this.sortByLabel(
                parsedResult.objects.map(obj => ({ label: obj.label, value: obj.apiname, apiname: obj.apiname }))
            );
            let gridSettings = parsedResult.gridSettings
                .map(obj => ({ label: obj.Label, value: obj.QualifiedApiName }));
            this.gridSettings = this.addClearOptions([...gridSettings]);
            this.fileDirectoryData = parsedResult.fileDirectoryData.map(obj => ({
                label: obj.label,
                value: obj.value
            }));
            this.fileDirectoryData = this.addClearOptions(this.fileDirectoryData);
            this.isLoading = false;
        }).catch(() => {
            this.isLoading = false;
        });
        this.loadTaskFields();
        this.loadFields(TMPActivityObject.objectApiName);
    }

    loadFields(objectName) {
        if (!objectName) {
            this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Object_Should_Be_Filled, 'warning', '');
            return Promise.resolve();
        }
        return getFields({ objectName: objectName })
            .then((result) => {
                if (objectName === TMPActivityObject.objectApiName) {
                    const baseOptions = this.sortByLabel(
                        result.map(field => ({ label: field.label, value: field.apiName }))
                    );
                    this.fieldNameTMPOptions = this.addClearOptions(baseOptions);
                } else {
                    this.objectFields = result || [];
                    const baseOptions = this.sortByLabel(
                        result.map(field => ({ label: field.label, value: field.apiName }))
                    );
                    this.fieldNameOptions = this.addClearOptions(baseOptions);
                    if (!this.selectedPageSettings?.relatedInformations?.parentRelationshipApiName) {
                        this.relatedInformationsFilterFields = [...(result || [])];
                    }
                }
                return result;
            })
            .catch((error) => {
                console.log(this.labels.LBL_Error + JSON.stringify(error));
                return Promise.reject(error);
            });
    }

    loadChildRelationships(parentObjectApiName) {
        if (!parentObjectApiName) {
            this.childRelationships = [];
            return Promise.resolve();
        }
        return getChildRelationships({ parentObjectApiName })
            .then((rows) => {
                this.childRelationships = rows || [];
            })
            .catch((error) => {
                console.error('getChildRelationships', error);
                this.childRelationships = [];
            });
    }

    loadRelatedInformationsFilterFields(objectName) {
        if (!objectName) {
            return Promise.resolve();
        }
        return getFields({ objectName })
            .then((result) => {
                this.relatedInformationsFilterFields = result || [];
            })
            .catch(() => {
                this.relatedInformationsFilterFields = [...(this.objectFields || [])];
            });
    }

    loadTaskFields() {
        getFields({ objectName: Task.objectApiName })
            .then(result => {
                this.taskNameOptions = result
                    .map(field => ({
                        label: field.label || field.apiName,
                        value: field.apiName
                    }))
                    .sort((a, b) => a.label.toLowerCase().localeCompare(b.label.toLowerCase()));
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching Task fields: ', error);
                this.isLoading = false;
            });
    }

    handleSave(event) {
        try {
            this.isLoading = true;
            this.selectedPageSettings.fieldsConfiguration = this.selectedPageSettings.fieldsConfiguration?.map(row =>
                row.filter(f => f.fieldName && f.fieldName.trim() !== '')
            );
            saveSettings({ pageLayoutSettingsJSON: JSON.stringify(this.selectedPageSettings) })
                .then(result => {
                    this.checkDeployementStatus(result);
                    this.newFieldsConfiguration = true;
                    this.templateName = this.selectedPageSettings?.name;
                }).catch(error => {
                    console.error('Save error:', JSON.stringify(error));
                    console.error('Full error:', error);
                    this.showNotification(this.labels.LBL_Error, error, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            this.isLoading = false;
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleCancel() {
        this.selectedPageSettings = null;
        this.selectedpageLayoutSettingsName = null;
        const allItems = this.template.querySelectorAll('.list-item');
        allItems.forEach(item => {
            item.classList.remove('slds-is-active');
        });
        this.addNewPageLayout = false;
        this.newFieldsConfiguration = false;
        this.isLoading = true;
        this.initData();
    }

    handleChangeSettings(event) {
        let value = event.target.value;
        let index = event.target.dataset.index;
        this.selectedPageSettings.tabs[index].contentType = value;
        this.selectedPageSettings.tabs[index].isGridFile = (value === 'grid');
    }

    handleRowsChange(event) {
        this.rowsPerTemplate = event.detail.value;
        const count = parseInt(this.rowsPerTemplate, 10);
        this.initializeFieldsPerRow(count);
        this.selectedPageSettings.nbOfRows = parseInt(this.rowsPerTemplate);
        if (!this.addNewPageLayout) {
            this.newFieldsConfiguration = true;
        }
    }

    handleTemplateSourceChange(event) {
        let value = event.target.value;
        this.selectedPageSettings.source = value;
    }

    handleFieldCountChange(event) {
        const rowIndex = event.target.dataset.index;
        const count = parseInt(event.detail.value, 10);
        const existingFields = this.selectedPageSettings.fieldsConfiguration[rowIndex] || [];
        const newFields = [];
        for (let colIndex = 0; colIndex < count; colIndex++) {
            const existing = existingFields[colIndex];
            newFields.push({
                fieldKey: `row-${rowIndex}-col-${colIndex}`,
                fieldName: existing?.fieldName || '',
                isMandatory: existing?.isMandatory || false,
                isReadOnly: existing?.isReadOnly || false,
                isEmpty: true
            });
        }
        this.fieldsPerRowList[rowIndex].fields = newFields;
        this.fieldsPerRowList[rowIndex].selectedFieldCount = String(count);
        this.updateRowDisplayFields(this.fieldsPerRowList[rowIndex]);
        this.selectedPageSettings.fieldsConfiguration[rowIndex] = newFields;
        this.selectedPageSettings.fieldsConfiguration.forEach((row, rowIndex) => {
            row.rowKey = 'row-' + rowIndex;
        });
        this.fieldsPerRowList = [...this.fieldsPerRowList];
        this.selectedPageSettings = { ...this.selectedPageSettings };
    }

    handleTemplateNameChange(event) {
        this.templateName = event.target.value;
        this.selectedPageSettings.name = this.templateName;
    }

    handleTasks(event) {
        this.selectedTaskFields = event.detail.value;
        this.selectedPageSettings.taskFields = this.selectedTaskFields;
    }

    handleNewFlowChange(event) {
        this.selectedNewFlow = event.detail.value;
        this.selectedPageSettings.newTaskFlow = this.selectedNewFlow;
    }

    handleChangeButtonSettings(event) {
        let value = event.target.value;
        let index = event.target.dataset.index;
        let field = event.target.dataset.field;
        this.selectedPageSettings.actionButtons[index][field] = value;
    }

    handleChangeTabSettings(event) {
        let value = event.target.value;
        let index = event.target.dataset.index;
        let field = event.target.dataset.field;
        this.selectedPageSettings.tabs[index][field] = value;
    }

    handleDelete(event) {
        let isBtn = event.target.dataset.btn;
        if (isBtn === 'relatedInfoFilter') {
            this.selectedPageSettings.relatedInformations.filters.splice(event.target.dataset.index, 1);
            this.popups.relatedInformations.filters.splice(event.target.dataset.index, 1);
        } else if (isBtn === 'yes') {
            this.selectedPageSettings.actionButtons.splice(event.target.dataset.index, 1);
        }
        else {
            this.selectedPageSettings.tabs.splice(event.target.dataset.index, 1);
        }
    }

    handleAdd(event) {
        let isBtn = 'btn' in event.target.dataset;
        if (isBtn) {
            if (this.selectedPageSettings.actionButtons.length > 5) {
                this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Max_Button_Limit_Reached, 'warning', '');
                return;
            }
            const index = this.selectedPageSettings.actionButtons.length;
            this.selectedPageSettings.actionButtons.push({
                buttonKey: `btn-${index}`,
                label: '',
                color: '',
                flow: ''
            });
        } else {
            if (this.selectedPageSettings.tabs.length > 9) {
                this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Max_Tab_Limit_Reached, 'warning', '');
                return;
            }
            const index = this.selectedPageSettings.tabs.length;
            this.selectedPageSettings.tabs.push({
                tabKey: `tab-${index}`,
                label: '',
                content: '',
                contentType: ''
            });
        }
    }

    handleFieldChange(event) {
        let field = event.target.dataset.field;
        let fieldIndex = event.target.dataset.colindex;
        let rowIndex = event.target.dataset.rowindex
        let value = '';
        if (field == 'isMandatory') {
            value = event.target.checked;
        }
        if (field == 'isReadOnly') {
            value = event.target.checked;
        }
        if (field == 'accessMode') {
            const selectedAccess = event.target.value;
            this.selectedPageSettings.fieldsConfiguration[rowIndex][fieldIndex].isMandatory = selectedAccess === 'mandatory';
            this.selectedPageSettings.fieldsConfiguration[rowIndex][fieldIndex].isReadOnly = selectedAccess === 'readOnly';
            return;
        }
        if (field == 'fieldName') {
            value = event.detail.value;
        }
        this.selectedPageSettings.fieldsConfiguration[rowIndex][fieldIndex][field] = value;
    }

    handleFirstFieldChange(event) {
        const field = event.target.dataset.field;
        let value = '';
        if (field == 'isMandatory') {
            value = event.target.checked;
        }
        if (field == 'isReadOnly') {
            value = event.target.checked;
        }
        if (field == 'fieldName') {
            value = event.detail.value;
        }
        if (field == 'accessMode') {
            const selectedAccess = event.target.value;
            this.headerField.isMandatory = selectedAccess === 'mandatory';
            this.headerField.isReadOnly = selectedAccess === 'readOnly';
            this.selectedPageSettings.headerField = this.headerField;
            return;
        }
        this.headerField[field] = value;
        this.selectedPageSettings.headerField = this.headerField;
    }

    handleHeaderFieldToggle(event) {
        this.selectedPageSettings.headerField.showHeaderField = event.target.checked;
    }

    handleToggleChange(event) {
        this.isFlowMode = event.target.checked;
        this.selectedPageSettings.isFlowMode = this.isFlowMode;
    }

    handleFlowChange(event) {
        this.selectedFlow = event.detail.value;
        this.selectedPageSettings.selectedFlow = this.selectedFlow;
    }

    handleChange(e) {
        this.topLeftCornerFields = e.detail.value;
        this.selectedPageSettings.topLeftCornerFields = this.topLeftCornerFields;
    }

    handleRightFieldsChange(e) {
        this.topRightCornerFields = e.detail.value;
        this.selectedPageSettings.topRightCornerFields = this.topRightCornerFields;
    }

    handleRightFields2Change(e) {
        this.topRightCornerFields2 = e.detail.value;
        this.selectedPageSettings.activityFields = this.topRightCornerFields2;
    }

    handleButtomLeftFieldsChange(e) {
        this.bottomLeftCornerFields = e.detail.value;
        this.selectedPageSettings.bottomLeftCornerFields = this.bottomLeftCornerFields;
    }

    handleIconsChange(event) {
        let iconValue = event.detail.value;
        let icon = event.target.dataset.icon;
        if (icon == 'topLeftLogo1Value') {
            this.selectedPageSettings.topLeftCornerLogo1.value = iconValue;
        }
        else if (icon == 'topLeftLogo2Value') {
            this.selectedPageSettings.topLeftCornerLogo2.value = iconValue;
        }
        else if (icon == 'topRightLogo1Value') {
            this.selectedPageSettings.statusIcon.value = iconValue;
        }
        else if (icon == 'topRightLogo2Value') {
            this.selectedPageSettings.activityLeftIcon.value = iconValue;
        }
        else if (icon == 'topRightLogo3Value') {
            this.selectedPageSettings.activityRightIcon.value = iconValue;
        }
        else if (icon == 'bottomLogo1Value') {
            this.selectedPageSettings.bottomLeftCornerLogo1.value = iconValue;
        }
        else if (icon == 'bottomLogo2Value') {
            this.selectedPageSettings.bottomLeftCornerLogo2.value = iconValue;
        }
    }

    ensureRelatedInformationsDefaults() {
        const existing = this.selectedPageSettings.relatedInformations || {};
        this.selectedPageSettings.relatedInformations = {
            objectApiName: this.selectedPageSettings.objectApiName || '',
            parentRelationshipApiName: existing.parentRelationshipApiName || '',
            aggregateFunction: existing.aggregateFunction || 'COUNT',
            aggregateFieldName: existing.aggregateFieldName || '',
            label: existing.label || '',
            filters: Array.isArray(existing.filters) ? existing.filters : [],
            whereClause: existing.whereClause || '',
        };
    }

    handleRelatedInformationsChange(event) {
        this.ensureRelatedInformationsDefaults();
        const field = event.target.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        this.selectedPageSettings.relatedInformations[field] = value;
        this.selectedPageSettings = { ...this.selectedPageSettings };
    }

    handleRelatedInformationsRelationshipChange(event) {
        this.ensureRelatedInformationsDefaults();
        const value = event.detail?.value ?? '';
        this.selectedPageSettings.relatedInformations.parentRelationshipApiName = value;
        const rel = (this.childRelationships || []).find(
            (r) => r.relationshipApiName && r.relationshipApiName.toLowerCase() === (value || '').toLowerCase()
        );
        if (rel) {
            this.selectedPageSettings.relatedInformations.objectApiName = rel.childObjectApiName;
            this.loadRelatedInformationsFilterFields(rel.childObjectApiName);
            const filters = this.selectedPageSettings.relatedInformations.filters || [];
            const hasMeaningful = filters.some((f) => f.fieldName && (f.value || '').trim() !== '');
            if (!hasMeaningful && rel.foreignKeyFieldApiName) {
                this.selectedPageSettings.relatedInformations.filters = [
                    { fieldName: rel.foreignKeyFieldApiName, operator: '=', value: '{recordId}' }
                ];
            }
        } else {
            this.selectedPageSettings.relatedInformations.objectApiName = this.selectedPageSettings.objectApiName || '';
            this.selectedPageSettings.relatedInformations.filters = [];
            this.relatedInformationsFilterFields = [...(this.objectFields || [])];
        }
        this.selectedPageSettings = { ...this.selectedPageSettings };
    }

    createEmptyRelatedInformationsFilterRow(index, overrides = {}) {
        const operator = overrides.operator ?? '';
        return {
            rowKey: `flt-${index}`,
            fieldName: '',
            operator,
            value: '{recordId}',
            inputType: 'text',
            fieldType: '',
            isPicklist: false,
            isMultiPicklist: false,
            isReference: false,
            picklistValues: [],
            previousObject: '',
            refFieldName: '',
            operationsOptions: overrides.operationsOptions ?? getDefaultStringOperations(),
            disableValue: OPERATIONS_WITHOUT_VALUE.includes(operator),
            ...overrides
        };
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

    normalizePicklistValues(picklistValues) {
        if (Array.isArray(picklistValues)) {
            return picklistValues;
        }
        if (typeof picklistValues === 'string' && picklistValues) {
            try {
                return JSON.parse(picklistValues);
            } catch (e) {
                return [];
            }
        }
        return [];
    }

    applySelectedFieldToRelatedFilter(filter, selectedField, resetValue) {
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
            filter.operationsOptions = getDefaultStringOperations();
            filter.disableValue = false;
            if (resetValue) {
                filter.value = '';
                filter.operator = '';
            }
            return filter;
        }
        const fieldType = selectedField.fieldType || '';
        const isMultiPicklist = fieldType === 'MultiPicklist';
        filter.fieldName = selectedField.fieldName;
        filter.fieldType = fieldType;
        filter.isReference = !!selectedField.isReference;
        filter.isMultiPicklist = isMultiPicklist;
        filter.isPicklist = !!selectedField.isPicklist && !isMultiPicklist;
        filter.picklistValues = this.normalizePicklistValues(selectedField.picklistValues);
        filter.previousObject = selectedField.previousObject || '';
        filter.refFieldName = selectedField.refFieldName || '';
        filter.inputType = this.getFilterValueInputType(fieldType);
        filter.operationsOptions = getOperationsBySubFieldType(fieldType);
        if (resetValue) {
            filter.value = '';
            filter.operator = '';
            filter.disableValue = false;
        } else {
            filter.disableValue = OPERATIONS_WITHOUT_VALUE.includes(filter.operator);
        }
        return filter;
    }

    handleRelatedInformationsFieldSelect(event) {
        const index = Number(event.currentTarget.dataset.index);
        const selectedField = event.detail || {};
        const filter = { ...this.popups.relatedInformations.filters[index] };
        this.applySelectedFieldToRelatedFilter(filter, selectedField, true);
        this.popups.relatedInformations.filters[index] = filter;
        this.popups.relatedInformations.filters = [...this.popups.relatedInformations.filters];
    }

    handleRelatedInformationsFieldRestore(event) {
        const index = Number(event.currentTarget.dataset.index);
        const selectedField = event.detail || {};
        if (!selectedField?.fieldName || index == null) {
            return;
        }
        const filter = { ...this.popups.relatedInformations.filters[index] };
        this.applySelectedFieldToRelatedFilter(filter, selectedField, false);
        this.popups.relatedInformations.filters[index] = filter;
        this.popups.relatedInformations.filters = [...this.popups.relatedInformations.filters];
    }

    openRelatedInformationsPopup() {
        this.ensureRelatedInformationsDefaults();
        const relatedConfig = this.selectedPageSettings.relatedInformations;
        this.popups.relatedInformations.filters = (relatedConfig.filters || []).map((item, index) => {
            const operator = item.operator || '';
            return this.createEmptyRelatedInformationsFilterRow(index, {
                fieldName: item.fieldName || '',
                operator,
                value: item.value ?? '',
                operationsOptions: getDefaultStringOperations(),
                disableValue: OPERATIONS_WITHOUT_VALUE.includes(operator),
            });
        });
        const pr = (relatedConfig.parentRelationshipApiName || '').trim();
        const hasMeaningfulFilter = this.popups.relatedInformations.filters.some(
            (f) => f.fieldName && (f.value || '').trim() !== ''
        );
        if (!hasMeaningfulFilter && pr) {
            const rel = (this.childRelationships || []).find(
                (r) => r.relationshipApiName && r.relationshipApiName.toLowerCase() === pr.toLowerCase()
            );
            if (rel?.foreignKeyFieldApiName) {
                this.popups.relatedInformations.filters = [
                    this.createEmptyRelatedInformationsFilterRow(0, {
                        fieldName: rel.foreignKeyFieldApiName,
                        operator: FilterOperations.EQUALS,
                        value: '{recordId}',
                        operationsOptions: getDefaultStringOperations(),
                        disableValue: false,
                    })
                ];
            }
        }
        if (!this.popups.relatedInformations.filters.length) {
            this.popups.relatedInformations.filters = [this.createEmptyRelatedInformationsFilterRow(0)];
        }
        this.popups.relatedInformations.isOpen = true;
    }

    closeRelatedInformationsPopup() {
        this.popups.relatedInformations.filters = [];
        this.popups.relatedInformations.isOpen = false;
    }

    addRelatedInformationsFilterRow() {
        const index = this.popups.relatedInformations.filters.length;
        this.popups.relatedInformations.filters = [
            ...this.popups.relatedInformations.filters,
            this.createEmptyRelatedInformationsFilterRow(index)
        ];
    }

    removeRelatedInformationsFilterRow(event) {
        const index = Number(event.currentTarget.dataset.index);
        this.popups.relatedInformations.filters = this.popups.relatedInformations.filters.filter((_, i) => i !== index);
        if (!this.popups.relatedInformations.filters.length) {
            this.popups.relatedInformations.filters = [this.createEmptyRelatedInformationsFilterRow(0)];
        }
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


    confirmRelatedInformationsPopup() {
        this.ensureRelatedInformationsDefaults();
        this.selectedPageSettings.relatedInformations.filters = this.popups.relatedInformations.filters
            .filter(item => {
                if (!item.fieldName || !item.operator) {
                    return false;
                }
                if (OPERATIONS_WITHOUT_VALUE.includes(item.operator)) {
                    return true;
                }
                return item.value !== '';
            })
            .map(item => ({ fieldName: item.fieldName, operator: item.operator, value: item.value }));
        this.selectedPageSettings = { ...this.selectedPageSettings };
        this.closeRelatedInformationsPopup();
    }

    handleChangepageLayoutSettings(event) {
        const selectedName = event.detail.value;
        this.selectedpageLayoutSettingsName = selectedName;
        this.selectedPageSettings = this.pageLayoutSettingsList.find(item => item.name === selectedName);
        this.selectedPageSettings.fieldsConfiguration = this.selectedPageSettings.fieldsConfiguration || [];
        this.selectedPageSettings.headerField = this.selectedPageSettings.headerField || { isReadOnly: false, isMandatory: false, fieldName: "", showHeaderField: true };
        this.ensureRelatedInformationsDefaults();
        this.headerField = this.selectedPageSettings.headerField;
        const parsedRows = parseInt(this.selectedPageSettings.nbOfRows, 10);
        this.rowsPerTemplate = Number.isFinite(parsedRows) && parsedRows > 0 ? String(parsedRows) : null;
        this.selectedPageSettings.tabs = this.selectedPageSettings.tabs || [];
        this.selectedPageSettings.actionButtons = this.selectedPageSettings.actionButtons || [];
        this.ensureItemKeys();
        this.loadFields(this.selectedPageSettings.objectApiName)
            .then(() => this.loadChildRelationships(this.selectedPageSettings.objectApiName))
            .then(() => {
                const pr = (this.selectedPageSettings.relatedInformations?.parentRelationshipApiName || '').trim();
                if (!pr) {
                    return Promise.resolve();
                }
                const rel = (this.childRelationships || []).find(
                    (r) => r.relationshipApiName && r.relationshipApiName.toLowerCase() === pr.toLowerCase()
                );
                if (rel) {
                    this.selectedPageSettings.relatedInformations.objectApiName = rel.childObjectApiName;
                    this.selectedPageSettings = { ...this.selectedPageSettings };
                    return this.loadRelatedInformationsFilterFields(rel.childObjectApiName);
                }
                return Promise.resolve();
            });
        this.selectedPageSettings.fieldsConfiguration.forEach((row, rowIndex) => {
            row.rowKey = 'row-' + rowIndex;
            if (row.length < 3) {
                for (let i = row.length; i < 3; i++) {
                    row.push({
                        fieldName: '',
                        isMandatory: false,
                        isReadOnly: false,
                        isEmpty: true
                    });
                }
            }
            row.forEach((field, colIndex) => {
                field.isEmpty = !field.fieldName;
                field.fieldKey = `row-${rowIndex}-col-${colIndex}`;
            });
        });
        if (this.rowsPerTemplate) {
            this.initializeFieldsPerRow(parseInt(this.rowsPerTemplate, 10));
            this.newFieldsConfiguration = true;
        } else {
            this.fieldsPerRowList = [];
            this.newFieldsConfiguration = false;
        }

        this.addNewPageLayout = false;
        this.selectedPageSettings?.tabs.forEach(elt => {
            elt.isGridFile = elt?.contentType == "grid";
        });
    }
    initializeFieldsPerRow(count) {
        const previousFieldsConfiguration = JSON.parse(JSON.stringify(this.selectedPageSettings?.fieldsConfiguration || []));
        this.fieldsPerRowList = [];
        this.selectedPageSettings.fieldsConfiguration = [];
        this.fieldsConfiguration = [];
        let bigArr = [];
        for (let rowIndex = 0; rowIndex < count; rowIndex++) {
            let fields = [];
            for (let colIndex = 0; colIndex < 3; colIndex++) {
                const existingField = previousFieldsConfiguration[rowIndex]?.[colIndex];
                fields.push({
                    fieldKey: `row-${rowIndex}-col-${colIndex}`,
                    fieldName: existingField?.fieldName || '',
                    isMandatory: existingField?.isMandatory || false,
                    isReadOnly: existingField?.isReadOnly || false,
                    isEmpty: !(existingField?.fieldName),
                });
            }
            const selectedFieldCount = fields.filter(field => field.fieldName).length;
            const rowItem = {
                rowKey: `row-${rowIndex}`,
                rowNumber: rowIndex + 1,
                selectedFieldCount: String(selectedFieldCount || 3),
                fields: fields,
                displayFields: []
            };
            this.updateRowDisplayFields(rowItem);
            this.fieldsPerRowList.push(rowItem);
            bigArr.push(fields);
        }
        this.fieldsConfiguration = bigArr;
        this.selectedPageSettings.fieldsConfiguration = this.fieldsConfiguration;
        this.selectedPageSettings.fieldsConfiguration.forEach((row, rowIndex) => {
            row.rowKey = 'row-' + rowIndex;
        });

    }

    updateRowDisplayFields(row) {
        const count = parseInt(row.selectedFieldCount, 10) || 3;
        row.displayFields = row.fields.slice(0, count);
    }

    createEmptyIcon() {
        return { isStaticRessource: false, value: '' };
    }

    togglePopupAddPageSettings() {
        this.addNewPageLayout = true;
        this.rowsPerTemplate = null;
        this.fieldsPerRowList = [];
        this.selectedPageSettings = {
            topLeftCornerLogo2: this.createEmptyIcon(),
            topLeftCornerLogo1: this.createEmptyIcon(),
            topLeftCornerFields: [],
            taskFields: [],
            selectedFlow: null,
            fieldsConfiguration: null,
            nbOfRows: null,
            objectApiName: "",
            newTaskFlow: "",
            name: "",
            isFlowMode: false,
            actionButtons: [],
            tabs: [],
            headerField: { isReadOnly: false, isMandatory: false, fieldName: "", showHeaderField: true },
            bottomLeftCornerLogo1: this.createEmptyIcon(),
            bottomLeftCornerLogo2: this.createEmptyIcon(),
            bottomLeftCornerFields: [],
            statusIcon: this.createEmptyIcon(),
            activityRightIcon: this.createEmptyIcon(),
            activityLeftIcon: this.createEmptyIcon(),
            topRightCornerFields: [],
            activityFields: [],
            relatedInformations: {
                objectApiName: '',
                parentRelationshipApiName: '',
                aggregateFunction: 'COUNT',
                aggregateFieldName: '',
                label: '',
                filters: [],
                whereClause: '',
            }
        }
        this.fieldNameOptions = [];
        this.fileDirectoryData = [];
        this.gridSettings = [];
        this.fieldNameTMPOptions = [];
    }

    searchObject(event) {
        let searchKey = event.target.value;
        if (!searchKey) {
            this.selectedObject = null;
            this.selectedPageSettings.objectApiName = "";
            this.showObjectDropdown = true;
            return;
        }
        this.searchedObjects = this.sortByLabel(
            this.customObjects.filter((option) =>
                option.label.toLowerCase().includes(event.detail.value)
            )
        );

        this.showObjectDropdown = true;
    }

    showallObjects() {
        this.searchedObjects = this.sortByLabel([...this.customObjects]);
        this.showObjectDropdown = true;
    }

    selectObject(event) {
        let selectedValue = event.target.dataset.value;
        this.selectedObject = selectedValue;
        this.showObjectDropdown = false;
        this.selectedPageSettings.objectApiName = this.selectedObject;
        if (!this.selectedPageSettings.relatedInformations) {
            this.selectedPageSettings.relatedInformations = {};
        }
        this.selectedPageSettings.relatedInformations.objectApiName = this.selectedObject;
        this.selectedPageSettings.relatedInformations.parentRelationshipApiName = '';
        this.loadFields(this.selectedObject).then(() => this.loadChildRelationships(this.selectedObject));
    }

    closeDropdown() {
        this.showObjectDropdown = false;
    }

    stopClose(event) {
        event.stopPropagation();
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
                        this.isLoading = false;
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
                            this.initData();
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Success, 'success')
                this.initData();
            }
        });
    }

    topLeftIconsChange(event) {
        let radioButton = event.detail.value;
        let radioBttn = radioButton == 'true'
        let icon = event.target.dataset.icon;
        if (icon == 'topLeftLogo1') {
            this.selectedPageSettings.topLeftCornerLogo1.isStaticRessource = radioBttn;
        }
        else if (icon == 'topLeftLogo2') {
            this.selectedPageSettings.topLeftCornerLogo2.isStaticRessource = radioBttn;
        }
    }

    topRightIconsChange(event) {
        let radioButton = event.detail.value;
        let radioBttn = radioButton == 'true'
        let icon = event.target.dataset.icon;
        if (icon == 'topRightLogo1') {
            this.selectedPageSettings.statusIcon.isStaticRessource = radioBttn;
        }
        else if (icon == 'topRightLogo2') {
            this.selectedPageSettings.activityLeftIcon.isStaticRessource = radioBttn;
        }
        else if (icon == 'topRightLogo3') {
            this.selectedPageSettings.activityRightIcon.isStaticRessource = radioBttn;
        }
    }

    bottomIconsChange(event) {
        let radioButton = event.detail.value;
        let radioBttn = radioButton == 'true'
        let icon = event.target.dataset.icon;
        if (icon == 'bottomLogo1') {
            this.selectedPageSettings.bottomLeftCornerLogo1.isStaticRessource = radioBttn;
        }
        else if (icon == 'bottomLogo2') {
            this.selectedPageSettings.bottomLeftCornerLogo2.isStaticRessource = radioBttn;
        }
    }

    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({ title: title, message: message, variant: variant, mode: mode });
        this.dispatchEvent(evt);
    }

    sortByLabel(array) {
        return array.sort((a, b) => a.label.localeCompare(b.label));
    }
}