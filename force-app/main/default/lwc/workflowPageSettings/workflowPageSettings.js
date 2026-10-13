import { LightningElement, api, track } from 'lwc';
import { labels, sectionsTypesMap, sectionsWrapperMap, FilterOperations, FIELD_TYPE_CONFIG } from './properties.js';
import initData from '@salesforce/apex/LayoutSettingsController.initData';
import getLayoutPagesList from '@salesforce/apex/LayoutSettingsController.getLayoutPagesList';
import saveSettings from '@salesforce/apex/LayoutSettingsController.saveSettings';
import getFields from '@salesforce/apex/LayoutSettingsController.getFields';
import getLayoutPageByDeveloperName from '@salesforce/apex/LayoutSettingsController.getLayoutPageByDeveloperName';
import checkDeploymentStatus from '@salesforce/apex/LayoutSettingsController.checkDeploymentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const OPERATIONS_WITHOUT_VALUE = [
    FilterOperations.ISNULL,
    FilterOperations.ISBLANK,
    FilterOperations.ISNOTNULL,
    FilterOperations.ISNOTBLANK,
];
export default class WorkflowPageSettings extends LightningElement {
    @api
    get templateDeveloperName() {
        return this.templateName;
    }
    set templateDeveloperName(template) {
        this.templateName = template;
        if (template) {
            this.loadLayoutTemplate(template);
        }
    }
    @api
    get bodySize() {
        return this._bodySize;
    }
    set bodySize(bodySize) {
        this._bodySize = `height:${bodySize - 80}px;`
        this._tabContentSize = `height:${bodySize - 126}px;`

    }
    @api
    get pageType() {
        return this._pageType;
    }
    set pageType(type) {
        this._pageType = type;
    }
    labels = labels;
    @track Loading = false;
    @track _bodySize;
    @track _tabContentSize;
    @track templateName = '';
    @track _pageType;
    @track isNewTemplate = true;
    @track layouts = [];
    @track isLeftOpen = true;
    @track isRightOpen = true;
    @track showTemplate = true;
    @track showObjectDropdown = false;
    @track screenFlowsList = [];
    @track themesList = [];
    @track themes = [];
    @track selectedThemeStyle = '';
    @track activityObjectFields = [];
    @track taskObjectFields = [];
    @track pages = [];
    @track objectsList = [];
    @track searchKeys = {
        objectSearchKey: ''
    }
    @track gridSettings = [];
    @track normalizedApiName = {
        ObjectApiName__c: 'ObjectApiName__c'
    };
    developerNameRegex = /^[A-Za-z][A-Za-z0-9_]*$/;
    @track instance = {
        LayoutPages: [],
        fieldNameOptions: [],
        objectChildRelationship: [],
        objectChildRelationshipOptions: [],
        currentLayout: {
            settings: {
                objectApiName: '',
                developerName: '',
                type: '',
                theme: '',
                label: '',
                description: '',
                isActive: true,
                sectionGroupTab: [],
                sections: []
            },
            settingsWrappers: {
                sidebarSectionWrapper: [],
                mainSectionWrapper: [],
                rightSectionWrapper: []
            }
        }
    }
    @track popups = {
        themePopup: {
            isOpen: false,
            sectionIndex: null,
            wrapper: null,
            wrapperIndex: null,
            value: '',
            displayValue: {
                titleStyle: {
                    titleBackgroundColor: '',
                    titleColor: ''
                }
            },
            open: (event) => {
                const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
                const wrapper = event.currentTarget.dataset.wrapper;
                const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
                const wrapperObj = this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex];
                const titleStyle = wrapperObj.sectionWrapper.titleStyle || '';
                const backgroundColorMatch = titleStyle.match(/background-color\s*:\s*([^;]*)/i);
                const colorMatch = titleStyle.match(/(?:^|;)\s*color\s*:\s*([^;]*)/i);
                this.popups.themePopup.value = titleStyle;
                this.popups.themePopup.displayValue.titleStyle.titleBackgroundColor = backgroundColorMatch ? backgroundColorMatch[1].trim() : '';
                this.popups.themePopup.displayValue.titleStyle.titleColor = colorMatch ? colorMatch[1].trim() : '';
                this.popups.themePopup.isOpen = true;
                this.popups.themePopup.sectionIndex = sectionIndex;
                this.popups.themePopup.wrapper = wrapper;
                this.popups.themePopup.wrapperIndex = wrapperIndex;
            },
            handleChange: (event) => {
                const property = event.currentTarget.dataset.type;
                const param = event.currentTarget.dataset.param;
                const field = event.currentTarget.dataset.field;
                const value = event.target.value;
                let style = this.popups.themePopup.value || '';
                const regex = new RegExp(`(^|;)${property}:[^;]*;?`, 'g');
                style = style.replace(regex, '$1');
                if (style && !style.endsWith(';')) {
                    style += ';';
                }
                style += `${property}:${value};`;
                this.popups.themePopup.displayValue[field][param] = value;
                this.popups.themePopup.value = style;
                console.log('style:', this.popups.themePopup.value);
                console.log('>>>>>>>>>>>>>>> this.popups.themePopup.displayValue:' + JSON.stringify(this.popups.themePopup.displayValue));
                console.log('>>>>>>>>>>>>>>> this.popups.themePopup.value:' + JSON.stringify(this.popups.themePopup.value));
            },
            confirm: () => {
                const popup = this.popups.themePopup;
                const wrapperObj = this.instance.currentLayout.settingsWrappers[popup.wrapper][popup.wrapperIndex];
                const section = this.instance.currentLayout.settings.sections[popup.sectionIndex];
                wrapperObj.sectionWrapper.titleStyle = popup.value;
                section.titleStyle = popup.value;
                console.log('>>>>>>>>>>>>>>> wrapperObj.sectionWrapper:' + JSON.stringify(wrapperObj.sectionWrapper));
                console.log('>>>>>>>>>>>>>>> section:' + JSON.stringify(section));
                popup.close();
            },
            close: () => {
                const popup = this.popups.themePopup;
                popup.isOpen = false;
                popup.sectionIndex = null;
                popup.wrapper = null;
                popup.wrapperIndex = null;
                popup.wrapperIndex = null;
                popup.value = '';
                popup.displayValue = {
                    titleStyle: {
                        titleBackgroundColor: '',
                        titleColor: ''
                    }
                };
            }
        },
        tabParams: {
            title: '',
            isOpen: false,
            params: [],
            target: null,
            context: null,
            sectionIndex: null,
            wrapper: null,
            wrapperIndex: null,
            rowIndex: null,
            type: null,
            gridSettingsLayouts: [],
            handleChange: (event) => {
                const index = Number(event.currentTarget.dataset.index);
                const param = this.popups.tabParams.params[index];
                if (!param) {
                    return;
                }
                param.value = param.isBoolean ? event.detail.checked : event.detail.value;
            },
            close: () => {
                this.popups.tabParams.params = [];
                this.popups.tabParams.target = null;
                this.popups.tabParams.context = null;
                this.popups.tabParams.sectionIndex = null;
                this.popups.tabParams.wrapper = null;
                this.popups.tabParams.wrapperIndex = null;
                this.popups.tabParams.rowIndex = null;
                this.popups.tabParams.type = null;
                this.popups.tabParams.isOpen = false;
            },
            confirm: () => {
                const popup = this.popups.tabParams;
                const params = popup.params;
                const target = popup.target;
                let isValid = true;
                params.forEach(param => {
                    if (!param.required) {
                        return;
                    }
                    const value = param.value;
                    if ((param.isString && (!value || value.trim() === '')) || (param.isInteger && (value === null || value === undefined || value === '')) || (param.isBoolean && typeof value !== 'boolean')) {
                        isValid = false;
                    }
                });
                if (!isValid) {
                    this.showNotification(this.Label.LBL_Error, this.Label.MSG_Fill_Required_Fields, 'error', 'sticky');
                    return;
                }
                if (!target.params) {
                    target.params = {};
                }
                if (this.instance.currentLayout.settings.objectApiName) {
                    target.params.objectApiName = this.instance.currentLayout.settings.objectApiName;
                }
                params.forEach(param => {
                    target.params[param.name] = param.value === '' ? '' : param.value;
                });
                popup.close();
            },
            open: (event) => {
                const popup = this.popups.tabParams;
                const sectionIndex = Number(event.currentTarget.dataset.sectionindex);
                const wrapper = event.currentTarget.dataset.wrapper;
                const wrapperIndex = Number(event.currentTarget.dataset.wrapperindex);
                const rowIndex = Number(event.currentTarget.dataset.rowindex);
                const context = event.currentTarget.dataset.context;
                const type = event.currentTarget.dataset.type;
                const contentType = event.currentTarget.dataset.contentType;
                const section = this.instance.currentLayout.settings.sections[sectionIndex];
                let target;
                switch (context) {
                    case 'components':
                        target = section.components[rowIndex];
                        break;
                    case 'tabset':
                        target = section.tabset[rowIndex].component;
                        break;
                    default:
                        this.showNotification(this.Label.LBL_Error, 'Unsupported configuration target.', 'error');
                        return;
                }
                let pluginName;
                switch (contentType) {
                    case 'grid':
                        pluginName = 'gridSettingsPlugin';
                        break;

                    case 'page':
                        pluginName = 'fileDirectoryManager';
                        break;

                    default:
                        pluginName = target.name;
                }
                const paramsSettings = this.lwcParamsSettingsList?.find(item => item.name === pluginName);
                let params = paramsSettings?.paramSetting;
                if (!params) {
                    this.showNotification(this.Label.LBL_Error, this.Label.Msg_NoInputParams, 'error');
                    return;
                }
                params = JSON.parse(JSON.stringify(params));
                if (contentType === 'grid') {
                    params = params.filter(param => !['objectApiName', 'templateName'].includes(param.name));
                }
                params.forEach((param, index) => {
                    param[`is${param.type}`] = true;
                    if (param.getDataSourceList) {
                        param.datasourceList =
                            Object.keys(param.getDataSourceList).map(key => ({
                                value: key,
                                label: param.getDataSourceList[key]
                            }));
                        param.isCombobox = param.datasourceList.length > 0;
                    }
                    param.paramKey = `param-${index}`;
                    param.required = param.required === true || param.required === 'true';
                    if (param.isBoolean) {
                        param.value = param.defaultValue === true || param.defaultValue === 'true';
                    }
                    else if (param.isInteger) {
                        param.value = param.defaultValue !== undefined && param.defaultValue !== null && param.defaultValue !== '' ? Number(param.defaultValue) : null;
                    }
                    else {
                        param.value = param.defaultValue;
                    }
                });
                if (target.params) {
                    Object.keys(target.params).forEach(name => {
                        const param = params.find(p => p.name === name);
                        if (!param) {
                            return;
                        }
                        const value = target.params[name];
                        if (param.isBoolean) {
                            param.value = value === true || value === 'true';
                        }
                        else if (param.isInteger) {
                            param.value = value !== null && value !== undefined && value !== '' ? Number(value) : null;
                        }
                        else {
                            param.value = value;
                        }
                    });
                }
                popup.title = event.currentTarget.dataset.title || 'Settings';
                popup.params = params;
                popup.target = target;
                popup.context = context;
                popup.sectionIndex = sectionIndex;
                popup.wrapper = wrapper;
                popup.wrapperIndex = wrapperIndex;
                popup.rowIndex = rowIndex;
                popup.type = type;
                popup.isOpen = true;
            }
        },
        relatedInformations: {
            isOpen: false,
            filters: [],
            groupByFields: [],
            relatedInformationRowIndex: null,
            sectionIndex: null,
            wrapper: null,
            wrapperIndex: null,
            objectApiName: ''
        }
    }
    draggedWrapperIndex;
    draggedWrapperName;
    modalConfig = {
        isOpen: false,
        title: '',
        message: '',
        confirmLabel: '',
        onConfirmAction: null,
        onCloseAction: null
    };
    tabComponentsOptions = [
        { label: 'grid', value: 'grid' },
        { label: 'page', value: 'page' },
    ];
    fieldCountOptions = [
        { label: '1', value: 1 },
        { label: '2', value: 2 },
        { label: '3', value: 3 }
    ];
    iconOptions = [
        { label: this.labels.LBL_StaticResource, value: 'staticresource' },
        { label: this.labels.LBL_Field, value: 'field' }
    ];
    actionType = [
        { label: 'Text', value: 'text' },
        { label: 'Icon', value: 'icon' },
        { label: labels.LBL_PageLayoutSettings_Button, value: 'button' },
        { label: labels.LBL_PageLayoutSettings_OnClick, value: 'onclick' },
    ];
    redirectionType = [
        { label: labels.LBL_PageLayoutSettings_Flow, value: 'flow' },
        { label: 'url', value: 'url' },
    ];
    @track staticResourceOptions;
    sectionsList = [
        {
            wrapperName: 'sidebarSectionWrapper',
            key: 0
        },
        {
            wrapperName: 'bodyWrapper',
            key: 1
        },
        {
            wrapperName: 'rightSectionWrapper',
            key: 2
        }
    ]
    sectionMenuItems = [
        { value: 'fieldGroup', label: this.labels.LBL_WorkFlowPage_MenuList_fieldGroup },
        { value: 'imageFields', label: this.labels.LBL_WorkFlowPage_MenuList_imageFields },
        { value: 'actionBar', label: this.labels.LBL_WorkFlowPage_MenuList_actionBar },
        { value: 'tabset', label: this.labels.LBL_WorkFlowPage_MenuList_tabset },
        { value: 'statusCard', label: this.labels.LBL_WorkFlowPage_MenuList_statusCard },
        { value: 'TimelineCard', label: this.labels.LBL_WorkFlowPage_MenuList_TimelineCard },
        { value: 'taskList', label: this.labels.LBL_WorkFlowPage_MenuList_taskList },
        { value: 'Component', label: this.labels.LBL_WorkFlowPage_MenuList_Component },
        { value: 'HeaderCard', label: this.labels.LBL_WorkFlowPage_MenuList_HeaderCard },
        { value: 'AgregatesCard', label: this.labels.LBL_WorkFlowPage_MenuList_AgregatesCard }
    ];
    sectionToWrapperMap = {
        sidebar: 'sidebarSectionWrapper',
        main: 'mainSectionWrapper',
        right: 'rightSectionWrapper'
    };
    /*=======================
        lifecycle hooks
      =======================
     */
    connectedCallback() {
        // window.addEventListener('resize', this.changeHeight);
        this.Loading = true;
        // ensure init data is loaded before trying to render a provided template
        this.initData().then(() => {
            if (this.templateName) {
                this.loadLayoutTemplate(this.templateName);
            } else {
                if (!this._pageType) {
                    throw new Error('The "pageType or templateDeveloperName" property is required.');
                }
                this.instance.currentLayout.settings.type = this._pageType;
            }
        }).catch(() => { });
    }
    // renderedCallback() {
    //     this.changeHeight();
    // }
    initData() {
        try {
            let self = this;
            console.log('initData called');
            return initData().then((result) => {
                let parsedResult = JSON.parse(result);
                self.normalizedApiName = {
                    ObjectApiName__c: parsedResult.prefix + 'ObjectApiName__c'
                };
                self.objectsList = parsedResult.objects;
                self.screenFlowsList = parsedResult.screenFlows;
                console.log('>>>>>>>>>>>>>>>>>> result.themesList:' + JSON.stringify(parsedResult.themesList));
                this.themes = parsedResult.themesList?.map(theme => ({
                    ...theme,
                    themeAttributes: JSON.parse(theme.themeAttributes)
                }));
                self.themesList = parsedResult.themesList?.map(theme => ({
                    label: theme.label,
                    value: theme.value
                }));
                self.taskObjectFields = parsedResult.taskObjectFields.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                self.activityObjectFields = parsedResult.activityObjectFields.map(field => ({
                    label: field.label || field.apiName,
                    value: field.apiName
                }));
                let gridSettings = parsedResult.gridSettings.map(obj => ({ label: obj.Label, value: obj.QualifiedApiName }));
                this.gridSettings = [...gridSettings];
                parsedResult.pages.forEach(page => {
                    this.pages.push({ label: page.MasterLabel, value: page.DeveloperName });
                })
                this.lwcParamsSettingsList = parsedResult.lwcParamsSettingsList || [];
                this.staticResourceOptions = parsedResult.staticResourceList || [];
                // this.LoadLayoutPages().then(() => {
                //     self.Loading = false;
                // });
                console.log('result init dataL:' + JSON.stringify(parsedResult));
                self.Loading = false;
                return parsedResult;
            });
        } catch (error) {
            this.Loading = false;
            console.log('error in init data %c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    // changeHeight = () => {
    //     const headerEl = this.template.querySelector('.workflow-header');
    //     if (headerEl) {
    //         const headerHeight = headerEl.getBoundingClientRect().height;
    //         const calculatedHeight = (window.innerHeight - headerHeight - 150) + 'px';
    //         const body = this.template.querySelector('.workflow-body');
    //         if (body) {
    //             body.style.height = calculatedHeight;
    //         }
    //         const tabset = this.template.querySelector('.tabset');
    //         if (tabset) {
    //             tabset.style.height = calculatedHeight;
    //         }
    //         const customfieldsbody = this.template.querySelector('.custom-fields-body');
    //         if (customfieldsbody) {
    //             customfieldsbody.style.minHeight = calculatedHeight;
    //         }
    //     }
    // };
    loadLayoutTemplate(developerName) {
        this.Loading = true;
        const devName = developerName || this.templateName;
        getLayoutPageByDeveloperName({ developerName: devName }).then(result => {
            let layout = JSON.parse(result);
            //layout.layoutSettings.fieldsConfiguration =
            this.buildLayoutTemplate(layout.layoutSettings);
            console.log('after load settings: ' + JSON.stringify(this.instance.currentLayout.settings));
            console.log('after load wrapper: ' + JSON.stringify(this.instance.currentLayout.settingsWrappers));
            this.templateName = devName;
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
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky')
            this.Loading = false;
        });
    }
    buildLayoutTemplate(layoutSettings) {
        this.selectedThemeStyle = `background-color: ${this.instance.currentLayout.settings.theme?.themeAttributes?.brandColor};`;
        // reset wrappers
        this.instance.currentLayout.settingsWrappers = {
            sidebarSectionWrapper: [],
            mainSectionWrapper: [],
            rightSectionWrapper: []
        };
        const sections = [...layoutSettings.sections].sort((a, b) => {
            if (a.region === b.region) {
                return a.order - b.order;
            }
            return 0;
        });
        this.instance.currentLayout.settings = { ...layoutSettings, sections };
        sections.forEach((section, sectionIndex) => {
            const wrapperName = section.region;
            const wrapperList = this.instance.currentLayout.settingsWrappers[this.sectionToWrapperMap[wrapperName]];
            let sectionWrapper = { ...section };
            const isSingleIcon = section.styleVariant === 'statusCard' || section.styleVariant === 'HeaderCard';
            sectionWrapper.icons = section.icons?.map(icon => {
                const base = {
                    name: icon.name || '',
                    type: icon.type,
                    contentType: icon.contentType,
                    isStaticRessource: icon.contentType === 'staticresource' ? true : false,
                    previewStyle: icon.contentType === 'staticresource' ? `opacity:0.5;width:80px;height:80px;background-image:url(${icon.name});background-size:contain;background-position:left;background-repeat:no-repeat;` : ''
                };
                if (isSingleIcon) {
                    return base;
                }
                return {
                    ...base,
                    label: icon.type === 'primary' ? this.labels.LBL_LayoutSettings_PrimaryIcon : this.labels.LBL_LayoutSettings_SecondaryIcon
                };
            });
            const wrapperObject = {
                sectionWrapper: sectionWrapper,
                isFieldGroup: section.styleVariant === 'fieldGroup',
                isImageFields: section.styleVariant === 'imageFields',
                isActionBar: section.styleVariant === 'actionBar',
                isTabset: section.styleVariant === 'tabset',
                isStatusCard: section.styleVariant === 'statusCard',
                isTimelineCard: section.styleVariant === 'TimelineCard',
                isTaskList: section.styleVariant === 'taskList',
                isComponent: section.styleVariant === 'Component',
                isHeaderCard: section.styleVariant === 'HeaderCard',
                isAgregatesCard: section.styleVariant === 'AgregatesCard',
                showActions: false,
                key: `${wrapperList.length}-${section.region}`,
                containerKey: wrapperList.length,
                contentLabel: `${this.sectionMenuItems.find(item => item.value === section.styleVariant).label} `,
                contentText: sectionsTypesMap[section.styleVariant],
                sectionIndex,
                toggleIcon: 'utility:chevronright',
                isExpanded: false,
                showActions: section.actions.length > 0
            };
            Object.assign(wrapperObject, JSON.parse(JSON.stringify(sectionsWrapperMap[section.styleVariant] || {})));
            switch (section.styleVariant) {
                case 'fieldGroup':
                    wrapperObject.wrapper.header = JSON.parse(JSON.stringify(section.header));
                    wrapperObject.wrapper.actions = section.actions.length ? JSON.parse(JSON.stringify(section.actions[0])) : wrapperObject.wrapper.actions;
                    wrapperObject.wrapper.isFlowMode = section.actions.length > 0
                    wrapperObject.wrapper.fieldsWrapper =
                        section.fields.map((row, rowIndex) => ({
                            rowKey: rowIndex,
                            rowNumber: rowIndex + 1,
                            expanded: false,
                            fieldsNumber: row.length,
                            fields: row.map((field, fieldIndex) => ({
                                ...field,
                                fieldKey: fieldIndex
                            }))
                        }));
                    break;
                case 'actionBar':
                    wrapperObject.wrapper.actions = JSON.parse(JSON.stringify(section.actions)).map((action, index) => ({
                        ...action,
                        isFlow: action.redirectionType === 'flow',
                        key: index
                    }));
                    break;
                case 'statusCard':
                    wrapperObject.wrapper.fields = section.fields.map(group => group?.[0]?.fieldName);
                    break;
                case 'TimelineCard':
                    wrapperObject.wrapper.fields = section.fields.map(group => group?.[0]?.fieldName);
                    break;
                case 'taskList':
                case 'HeaderCard':
                    wrapperObject.wrapper.fields = section.fields.map(group => group?.[0]?.fieldName);
                    wrapperObject.wrapper.actions = JSON.parse(JSON.stringify(section.actions)).map((action, index) => ({
                        ...action,
                        isFlow: action.redirectionType === 'flow',
                        key: index
                    }));
                    break;
                case 'tabset':
                    wrapperObject.wrapper =
                        section.tabset.map((tab, index) => ({
                            ...JSON.parse(JSON.stringify(tab)),
                            key: index,
                            component: {
                                ...tab.component,
                                isGridFile: tab.component.type === 'grid'
                            }
                        }));
                    break;
                case 'Component':
                    wrapperObject.wrapper =
                        section.components.map((component, index) => ({
                            ...JSON.parse(JSON.stringify(component)),
                            key: index,
                            isGridFile: component.type === 'grid'
                        }));
                    break;
                case 'AgregatesCard':
                    wrapperObject.wrapper.aggregates =
                        section.aggregates.map((aggregate, index) => ({
                            ...JSON.parse(JSON.stringify(aggregate)),
                            key: index
                        }));
                    break;
                case 'imageFields':
                    wrapperObject.wrapper.fields = section.fields.map(group => group?.[0]?.fieldName);
                    wrapperObject.wrapper.actions = JSON.parse(JSON.stringify(section.actions)).map((action, index) => ({
                        ...action,
                        isFlow: action.redirectionType === 'flow',
                        key: index
                    }));
                    break;
            }
            wrapperList.push(wrapperObject);
        });
        console.log('-------------------------- this.instance.currentLayout.settingsWrappers.mainSectionWrapper:' + JSON.stringify(this.instance.currentLayout.settingsWrappers.mainSectionWrapper));
    }

    /* ============================
       header handlers
       ============================
     */
    handleCancel() {
        this.showTemplate = false;
        this.resetTemplate();
        this.dispatchEvent(
            new CustomEvent('cancel', {
                detail: {
                    action: true
                }
            })
        );
    }
    handleDelete() {
        this.Loading = true;
        this.instance.currentLayout.settings.isActive = false;
        this.handleSave();
        this.Loading = false;
    }

    /* ============================
       sections handlers
       ============================
     */
    showallObjects() {
        this.showObjectDropdown = true;
    }
    handleChangeLayoutObject(event) {
        const value = event.target.value ?? event.currentTarget.dataset.value;
        this.instance.currentLayout.settings.objectApiName = value;
        this.searchKeys.objectSearchKey = value;
        this.showObjectDropdown = false;
        this.loadFields(value);
    }
    handleSectionAction(event) {
        const action = event.currentTarget.dataset.action || event.detail?.value;
        const wrapper = event.target.wrapper ?? event.currentTarget.dataset.wrapper ?? 'sidebarSectionWrapper';
        const region = event.target.region ?? event.currentTarget.dataset.region;
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        let sectionsList = JSON.parse(JSON.stringify(this.instance.currentLayout.settings.sections || []));
        let wrapperList = JSON.parse(JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper] || []));
        if (action === 'delete') {
            sectionsList.splice(sectionIndex, 1);
            wrapperList.splice(wrapperIndex, 1);
            wrapperList = wrapperList.map((item, idx) => {
                const globalSectionIndex = sectionsList.findIndex(
                    section => section.styleVariant === item.wrapper.styleVariant && section.title === item.wrapper.title
                );
                return {
                    ...item,
                    key: idx,
                    sectionIndex: globalSectionIndex,
                    containerKey: item.containerKey || (Date.now() + idx),
                    toggleIcon: item.isExpanded === false ? 'utility:chevronright' : 'utility:chevrondown'
                };
            });
            sectionsList = sectionsList.map((item, idx) => {
                return { ...item, order: idx + 1 };
            });
        }
        else if (action === 'toggle') {
            if (wrapperList[wrapperIndex].isExpanded === undefined) {
                wrapperList[wrapperIndex].isExpanded = true;
            }
            wrapperList[wrapperIndex].isExpanded = !wrapperList[wrapperIndex].isExpanded;
            wrapperList[wrapperIndex].toggleIcon = wrapperList[wrapperIndex].isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
        } else if (action === 'settings') {
            this.popups.themePopup.open(event);
        }
        console.log('before sections:' + JSON.stringify(this.instance.currentLayout.settings.sections));
        this.instance.currentLayout.settings.sections = sectionsList;
        this.instance.currentLayout.settingsWrappers[wrapper] = wrapperList;
        console.log('after sections:' + JSON.stringify(this.instance.currentLayout.settings.sections));
    }
    handleSectionMenu(event) {
        const action = event.detail.value;
        const sectionIndex = event.target.dataset.sectionindex;
        const wrapper = event.target.dataset.wrapper;
        const wrapperIndex = event.target.dataset.wrapperindex;
        const region = event.target.region ?? event.currentTarget.dataset.region;
        let sectionsList = JSON.parse(JSON.stringify(this.instance.currentLayout.settings.sections || []));
        let wrapperList = JSON.parse(JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper] || []));
        switch (action) {
            case 'settings':
                this.popups.themePopup.open(event);
                break;
            case 'delete':
                const datasetPayload = {
                    currentTarget: {
                        dataset: { ...event.currentTarget.dataset }
                    },
                    target: {
                        dataset: { ...event.target.dataset }
                    },
                    detail: {
                        value: 'delete'
                    }
                };
                this.handleDeleteItem(datasetPayload);
                break;
        }
    }
    handleAddSection(event) {
        const wrapper = event.target.wrapper ?? event.currentTarget.dataset.wrapper;
        const region = event.target.region ?? event.currentTarget.dataset.region;
        const selectedValue = event.detail.value;
        const selectedlabel = this.sectionMenuItems.find(item => item.value === selectedValue).label
        const wrapperList = this.instance.currentLayout.settingsWrappers[wrapper];
        const sections = this.instance.currentLayout.settings.sections;
        // Collapse any already-expanded sections in this wrapper before adding the new one
        if (Array.isArray(wrapperList) && wrapperList.length) {
            wrapperList.forEach(w => {
                w.isExpanded = false;
                w.toggleIcon = 'utility:chevronright';
            });
        }
        console.log('>>>>>>>>>>>> wrapper:' + JSON.stringify(wrapper));
        sections.push({
            title: '',
            name: '',
            showTitle: true,
            titleStyle: '',
            styleVariant: selectedValue,
            fields: [],
            header: {
                type: '',
                fieldName: '',
                isMandatory: false,
                isReadOnly: false,
                standard: false,
                ...(this._pageType === 'record' ? { stickyBare: false } : {})
            },
            icons: (selectedValue === 'statusCard' || selectedValue === 'HeaderCard')
                ? [
                    {
                        name: '',
                        type: 'primary',
                        contentType: 'staticresource',
                    }
                ]
                : [
                    {
                        name: '',
                        type: 'primary',
                        contentType: 'staticresource'
                    },
                    {
                        name: '',
                        type: 'secondary',
                        contentType: 'staticresource'
                    }
                ],
            tabset: [],
            components: [],
            actions: [],
            region: region,
            sectionGroupTab: null,
            order: wrapperList.length + 1,
            aggregates: [],
            themeName: ''
        });
        const wrapperObject = {
            sectionWrapper: {
                title: '',
                name: '',
                showTitle: true,
                titleStyle: '',
                styleVariant: selectedValue,
                fields: [],
                header: {
                    type: '',
                    fieldName: '',
                    isMandatory: false,
                    isReadOnly: false,
                    standard: false,
                    ...(this._pageType === 'record' ? { stickyBare: false } : {})
                },
                icons:
                    (selectedValue === 'statusCard' || selectedValue === 'HeaderCard')
                        ? [
                            {
                                name: '',
                                type: 'primary',
                                contentType: 'staticresource',
                                isStaticRessource: "false",
                                previewStyle: ""
                            }
                        ]
                        : [
                            {
                                name: '',
                                type: 'primary',
                                contentType: 'staticresource',
                                isStaticRessource: "false",
                                label: this.labels.LBL_LayoutSettings_PrimaryIcon,
                                previewStyle: ""
                            },
                            {
                                name: '',
                                type: 'secondary',
                                contentType: 'staticresource',
                                isStaticRessource: "false",
                                label: this.labels.LBL_LayoutSettings_SecondaryIcon,
                                previewStyle: ""
                            }
                        ],
                region: region,
                sectionGroupTab: null,
                order: wrapperList.length + 1,
                themeName: ''
            },
            isFieldGroup: selectedValue === 'fieldGroup',
            isImageFields: selectedValue === 'imageFields',
            isActionBar: selectedValue === 'actionBar',
            isTabset: selectedValue === 'tabset',
            isStatusCard: selectedValue === 'statusCard',
            isTimelineCard: selectedValue === 'TimelineCard',
            isTaskList: selectedValue === 'taskList',
            isComponent: selectedValue === 'Component',
            isHeaderCard: selectedValue === 'HeaderCard',
            isAgregatesCard: selectedValue === 'AgregatesCard',
            showActions: false,
            key: wrapperList.length,
            containerKey: wrapperList.length,
            contentLabel: selectedlabel,
            contentText: sectionsTypesMap[selectedValue],
            sectionIndex: sections.length - 1,
            toggleIcon: 'utility:chevrondown',
            isExpanded: true
        };
        const wrapperDefaults = JSON.parse(JSON.stringify(sectionsWrapperMap[selectedValue] || {}));
        Object.assign(wrapperObject, wrapperDefaults);
        wrapperList.push(wrapperObject);
        this.instance.currentLayout.settingsWrappers[wrapper] = wrapperList;
        console.log('added section:', JSON.stringify(wrapperList));
        console.log('this.instance.currentLayout.settingsWrappers:', JSON.stringify(this.instance.currentLayout.settingsWrappers));
        console.log('sections:', JSON.stringify(sections));
    }
    // validateName(event) {
    //     const input = event.target;
    //     const value = input.value;
    //     if (!value || !this.developerNameRegex.test(value)) {
    //         input.setCustomValidity(this.labels.LBL_InvalidDeveloperName);
    //     } else {
    //         input.setCustomValidity('');
    //     }
    //     input.reportValidity();
    // }

    handleDragStart(event) {
        this.draggedWrapperIndex = Number(event.currentTarget.dataset.index);
        this.draggedWrapperName = event.currentTarget.dataset.wrapper;
    }
    handleDragOver(event) {
        event.preventDefault();
    }
    handleDrop(event) {
        event.preventDefault();
        const wrapperName = event.currentTarget.dataset.wrapper;
        const dropIndex = Number(event.currentTarget.dataset.index);
        if (wrapperName !== this.draggedWrapperName) {
            return;
        }
        const wrapperList = [
            ...this.instance.currentLayout.settingsWrappers[wrapperName]
        ];
        const draggedIndex = this.draggedWrapperIndex;
        if (draggedIndex === dropIndex) {
            return;
        }
        const [draggedItem] = wrapperList.splice(draggedIndex, 1);
        wrapperList.splice(dropIndex, 0, draggedItem);
        wrapperList.forEach((wrapper, index) => {
            wrapper.sectionWrapper.order = index + 1;
        });
        this.instance.currentLayout.settingsWrappers[wrapperName] = wrapperList;
        this.instance.currentLayout.settings.sections =
            Object.values(this.instance.currentLayout.settingsWrappers).flat().map(wrapper => wrapper.sectionWrapper);
        this.buildLayoutTemplate(this.instance.currentLayout.settings);
        this.instance = { ...this.instance };
    }
    handlePageLayoutSettingsChange(event) {
        const settingsField = event.currentTarget.dataset.field;
        const type = event.currentTarget.dataset.type;
        const wrapper = event.currentTarget.dataset.wrapper;
        const rowIndex = event.currentTarget.dataset.rowindex !== undefined ? parseInt(event.currentTarget.dataset.rowindex, 10) : undefined;
        const sectionIndex = event.currentTarget.dataset.sectionindex !== undefined ? parseInt(event.currentTarget.dataset.sectionindex, 10) : undefined;
        const wrapperIndex = event.currentTarget.dataset.wrapperindex !== undefined ? parseInt(event.currentTarget.dataset.wrapperindex, 10) : undefined;
        let value;
        if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
            value = event.target.checked;
        } else {
            value = event.detail?.value ?? event.target.value ?? event.currentTarget.dataset.value;
        }
        console.log('handlePageLayoutSettingsChange: field=' + settingsField + ', type=' + type + ', wrapper=' + wrapper + ', rowIndex=' + rowIndex + ', sectionIndex=' + sectionIndex + ', wrapperIndex=' + wrapperIndex + ', value=' + value);
        if (!wrapper) {
            if (type != undefined) {
                if (rowIndex != undefined) {
                    this.instance.currentLayout.settings[settingsField][rowIndex][type] = value;
                    if (type === 'label') {
                        const name = value.trim().replace(/\s+/g, '_');
                        this.instance.currentLayout.settings[settingsField][rowIndex].Name = name;
                    }
                }
                this.instance.currentLayout.settings[settingsField][type] = value;
            } else {
                this.instance.currentLayout.settings[settingsField] = value;
                console.log('Updated setting:', settingsField, value);
                if (settingsField === 'theme') {
                    console.log('this.themes:' + JSON.stringify(this.themes));
                    const theme = this.themes.find(t => t.value === value);
                    if (theme) {
                        this.selectedThemeStyle = `background-color: ${theme.themeAttributes.brandColor};`;
                    }
                }
            }
            console.log('---------------------- this.instance.currentLayout.settings[settingsField]:' + JSON.stringify(this.instance.currentLayout.settings[settingsField]));
            return;
        }
        const wrapperArray = this.instance.currentLayout.settingsWrappers[wrapper];
        const sectionData = this.instance.currentLayout.settings.sections[sectionIndex];
        const wrapperObj = wrapperArray?.[wrapperIndex];
        console.log('------- wrapperArray:' + JSON.stringify(wrapperArray));
        console.log('------- sectionData:' + JSON.stringify(sectionData));
        console.log('------- wrapperObj:' + JSON.stringify(wrapperObj));
        if (wrapperObj && sectionData) {
            if (rowIndex !== undefined && settingsField === 'icons') {
                let icons = [...wrapperObj.sectionWrapper.icons];
                let sectionIcons = [...sectionData.icons];
                icons[rowIndex] = { ...icons[rowIndex], [type]: value };
                // handle isStaticRessource cleanly
                if (type === 'contentType') {
                    icons[rowIndex].isStaticRessource = value === 'staticresource';
                }
                icons[rowIndex].previewStyle = icons[rowIndex].isStaticRessource
                    ? `opacity:0.5;
                            width:80px;
                            height:80px;
                            background-image:url(${icons[rowIndex].name});
                            background-size:contain;
                            background-position:left;
                            background-repeat:no-repeat;`
                    : '';
                sectionIcons[rowIndex] = {
                    ...sectionIcons[rowIndex],
                    [type]: value,
                    isStaticRessource: icons[rowIndex].isStaticRessource,
                    previewStyle: icons[rowIndex].previewStyle
                };
                wrapperObj.sectionWrapper = { ...wrapperObj.sectionWrapper, icons };
                sectionData.icons = sectionIcons;
                console.log('icons updated:', JSON.stringify(icons));
            } else if (settingsField === 'fields') {
                wrapperObj.wrapper.fields = value;
                sectionData.fields = value.map(fieldApiName => [{ type: '', isMandatory: false, isReadOnly: false, standard: false, fieldName: fieldApiName, ...(this._pageType === 'record' ? { stickyBare: false } : {}) }]);
            } else if (settingsField) {
                if (type) {
                    if (rowIndex !== undefined) {
                        wrapperObj.sectionWrapper[settingsField][rowIndex][type] = value;
                        sectionData[settingsField][rowIndex][type] = value;
                    } else {
                        wrapperObj.sectionWrapper[settingsField][type] = value;
                        sectionData[settingsField][type] = value;
                    }
                } else {
                    wrapperObj.sectionWrapper[settingsField] = value;
                    sectionData[settingsField] = value;
                }
            }
        }
        console.log('-------------------- wrapperObj:' + JSON.stringify(wrapperObj));
        console.log('-------------------- sectionData:' + JSON.stringify(sectionData));
    }
    //fields group configuration
    handlePageLayoutFieldsGroupChange(event) {
        const field = event.currentTarget.dataset.field;
        const type = event.currentTarget.dataset.type;
        const rowIndex = Number(event.currentTarget.dataset.rowindex);
        const colIndex = Number(event.currentTarget.dataset.colindex);
        const sectionIndex = Number(event.currentTarget.dataset.sectionindex);
        const wrapperIndex = Number(event.currentTarget.dataset.wrapperindex);
        const wrapperName = event.currentTarget.dataset.wrapper;
        const value = event.target.checked !== undefined ? event.target.checked : event.detail?.value ?? event.target.value;
        console.log('==================== handlePageLayoutFieldsGroupChange ====================');
        console.log(JSON.stringify({
            field,
            type,
            value,
            rowIndex,
            colIndex,
            sectionIndex,
            wrapperIndex
        }));
        const section = this.instance.currentLayout.settings.sections[sectionIndex];
        const wrapper = this.instance.currentLayout.settingsWrappers[wrapperName][wrapperIndex].wrapper;
        switch (field) {
            case 'actions': {
                wrapper.actions[type] = value;
                if (!section.actions.length) {
                    section.actions.push({ ...wrapper.actions });
                } else {
                    section.actions[0][type] = value;
                }
                break;
            }
            case 'isFlowMode': {
                wrapper.isFlowMode = value;
                if (!value) {
                    wrapper.actions.redirectionValue = '';
                    section.actions = [];
                }
                break;
            }
            case 'header': {
                let updatedHeader = JSON.parse(JSON.stringify(section.header || {}));
                let updatedWrapperHeader = JSON.parse(JSON.stringify(wrapper.header || {}));
                updatedHeader[type] = value;
                updatedWrapperHeader[type] = value;
                if (type === 'isMandatory' && value) {
                    updatedHeader.isReadOnly = false;
                    updatedWrapperHeader.isReadOnly = false;
                }
                if (type === 'isReadOnly' && value) {
                    updatedHeader.isMandatory = false;
                    updatedWrapperHeader.isMandatory = false;
                }
                this.instance.currentLayout.settings.sections[sectionIndex].header = updatedHeader;
                this.instance.currentLayout.settingsWrappers[wrapperName][wrapperIndex].wrapper.header = updatedWrapperHeader;
                break;
            }
            case 'fields': {
                if (!section.fields[rowIndex] || !wrapper.fieldsWrapper[rowIndex]) {
                    console.error('Row missing:', rowIndex);
                    return;
                }
                if (!section.fields[rowIndex][colIndex] || !wrapper.fieldsWrapper[rowIndex].fields[colIndex]) {
                    console.error('Column missing:', colIndex);
                    return;
                }
                section.fields[rowIndex][colIndex][type] = value;
                wrapper.fieldsWrapper[rowIndex].fields[colIndex][type] = value;
                if (type === 'isMandatory' && value) {
                    section.fields[rowIndex][colIndex].isReadOnly = false;
                    wrapper.fieldsWrapper[rowIndex].fields[colIndex].isReadOnly = false;
                }
                if (type === 'isReadOnly' && value) {
                    section.fields[rowIndex][colIndex].isMandatory = false;
                    wrapper.fieldsWrapper[rowIndex].fields[colIndex].isMandatory = false;
                }
                break;
            }
            default:
                console.warn('Unhandled field:', field);
        }
        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>> wrapper:' + JSON.stringify(wrapper));
        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>> section:' + JSON.stringify(section));
        this.instance = {
            ...this.instance
        };
    }
    handleDeleteItem(event) {
        let styleVariant = event.currentTarget.dataset.stylevariant;
        const datasetPayload = {
            currentTarget: {
                dataset: { ...event.currentTarget.dataset }
            },
            target: {
                dataset: { ...event.target.dataset }
            },
            detail: {
                value: 'delete'
            }
        };
        try {
            switch (styleVariant) {
                case 'tabset':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteTabset,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleConfigTabBtn(datasetPayload)
                    });
                    break;
                case 'component':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteComponent,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleConfigComponentBtn(datasetPayload)
                    });
                    break;
                case 'Actions':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteAction,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleConfigActionsBtn(datasetPayload)
                    });
                    break;
                case 'section':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteSection,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleSectionAction(datasetPayload)
                    });
                    break;
                case 'fieldsGroup':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteRow,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleRowsChange(datasetPayload)
                    });
                    break;
                case 'aggregates':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteRow,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleRelatedInformationBtn(datasetPayload)
                    });
                    break;
                case 'sectionGroupTab':
                    this.openModal({
                        title: this.labels.LBL_Confirm,
                        message: this.labels.MSG_PageLayoutSettings_DeleteRow,
                        confirmLabel: this.labels.LBL_Proceed,
                        onConfirmAction: () => this.handleSectionGroupBtn(datasetPayload)
                    });
                    break;
                default:
                    break;
            }
        } catch (error) {
            console.log('error in delete item:' + error.message);
        }
    }
    handleRowsChange(event) {
        const wrapper = event.currentTarget.dataset.wrapper;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const action = event.currentTarget.dataset.action;
        let fields = [...this.instance.currentLayout.settings.sections[sectionIndex].fields];
        let wrapperRows = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.fieldsWrapper
        ];
        try {
            switch (action) {
                case 'add':
                    if (wrapperRows.length >= 6) return;
                    wrapperRows.push({
                        rowKey: wrapperRows.length,
                        rowNumber: wrapperRows.length + 1,
                        fields: [{ type: '', fieldName: '', isMandatory: false, isReadOnly: false, fieldKey: 0, standard: false, ...(this._pageType === 'record' ? { stickyBare: false } : {}) }],
                        fieldsNumber: 1,
                        expanded: false
                    });
                    fields.push([{ type: '', fieldName: '', isMandatory: false, isReadOnly: false, standard: false, ...(this._pageType === 'record' ? { stickyBare: false } : {}) }]);
                    break;
                case 'delete':
                    const index = wrapperRows.findIndex(row => String(row.rowKey) === String(rowIndex));
                    if (index === -1) { return; }
                    wrapperRows.splice(index, 1);
                    fields.splice(index, 1);
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
            this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.fieldsWrapper = wrapperRows;
            this.instance.currentLayout.settings.sections[sectionIndex].fields = fields;
        } catch (error) {
            console.log('error in handle rows change:' + error.message);
        }
    }
    handleFieldCountChange(event) {
        const wrapper = event.currentTarget.dataset.wrapper;
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const count = parseInt(event.detail.value, 10);
        let wrapperRows = [...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.fieldsWrapper];
        let fields = [...this.instance.currentLayout.settings.sections[sectionIndex].fields];
        let rowFields = [...wrapperRows[rowIndex].fields];
        let sectionFields = [...fields[rowIndex]];
        console.log(JSON.stringify(rowIndex));
        console.log(JSON.stringify(wrapperRows));
        console.log(JSON.stringify(wrapperRows[rowIndex]));
        if (count > rowFields.length) {
            for (let i = rowFields.length; i < count; i++) {
                rowFields.push({
                    fieldKey: i,
                    fieldName: '',
                    type: '',
                    isMandatory: false,
                    isReadOnly: false,
                    standard: false,
                    ...(this._pageType === 'record' ? { stickyBare: false } : {})
                });

                sectionFields.push({
                    fieldName: '',
                    isMandatory: false,
                    isReadOnly: false,
                    type: '',
                    standard: false,
                    ...(this._pageType === 'record' ? { stickyBare: false } : {})
                });
            }
        }
        else if (count < rowFields.length) {
            rowFields = rowFields.slice(0, count);
            sectionFields = sectionFields.slice(0, count);
        }
        wrapperRows[rowIndex].fields = rowFields;
        wrapperRows[rowIndex].fieldsNumber = count;
        fields[rowIndex] = sectionFields;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.fieldsWrapper = wrapperRows;
        this.instance.currentLayout.settings.sections[sectionIndex].fields = fields;
    }
    //tabs configuration
    handleChangeRedirectiontabsSettings(event) {
        const field = event.currentTarget.dataset.field;
        const wrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const value = event.detail.value ?? event.target.value;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].tabset];
        let tabsWrapper = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper
        ];
        tabs[rowIndex].component.type = value;
        tabsWrapper[rowIndex].component.type = value;
        tabsWrapper[rowIndex].component.isGridFile = (value === 'grid');
        console.log('>>>>>>>>>>>>>>>>>>. tabs:' + JSON.stringify(tabs));
        console.log('>>>>>>>>>>>>>>>>>>. tabsWrapper:' + JSON.stringify(tabsWrapper));
        this.instance.currentLayout.settings.sections[sectionIndex].tabset = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper = tabsWrapper;
        console.log('-------------------- tabs:' + JSON.stringify(this.instance.currentLayout.settings.sections[sectionIndex]));
        console.log('-------------------- tabsWrapper:' + JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex]));
    }
    handleCollectionRowChange(event) {
        const field = event.currentTarget.dataset.field;
        const wrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const value = event.detail.value ?? event.target.value;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].tabset];
        let tabsWrapper = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper
        ];
        switch (type) {
            case 'label':
                tabs[rowIndex].label = value;
                tabsWrapper[rowIndex].label = value;
                break;
            default:
                tabs[rowIndex].component[type] = value;
                tabsWrapper[rowIndex].component[type] = value;
                break;
        }
        console.log('>>>>>>>>>>>>>>>>>>. tabs:' + JSON.stringify(tabs));
        console.log('>>>>>>>>>>>>>>>>>>. tabsWrapper:' + JSON.stringify(tabsWrapper));
        this.instance.currentLayout.settings.sections[sectionIndex].tabset = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper = tabsWrapper;
        console.log('-------------------- tabs:' + JSON.stringify(this.instance.currentLayout.settings.sections[sectionIndex]));
        console.log('-------------------- tabsWrapper:' + JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex]));
    }
    handleConfigTabBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = parseInt(event.currentTarget.dataset.rowindex, 10);
        let wrapper = event.currentTarget.dataset.wrapper;
        let sectionindex = event.currentTarget.dataset.sectionindex;
        let wrapperindex = event.currentTarget.dataset.wrapperindex;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionindex].tabset];
        let tabsWrapper = this.instance.currentLayout.settingsWrappers[wrapper][wrapperindex].wrapper;
        console.log('>>>>>>>>>>>>>>>>>>. tabs:' + JSON.stringify(tabs));
        console.log('>>>>>>>>>>>>>>>>>>. tabsWrapper:' + JSON.stringify(tabsWrapper));
        let rowsCount = tabs.length;
        switch (action) {
            case 'delete':
                tabs.splice(index, 1);
                tabsWrapper.splice(index, 1);
                break;
            case 'add':
                if (rowsCount >= 8) {
                    this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Max_Tab_Limit_Reached, 'warning', '');
                    return;
                }
                tabs.push({ label: '', component: { label: '', style: '', type: '', name: '' } });
                tabsWrapper.push({ label: '', component: { label: '', style: '', type: '', name: '', isGridFile: false }, key: rowsCount });
                break;
            default:
        }
        this.instance.currentLayout.settings.sections[sectionindex].tabset = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperindex].wrapper = tabsWrapper;
    }
    //SectionGroup handler
    handleSectionGroupBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = parseInt(event.currentTarget.dataset.rowindex, 10);
        let sectionGroups = [...this.instance.currentLayout.settings.sectionGroupTab];
        console.log('>>>>>>>>>>>>>>>>>> sectionGroups:' + JSON.stringify(sectionGroups));
        let rowsCount = sectionGroups.length;
        switch (action) {
            case 'delete':
                sectionGroups.splice(index, 1);
                break;
            case 'add':
                if (rowsCount >= 5) {
                    this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Max_Button_Limit_Reached, 'warning', '');
                    return;
                }
                sectionGroups.push({ label: '', name: '', key: sectionGroups.length });
                break;
            default:
        }
        this.instance.currentLayout.settings.sectionGroupTab = sectionGroups;
    }
    //component handler
    handleConfigComponentBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = parseInt(event.currentTarget.dataset.rowindex, 10);
        let wrapper = event.currentTarget.dataset.wrapper;
        let sectionindex = event.currentTarget.dataset.sectionindex;
        let wrapperindex = event.currentTarget.dataset.wrapperindex;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionindex].components];
        let tabsWrapper = this.instance.currentLayout.settingsWrappers[wrapper][wrapperindex].wrapper;
        console.log('>>>>>>>>>>>>>>>>>>. tabs:' + JSON.stringify(tabs));
        console.log('>>>>>>>>>>>>>>>>>>. tabsWrapper:' + JSON.stringify(tabsWrapper));
        let rowsCount = tabs.length;
        switch (action) {
            case 'delete':
                tabs.splice(index, 1);
                tabsWrapper.splice(index, 1);
                break;
            case 'add':
                if (rowsCount >= 8) {
                    this.showNotification(this.labels.MSG_Warning, this.labels.MSG_Max_Button_Limit_Reached, 'warning', '');
                    return;
                }
                tabs.push({ label: '', style: '', type: '', name: '', params: {} });
                tabsWrapper.push({ label: '', style: '', type: '', name: '', isGridFile: false, params: {}, key: tabsWrapper.length });
                break;
            default:
        }
        this.instance.currentLayout.settings.sections[sectionindex].components = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperindex].wrapper = tabsWrapper;
    }
    handleChangeRedirectionComponentSettings(event) {
        const field = event.currentTarget.dataset.field;
        const wrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const value = event.detail.value ?? event.target.value;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].components];
        let tabsWrapper = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper
        ];
        console.log('wrapper:' + JSON.stringify(wrapper));
        console.log('rowIndex:' + JSON.stringify(rowIndex));
        console.log('sectionIndex:' + JSON.stringify(sectionIndex));
        console.log('wrapperIndex:' + JSON.stringify(wrapperIndex));
        console.log('value:' + JSON.stringify(value));
        tabs[rowIndex].type = value;
        tabsWrapper[rowIndex].type = value;
        tabsWrapper[rowIndex].isGridFile = (value === 'grid');
        console.log('>>>>>>>>>>>>>>>>>>. tabs:' + JSON.stringify(tabs));
        console.log('>>>>>>>>>>>>>>>>>>. tabsWrapper:' + JSON.stringify(tabsWrapper));
        this.instance.currentLayout.settings.sections[sectionIndex].components = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper = tabsWrapper;
        console.log('-------------------- tabs:' + JSON.stringify(this.instance.currentLayout.settings.sections[sectionIndex]));
        console.log('-------------------- tabsWrapper:' + JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex]));
    }
    handleComponentsChange(event) {
        const field = event.currentTarget.dataset.field;
        const wrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const value = event.detail.value ?? event.target.value;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].components];
        let tabsWrapper = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper
        ];
        tabs[rowIndex][type] = value;
        tabsWrapper[rowIndex][type] = value;
        console.log('>>>>>>>>>>>>>>>>>>. tabs:' + JSON.stringify(tabs));
        console.log('>>>>>>>>>>>>>>>>>>. tabsWrapper:' + JSON.stringify(tabsWrapper));
        this.instance.currentLayout.settings.sections[sectionIndex].components = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper = tabsWrapper;
        console.log('-------------------- tabs:' + JSON.stringify(this.instance.currentLayout.settings.sections[sectionIndex]));
        console.log('-------------------- tabsWrapper:' + JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex]));
    }
    //agregates handlers
    handleRelatedInformationBtn(event) {
        const action = event.currentTarget.dataset.action;
        const wrapper = event.currentTarget.dataset.wrapper;
        const wrapperIndex = Number(event.currentTarget.dataset.wrapperindex);
        const sectionIndex = Number(event.currentTarget.dataset.sectionindex);
        const rowIndex = Number(event.currentTarget.dataset.rowindex);
        const section = this.instance.currentLayout.settings.sections[sectionIndex];
        const sectionWrapper = this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex];
        const aggregates = [...(section.aggregates || [])];
        const aggregatesWrapper = [...(sectionWrapper.wrapper.aggregates || [])];
        switch (action) {
            case 'delete':
                aggregates.splice(rowIndex, 1);
                aggregatesWrapper.splice(rowIndex, 1);
                break;
            case 'add':
                if (aggregates.length >= 5) {
                    this.showNotification(this.Label.MSG_Warning, this.Label.MSG_Max_Button_Limit_Reached, 'warning', '');
                    return;
                }
                aggregates.push({
                    label: '',
                    objectApiName: '',
                    parentRelationshipApiName: '',
                    filters: []
                })
                aggregatesWrapper.push({
                    key: aggregatesWrapper.length,
                    label: '',
                    objectApiName: '',
                    parentRelationshipApiName: '',
                    filters: []
                });
                break;
        }
        section.aggregates = aggregates;
        sectionWrapper.wrapper.aggregates = aggregatesWrapper;
    }
    handleRelatedInformationsRelationshipChange(event) {
        const value = event.detail.value;
        const type = event.currentTarget.dataset.type;
        const wrapper = event.currentTarget.dataset.wrapper;
        const wrapperIndex = Number(event.currentTarget.dataset.wrapperindex);
        const sectionIndex = Number(event.currentTarget.dataset.sectionindex);
        const rowIndex = Number(event.currentTarget.dataset.rowindex);
        const currentLayout = JSON.parse(JSON.stringify(this.instance.currentLayout));
        const section = currentLayout.settings.sections[sectionIndex];
        const sectionWrapper = currentLayout.settingsWrappers[wrapper]?.[wrapperIndex];
        if (!section || !sectionWrapper) {
            console.error('Section or Wrapper index not found');
            return;
        }
        if (!section.aggregates) section.aggregates = [];
        if (!sectionWrapper.wrapper.aggregates) sectionWrapper.wrapper.aggregates = [];
        const aggregate = section.aggregates[rowIndex] || {};
        const aggregateWrapper = sectionWrapper.wrapper.aggregates[rowIndex] || {};
        switch (type) {
            case 'label':
                aggregate.label = value;
                aggregateWrapper.label = value;
                break;
            case 'relationship':
                aggregate.parentRelationshipApiName = value;
                aggregateWrapper.parentRelationshipApiName = value;

                const rel = (this.instance.objectChildRelationship || []).find(
                    r => r.relationshipApiName && r.relationshipApiName.toLowerCase() === value.toLowerCase()
                );
                if (rel) {
                    aggregate.objectApiName = rel.childObjectApiName;
                    aggregateWrapper.objectApiName = rel.childObjectApiName;
                } else {
                    aggregate.objectApiName = '';
                    aggregateWrapper.objectApiName = '';
                }
                aggregate.filters = [];
                aggregateWrapper.filters = [];
                break;
        }
        section.aggregates[rowIndex] = aggregate;
        sectionWrapper.wrapper.aggregates[rowIndex] = aggregateWrapper;
        this.instance.currentLayout = currentLayout;
    }

    openRelatedInformationsPopup(event) {
        const rowIndex = Number(event.currentTarget.dataset.rowindex);
        const sectionIndex = Number(event.currentTarget.dataset.sectionindex);
        const wrapper = event.currentTarget.dataset.wrapper;
        const wrapperIndex = Number(event.currentTarget.dataset.wrapperindex);
        const section = this.instance?.currentLayout?.settings?.sections?.[sectionIndex];
        const aggregate = section?.aggregates?.[rowIndex] || {};
        const formattedFilters = (aggregate.filters || []).map((item, idx) => {
            const operator = item.operator || '';
            return {
                rowKey: `flt-${idx}`,
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
                operationsOptions: typeof FIELD_TYPE_CONFIG !== 'undefined' ? FIELD_TYPE_CONFIG.getInitialValueByType('') : [],
                disableValue: typeof OPERATIONS_WITHOUT_VALUE !== 'undefined' && OPERATIONS_WITHOUT_VALUE.includes(operator)
            };
        });
        this.popups.relatedInformations = {
            ...this.popups.relatedInformations,
            isOpen: true,
            objectApiName: aggregate.objectApiName || '',
            relatedInformationRowIndex: rowIndex,
            sectionIndex: sectionIndex,
            wrapper: wrapper,
            wrapperIndex: wrapperIndex,
            filters: formattedFilters
        };
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
    closeRelatedInformationsPopup() {
        this.popups.relatedInformations.isOpen = false;
        this.popups.relatedInformations.filters = [];
        this.popups.relatedInformations.groupByFields = [];
        this.popups.relatedInformations.objectApiName = [];
        this.popups.relatedInformations.relatedInformationRowIndex = null;
    }
    confirmRelatedInformationsPopup() {
        try {
            const { sectionIndex, wrapper, wrapperIndex, relatedInformationRowIndex } = this.popups.relatedInformations;
            const section = this.instance.currentLayout.settings.sections[sectionIndex];
            const sectionWrapper = this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex];
            const filters = this.popups.relatedInformations.filters
                .filter(item => {
                    if (!item.fieldName || !item.operator) {
                        return false;
                    }
                    if (OPERATIONS_WITHOUT_VALUE.includes(item.operator)) {
                        return true;
                    }
                    return item.value !== '';
                })
                .map(item => ({
                    fieldName: item.fieldName,
                    operator: item.operator,
                    value: item.value,
                    fieldType: item.fieldType
                }));
            section.aggregates[relatedInformationRowIndex].filters = filters;
            sectionWrapper.wrapper.aggregates[relatedInformationRowIndex].filters = [...filters];
            this.closeRelatedInformationsPopup();
        } catch (error) {
            console.error('Error in confirmRelatedInformationsPopup:', error);
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
        console.log('********************************** this.popups.relatedInformations:' + JSON.stringify(this.popups.relatedInformations));
    }
    //actions handlers
    handleToggleActions(event) {
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const wrapper = event.currentTarget.dataset.wrapper;
        let wrapperObj = this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex];
        const current = wrapperObj.showActions || false;
        wrapperObj.showActions = !current;
    }
    handleConfigActionsBtn(event) {
        let action = event.currentTarget.dataset.action;
        let index = parseInt(event.currentTarget.dataset.rowindex, 10);
        let wrapper = event.currentTarget.dataset.wrapper;
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].actions];
        let tabsWrapper = this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.actions;
        let rowsCount = tabs.length;
        switch (action) {
            case 'delete':
                tabs.splice(index, 1);
                tabsWrapper.splice(index, 1);
                tabs = tabs.map((t, i) => ({ ...t, order: i }));
                tabsWrapper = tabsWrapper.map((t, i) => ({ ...t, order: i, key: i }));
                break;
            case 'add':
                tabs.push({ label: '', icon: '', actionType: '', redirectionType: 'flow', redirectionValue: '', order: rowsCount, color: '' });
                tabsWrapper.push({ label: '', icon: '', actionType: '', redirectionType: 'flow', redirectionValue: '', order: rowsCount, key: rowsCount, isFlow: true, color: '' });
                break;
            default:
        }
        this.instance.currentLayout.settings.sections[sectionIndex].actions = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.actions = tabsWrapper;
        console.log('-------------------- tabs:' + JSON.stringify(this.instance.currentLayout.settings.sections[sectionIndex]));
        console.log('-------------------- tabsWrapper:' + JSON.stringify(this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper));
    }
    handleChangeRedirectionActionsSettings(event) {
        const field = event.currentTarget.dataset.field;
        const wrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const value = event.detail.value ?? event.target.value;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].actions];
        let tabsWrapper = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.actions
        ];
        console.log('value', event.detail.value);
        console.log('before', JSON.stringify(this.instance.currentLayout.settings.sections));
        console.log('before tabs', JSON.stringify(tabs));
        console.log('before tabsWrapper', JSON.stringify(tabsWrapper));
        tabs[rowIndex].redirectionType = value;
        tabs[rowIndex].redirectionType = value;
        tabsWrapper[rowIndex].redirectionType = value;
        tabsWrapper[rowIndex].isFlow = (value === 'flow');
        this.instance.currentLayout.settings.sections[sectionIndex].actions = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.actions = tabsWrapper;
        console.log('after', JSON.stringify(this.instance.currentLayout.settings.sections));
        console.log('after tabs', JSON.stringify(tabs));
        console.log('after tabsWrapper', JSON.stringify(tabsWrapper));
    }
    handleActionChange(event) {
        const field = event.currentTarget.dataset.field;
        const wrapper = event.currentTarget.dataset.wrapper;
        const type = event.currentTarget.dataset.type;
        const rowIndex = parseInt(event.currentTarget.dataset.rowindex, 10);
        const sectionIndex = parseInt(event.currentTarget.dataset.sectionindex, 10);
        const wrapperIndex = parseInt(event.currentTarget.dataset.wrapperindex, 10);
        const value = event.detail.value ?? event.target.value;
        let tabs = [...this.instance.currentLayout.settings.sections[sectionIndex].actions];
        let tabsWrapper = [
            ...this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.actions
        ];
        tabs[rowIndex][type] = value;
        tabsWrapper[rowIndex][type] = value;
        this.instance.currentLayout.settings.sections[sectionIndex].actions = tabs;
        this.instance.currentLayout.settingsWrappers[wrapper][wrapperIndex].wrapper.actions = tabsWrapper;
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
                console.log('------------------------- objectChildRelationshipOptions:' + JSON.stringify(this.instance.objectChildRelationshipOptions));
                console.log('------------------------- this.instance.objectChildRelationship:' + JSON.stringify(this.instance.objectChildRelationship));
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
            console.log('Sections length:', JSON.stringify(this.instance.currentLayout.settings.sections).length);

            if (this.isNewTemplate) {
                const payload = {
                    developerName: this.templateName,
                    settings: this.instance.currentLayout.settings,
                    isNew: this.isNewTemplate
                };
                this.dispatchEvent(new CustomEvent('save', { detail: payload }));
            }
            saveSettings({ pageLayoutSettingsJSON: JSON.stringify(this.instance.currentLayout.settings) })
                .then(result => {
                    console.log('handle save result:', JSON.stringify(result));
                    if (!result || (typeof result === 'string' && result.toLowerCase().includes('error'))) {
                        const message = typeof result === 'string' ? result : this.labels.MSG_Error;
                        this.showNotification(this.labels.LBL_Error, message, 'error');
                        this.Loading = false;
                        return;
                    }
                    this.checkDeployementStatus(result);
                }).catch(error => {
                    console.error('Save error:', JSON.stringify(error));
                    console.error('Full error:', error);
                    this.showNotification(this.labels.LBL_Error, error.body?.message || error.message || JSON.stringify(error), 'error');
                    this.Loading = false;
                });
        } catch (error) {
            console.error('Save exception:', error);
            this.Loading = false;
            this.showNotification(this.labels.LBL_Error, error.message || JSON.stringify(error), 'error');
        }
    }
    resetTemplate() {
        this.templateName = null;
        this.isNewTemplate = true;
        this.showTemplate = false;
        this.instance = {
            ...this.instance,
            showObjectDropdown: false,
            fieldNameOptions: [],
            currentLayout: {
                settings: {
                    objectApiName: '',
                    developerName: '',
                    type: '',
                    label: '',
                    description: '',
                    isActive: true,
                    sectionGroupTab: [],
                    sections: []
                },
                settingsWrappers: {
                    sidebarSectionWrapper: [],
                    mainSectionWrapper: [],
                    rightSectionWrapper: []
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
        // this.instance.LayoutPages = this.instance.LayoutPages.map(layout => ({
        //     ...layout,
        //     selected: false,
        //     listItemClass: 'slds-split-view__list-item'
        // }));
        // this.layouts = this.instance.LayoutPages;
    }
    //generic modal handling
    openModal({ title, message, confirmLabel, onConfirmAction, onCloseAction }) {
        this.modalConfig = {
            isOpen: true,
            title,
            message,
            confirmLabel,
            onConfirmAction,
            onCloseAction
        };
    }
    closeModal() {
        if (this.modalConfig.onCloseAction) {
            this.modalConfig.onCloseAction();
        }
        this.modalConfig = {
            isOpen: false,
            title: '',
            message: '',
            confirmLabel: '',
            onConfirmAction: null,
            onCloseAction: null,
            isOpen: false
        };
    }
    handleConfirm() {
        if (this.modalConfig.onConfirmAction) {
            this.modalConfig.onConfirmAction();
        }
        this.closeModal();
    }
    /*
        getters
    */
    get statusIconValue() {
        return this._toRadioString(this.instance.currentLayout.settings.statusIcon?.isStaticRessource);
    }
    get templateNameDisabled() {
        return !this.isNewTemplate;
    }
    get sectionsGroupOptions() {
        return this.instance.currentLayout.settings.sectionGroupTab.map(section => ({
            label: section.label,
            value: section.Name
        }));
    }
    get wrapperTabs() {
        return [
            {
                label: this.labels.LBL_WorkflowPage_leftSection,
                wrapper: 'sidebarSectionWrapper',
                region: 'sidebar',
                sections: this.instance.currentLayout.settingsWrappers.sidebarSectionWrapper
            },
            {
                label: this.labels.LBL_WorkflowPage_mainSection,
                wrapper: 'mainSectionWrapper',
                region: 'main',
                sections: this.instance.currentLayout.settingsWrappers.mainSectionWrapper
            },
            {
                label: this.labels.LBL_WorkflowPage_rightSection,
                wrapper: 'rightSectionWrapper',
                region: 'right',
                sections: this.instance.currentLayout.settingsWrappers.rightSectionWrapper
            }
        ];
    }
    _toRadioString(value) {
        return value === true ? 'true' : 'false';
    }
    checkDeployementStatus(idDeployment) {
        let counter = 0;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            console.log('Raw deployment response:', fresult);
            let parsed;
            try {
                parsed = JSON.parse(fresult);
                console.log('Parsed deployment response:', JSON.stringify(parsed, null, 2));
            } catch (parseError) {
                console.error('Deployment status parse error:', parseError, fresult);
                this.showNotification(this.labels.LBL_Error, this.labels.MSG_Error, 'error');
                this.Loading = false;
                return;
            }
            const deployResult = parsed?.deployResult;
            const fdone = deployResult?.done;
            const success = deployResult?.success;
            const status = deployResult?.status;
            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        clearInterval(interval);
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Error, 'error');
                        this.Loading = false;
                        return;
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let parsedResult;
                        try {
                            parsedResult = JSON.parse(result);
                        } catch (parseError) {
                            console.error('Deployment status parse error:', parseError, result);
                            clearInterval(interval);
                            this.showNotification(this.labels.LBL_Error, this.labels.MSG_Error, 'error');
                            this.Loading = false;
                            return;
                        }
                        const done = parsedResult?.deployResult?.done;
                        const successRetry = parsedResult?.deployResult?.success;
                        const retryStatus = parsedResult?.deployResult?.status;
                        if (done) {
                            clearInterval(interval);
                            if (successRetry) {
                                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Success, 'success');
                                const devName = this.instance?.currentLayout?.settings?.developerName || this.templateName;
                                if (devName) {
                                    this.loadLayoutTemplate(devName);
                                }
                            } else {
                                this.showNotification(this.labels.LBL_Error, this.labels.MSG_Deploy_Ended_With_Status + ' ' + retryStatus, 'error');
                            }
                            this.Loading = false;
                        }
                    }).catch(error => {
                        console.error('Deployment status follow-up error:', error);
                        clearInterval(interval);
                        this.showNotification(this.labels.LBL_Error, error.body?.message || error.message || JSON.stringify(error), 'error');
                        this.Loading = false;
                    });
                    counter++;
                }, 5000);
            } else {
                if (success) {
                    this.showNotification(this.labels.LBL_Success, this.labels.MSG_Success, 'success');
                    const devName = this.instance?.currentLayout?.settings?.developerName || this.templateName || (this.instance?.currentLayout?.settings?.label ? this.instance.currentLayout.settings.label.replace(/\s+/g, '_') : null);
                    if (devName) {
                        this.loadLayoutTemplate(devName);
                    }
                } else {
                    this.showNotification(this.labels.LBL_Error, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'error');
                }
                this.Loading = false;
            }
        }).catch(error => {
            console.error('Deployment status error:', error);
            this.showNotification(this.labels.LBL_Error, error.body?.message || error.message || JSON.stringify(error), 'error');
            this.Loading = false;
        });
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