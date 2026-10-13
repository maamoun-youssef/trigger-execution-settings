/**
* @author ULiT
* @date 28-04-2025
* @description PageSettings
*******************************************************************************************************************************************
*/
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//APEX
import loadAllData from '@salesforce/apex/PageSettingsController.loadAllData';
import uploadImage from '@salesforce/apex/PageSettingsController.uploadImage';
import save from '@salesforce/apex/PageSettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/PageSettingsController.checkDeploymentStatus';

/**
* Custom Labels
*/
import LBL_Save from "@salesforce/label/c.LBL_Save";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Deployment_In_Progress from "@salesforce/label/c.LBL_Deployment_In_Progress";
import LBL_PageSettings_Configuration from "@salesforce/label/c.LBL_PageSettings_Configuration";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import Cancel from "@salesforce/label/c.Cancel";
import LBL_PageSettings_Title from "@salesforce/label/c.LBL_PageSettings_Title";
import LBL_PageSettings_Sub_Title from "@salesforce/label/c.LBL_PageSettings_Sub_Title";
import LBL_PageSettings_Icon from "@salesforce/label/c.LBL_PageSettings_Icon";
import LBL_PageSettings_Order from "@salesforce/label/c.LBL_PageSettings_Order";
import LBL_PageSettings_Color from "@salesforce/label/c.LBL_PageSettings_Color";
import LBL_PageSettings_Is_Active from "@salesforce/label/c.LBL_PageSettings_Is_Active";
import LBL_PageSettings_Label from "@salesforce/label/c.LBL_PageSettings_Label";
import LBL_PageSettings_Redirection_Type from "@salesforce/label/c.LBL_PageSettings_Redirection_Type";
import LBL_PageSettings_Redirection from "@salesforce/label/c.LBL_PageSettings_Redirection";
import LBL_PageSettings_Is_Internal_Display from "@salesforce/label/c.LBL_PageSettings_Is_Internal_Display";
import LBL_PageSettings_Is_Portal_Display from "@salesforce/label/c.LBL_PageSettings_Is_Portal_Display";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Delete_Section from '@salesforce/label/c.LBL_Delete_Section';
import LBL_Delete_Theme from '@salesforce/label/c.LBL_Delete_Theme';
import LBL_Confirm_Section from '@salesforce/label/c.LBL_Confirm_Section';
import LBL_Confirm_Theme from '@salesforce/label/c.LBL_Confirm_Theme';
import LBL_AddTheme from "@salesforce/label/c.LBL_AddTheme";
import LBL_PageSettings_Add_New_Settings from "@salesforce/label/c.LBL_PageSettings_Add_New_Settings";
import LBL_PageSettings_Select_Settings from "@salesforce/label/c.LBL_PageSettings_Select_Settings";
import LBL_PageSettings_Themes from "@salesforce/label/c.LBL_PageSettings_Themes";
import LBL_PageSettings_Main_Info from "@salesforce/label/c.LBL_PageSettings_Main_Info";
import LBL_PageSettings_Sections from "@salesforce/label/c.LBL_PageSettings_Sections";
import LBL_PageSettings_Flow_Section from "@salesforce/label/c.LBL_PageSettings_Flow_Section";
import LBL_PageSettings_Flow_ApiName from "@salesforce/label/c.LBL_PageSettings_Flow_ApiName";
import LBL_PageSettings_Flow_Label from "@salesforce/label/c.LBL_PageSettings_Flow_Label";
import LBL_PageSettings_Flow_Button_Label from "@salesforce/label/c.LBL_PageSettings_Flow_Button_Label";
import LBL_PageSettings_Flow_Button_Icon from "@salesforce/label/c.LBL_PageSettings_Flow_Button_Icon";
import LBL_PageSettings_Select_Page_Settings from "@salesforce/label/c.LBL_PageSettings_Select_Page_Settings";
import LBL_PageSettings_Header_Background from "@salesforce/label/c.LBL_PageSettings_Header_Background";
import LBL_PageSettings_Add_Section from "@salesforce/label/c.LBL_PageSettings_Add_Section";
import LBL_FileDirectory_PageDeleteMessageTitle from "@salesforce/label/c.LBL_FileDirectory_PageDeleteMessageTitle";
import LBL_FileDirectory_PageDeleteMessageDescription from "@salesforce/label/c.LBL_FileDirectory_PageDeleteMessageDescription";
import ConnectSectionAvatar from "@salesforce/resourceUrl/ConnectSectionAvatar";
import ConnectThemeAvatar from "@salesforce/resourceUrl/ConnectThemeAvatar";
import ConnectHeaderAvatar from "@salesforce/resourceUrl/ConnectHeaderAvatar";
import ConnectLogo from "@salesforce/resourceUrl/ConnectLogo";


const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';


export default class PageSettings extends LightningElement {
    @track isLoading = false;
    @track addNewRowPageSettings = false;
    @track newPageSettings;
    @track pageSettingsList = [];
    @track initPageSettingsList = [];
    @track selectedPageSettings;
    @track selectedSection;
    @track selectedSectionIndex;
    @track displayedThemes = [];
    @track gridtemplates = [];
    @track pages = [];
    @track flows = [];
    @track mainPanelHeight;

    @track labels = {
        LBL_Deployment_In_Progress,
        LBL_PageSettings_Configuration,
        LBL_Success,
        MSG_Successfully_Saved,
        LBL_Save,
        LBL_No_Item_To_Display,
        MSG_Deploy_Ended_With_Status,
        MSG_Save_Complete,
        MSG_Deploy_Last_Status,
        LBL_AddTheme,
        Cancel,
        LBL_PageSettings_Title,
        LBL_PageSettings_Sub_Title,
        LBL_PageSettings_Icon,
        LBL_PageSettings_Order,
        LBL_PageSettings_Color,
        LBL_PageSettings_Is_Active,
        LBL_PageSettings_Label,
        LBL_PageSettings_Redirection_Type,
        LBL_PageSettings_Redirection,
        LBL_PageSettings_Is_Internal_Display,
        LBL_PageSettings_Is_Portal_Display,
        LBL_PageSettings_Main_Info,
        LBL_Delete,
        LBL_Cancel,
        LBL_Delete_Section,
        LBL_Delete_Theme,
        LBL_Confirm_Section,
        LBL_Confirm_Theme,
        LBL_PageSettings_Add_New_Settings,
        LBL_PageSettings_Select_Settings,
        LBL_PageSettings_Themes,
        LBL_PageSettings_Sections,
        LBL_PageSettings_Flow_Section,
        LBL_PageSettings_Flow_ApiName,
        LBL_PageSettings_Flow_Label,
        LBL_PageSettings_Flow_Button_Label,
        LBL_PageSettings_Flow_Button_Icon,
        LBL_PageSettings_Select_Page_Settings,
        LBL_PageSettings_Header_Background,
        LBL_PageSettings_Add_Section,
        LBL_FileDirectory_PageDeleteMessageTitle,
        LBL_FileDirectory_PageDeleteMessageDescription,
        pageSettings: {
            Name: '',
            isActive: '',
            Description: '',
            isDeleted: '',
            HeaderBackground: '',
            Icon: '',
            Sections: '',
            Themes: '',
            FlowSettings: '',
        }
    }
    @track popups = {
        themeParams: {
            title: '',
            theme: {},
            isOpen: false,
            params: [],
            gridSettingsLayouts: [],
            handleThemeParamChange: (event) => {
                let index = event.currentTarget.dataset.index;
                let param = this.popups.themeParams.params[index];
                param.value = !param.isBoolean ? event.detail.value : event.detail.checked;
            },
            close: (event) => {
                this.popups.themeParams.params = [];
                this.popups.themeParams.theme = {};
                this.popups.themeParams.isOpen = false;
            },
            confirm: (event) => {
                const params = this.popups.themeParams.params;
                const theme = this.popups.themeParams.theme;
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
                        this.labels.LBL_Error || 'Error',
                        'Please fill in all required  fields before saving.',
                        'error',
                        'sticky'
                    );
                    return;
                }

                if (!theme.params) {
                    theme.params = {};
                }
                params.forEach(param => {
                    theme.params[param.name] = param.value === '' ? '' : param.value;
                });
                this.popups.themeParams.params = [];
                this.popups.themeParams.theme = {};
                this.popups.themeParams.isOpen = false;
            },
            open: (event) => {
                let index = event.currentTarget.dataset.index;
                let theme = this.selectedSection.themes[index];
                let paramsSettings = this.lwcParamsSettingsList?.find(it => it.name == (theme.isGrid ? 'gridSettingsPlugin' : theme.redirection));
                let params = paramsSettings?.paramList;
                if (params) {
                    if (theme.isGrid) {
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
                    if (theme?.params) {
                        Object.keys(theme?.params).forEach(name => {
                            let param = params.find(it => it.name == name);
                            if (param) {
                                param.value = param.isBoolean ? theme?.params[name] == 'true' : (param.isInteger && +theme?.params[name] ? +theme?.params[name] : theme?.params[name]);
                            }
                        })
                    }
                    this.popups.themeParams.params = params;
                    this.popups.themeParams.theme = theme;
                    this.popups.themeParams.isOpen = true;
                } else {
                    this.showNotification(this.labels.LBL_Error, 'no available Params', 'error');
                }
            },
        }
    }
    @track deletePopup = {
        visibility: false,
        title: '',
        body: '',
        mode: '',
    };
    deletePopupMethods = {
        open() {
            this.deletePopup.visibility = true;
        },
        close() {
            this.deletePopup.visibility = false;
        }

    }
    PAGE_SETTINGS_API = {
        PageSettings__mdt: 'PageSettings__mdt',
        Name__c: 'Name__c',
        isActive__c: 'isActive__c',
        Description__c: 'Description__c',
        isDeleted__c: 'isDeleted__c',
        HeaderBackground__c: 'HeaderBackground__c	',
        Icon__c: 'Icon__c',
        Sections__c: 'Sections__c',
        Themes__c: 'Themes__c',
        FlowSettings__c: 'FlowSettings__c',
    }

    staticUrl = {
        ConnectSectionAvatar: ConnectSectionAvatar,
        ConnectThemeAvatar: ConnectThemeAvatar,
        ConnectHeaderAvatar: ConnectHeaderAvatar,
        ConnectLogo: ConnectLogo
    }

    // hasRenderedOnce = false;
    renderedCallback() {
        this.changeHeight();
        // if (this.hasRenderedOnce || !this.pageSettingsList || this.pageSettingsList.length === 0) return;
        // this.selectedPageSettings = JSON.parse(JSON.stringify(this.pageSettingsList[0]));
        // const allItems = this.template.querySelectorAll('.slds-split-view__list-item');
        // if (allItems.length > 0) {
        //     allItems[0].classList.add('slds-is-active');
        // }
        // this.hasRenderedOnce = true;
        this.ensureSelectedPageIsActive();
    }

    ensureSelectedPageIsActive() {
        if (this.selectedPageSettings) {
            const selectedItem = this.template.querySelector(`[data-id="${this.selectedPageSettings.name}"]`);
            if (selectedItem && !selectedItem.classList.contains('slds-is-active')) {
                const allItems = this.template.querySelectorAll('.list-item');
                allItems.forEach(item => {
                    item.classList.remove('slds-is-active');
                });
                selectedItem.classList.add('slds-is-active');
            }
        }
    }
    //LIFECYCLE
    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        this.initData();
        // if (this.pageSettingsList && this.pageSettingsList.length > 0) {
        //     this.selectedPageSettings = JSON.parse(JSON.stringify(this.pageSettingsList[0]));
        // }
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `
        .slds-col.slds-size--1-of-5 {
            background-color: white;
        }
    `;
        document.body.appendChild(tabStyle);
    }

    initData() {
        this.pageSettingsList = [];
        this.initPageSettingsList = [];
        this.gridtemplates = [];
        this.pages = [];
        this.pageSettingsOptions = [];
        this.isLoading = true;
        try {
            loadAllData().then((result) => {
                let parsedResult = JSON.parse(result);
                this.pageSettingsList = parsedResult.pageSettingsList.map((it, index) => { it._key = `s_0${index}`; return it; });
                this.pageSettingsOptions = this.pageSettingsList.map(item => ({
                    label: item.name,
                    value: item.name
                }));
                this.gridtemplates = parsedResult.templates;
                this.lwcParamsSettingsList = parsedResult.lwcParamsSettingsList || [];
                parsedResult.pages.forEach(page => {
                    this.pages.push({ label: page.MasterLabel, value: page.DeveloperName });
                })
                if (parsedResult.activeFlows) {
                    let options = [];
                    let parsedActiveFlows = JSON.parse(parsedResult.activeFlows);
                    let flowRecords = JSON.parse(parsedActiveFlows.flowsSerialized);
                    let flowDefinitionRecords = JSON.parse(parsedActiveFlows.flowDefinitionSerialized);
                    let devNameMap = {}
                    for (let flowDefinition of flowDefinitionRecords) {
                        devNameMap[flowDefinition.ActiveVersionId] = (flowDefinition.NamespacePrefix ? flowDefinition.NamespacePrefix + '__' : '') + flowDefinition.DeveloperName;
                    }
                    for (let flow of flowRecords) {
                        options.push({ label: flow.MasterLabel, value: devNameMap[flow.Id] })
                    }
                    this.flows = options;
                }
                this.pageSettingsList.forEach(item => {
                    let sectionIndex = 0;
                    item.sections.forEach(section => {
                        if (!section.icon) {
                            section.icon = this.staticUrl.ConnectSectionAvatar;
                        }
                        section.themes = item.themes.filter(theme => theme.sectionIndex == sectionIndex);
                        let themeKey = 0;
                        section.themes.forEach(theme => {
                            if (!theme.icon) {
                                theme.icon = this.staticUrl.ConnectThemeAvatar;
                            }
                            theme.key = `Theme:${themeKey}`;
                            theme.isURL = theme.redirectionType == 'URL';
                            theme.isGrid = theme.redirectionType == 'Grid';
                            theme.isLWC = theme.redirectionType == 'Page';
                            theme.isFlow = theme.redirectionType == 'Flow';
                            if (theme.isGrid) {
                                theme.options = JSON.parse(JSON.stringify(this.gridtemplates));
                            } else if (theme.isLWC) {
                                theme.options = JSON.parse(JSON.stringify(this.pages));
                            } else if (theme.isFlow) {
                                theme.options = JSON.parse(JSON.stringify(this.flows));
                            } else {
                                theme.options = [];
                            }
                            theme.options = theme?.options?.sort((a, b) => `${a.label}`.localeCompare(`${b.label}`));
                            if (theme.isGrid || theme.isLWC) {
                                theme.hasConfiguration = this.lwcParamsSettingsList?.find(it => it.name == (theme.isGrid ? 'gridSettingsPlugin' : theme.redirection))?.paramList?.length ? true : false;
                            } else if (theme.isFlow) {
                                theme.hasConfiguration = true;
                            }
                            themeKey++;
                        })
                        sectionIndex++;
                    })
                })
                if (this.selectedPageSettings) {
                    this.selectedPageSettings = JSON.parse(JSON.stringify(this.pageSettingsList.filter(item => item.name == this.selectedPageSettings.name)[0]));
                    if (!this.selectedPageSettings.headerBackground) {
                        this.selectedPageSettings.headerBackground = this.staticUrl.ConnectHeaderAvatar;
                    }
                    if (!this.selectedPageSettings.icon) {
                        this.selectedPageSettings.icon = this.staticUrl.ConnectLogo;
                    }
                    if (this.selectedSection) {
                        this.selectedSection = this.selectedPageSettings.sections[this.selectedSectionIndex];
                    }
                }
                this.initPageSettingsList = [...this.pageSettingsList];
                this.sortSettings();
                this.PAGE_SETTINGS_API = {
                    PageSettings__mdt: parsedResult.prefix + 'PageSettings__mdt',
                    Name__c: parsedResult.prefix + 'Name__c',
                    isActive__c: parsedResult.prefix + 'isActive__c',
                    Description__c: parsedResult.prefix + 'Description__c',
                    isDeleted__c: parsedResult.prefix + 'isDeleted__c',
                    HeaderBackground__c: parsedResult.prefix + 'HeaderBackground__c',
                    Icon__c: parsedResult.prefix + 'Icon__c',
                    Sections__c: parsedResult.prefix + 'Sections__c',
                    Themes__c: parsedResult.prefix + 'Themes__c',
                    FlowSettings__c: parsedResult.prefix + 'FlowSettings__c',
                }
                this.setLabels(parsedResult.fieldsMap);
                this.isLoading = false;
            }).catch(error => {
                console.error(error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    setLabels(fieldsMap) {
        let settingsApiName = this.PAGE_SETTINGS_API.PageSettings__mdt.replace('__c', '__mdt')
        this.labels.pageSettings.Name = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.Name__c].label;
        this.labels.pageSettings.isActive = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.isActive__c].label;
        this.labels.pageSettings.isDeleted = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.isDeleted__c].label;
        this.labels.pageSettings.Description = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.Description__c].label;
        this.labels.pageSettings.HeaderBackground = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.HeaderBackground__c].label;
        this.labels.pageSettings.Icon = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.Icon__c].label;
        this.labels.pageSettings.Sections = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.Sections__c].label;
        this.labels.pageSettings.Themes = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.Themes__c].label;
        this.labels.pageSettings.FlowSettings = fieldsMap[settingsApiName][this.PAGE_SETTINGS_API.FlowSettings__c].label;
    }

    async handleDeletePageSettings() {
        const userConfirmed = await this.showPopup('Page');
        if (!userConfirmed) {
            this.deletePopup.visibility = false;
            return;
        }

        this.deletePopup.visibility = false;
        this.isLoading = true;

        try {
            this.selectedPageSettings.isDeleted = true;
            let pageSettingsToSave = JSON.parse(JSON.stringify([this.selectedPageSettings]));
            const result = await save({ pageSettingsListJSON: JSON.stringify(pageSettingsToSave) });
            this.pageSettingsList = this.pageSettingsList.filter(
                ps => ps.name !== this.selectedPageSettings.name
            );

            this.pageSettingsOptions = this.pageSettingsList.map(item => ({
                label: item.name,
                value: item.name
            }));
            this.selectedPageSettings = null;
            this.selectedPageSettingsName = null;
            this.showNotification(
                this.labels.LBL_Success,
                this.labels.LBL_PageSettings_Deleted_Success,
                'success'
            );

        } catch (error) {
            console.error(error);
            this.showNotification(
                this.labels.LBL_Error,
                error?.body?.message || error?.message || error,
                'error',
                'sticky'
            );
        } finally {
            this.isLoading = false;
        }
    }

    get canDeletePageSettings() {
        return this.selectedPageSettings &&
            (this.selectedPageSettings.namespacePrefix === null ||
                this.selectedPageSettings.namespacePrefix === undefined ||
                this.selectedPageSettings.namespacePrefix === '');
    }

    sortSettings() {
        this.pageSettingsList.sort((a, b) => {
            if (a.name === undefined) return -1;
            if (b.name === undefined) return 1;
            let aValue = a.name.toLowerCase();
            let bValue = b.name.toLowerCase();
            return ((aValue > bValue) ? 1 : ((bValue > aValue) ? -1 : 0)); // Sort ascending
        });
    }

    handleChangeSectionSettings(event) {
        try {
            let field = event.target.dataset.field;
            let index = event.target.dataset.index;
            let value = event.detail && event.detail.checked != null ? event.detail.checked : event.target.value;
            if (field == 'isActive') {
                this.selectedPageSettings.sections[index][field] = !this.selectedPageSettings.sections[index][field];
            } else {
                this.selectedPageSettings.sections[index][field] = value;
            }
        } catch (error) {
            console.error(error)
        }
    }

    handleChangeFlowSettings(event) {
        try {
            let field = event.target.dataset.field;
            let value = event.detail && event.detail.checked != null ? event.detail.checked : event.target.value;          
            this.selectedPageSettings.flowSettings[field] = value;
        } catch (error) {
            console.error(error)
        }
    }

    handleChangeThemeSettings(event) {
        let field = event.currentTarget.dataset.field;
        let index = event.currentTarget.dataset.index;
        let value = event.detail?.checked ?? event.detail?.value ?? event.currentTarget.value;
        let theme = this.selectedSection.themes[index];
        if (field == 'isActive' || field == 'isInternalDisplay' || field == 'isPortalDisplay') {
            theme[field] = !theme[field];
            if (field == 'isActive' && !theme.isActive) {
                theme.isInternalDisplay = false;
                theme.isPortalDisplay = false;
            }
        } else {
            theme[field] = value;
        }
        if (field == 'redirectionType') {
            theme.isURL = theme[field] == 'URL';
            theme.isGrid = theme[field] == 'Grid';
            theme.isLWC = theme[field] == 'Page';
            theme.isFlow = theme[field] == 'Flow';
            theme.redirection = '';
            if (theme.isGrid) {
                theme.options = JSON.parse(JSON.stringify(this.gridtemplates));
            } else if (theme.isLWC) {
                theme.options = JSON.parse(JSON.stringify(this.pages));
            } else if (theme.isFlow) {
                theme.options = JSON.parse(JSON.stringify(this.flows));
            } else {
                theme.options = [];
            }
            theme.options = theme.options?.sort((a, b) => `${a.label}`.localeCompare(`${b.label}`));
        }
        if (theme.isGrid || theme.isLWC) {
            theme.hasConfiguration = this.lwcParamsSettingsList?.find(it => it.name == (theme.isGrid ? 'gridSettingsPlugin' : theme.redirection))?.paramList?.length ? true : false;
        }
        if (field == 'redirection') {
            theme.redirection = value;
        }

    }

    handleThemesSelection(event) {
        this.isLoading = true;
        let index = event.currentTarget.dataset.index;
        this.selectedSection = this.selectedPageSettings.sections[index];
        this.selectedSectionIndex = index;
        // this.displayedThemes = this.selectedPageSettings.themes.filter(theme => theme.sectionIndex == index);
        this.isLoading = false;
    }

    // handleChangePageSettings(event) {
    //     console.log('handleChangePageSettings');
    //     this.isLoading = true;
    //     let index = event.currentTarget.dataset.index;
    //     this.selectedPageSettings = JSON.parse(JSON.stringify(this.pageSettingsList[index]));
    //     this.selectedSection = null;
    //     this.selectedSectionIndex = null;
    //     console.log('this.selectedPageSettings >>> ' + JSON.stringify(this.selectedPageSettings));
    //     const allItems = this.template.querySelectorAll('.list-item');
    //     allItems.forEach(item => {
    //         item.classList.remove('slds-is-active');
    //     });
    //     const selectedItem = event.currentTarget;
    //     selectedItem.classList.add('slds-is-active');
    //     this.isLoading = false;
    // }

    @track selectedPageSettings = null;
    @track selectedPageSettingsName = null;

    @track pageSettingsOptions = [];

    handleChangePageSettings(event) {
        const selectedName = event.detail.value;
        this.selectedPageSettingsName = selectedName;
        this.selectedPageSettings = this.pageSettingsList.find(item => item.name === selectedName);
        this.selectedSection = null;
        this.selectedSectionIndex = null;
    }

    handleCancel() {
        this.selectedPageSettings = null;
        this.selectedPageSettingsName = null;
        const allItems = this.template.querySelectorAll('.list-item');
        allItems.forEach(item => {
            item.classList.remove('slds-is-active');
        });
    }

    togglePopupAddPageSettings() {
        this.addNewRowPageSettings = !this.addNewRowPageSettings;
        if (this.addNewRowPageSettings) {
            this.newPageSettings = {
                name: '',
                description: '',
                isDeleted: false,
                headerBackground: ConnectHeaderAvatar,
                icon: ConnectLogo,
                sections: [],
                themes: [],
                flowSettings: {},
            };
        }
    }

    handleChangeNewPageSettings(event) {
        console.log('handleChangeNewPageSettings')
        let field = event.target.dataset.field;
        let value = event.detail && event.detail.checked != null ? event.detail.checked : event.target.value;
        console.log('field >>> ' + field)
        if (field == 'headerBackground') {
            this.handleChangeIconChange(this.newPageSettings, field);
        } else {
            this.newPageSettings[field] = value;
        }
    }

    handleChangeSelectedPageSettings(event) {
        console.log('handleChangeSelectedPageSettings')
        let field = event.target.dataset.field;
        let value = event.detail && event.detail.checked != null ? event.detail.checked : event.target.value;
        console.log('field >>> ' + field)
        if (field == 'headerBackground') {
            this.handleChangeIconChange(this.selectedPageSettings, field);
        } else if (field == 'isActive') {
            this.selectedPageSettings[field] = !this.selectedPageSettings[field];
        } else {
            this.selectedPageSettings[field] = value;
        }
    }

    handleChangeIconChange(object, field) {
        console.log('handleChangeIconChange')
        let inputImage = document.createElement('input');
        inputImage.type = 'file';
        inputImage.accept = 'image/*';
        inputImage.onchange = (event) => {
            let file = event.target.files[0];
            let fileName = file.name;
            if (!file) {
                this.showNotification('Error', 'Please select a file to upload.', 'error');
                return;
            }
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64data = reader.result.split(',')[1];
                uploadImage({ base64Image: base64data, imageName: fileName }).then(result => {
                    /*console.log('result: ' + result)
                    // module.iconUrl = result;
                    this.settingsList[index].sectionIconStyle = `background-image:url('${result}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    this.settingsList[index].sectionIcon = result;*/
                    object[field] = result
                }).catch(error => {
                    console.log('error.message', error)
                    this.showNotification('error :', error.message);
                });
            };
            reader.readAsDataURL(file);
        }
        inputImage.click();
    }

    handleAddNewPageSettings() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            return;
        }
        this.selectedPageSettings = this.newPageSettings;
        this.selectedPageSettingsName = this.newPageSettings.name;
        this.handleSave();
        this.togglePopupAddPageSettings();
    }

    handleAddSection() {
        let newSection = {
            isNew: true,
            title: '',
            subTitle: '',
            icon: '',
            order: String(this.selectedPageSettings.sections.length + 1),
            color: '',
            isActive: true,
            themes: [],
        };
        this.selectedPageSettings.sections.push(newSection);
    }

    async handleDeleteSection(event) {
        let index = event.target.dataset.index;
        const userConfirmed = await this.showPopup('Section');
        if (!userConfirmed) {
            this.deletePopup.visibility = false;
            return
        } else {
            if (this.selectedSectionIndex == index) {
                this.selectedSectionIndex = null;
                this.selectedSection = null;
            }
            this.selectedPageSettings.sections.splice(index, 1);
            this.deletePopup.visibility = false;
        }
    }

    handleAddTheme() {
        let newTheme = {
            sectionIndex: this.selectedSectionIndex,
            label: '',
            redirectionType: '',
            redirection: '',
            icon: '',
            options: [],
            isInternalDisplay: true,
            isPortalDisplay: true,
            isActive: true,
        };
        console.log('newTheme >>> ' + JSON.stringify(newTheme))
        this.selectedSection.themes.push(newTheme);
    }

    async handleDeleteTheme(event) {
        let index = event.target.dataset.index;
        const userConfirmed = await this.showPopup('Theme');
        if (!userConfirmed) {
            this.deletePopup.visibility = false;
            return
        } else {
            this.selectedSection.themes.splice(index, 1);
            this.deletePopup.visibility = false;
        }
    }

    handleSave() {
        const orders = this.selectedPageSettings.sections.map(section => section.order.toString().trim());
        const isAllNumeric = orders.every(order => !isNaN(order) && order !== '');
        const orderCountMap = new Map();
        let hasDuplicate = false;
        orders.forEach(order => {
            if (orderCountMap.has(order)) {
                hasDuplicate = true;
            } else {
                orderCountMap.set(order, 1);
            }
        });
        if (!isAllNumeric) {
            this.showNotification('Validation Error', 'Each section must have a valid numeric "Order" value.', 'error', 'sticky');
            return;
        }
        if (hasDuplicate) {
            this.showNotification('Validation Error', 'Each "Order" value must be unique. Duplicate values are not allowed.', 'error', 'sticky');
            return;
        }
        this.isLoading = true;
        this.selectedPageSettings.themes = [];
        let sectionIndex = 0;
        this.selectedPageSettings.sections.forEach(section => {
            if (section.themes) {
                section.themes.forEach(theme => {
                    theme.sectionIndex = sectionIndex;
                    this.selectedPageSettings.themes.push(theme)
                })
            }
            delete section.isNew;
            sectionIndex++;
        })
        console.log('JSON.stringify([this.selectedPageSettings]) >>> ' + JSON.stringify([this.selectedPageSettings]))
        try {
            save({ pageSettingsListJSON: JSON.stringify([this.selectedPageSettings]) }).then((result) => {
                this.checkDeployementStatus(result);
            }).catch(error => {
                console.error(error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    checkDeployementStatus(idDeployment) {
        this.loadingData = true;
        let self = this;
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
                        self.loadingData = false;
                        clearInterval(interval);
                        self.dispatchEvent(new ShowToastEvent({
                            title: self.labels.MSG_Information,
                            message: self.labels.MSG_Request_Timed_Out + ' ' + self.labels.MSG_Deploy_Last_Status + ' ' + status,
                            variant: INFO_VARIANT,
                            mode: STICKY_VARIANT
                        }));
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            self.loadingData = false;
                            self.initData();
                            clearInterval(interval);
                            if (success) {
                                self.showNotification(self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
                            } else {
                                self.showNotification(self.labels.MSG_Information, self.labels.MSG_Deploy_Ended_With_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.loadingData = false;
                self.initData();
                self.showNotification(self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
            }
        });
    }

    showPopup(mode) {
        this.deletePopup.visibility = true;
        this.deletePopup.mode = mode;
        if (mode == 'Section') {
            this.deletePopup.title = this.labels.LBL_Delete_Section;
            this.deletePopup.body = this.labels.LBL_Confirm_Section;
        } else if (mode == 'Theme') {
            this.deletePopup.title = this.labels.LBL_Delete_Theme;
            this.deletePopup.body = this.labels.LBL_Confirm_Theme;
        } else if (mode == 'Page') {
            this.deletePopup.title = this.labels.LBL_FileDirectory_PageDeleteMessageTitle;
            this.deletePopup.body = this.labels.LBL_FileDirectory_PageDeleteMessageDescription;
        }
        return new Promise((resolve) => {
            this._resolvePopup = resolve; // Save the resolve function to call later
        });
    }

    handlePopupAction(event) {
        document.body.style.overflowY = 'hidden'
        const data = event.currentTarget ? event.currentTarget.dataset.id : event.target.dataset.id;
        this.deletePopup.visibility = false; // Hide the popup
        this._resolvePopup(data == 'confirm'); // Resolve the promise with true (if confirm) or false (if cancel)
        this._resolvePopup = null;
    }

    get redirectionOptions() {
        return [
            { label: 'Grid', value: 'Grid' },
            { label: 'Page', value: 'Page' },
            { label: 'URL', value: 'URL' },
            { label: 'Flow', value: 'Flow' },
        ]
    }

    changeHeight = () => {
        let mainPanelHeight;
        if (window.innerWidth < 980) {
            mainPanelHeight = window.innerHeight - 213;
        } else {
            mainPanelHeight = window.innerHeight - 183;
        }
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px';
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