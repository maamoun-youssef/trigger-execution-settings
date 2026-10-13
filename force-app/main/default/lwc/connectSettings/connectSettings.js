import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//APEX
import loadConnectSettings from '@salesforce/apex/ConnectSettingsCtrl.loadConnectSettings';
import saveSettings from '@salesforce/apex/ConnectSettingsCtrl.saveSettings';
import generateFileDirectorySharing from '@salesforce/apex/ConnectSettingsCtrl.generateFileDirectorySharing';
import checkDeploymentStatus from '@salesforce/apex/ConnectSettingsCtrl.checkDeploymentStatus';
import getObjectDescriptions from '@salesforce/apex/ConnectSettingsCtrl.getObjectDescriptions';
import uploadImagePortalFavIcon from '@salesforce/apex/ConnectSettingsCtrl.uploadImagePortalFavIcon';
import uploadFile from '@salesforce/apex/ConnectSettingsCtrl.uploadFile';

// STATIC RESSOURCES
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
import welcomeIcon from "@salesforce/resourceUrl/welcomeIcon";
import chatterIcon from "@salesforce/resourceUrl/chatterIcon";
import uploadCloud from "@salesforce/resourceUrl/uploadCloud";
import CustomSettingsLogo from "@salesforce/resourceUrl/CustomSettingsLogo";
import ConnectPlayAnimation from "@salesforce/resourceUrl/ConnectPlayAnimation";
//ICONS
import sortLeft from "@salesforce/resourceUrl/sortLeft";
import sortRight from "@salesforce/resourceUrl/sortRight";
import sortUp from "@salesforce/resourceUrl/sortUp";
import sortDown from "@salesforce/resourceUrl/sortDown";
// import Connect_Logo from "@salesforce/resourceUrl/Connect_Logo";
import ConnectMenuAvatar from "@salesforce/resourceUrl/ConnectMenuAvatar";

import { labels } from './properties.js';
import { loadIconList } from 'c/iconResourcePicker';
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const classPrefix = `${PREFIX ? PREFIX.toLowerCase().replace(/__/gi, '') + '-' : 'c-'}connect-settings`;
export default class ConnectSettings extends LightningElement {
    //LABELS
    labels = labels;
    sortLeft = sortLeft;
    sortRight = sortRight;
    sortUp = sortUp;
    sortDown = sortDown;
    isLoading = false;
    flowPickList = {};
    @track videoUrl = '';
    @track fieldLabelMap = {};
    @track availableApprovalProfiles = [];
    @track selectedApprovalProfiles = [];
    @track availableNonApprovalProfiles = [];
    @track selectedNonApprovalProfiles = [];
    @track availableSummaryFields = [];
    @track availableHeaderFields = [];
    @track availableAdditionalFields = [];
    @track selectedSummaryFields = [];
    @track selectedSellinType = [];
    @track selectedHeaderFields = [];
    @track selectedAdditionalFields = [];
    @track profileOptions = [];
    @track groupOptions = [];
    @track permissionSetGroupOptions = [];
    @track LanguageLocaleKeyOptions = [];
    @track LocaleSidKeyOptions = [];
    @track guideDocUrl = '';
    @track directoryManagerOptions = [{
        value: 'SupplierOwner',
        label: this.labels.LBL_Connect_Supplier_Owner
    }, {
        value: 'NegoscopeOwner',
        label: this.labels.LBL_Connect_NegoScope_Owner
    },
    ];
    @track SellinStatementGenerationModeOptions = [{
        value: 'Automatic',
        label: this.labels.LBL_Connect_SellInStatementAutomatic
    }, {
        value: 'Manual',
        label: this.labels.LBL_Connect_SellInStatementManual
    },
    ];
    @track availableSellinTypes = [
        {
            value: 'LBL_Connect_RegularDiscountableRevenue',
            name: this.labels.LBL_Connect_RegularDiscountableRevenue.slice(0, this.labels.LBL_Connect_RegularDiscountableRevenue.length - 1)
        },
        {
            value: 'LBL_Connect_PromoDiscountableRevenue',
            name: this.labels.LBL_Connect_PromoDiscountableRevenue.slice(0, this.labels.LBL_Connect_PromoDiscountableRevenue.length - 1)
        },
        {
            value: 'LBL_Connect_TotalDiscountableRevenue',
            name: this.labels.LBL_Connect_TotalDiscountableRevenue.slice(0, this.labels.LBL_Connect_TotalDiscountableRevenue.length - 1)
        },
        {
            value: 'LBL_Connect_NonDiscountableRevenue',
            name: this.labels.LBL_Connect_NonDiscountableRevenue.slice(0, this.labels.LBL_Connect_NonDiscountableRevenue.length - 1)
        },
        {
            value: 'LBL_Connect_RegularDiscountableQuantity',
            name: this.labels.LBL_Connect_RegularDiscountableQuantity.slice(0, this.labels.LBL_Connect_RegularDiscountableQuantity.length - 1)
        },
        {
            value: 'LBL_Connect_PromoDiscountableQuantity',
            name: this.labels.LBL_Connect_PromoDiscountableQuantity.slice(0, this.labels.LBL_Connect_PromoDiscountableQuantity.length - 1)
        },
        {
            value: 'LBL_Connect_TotalDiscountableQuantity',
            name: this.labels.LBL_Connect_TotalDiscountableQuantity.slice(0, this.labels.LBL_Connect_TotalDiscountableQuantity.length - 1)
        },
        {
            value: 'LBL_Connect_NonDiscountableQuantity',
            name: this.labels.LBL_Connect_NonDiscountableQuantity.slice(0, this.labels.LBL_Connect_NonDiscountableQuantity.length - 1)
        },
    ];
    @track sellinStatementRevenueTypeOptions = [];
    @track sellinStatementRevenueTypeOptionsWithDescription = [];
    @track licenseQuotas = {
        activation: false,
        licensePerSupplier: 5
    }
    @track connectSettings = {};
    previousConnectSettings = {};
    //STRINGS
    @track mainPanelHeight;
    //LOGO
    staticUrl = {
        PortalFavIcon: connect_defaults + '/connect_logo/connect_default_logo.png',
        ConnectPlayAnimation: ConnectPlayAnimation,
        ConnectMenuAvatar: ConnectMenuAvatar
    }
    @track CustomSettingsLogo = `max-width:110px; height:50px; background-image: url('${CustomSettingsLogo}'); background-position: left center;`;
    //ICON PICKER
    showIconPicker = false;
    iconPickerIndex;
    doOnce = false;
    table = {
    };

    tableStructure = {
        comboBoxOptions: [
            { label: 'FileDirectory Read-Only', value: 'FileDirectory Read-Only' },
            { label: 'FileDirectory Edit', value: 'FileDirectory Edit' },
            { label: 'Null', value: 'Null' }
        ],
        comboBoxReadOnly: [
            { label: 'Lecture Seule', value: 'Lecture Seule' },
            { label: 'Null', value: 'Null' }
        ],

        extractLabel(data) {
            // Define the regular expression to match the pattern and capture the data after "SLabel."
            const regex = /\{\!\$Label\.(.*?)\}/;

            // Apply the regex to the input string and extract the desired part
            const match = data.match(regex);

            // Check if there's a match and return the captured group
            return match ? match[1] : null;
        },
    };

    loadOptionStyle() {
        const comboboxes = this.template.querySelectorAll('lightning-combobox');
        comboboxes.forEach(combobox => {
            const value = combobox.value;
            const parentTd = combobox.closest('td');
            if (parentTd) {
                if (value === 'Modifier' || value === 'Lecture Seule') {
                    parentTd.style.background = 'fixed'; // Set background to fixed
                    const color = value === 'Modifier' ? '#eaf8e4' : '#fdf2ed';
                    parentTd.style.color = value === 'Modifier' ? '#6bbc91' : '#ec967c';
                    parentTd.style.backgroundColor = color;
                } else {
                    parentTd.style.background = 'none'; // Clears any background
                }
            }
        });
    }

    handleRoleChange(event) {
        const checked = event.target.checked;
        const fieldName = event.target.dataset.field;
        const parentTr = event.target.closest('tr');
        const roleIndex = parentTr.dataset.size;
        const itemIndex = parentTr.dataset.index;
        const permissionDetailIndex = event.target.dataset.index;
        const newValue = checked ? true : false;
        this.connectSettings.rolePermissions.roles[roleIndex].permissionRoles[itemIndex].permissionDetails[permissionDetailIndex][fieldName] = newValue;
        if (fieldName === 'hasAccessToFile' && !newValue) {
            this.connectSettings.rolePermissions.roles[roleIndex].permissionRoles[itemIndex].permissionDetails[permissionDetailIndex].canUploadFile = false;
        }
    }

    // check if the image url iz valid (help method)
    validateImageUrl(url) {
        return new Promise((resolve) => {
            const image = document.createElement('img');
            image.style.display = 'none';

            image.onload = () => {
                document.body.removeChild(image);
                resolve(true);
            };

            image.onerror = () => {
                document.body.removeChild(image);
                resolve(false);
            };

            image.src = url;
            document.body.appendChild(image);
        });
    }

    @track pageSettingOptions = [];
    @track selectedSetting = '';
    //LIFECYCLE
    connectedCallback() {
        this.template.addEventListener('click', (event) => {
            const uploadElement = event.target.closest('lightning-file-upload[data-field="logo"]');
            if (uploadElement) {
                event.preventDefault();
                event.stopPropagation();
                const fileInput = this.template.querySelector('.logo-file-input');
                if (fileInput) {
                    fileInput.click();
                }
            }
        });
        Promise.all([]).then(() => {
            console.log('loading style success');
        }).catch(error => {
            console.log('error loading style');
        });
        window.addEventListener('resize', this.changeHeight);
        // Apply Style to Lightnng Tab
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
            ${classPrefix} .slds-vertical-tabs__nav-item:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item a:hover,
            .slds-vertical-tabs__nav-item a:focus {
                color: #806BBF;
                background: white;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active:hover {
                background: white;
                color: #806BBF;
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
        this.isLoading = true;
        this.loadData();
    }

    renderedCallback() {
        if (this.template.querySelector('.settings-header')) {
            this.changeHeight();
        }
        if (this.doOnce == false) {
            setTimeout(() => {
                this.loadOptionStyle();
                this.doOnce = true;
            }, 3000);
        } else {
            this.loadOptionStyle()
        };
    }

    //LOAD DATA
    loadData() {
        this.showUploadSection = true;
        this.loadObjectDescriptions();
        // load the rest of settings
        loadConnectSettings()
            .then(result => {
                let parsedResult = result;
                this.afterLoad(parsedResult);
                // Read the icon list in the background, so the icon picker opens with it ready.
                // A failure is ignored here: the picker loads the list again when it opens.
                loadIconList(this).catch(() => {});
                if (this.connectSettings?.guideDocUrl) {
                    this.connectSettings.guideDocUrl = this.connectSettings.guideDocUrl;
                    this.showCloudIcon.portalGuide = false;
                }
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.isLoading = false;
            })
    }

    afterLoad(mainWrapper) {
        // Parse mainWrapper if it's a JSON string, or use it directly if it's already an object
        let parsedWrapper = typeof mainWrapper === 'string' ? JSON.parse(mainWrapper) : mainWrapper;
        // Set UP Page Settings Options
        this.pageSettingOptions.push({ label: '---', value: null })
        Object.keys(parsedWrapper.pageSettingsMap).forEach(key => {
            this.pageSettingOptions.push({ label: parsedWrapper.pageSettingsMap[key], value: key })
        })
        //SET UP sellinStatementRecordTypes
        parsedWrapper.sellinStatementRecordTypes.forEach(rt => {
            this.sellinStatementRevenueTypeOptionsWithDescription.push({ label: rt.Name, value: rt.Id, description: rt.Description });
        });
        this.sellinStatementRevenueTypeOptions = this.sellinStatementRevenueTypeOptionsWithDescription.map(({ label, value }) => ({ label, value }));
        // Assign connectSettings if it exists in the parsed object
        if (parsedWrapper && parsedWrapper.settings) {
            this.connectSettings = parsedWrapper.settings;
            // Preserve previous settings
            this.previousConnectSettings = JSON.parse(JSON.stringify(this.connectSettings));
        } else {
            console.error('Settings object not found in mainWrapper');
        }
        this.roleTableLabels = parsedWrapper.roleTableLabels;
        this.loadWelcomSettings();
        let groupOptions = [];
        let permissionSetGroupOptions = [];
        let languageLocaleKeyOptions = [];
        let localeSidKeyOptions = [];

        parsedWrapper.groupList?.forEach(group => {
            groupOptions.push({
                value: group.Id,
                label: group.DeveloperName
            })
        });
        parsedWrapper.permissionSetGroupList?.forEach(group => {
            permissionSetGroupOptions.push({
                value: group.DeveloperName,
                label: group.MasterLabel
            })
        });

        if (parsedWrapper.languageLocaleKeyMap) {
            const allowed = ['en_US', 'fr'];
            Object.keys(parsedWrapper.languageLocaleKeyMap).filter(key => allowed.includes(key)).forEach(key => {
                languageLocaleKeyOptions.push({
                    value: key,
                    label: parsedWrapper.languageLocaleKeyMap[key]
                });
            });
        }

        if (parsedWrapper.localeSidKeyMap) {
            const allowed = ['en_US', 'fr_FR'];
            Object.keys(parsedWrapper.localeSidKeyMap).filter(key => allowed.includes(key)).forEach(key => {
                localeSidKeyOptions.push({
                    value: key,
                    label: parsedWrapper.localeSidKeyMap[key]
                });
            });
        }

        this.groupOptions = groupOptions;
        this.permissionSetGroupOptions = permissionSetGroupOptions;
        this.LanguageLocaleKeyOptions = languageLocaleKeyOptions;
        this.LocaleSidKeyOptions = localeSidKeyOptions;

        if (this.connectSettings.licenseQuotas) {
            this.licenseQuotas = this.connectSettings.licenseQuotas;
        }

        let selectedApprovalProfiles = [];
        let selectedNonApprovalProfiles = [];
        //FILL AVAILABLE PROFILES
        let availableApprovalProfiles = [];
        let availableNonApprovalProfiles = [];
        let profileOptions = [];
        this.flowPickList = parsedWrapper.flowList.map(item => {
            return {
                value: (item.NamespacePrefix ? item.NamespacePrefix + '__' : '') + item.ApiName,
                label: item.Label,
            }
        })
        for (let profile of parsedWrapper.profileList) {
            if (profile.UserLicense.Name.includes('Community Plus')) {
                profileOptions.push({
                    label: profile.Name,
                    value: profile.Id
                })
            };
            let profileWrap = {
                name: profile.Id,
                label: profile.Name
            }
            if (this.connectSettings.approvalProfiles && !this.connectSettings.approvalProfiles.includes(profile.Id)) {
                availableApprovalProfiles.push({ ...profileWrap });
            } else {
                selectedApprovalProfiles.push({ ...profileWrap });
            }
            if (this.connectSettings.nonApprovalProfiles && !this.connectSettings.nonApprovalProfiles.includes(profile.Id)) {
                availableNonApprovalProfiles.push({ ...profileWrap });
            } else {
                selectedNonApprovalProfiles.push({ ...profileWrap });
            }
        }
        this.profileOptions = profileOptions;
        this.availableApprovalProfiles = availableApprovalProfiles;
        this.selectedApprovalProfiles = selectedApprovalProfiles;
        this.availableNonApprovalProfiles = availableNonApprovalProfiles;
        this.selectedNonApprovalProfiles = selectedNonApprovalProfiles;
        //FILL FIELDS
        let selectedSummaryApiNames = [];
        let selectedSellinTypeNames = [];
        let selectedHeaderApiNames = [];
        let selectedAdditionalApiNames = [];
        if (this.connectSettings.summaryFields) {
            selectedSummaryApiNames = this.connectSettings.summaryFields;
        }
        if (this.connectSettings.sellInRevenueOptions) {
            selectedSellinTypeNames = this.connectSettings.sellInRevenueOptions;
        }
        if (this.connectSettings.cardHeaderFields) {
            selectedHeaderApiNames = this.connectSettings.cardHeaderFields;
        }
        if (this.connectSettings.additionalFields) {
            selectedAdditionalApiNames = this.connectSettings.additionalFields;
        }
        //FILL SELECTED COD FIELDS
        let selectedSummaryFields = [];
        let selectedSellinType = [];
        let selectedHeaderFields = [];
        let selectedAdditionalFields = [];

        selectedSummaryApiNames.forEach(field => {
            selectedSummaryFields.push({
                name: field,
                label: parsedWrapper.fieldsMap[field]
            })
        });
        // selectedSellinTypeNames.forEach(revenue => {
        //     selectedSellinType.push({
        //         name: revenue,
        //         label: parsedWrapper?.fieldsMap[revenue]
        //     })
        // });

        selectedSellinTypeNames.forEach(revenue => {
            const foundSellinType = this.availableSellinTypes.find(option => option.value === revenue);
            if (foundSellinType) {
                selectedSellinType.push(foundSellinType);
            }
        });
        selectedHeaderApiNames.forEach(field => {
            selectedHeaderFields.push({
                name: field,
                label: parsedWrapper.fieldsMap[field]
            })
        });
        selectedAdditionalApiNames.forEach(field => {
            selectedAdditionalFields.push({
                name: field,
                label: parsedWrapper.fieldsMap[field]
            })
        });
        this.selectedSummaryFields = selectedSummaryFields;
        this.selectedSellinType = selectedSellinType;
        const listOfSellValue = this.selectedSellinType.map(element => element.name);
        this.availableSellinTypes = this.availableSellinTypes.filter(item => !listOfSellValue.includes(item.name));
        this.selectedHeaderFields = selectedHeaderFields;
        this.selectedAdditionalFields = selectedAdditionalFields;
        //FILL AVAILABLE COD FIELDS
        let availableSummaryFields = [];
        let availableSellinTypes = [];
        let availableHeaderFields = [];
        let availableAdditionalFields = [];

        for (let field in parsedWrapper.fieldsMap) {
            if (!selectedSummaryApiNames.includes(field)) {
                availableSummaryFields.push({
                    name: field,
                    label: parsedWrapper.fieldsMap[field],
                    isSelected: false
                })
            }

            if (!selectedHeaderApiNames.includes(field)) {
                availableHeaderFields.push({
                    name: field,
                    label: parsedWrapper.fieldsMap[field],
                    isSelected: false
                })
            }
            if (!selectedAdditionalApiNames.includes(field)) {
                availableAdditionalFields.push({
                    name: field,
                    label: parsedWrapper.fieldsMap[field],
                    isSelected: false
                })
            }
        }
        this.availableSummaryFields = availableSummaryFields;
        this.availableHeaderFields = availableHeaderFields;
        this.availableAdditionalFields = availableAdditionalFields;
        this.isLoading = false;
    }

    initRoleTable() {
        this.table = this.connectSettings?.rolePermissions;
        if (this.table) {
            this.table.rowSpan = (this.table.roles?.length ?? 0) + 1;
            const translatedHeaders = this.table?.headers?.map(item => this.roleTableLabels?.[item] || item);
            this.table.headerLabels = translatedHeaders;
            this.table.label = this.labels[this.table.name];
            this.table.headerColspan = translatedHeaders.length * 2;
            this.table.roles?.forEach((item, index1) => {
                item._key = 'key-00' + index1;
                item.label = this.roleTableLabels?.[item.type] || item.type;
                item.rowspan = item.permissionRoles.length;
                item.permissionRoles.forEach((role, index2) => {
                    role._keyhasAccessToFile = item._key + '-hasAccessToFile00' + index2;
                    role._keycanUploadFile = item._key + '-canUploadFile00' + index2;
                    role.label = this.roleTableLabels?.[role.title] || role.title;
                });
                item.permissionRoles[0].firstIndex = true;
            })
        }
    }

    loadWelcomSettings() {
        this.initRoleTable();
        this.videoUrl = this.connectSettings.onboardingVideoUrl || this.staticUrl.ConnectPlayAnimation;
        this.connectSettings.connectLogoIcon = this.connectSettings.connectLogoIcon || this.staticUrl.PortalFavIcon;
        if (this.connectSettings.connectLogoIcon) {
            this.showCloudIcon.portalFav = false;
            this.PortalFavIcon = `max-width:300px; height:200px; background-position: center; background-image: url('${this.connectSettings.connectLogoIcon}'); background-repeat: no-repeat; background-size: contain;`;
        } else {
            console.error('Photo URL is empty.');
        }
        if (this.videoUrl) {
            this.showCloudIcon.portalVideo = false;
        } else {
            console.error('Video URL is empty.');
        }
        this.connectSettings.modulesConfiguration?.forEach((item, index) => {
            item.isURL = item.redirectionType == 'URL';
            item.isSettings = item.redirectionType == 'Settings';
            this.validateImageUrl(item.iconUrl).then(value => {
                if (!item.index) {
                    item.index = index + 1;
                }
                if (!value) {
                    item.iconUrl = this.staticUrl.ConnectMenuAvatar;
                }
                item.iconStyle = `background-image:url('${item.iconUrl}'); aspect-ratio: 1/1; width: 35px; background-size: cover; height:35px; translate: 0px 4px;`;
            })
        });
        if (this.connectSettings.searchableObjects) {
            this.connectSettings.searchableObjects.forEach(element => {
                this.searchableObjects.push({ label: '', apiName: element, isSelected: false });
            });
        }
    }

    handleChangeModuleConfigurations(event) {
        let index = event.target.dataset.index;
        let field = event.target.dataset.field;
        let value = event.detail && event.detail.checked != null ? event.detail.checked : event.target.value;
        if (field == 'iconUrl') {
            this.iconPickerIndex = index;
            this.showIconPicker = true;
        } else if (field == 'isDisplayed') {
            this.connectSettings.modulesConfiguration[index][field] = !this.connectSettings.modulesConfiguration[index][field];
        } else if (field == 'isActive') {
            this.connectSettings.modulesConfiguration[index][field] = !this.connectSettings.modulesConfiguration[index][field];
        } else {
            this.connectSettings.modulesConfiguration[index][field] = value;
        }
        if (field == 'redirectionType') {
            this.connectSettings.modulesConfiguration[index].isURL = this.connectSettings.modulesConfiguration[index][field] == 'URL';
            this.connectSettings.modulesConfiguration[index].isSettings = this.connectSettings.modulesConfiguration[index][field] == 'Settings';
        }
    }

    handleIconSelect(event) {
        let iconUrl = event.detail.url;
        this.connectSettings.modulesConfiguration[this.iconPickerIndex].iconUrl = iconUrl;
        this.connectSettings.modulesConfiguration[this.iconPickerIndex].iconStyle = `background-image:url('${iconUrl}'); aspect-ratio: 1/1; width: 35px; background-size: cover; height:35px; translate: 0px 4px;`;
        this.closeIconPicker();
    }

    closeIconPicker() {
        this.showIconPicker = false;
        this.iconPickerIndex = undefined;
    }

    get redirectionOptions() {
        return [
            { label: 'Settings', value: 'Settings' },
            { label: 'URL', value: 'URL' },
        ]
    }

    //EVENT HANDLERS
    handleChangeUserProfile(event) {
        this.connectSettings.connectUserProfile = event.target.value
    }

    handleChangeDirectoryManager(event) {
        this.connectSettings.directoryManager = event.target.value
    }

    handleChangeSellInWelcomeMessage(event) {
        this.connectSettings.sellInWelcomeMessage = event.target.value
    }

    handleChangeUserGroup(event) {
        this.connectSettings.connectUserGroup = event.target.value
    }

    handleChangePermissionSetGroup(event) {
        this.connectSettings.connectUserPermissionSetGroup = event.target.value
    }

    handleChangeLanguageLocaleKey(event) {
        this.connectSettings.LanguageLocaleKey = event.target.value
    }

    handleChangeLocaleSidKey(event) {
        this.connectSettings.LocaleSidKey = event.target.value
    }

    handleChangeFlow(event) {
        const field = event.target.dataset.id;
        this.connectSettings[field] = event.target.value
    }

    handleChangeGenerationMode(event) {
        this.connectSettings.statementGenerationMode = event.target.value;
    }

    handleChangeRevenueTypeMode(event) {
        this.connectSettings.sellinStatementRevenueType = event.target.value;
    }

    handleLicenseQuota(event) {
        let param = event.target.dataset.lisence;
        this.licenseQuotas[param] = param == 'activation' ? event.target.checked : event.target.value;
    }

    handleFieldSelection(event) {
        let selectedIndex = event.currentTarget.dataset.index;
        let array = event.currentTarget.dataset.array;
        this[array][selectedIndex].isSelected = !this[array][selectedIndex].isSelected;
    }

    moveSelectedItemsUp(event) {
        let array = event.currentTarget.dataset.array;
        let fieldsList = this[array];
        for (let index = 0; index <= fieldsList.length; index++) {
            let element = fieldsList[index];
            if (element.isSelected) {
                if (index == 0) {
                    return;
                }
                fieldsList = this.array_move(fieldsList, index, index - 1);
            }
        }
    }

    moveSelectedItemsDown(event) {
        let array = event.currentTarget.dataset.array;
        let fieldsList = this[array];
        for (let index = fieldsList.length - 1; index >= 0; index--) {
            let element = fieldsList[index];
            if (element.isSelected) {
                if (index == fieldsList.length - 1) {
                    return;
                }
                fieldsList = this.array_move(fieldsList, index, index + 1);
            }
        }
    }

    array_move(arr, old_index, new_index) {
        if (new_index >= arr.length) {
            var k = new_index - arr.length + 1;
            while (k--) {
                arr.push(undefined);
            }
        }
        arr.splice(new_index, 0, arr.splice(old_index, 1)[0]);
        return arr; // for testing
    };

    moveSelectedItemsToRight(event) {
        let selectedArray = event.currentTarget.dataset.selectedArray;
        let availableArray = event.currentTarget.dataset.availableArray;
        let selectedFieldsList = this[selectedArray];
        let availableFieldsList = this[availableArray];
        let freeSpots;
        let newSelectedItems = availableFieldsList.filter(item => item.isSelected);
        newSelectedItems = newSelectedItems.slice(0, freeSpots);
        let newSelectedItemsApiNames = newSelectedItems.map(a => a.name);
        selectedFieldsList = [...selectedFieldsList, ...newSelectedItems];
        availableFieldsList = availableFieldsList.filter(item => !newSelectedItemsApiNames.includes(item.name));
        selectedFieldsList.forEach(item => item.isSelected = false);
        this[selectedArray] = [...selectedFieldsList];
        this[availableArray] = [...availableFieldsList];
    }

    moveSelectedItemsToLeft(event) {
        let selectedArray = event.currentTarget.dataset.selectedArray;
        let availableArray = event.currentTarget.dataset.availableArray;
        let selectedFieldsList = this[selectedArray];
        let availableFieldsList = this[availableArray];
        let newSelectedItems = selectedFieldsList.filter(item => item.isSelected);
        selectedFieldsList = selectedFieldsList.filter(item => !item.isSelected);
        availableFieldsList = [...availableFieldsList, ...newSelectedItems];
        availableFieldsList.forEach(item => item.isSelected = false);
        if (availableFieldsList.every(item => item.hasOwnProperty('label'))) {
            availableFieldsList.sort((a, b) => a.label.localeCompare(b.label))
        } else {
            availableFieldsList.sort((a, b) => a.name.localeCompare(b.name))
        }
        this[selectedArray] = [...selectedFieldsList];
        this[availableArray] = [...availableFieldsList];
    }

    handleSave(event) {
        try {
            this.isLoading = true;
            this.connectSettings.approvalProfiles = this.selectedApprovalProfiles.map(item => item.name);
            this.connectSettings.nonApprovalProfiles = this.selectedNonApprovalProfiles.map(item => item.name);
            this.connectSettings.sellInRevenueOptions = this.selectedSellinType.map(item => item.value);
            this.connectSettings.summaryFields = this.selectedSummaryFields.map(item => item.name);
            this.connectSettings.cardHeaderFields = this.selectedHeaderFields.map(item => item.name);
            this.connectSettings.additionalFields = this.selectedAdditionalFields.map(item => item.name);
            this.connectSettings.licenseQuotas = this.licenseQuotas;
            saveSettings({
                connectSettingsJSON: JSON.stringify(this.connectSettings)
            }).then(result => {
                this.checkDeployementStatus(result);
            }).catch(error => {
                this.showNotification('Error', error, 'error');
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
                        this.Loading = false;
                        clearInterval(interval);
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Request_Timed_Out, this.labels.MSG_Request_Timed_Out + ' ' + this.labels.MSG_Deploy_Last_Status + ' ' + status, 'info');
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Request_Timed_Out + ' ' + this.labels.MSG_Deploy_Last_Status + ' ' + status);
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            this.Loading = false;
                            clearInterval(interval);
                            if (success) {
                                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                                if (this.previousConnectSettings) {
                                    generateFileDirectorySharing({ previousConnectSettingsJSON: JSON.stringify(this.previousConnectSettings) });
                                    // Preserve previous settings
                                    this.previousConnectSettings = JSON.parse(JSON.stringify(this.connectSettings));
                                }
                            } else {
                                this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                this.Loading = false;
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                if (this.previousConnectSettings) {
                    generateFileDirectorySharing({ previousConnectSettingsJSON: JSON.stringify(this.previousConnectSettings) });
                    // Preserve previous settings
                    this.previousConnectSettings = JSON.parse(JSON.stringify(this.connectSettings));
                }
            }
        });
    }

    //PORTAL SETTINGS
    @track boardingList = [];
    @track settingsuserList = [];
    @track searchableObjects = [];
    @track objectDescriptions = [];
    objectDescriptionsAll = [];
    @track file;
    @track searchTerm = '';
    @track showFileInput = false;
    @track showUploadSection = false;
    @track showUploadSection = false;
    @track showCloudIcon = {
        portalFav: true,
        portalVideo: true,
        portalGuide: true,
    };
    @track PortalFavIcon;
    @track videoUrl = '';
    @track welcomeIcon = welcomeIcon;
    @track chatterIcon = chatterIcon;
    @track sortLeft = sortLeft;
    @track sortRight = sortRight;
    @track sortUp = sortUp;
    @track sortDown = sortDown;
    @track uploadCloud = uploadCloud;
    @track CustomSettingsLogo = `max-width:110px; height:40px; background-image: url('${CustomSettingsLogo}'); background-position: left center;`;
    @track showWelcomeSection = true;
    @track showChatterSettings = false;
    @track isMenuOpen = true;

    handleToggleBoarding(event) {
        this.connectSettings.enableSelfOnboarding = !this.connectSettings.enableSelfOnboarding;
        this.connectSettings.enableSelfOnboarding = event.target.checked;
    }

    handleToggleSettings(event) {
        this.connectSettings.enableUserSettings = !this.connectSettings.enableUserSettings;
        this.connectSettings.enableUserSettings = event.target.checked;
    }

    loadObjectDescriptions() {
        getObjectDescriptions().then(result => {
            this.objectDescriptions = result.map(obj => ({ ...obj, isSelected: false }));
            this.searchableObjects.forEach(element => {
                let index = this.objectDescriptions.findIndex(item => item.apiName == element.apiName);
                if (index > -1) {
                    element.label = this.objectDescriptions[index].label;
                    this.objectDescriptions.splice(index, 1);
                }
            })
            this.objectDescriptionsAll = JSON.parse(JSON.stringify(this.objectDescriptions));
        }).catch(error => {
            console.error('Error loading object descriptions', error);
        });
    }

    handleObjectSelection(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.objectDescriptions = this.objectDescriptions.map(obj => {
            if (obj.apiName === selectedId) {
                obj.isSelected = !obj.isSelected;
            }
            return obj;
        });
    }

    handleSearchableObjectSelection(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.searchableObjects = this.searchableObjects.map(obj => {
            if (obj.apiName === selectedId) {
                obj.isSelected = !obj.isSelected;
            }
            return obj;
        });
    }

    moveSelectedObjectsToRight() {
        const selectedObjects = this.objectDescriptions.filter(obj => obj.isSelected);
        this.searchableObjects = [...this.searchableObjects, ...selectedObjects];
        this.objectDescriptions = this.objectDescriptions.filter(obj => !obj.isSelected);
        this.objectDescriptionsAll = this.objectDescriptionsAll.filter(obj => !obj.isSelected);
        this.objectDescriptions.forEach(item => item.isSelected = false);
        this.objectDescriptionsAll.forEach(item => item.isSelected = false);
        this.searchableObjects.forEach(item => item.isSelected = false);
        selectedObjects.forEach(item => item.isSelected = false);
        this.connectSettings.searchableObjects = this.searchableObjects.map(item => item.apiName);
    }

    moveSelectedObjectsToLeft() {
        const selectedObjects = this.searchableObjects.filter(obj => obj.isSelected);
        this.objectDescriptions = [...this.objectDescriptions, ...selectedObjects];
        this.objectDescriptionsAll = [...this.objectDescriptionsAll, ...selectedObjects];
        this.searchableObjects = this.searchableObjects.filter(obj => !obj.isSelected);
        this.objectDescriptions.forEach(item => item.isSelected = false);
        this.objectDescriptionsAll.forEach(item => item.isSelected = false);
        this.searchableObjects.forEach(item => item.isSelected = false);
        selectedObjects.forEach(item => item.isSelected = false);
        this.connectSettings.searchableObjects = this.searchableObjects.map(item => item.apiName);
    }

    activateWelcome(event) {
        this.toggleActiveClass(event.target.closest('.negoptim-mainwelcom'));
        this.showWelcomeSection = true;
        this.showChatterSettings = false;
    }

    activateChatter(event) {
        this.toggleActiveClass(event.target.closest('.negoptim-mainchatter'));
        this.showWelcomeSection = false;
        this.showChatterSettings = true;
    }

    toggleActiveClass(element) {
        const currentActive = this.template.querySelector('.active');
        if (currentActive) {
            currentActive.classList.remove('active');
        }
        element.classList.add('active');
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        let field = event.target.dataset.field;
        if (uploadedFiles.length > 0) {
            const contentDocumentId = uploadedFiles[0].documentId;
            const fileName = uploadedFiles[0].name;
            if (field === 'logo') {
                return;
            }
            uploadFile({ contentDocumentId, fileName })
                .then(result => {
                    if (field === 'video') {
                        let videoElement = this.template.querySelector('video');
                        if (videoElement) {
                            this.connectSettings.onboardingVideoUrl = result;
                            this.videoUrl = result;
                            Promise.resolve().then(() => {
                                videoElement.load();
                            });
                        }
                    } else if (field === 'guide') {
                        this.connectSettings.guideDocUrl = result;
                        this.showCloudIcon.portalGuide = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Guide uploaded successfully.',
                                variant: 'success'
                            })
                        );
                    }
                })
                .catch(error => {
                    console.log('error.message', error);
                    this.showNotification('error :', error.message);
                });
        }
    }

    handleLogoFileSelect(event) {
        const file = event.target.files[0];
        if (!file) return;
        if (!file.type.startsWith('image/')) {
            this.showNotification('Error', 'Please select a valid image file.', 'error');
            return;
        }
        this.showSpinner = true;
        this.resizeImage(file, 150)
            .then(base64Image => {
                return uploadImagePortalFavIcon({
                    base64Image: base64Image,
                    imageName: file.name
                });
            })
            .then(result => {
                this.connectSettings.connectLogoIcon = result;
                this.logoUrl = result;
                this.PortalFavIcon = `max-width:300px; height:200px; background-position: center; background-image: url('${result}'); background-repeat: no-repeat; background-size: contain;`;
                this.showCloudIcon.portalFav = false;
                this.showSpinner = false;
            })
            .catch(error => {
                this.showNotification('Error', error.body?.message || error.message, 'error');
                this.showSpinner = false;
            });

        event.target.value = '';
    }

    resizeImage(file, targetHeight) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                const img = new Image();
                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    const aspectRatio = img.width / img.height;
                    canvas.height = targetHeight;
                    canvas.width = Math.round(targetHeight * aspectRatio);
                    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                    const base64 = canvas.toDataURL(file.type).split(',')[1];
                    resolve(base64);
                };
                img.onerror = () => {
                    reject(new Error('Failed to load image'));
                };
                img.src = e.target.result;
            };
            reader.onerror = () => {
                reject(new Error('Failed to read file'));
            };
            reader.readAsDataURL(file);
        });
    }

    downloadGuide() {
        const link = document.createElement('a');
        link.href = this.connectSettings.guideDocUrl;
        link.download = 'GuideDocument';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    handleSearch(event) {
        let searchTerm = event.target.value;
        this.searchTerm = searchTerm;
        if (searchTerm == null || searchTerm == '') {
            this.objectDescriptions = JSON.parse(JSON.stringify(this.objectDescriptionsAll));
            return;
        }
        this.objectDescriptions = this.objectDescriptionsAll.filter(obj => obj.label.toLowerCase().includes(searchTerm.toLowerCase()));
    }

    changeHeight = () => {
        try {
            const headerElement = this.template.querySelector('.settings-header');
            if (!headerElement) {
                setTimeout(() => this.changeHeight(), 110);
                return;
            }
            const viewportHeight = window.innerHeight;
            const headerHeight = headerElement.getBoundingClientRect().height;
            let mainPanelHeight = viewportHeight - headerHeight - 150;

            if (window.innerWidth < 980) {
                mainPanelHeight = viewportHeight - headerHeight - 190;
            }
            mainPanelHeight = Math.max(mainPanelHeight, 310);
            this.mainPanelHeight = `height: ${mainPanelHeight}px;`;
            console.log('Final height:', mainPanelHeight);
        } catch (error) {
            console.error('Error:', error);
            this.mainPanelHeight = 'height: calc(100vh - 200px);';
        }
    };

    //NOTIFICATIONS
    showNotification(title, message, variant) {
        this.isLoading = false;
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