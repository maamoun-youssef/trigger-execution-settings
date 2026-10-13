import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
// Services
import initData from "@salesforce/apex/NegoSettingsController.loadNegoSettings";
import save from "@salesforce/apex/NegoSettingsController.save";
import checkDeploymentStatus from "@salesforce/apex/NegoSettingsController.checkDeploymentStatus";
import locale from '@salesforce/i18n/lang';
import { showNotification } from 'c/appHelper';
//IMPORTS
import { labels, Contract_API, Contract_Discount_API, ProductDiscountStatement_API, ProductDiscountStatementDetail_API, RecordType_API, sellInConfigurationActions, PriceListStatement_API, PriceListStatementDetail_API } from './properties.js';

const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';
export default class NegoSettings extends NavigationMixin(LightningElement) {
    // handleDateChange(event) {
    //     const recordType = event.target.dataset.recordtype;
    //     const config = this.contractConsolidationConfigurationList.find(item => item.recordType === recordType);
    //     if (config) config.executionDate = event.target.value;
    // }

    handleIconClick(event) {
        const recordType = event.target.dataset.recordtype;
        const input = this.template.querySelector(`input[data-recordtype="${recordType}"]`);
        if (input) {
            input.showPicker?.() || input.click();
        }
    }

    handleDateChange(event) {
        const recordType = event.target.dataset.recordtype;
        const selectedDate = event.target.value;

        const config = this.contractConsolidationConfigurationList.find(item => item.recordType === recordType);
        if (config) {
            config.executionDate = selectedDate;
            config.formattedDate = this.formatDate(selectedDate);
        }
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const date = new Date(dateStr);
        const options = { day: 'numeric', month: 'long' };
        return date.toLocaleDateString(locale, options);
    }

    handleToggle(event) {
        const recordType = event.target.dataset.recordtype;
        const config = this.contractConsolidationConfigurationList.find(item => item.recordType === recordType);
        if (config) config.isActive = event.target.checked;
    }
    /* VARIABLES */
    mainPanelHeight;
    loading = false;
    isDefaultContractModelEditMode = false;
    SObjectMaps = {};
    contractRTMap = {};
    productDiscountStatementRTMap = {};
    priceListStatementRTMap = {};
    showRecordTypeConfig = false;
    /* TRACK VARIABLES */
    @track NEGO_SETTINGS_API = {
        NegoSettings__mdt: 'NegoSettings__mdt',
        ContractDuplicationConfiguration__c: 'ContractDuplicationConfiguration__c',
        ContractNameConfiguration__c: 'ContractNameConfiguration__c',
        ConditionManagerPageConfiguration__c: 'ConditionManagerPageConfiguration__c',
        ContractConsolidationConfiguration__c: 'ContractConsolidationConfiguration__c',
        ProductDiscountsConfiguration__c: 'ProductDiscountsConfiguration__c',
        PriceListStatementsConfiguration__c: 'PriceListStatementsConfiguration__c'
    }
    @track Contract_API = Contract_API;
    @track contractConsolidationConfigurationList = [];
    @track Contract_Discount_API = Contract_Discount_API;
    @track ProductDiscountStatement_API = ProductDiscountStatement_API;
    @track ProductDiscountStatementDetail_API = ProductDiscountStatementDetail_API;
    @track PriceListStatement_API = PriceListStatement_API;
    @track PriceListStatementDetail_API = PriceListStatementDetail_API;
    @track labels = {
        ...labels,
        LBL_myNego: 'my Nego',
        LBL_Nego_Settings: 'Nego Settings',
        defaultModelMSG: `Default Model: `,
        NegoSettings__mdt: {
            objectLabel: '',
            contractDuplicationConfigurationLabel: '',
            contractDuplicationConfigurationHelpText: '',
            contractNameConfigurationLabel: '',
            contractNameConfigurationHelpText: '',
            conditionManagerPageConfigurationLabel: '',
            conditionManagerPageConfigurationHelpText: '',
            contractConsolidationConfigurationLabel: '',
            contractConsolidationConfigurationHelpText: '',
            productDiscountsConfigurationLabel: '',
            productDiscountsConfigurationHelpText: '',
            priceListStatementsConfigurationLabel: '',
            priceListStatementsConfigurationHelpText: ''
        },
        Contract__c: {
            objectLabel: '',
            RecordTypeId: '',
            Status__c: '',
        },
        ProductDiscountStatement__c: {
            objectLabel: '',
            LoadPreferencePromoStatement__c: '',
        },
        PriceListStatement__c: {
            objectLabel: '',
        },
        RecordType: {
            objectLabel: '',
        },
    }
    @track gridSettingsLink = '';
    @track mainWrapper = {};
    @track negoSettings = {};
    @track sellInConfiguration = [];
    @track contractDuplicationConfigurationLines = [];
    @track contractNameConfigurations = {};
    @track newNameConfigurationsList = [];
    @track conditionManagerPageConfigurations = {
        DEFAULT: {},
        list: [],
    }
    @track productDiscountsConfigurationsList = []
    @track pdsNameConfigurations = {};
    @track newPDSNameConfigurationsList = [];
    @track isDefaultPDSModelEditMode = false;
    @track showPDSRecordTypeConfig = false;
    @track plsNameConfigurations = {};
    @track newPLSNameConfigurationsList = [];
    @track isDefaultPLSModelEditMode = false;
    @track showPLSRecordTypeConfig = false;
    @track loadPreferencePromoStatementInfoOpen = false;
    @track promoStatementTypeOptions = [];
    @track promoAgreementTypeOptions = [];
    @track showPDSConfigModal = false;
    @track newPDSConfig;
    @track loadedWireMethods = {
        recordTypeInfos: false,
        contractInfos: false,
        contractStatusValues: false,
        loadPreferencePromoStatementValues: false,
        promoStatementTypeValues: false,
        promoAgreementTypeValues: false,
    };
    /** Options variables */
    @track contractSourceStatusOptions = [];
    @track contractTargetStatusOptions = [];
    @track contractRecordTypesOptions = [];
    @track UnavailableSourceRTs = '';
    @track UnavailableTargetRTs = '';
    @track discountGridOptions = [];
    @track GridOptionsPDSD = [];
    @track importSettingsOptionsPDSD = [];
    @track loadPreferencePromoStatementOptions = [];
    @track priceListStatementsConfigurationsList = [];
    @track priceListStatementsRecordTypeOptions = [];
    @track defaultPriceListStatementRecordType;
    @track GridOptionsPLSD = [];
    @track importSettingsOptionsPLSD = [];
    @track negotiateConfig = {
        annualNegotiationRTs: {
            current: [],
            next: []
        },
        addendumNegotiationRTs: {
            current: [],
            next: []
        }
    };

    /* WIRES */
    @wire(getObjectInfo, { objectApiName: RecordType_API.RecordType }) wiredRecordTypeInfo({ data, error }) {
        if (data) {
            this.labels.RecordType.objectLabel = data.label;
            this.loadedWireMethods.recordTypeInfos = true;
            this.initData();
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: Contract_API.Contract__c }) wiredContractInfo({ data, error }) {
        if (data) {
            this.labels.Contract__c.objectLabel = data.label;
            this.loadedWireMethods.contractInfos = true;
            this.initData();
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: ProductDiscountStatement_API.objectApiName })
    wiredPDSInfo({ data, error }) {
        if (data) {
            this.labels.ProductDiscountStatement__c.objectLabel = data.label;
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: PriceListStatement_API.objectApiName })
    wiredPLSInfo({ data, error }) {
        if (data) {
            this.labels.PriceListStatement__c.objectLabel = data.label;
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Contract_API.Status__Field }) contractStatusPicklistValues({ error, data }) {
        if (data) {
            this.contractSourceStatusOptions.push({ label: this.labels.LBL_Any_Status, value: '' });
            for (let item of data.values) {
                this.contractSourceStatusOptions.push({ label: item.label, value: item.value });
                this.contractTargetStatusOptions.push({ label: item.label, value: item.value });
            }
            this.loadedWireMethods.contractStatusValues = true;
            this.initData();
        } else {
            console.log(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: ProductDiscountStatement_API.LoadPreferencePromoStatement_Field }) loadPreferencePromoStatementPicklistValues({ error, data }) {
        if (data) {
            this.loadPreferencePromoStatementOptions.push({ label: this.labels.LBL_None_Picklist_Value, value: '' });
            for (let item of data.values) {
                this.loadPreferencePromoStatementOptions.push({ label: item.label, value: item.value });
            }
            this.loadedWireMethods.loadPreferencePromoStatementValues = true;
            this.initData();
        } else {
            console.log(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: ProductDiscountStatement_API.PromoStatementType_Field }) loadPromoStatementTypePicklistValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                this.promoStatementTypeOptions.push({ label: item.label, value: item.value });
            }
            this.loadedWireMethods.promoStatementTypeValues = true;
            this.initData();
        } else {
            console.log(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: ProductDiscountStatement_API.PromoAgreementType_Field }) loadPromoAgreementTypePicklistValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                this.promoAgreementTypeOptions.push({ label: item.label, value: item.value });
            }
            this.loadedWireMethods.promoAgreementTypeValues = true;
            this.initData();
        } else {
            console.log(error);
        }
    }
    /* Getters */
    get contractNameConfigurationHasNoData() {
        return this.nameConfigurationsList.length == 0 && this.newNameConfigurationsList.length == 0;
    }
    get nameConfigurationsList() {
        let contractRTMap = this.contractRTMap;
        let contractNameConfigurations = this.contractNameConfigurations;
        return Object.keys(this.contractNameConfigurations).map(recordType => {
            return {
                recordType: recordType,
                label: contractRTMap[recordType],
                template: contractNameConfigurations[recordType].template,
                allowUpdate: contractNameConfigurations[recordType].allowUpdate,
            }
        }).filter(item => item.recordType != 'DEFAULT');
    };
    get pdsNameConfigurationHasNoData() {
        return this.pdsNameConfigurationsList.length === 0 && this.newPDSNameConfigurationsList.length === 0;
    }
    get pdsNameConfigurationsList() {
        const rtMap = this.productDiscountStatementRTMap || {};
        const cfg = this.pdsNameConfigurations || {};
        return Object.keys(cfg).map(rt => ({
            recordType: rt,
            label: rtMap[rt],
            template: cfg[rt]?.template,
            allowUpdate: cfg[rt]?.allowUpdate
        })).filter(row => row.recordType !== 'DEFAULT');
    }
    get plsNameConfigurationHasNoData() {
        return this.plsNameConfigurationsList.length === 0 && this.newPLSNameConfigurationsList.length === 0;
    }
    get plsNameConfigurationsList() {
        const rtMap = this.priceListStatementRTMap || {};
        const cfg = this.plsNameConfigurations || {};
        return Object.keys(cfg).map(rt => ({
            recordType: rt,
            label: rtMap[rt],
            template: cfg[rt]?.template,
            allowUpdate: cfg[rt]?.allowUpdate
        })).filter(row => row.recordType !== 'DEFAULT');
    }

    get isPdsConfigModalPromoRecordType() {
        return this.newPDSConfig.recordType === 'Promo';
    }

    get availablePDSRecordTypesForModal() {
        const usedRecordTypes = this.productDiscountsConfigurationsList.map(item => item.recordType);
        const baseUsedRTs = new Set();
        // Track non-Promo record types that are already used
        usedRecordTypes.forEach(rt => {
            if (rt !== 'Promo' && !rt.startsWith('Promo_')) {
                baseUsedRTs.add(rt);
            }
        });
        const promoConfigKeys = this.productDiscountsConfigurationsList.filter(item => item.recordType.startsWith('Promo_')).map(item => item.recordType);
        const statementTypeCount = this.promoStatementTypeOptions.filter(o => o.value).length;
        const agreementTypeCount = this.promoAgreementTypeOptions.filter(o => o.value).length;
        const maxPromoConfigs = statementTypeCount * agreementTypeCount;
        const promoFullyConfigured = promoConfigKeys.length >= maxPromoConfigs && maxPromoConfigs > 0;

        return Object.keys(this.productDiscountStatementRTMap)
            .filter(rt => {
                // Exclude non-Promo RTs that are already used
                if (baseUsedRTs.has(rt)) {
                    return false;
                }
                // Include Promo if not all combinations are configured
                if (rt === 'Promo') {
                    return !promoFullyConfigured;
                }
                return true;
            })
            .map(rt => ({
                label: this.productDiscountStatementRTMap[rt],
                value: rt
            }));
    }

    get isAddPDSConfigDisabled() {
        return this.availablePDSRecordTypesForModal.length === 0;
    }

    get isPDSConfigModalConfirmDisabled() {
        if (!this.newPDSConfig.recordType) {
            return true;
        }
        if (this.newPDSConfig.recordType === 'Promo') {
            return !this.newPDSConfig.promoStatementType || !this.newPDSConfig.promoAgreementType;
        }
        return false;
    }

    get availablePromoStatementTypeOptions() {
        if (!this.newPDSConfig.promoAgreementType) {
            return this.promoStatementTypeOptions;
        }
        const usedStatementTypes = this.productDiscountsConfigurationsList.filter(item => item.recordType.startsWith('Promo_') && item.promoAgreementType === this.newPDSConfig.promoAgreementType).map(item => item.promoStatementType);
        return this.promoStatementTypeOptions.filter(opt => !usedStatementTypes.includes(opt.value));
    }

    get availablePromoAgreementTypeOptions() {
        if (!this.newPDSConfig.promoStatementType) {
            return this.promoAgreementTypeOptions;
        }
        const usedAgreementTypes = this.productDiscountsConfigurationsList.filter(item => item.recordType.startsWith('Promo_') && item.promoStatementType === this.newPDSConfig.promoStatementType).map(item => item.promoAgreementType);
        return this.promoAgreementTypeOptions.filter(opt => !usedAgreementTypes.includes(opt.value));
    }

    connectedCallback() {
        Promise.all([]).then(() => {
            console.log('loading style success');
        }).catch(error => {
            console.log('error loading style');
        });
        window.addEventListener('resize', this.changeHeight);
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `
            .slds-vertical-tabs__nav-item.slds-is-active {
                background: white;
                color: #806BBF;
                height: 60px;
                width: 230px;
            }
            .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            .slds-vertical-tabs__nav-item {
                background: #806BBF;
                height: 60px;
                width: 230px;
                border-bottom: 2px solid white;
            }
            .slds-vertical-tabs__nav-item .slds-icon {
                --slds-c-icon-color-foreground: white;
            }
            .slds-vertical-tabs__link {
                color: white;
                font-size: 14px;
                height: 60px;
                font-weight: 600;
            }
            .slds-vertical-tabs__link:hover {
                background: #806BBF;
            }
            .slds-vertical-tabs__nav-item:hover {
                background: white;
                color: #806BBF;
            }
            .slds-vertical-tabs__nav-item:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            .slds-vertical-tabs__nav-item a:hover,
            .slds-vertical-tabs__nav-item a:focus {
                color: #806BBF;
                background: white;
            }
            .slds-vertical-tabs {
                border-radius: 0px 0px 0px 5px;
                border: none;
            }
            .slds-vertical-tabs__left-icon {
                --slds-c-icon-color-foreground-default: white;
            }
            lightning-tab-bar {
                width: 230px;
                background: #806BBF;
            }
            .slds-vertical-tabs__nav {
            width: var(--lwc-sizeXSmall, 12rem);
            border-right: var(--lwc-borderWidthThin, 1px) solid var(--slds-g-color-border-base-1, var(--lwc-colorBorder, rgb(229, 229, 229))); 
            background: var(--slds-g-color-neutral-base-95, var(--lwc-colorBackground, rgb(243, 243, 243)));
            }

            @media screen and (max-width: 980px) {
                .slds-vertical-tabs__nav-item.slds-is-active {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                .slds-vertical-tabs__nav-item {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                .slds-vertical-tabs__link {
                    font-size: 13px;
                    font-weight: 400;
                    height: 60px;
                }
                lightning-tab-bar {
                    width: 190px;
                }
                .slds-vertical-tabs__nav {
                border-right: none;
                background: none;
                }
            }
        `;
        document.body.appendChild(tabStyle);
        const tabStyleHover = document.createElement('style');
        tabStyleHover.innerText = `
            .tab-set-style a:hover {
                color: #806BBF;
                background-color: white;
                text-decoration: none;
            }
            .tab-set-style a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a {
                color: #806BBF;
                font-weight: 600;
            }
            .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover {
                color: #806BBF;
            }
            .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            .slds-tabs_default__item:hover .slds-tabs_default__link {
                color: black;
            }
        `;
        document.body.appendChild(tabStyleHover);
    }


    renderedCallback() {
        if (this.template.querySelector('.settings-header')) {
            this.changeHeight();
        }
    }

    //LOAD
    initData() {
        try {
            if (Object.values(this.loadedWireMethods).every(it => it)) {
                this.loading = true;
                initData().then((result) => {
                    let parsedResult = JSON.parse(result);
                    this.afterLoad(parsedResult);
                })
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleChangePriceListStatementsConfigurations(event) {
        let index = event.target.dataset.index;
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.priceListStatementsConfigurationsList[index][field] = value;
    }


    afterLoad(mainWrapper) {
        try {
            const allowedRecordTypes = ['Nego_Base', 'Nego_Base_Init', 'Landing'];
            this.contractConsolidationConfigurationList = [];
            const existingConsoMap = mainWrapper.negoSettings?.contractConsolidationConfiguration || {};
            for (let recordType in mainWrapper.contractRTMap) {
                if (allowedRecordTypes.includes(recordType)) {
                    let config = existingConsoMap[recordType] || { isActive: false, executionDate: null };

                    this.contractConsolidationConfigurationList.push({
                        recordType: recordType,
                        label: mainWrapper.contractRTMap[recordType],
                        isActive: config.isActive,
                        executionDate: config.executionDate,
                        formattedDate: this.formatDate(config.executionDate)
                    });
                }
            }
            this.NEGO_SETTINGS_API = {
                NegoSettings__mdt: mainWrapper.prefix + 'NegoSettings__mdt',
                ContractDuplicationConfiguration__c: mainWrapper.prefix + 'ContractDuplicationConfiguration__c',
                ContractNameConfiguration__c: mainWrapper.prefix + 'ContractNameConfiguration__c',
                ConditionManagerPageConfiguration__c: mainWrapper.prefix + 'ConditionManagerPageConfiguration__c',
                ContractConsolidationConfiguration__c: mainWrapper.prefix + 'ContractConsolidationConfiguration__c',
                ProductDiscountsConfiguration__c: mainWrapper.prefix + 'ProductDiscountsConfiguration__c',
                PriceListStatementsConfiguration__c: mainWrapper.prefix + 'PriceListStatementsConfiguration__c'
            }
            this.contractRTMap = mainWrapper.contractRTMap;
            this.productDiscountStatementRTMap = mainWrapper.productDiscountStatementRTMap;
            this.priceListStatementRTMap = mainWrapper.priceListStatementRTMap;
            this.gridSettingsLink = '/lightning/n/' + mainWrapper.prefix + 'Grid_Settings_Manager';
            //SET UP OPTIONS
            for (let [key, value] of Object.entries(mainWrapper.contractRTMap)) {
                this.contractRecordTypesOptions.push({ label: value, value: key });
            }
            //SET UP NEGO SETTINGS
            this.negoSettings = mainWrapper.negoSettings || {};
            if (this.negoSettings) {
                // SET UP CONTRACT NAMES CONFIGURATION
                if (this.negoSettings.contractNameConfiguration) {
                    this.contractNameConfigurations = this.negoSettings.contractNameConfiguration;
                } else {
                    this.contractNameConfigurations = {};
                }
                if (this.contractNameConfigurations && !this.contractNameConfigurations.hasOwnProperty('DEFAULT')) {
                    this.contractNameConfigurations['DEFAULT'] = {
                        template: '',
                        allowUpdate: true,
                    }
                }

                if (this.negoSettings.sellInConfiguration && this.negoSettings.sellInConfiguration?.length > 0) {
                    this.sellInConfiguration = this.negoSettings?.sellInConfiguration.map(e => {
                        e.name = this.labels[e.sellInName]
                        return e
                    })
                } else {
                    const sellInConfiguration = sellInConfigurationActions.map((item, index) => {
                        return {
                            colNumber: index + 1,
                            sellInKey: item.replace("LBL_", ""),
                            sellInName: item,
                            name: this.labels[item],
                            isActive: false,
                            isEdit: false
                        }
                    })
                    this.sellInConfiguration = sellInConfiguration;
                    console.log(this.sellInConfiguration)
                }
                this.showRecordTypeConfig = this.nameConfigurationsList.length > 0;
                // SET UP ConditionManagerPage CONFIGURATION
                this.conditionManagerPageConfigurations = {
                    DEFAULT: {},
                    list: [],
                }
                if (this.negoSettings.conditionManagerPageConfiguration && this.negoSettings.conditionManagerPageConfiguration.gridsConfiguration) {
                    for (let recordType in this.negoSettings.conditionManagerPageConfiguration.gridsConfiguration) {
                        let conditionManagerPageConfigurations = this.negoSettings.conditionManagerPageConfiguration.gridsConfiguration[recordType];
                        if (recordType != 'DEFAULT') {
                            let setting = {
                                recordType: recordType,
                                label: this.contractRTMap[recordType],
                                mainGridSettings: conditionManagerPageConfigurations.mainGridSettings,
                                subDiscountGridSettings: conditionManagerPageConfigurations.subDiscountGridSettings,
                                showSubDiscountColumn: conditionManagerPageConfigurations.showSubDiscountColumn,
                            }
                            this.conditionManagerPageConfigurations.list.push(setting)
                        } else {
                            this.conditionManagerPageConfigurations.DEFAULT = conditionManagerPageConfigurations;
                        }
                    }
                }
                if (this.conditionManagerPageConfigurations.DEFAULT == {}) {
                    this.conditionManagerPageConfigurations.DEFAULT = {
                        mainGridSettings: '',
                        subDiscountGridSettings: '',
                        showSubDiscountColumn: false,
                    }
                }
                console.log('this.conditionManagerPageConfigurations >>> ' + JSON.stringify(this.conditionManagerPageConfigurations))
                const pdsCfg = this.negoSettings.productDiscountsConfiguration || {};
                this.pdsNameConfigurations = pdsCfg.nameConfiguration || {};
                if (!this.pdsNameConfigurations.hasOwnProperty('DEFAULT')) {
                    this.pdsNameConfigurations['DEFAULT'] = { template: '', allowUpdate: false };
                }
                this.showPDSRecordTypeConfig = Object.keys(this.pdsNameConfigurations).some(k => k !== 'DEFAULT');
                const plsCfg = this.negoSettings.priceListStatementsConfiguration || {};
                this.defaultPriceListStatementRecordType = plsCfg.defaultPriceListStatementRecordType;
                this.plsNameConfigurations = plsCfg.nameConfiguration || {};
                if (!this.plsNameConfigurations.hasOwnProperty('DEFAULT')) {
                    this.plsNameConfigurations['DEFAULT'] = { template: '', allowUpdate: false };
                }
                this.showPLSRecordTypeConfig = Object.keys(this.plsNameConfigurations).some(k => k !== 'DEFAULT');
                this.productDiscountsConfigurationsList = [];
                const pdsConfigMap = this.negoSettings.productDiscountsConfiguration?.productDiscountsConfigurationMap || {};
                // Load saved configurations
                for (let configKey in pdsConfigMap) {
                    const savedConfig = pdsConfigMap[configKey];
                    let label = '';
                    let promoStatementType = '';
                    let promoAgreementType = '';
                    if (configKey.startsWith('Promo_')) {
                        const parts = configKey.split('_');
                        if (parts.length >= 3) {
                            promoStatementType = parts[1];
                            promoAgreementType = parts.slice(2).join('_');
                            const statementTypeLabel = this.promoStatementTypeOptions.find(o => o.value === promoStatementType)?.label || promoStatementType;
                            const agreementTypeLabel = this.promoAgreementTypeOptions.find(o => o.value === promoAgreementType)?.label || promoAgreementType;
                            label = `Promo - ${statementTypeLabel} - ${agreementTypeLabel}`;
                        } else {
                            label = configKey;
                        }
                    } else if (this.productDiscountStatementRTMap[configKey]) {
                        label = this.productDiscountStatementRTMap[configKey];
                    } else {
                        label = configKey;
                    }
                    const pdsConfig = {
                        recordType: configKey,
                        label: label,
                        promoStatementType: promoStatementType || savedConfig.promoStatementType || '',
                        promoAgreementType: promoAgreementType || savedConfig.promoAgreementType || '',
                        gridSettings: savedConfig.gridSettings || '',
                        communityGridSettings: savedConfig.communityGridSettings || '',
                        importSettings: savedConfig.importSettings || '',
                        communityImportSettings: savedConfig.communityImportSettings || ''
                    };
                    this.productDiscountsConfigurationsList.push(pdsConfig);
                }
                // SET UP Price List Statement CONFIGURATION
                this.priceListStatementsConfigurationsList = [];
                for (let recordType in mainWrapper.priceListStatementRTMap) {
                    let pls = {};
                    if (!this.negoSettings.priceListStatementsConfiguration || !this.negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap || !this.negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap.hasOwnProperty(recordType)) {
                        pls = {
                            recordType: recordType,
                            label: mainWrapper.priceListStatementRTMap[recordType],
                            gridSettings: '',
                            communityGridSettings: '',
                            importSettings: '',
                            communityImportSettings: ''
                        }
                    } else {
                        let m = this.negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap[recordType];
                        pls = {
                            recordType: recordType,
                            label: mainWrapper.priceListStatementRTMap[recordType],
                            gridSettings: m.gridSettings,
                            communityGridSettings: m.communityGridSettings,
                            importSettings: m.importSettings,
                            communityImportSettings: m.communityImportSettings
                        }
                    }
                    this.priceListStatementsConfigurationsList.push(pls);
                    this.priceListStatementsRecordTypeOptions.push({ label: mainWrapper.priceListStatementRTMap[recordType], value: recordType });
                }

                this.GridOptionsPLSD = [];
                if (mainWrapper.gridSettingsLayoutsMap && mainWrapper.gridSettingsLayoutsMap[this.PriceListStatementDetail_API.objectApiName]) {
                    for (let option in mainWrapper.gridSettingsLayoutsMap[this.PriceListStatementDetail_API.objectApiName]) {
                        this.GridOptionsPLSD.push({
                            label: mainWrapper.gridSettingsLayoutsMap[this.PriceListStatementDetail_API.objectApiName][option].label,
                            value: mainWrapper.gridSettingsLayoutsMap[this.PriceListStatementDetail_API.objectApiName][option].value
                        });
                    }
                }

                this.importSettingsOptionsPLSD = [];
                if (mainWrapper.importSettingsMap && mainWrapper.importSettingsMap[this.PriceListStatementDetail_API.objectApiName]) {
                    for (let option in mainWrapper.importSettingsMap[this.PriceListStatementDetail_API.objectApiName]) {
                        this.importSettingsOptionsPLSD.push({
                            label: mainWrapper.importSettingsMap[this.PriceListStatementDetail_API.objectApiName][option].label,
                            value: mainWrapper.importSettingsMap[this.PriceListStatementDetail_API.objectApiName][option].value
                        });
                    }
                }

                // Negotiate Page Configuration Section
                if (this.negoSettings.negotiatePageConfiguration) {
                    this.negotiateConfig = {
                        annualNegotiationRTs: {
                            current: this.negoSettings.negotiatePageConfiguration.annualNegotiationRTs?.current || [],
                            next: this.negoSettings.negotiatePageConfiguration.annualNegotiationRTs?.next || []
                        },
                        addendumNegotiationRTs: {
                            current: this.negoSettings.negotiatePageConfiguration.addendumNegotiationRTs?.current || [],
                            next: this.negoSettings.negotiatePageConfiguration.addendumNegotiationRTs?.next || []
                        }
                    };
                }

                //SET UP OPTIONS
                let gridSettingsLayoutsMap = mainWrapper.gridSettingsLayoutsMap;
                this.discountGridOptions = [];
                this.GridOptionsPDSD = [];
                if (gridSettingsLayoutsMap) {
                    for (let objectName in gridSettingsLayoutsMap) {
                        if (objectName == this.Contract_Discount_API.Contract_Discount__c) {
                            for (let option in gridSettingsLayoutsMap[objectName]) {
                                this.discountGridOptions.push({
                                    label: gridSettingsLayoutsMap[objectName][option].label,
                                    value: gridSettingsLayoutsMap[objectName][option].value
                                });
                            }
                        }
                        if (objectName == this.ProductDiscountStatementDetail_API.objectApiName) {
                            for (let option in gridSettingsLayoutsMap[objectName]) {
                                this.GridOptionsPDSD.push({
                                    label: gridSettingsLayoutsMap[objectName][option].label,
                                    value: gridSettingsLayoutsMap[objectName][option].value
                                });
                            }
                        }
                    }
                }
                let importSettingsMap = mainWrapper.importSettingsMap;
                if (importSettingsMap) {
                    for (let objectName in importSettingsMap) {
                        if (objectName == this.ProductDiscountStatementDetail_API.objectApiName) {
                            for (let option in importSettingsMap[objectName]) {
                                this.importSettingsOptionsPDSD.push({
                                    label: importSettingsMap[objectName][option].label,
                                    value: importSettingsMap[objectName][option].value
                                });
                            }
                        }
                    }
                }
            }
            // //SET UP LABELS
            this.setlabels(mainWrapper.fieldsMap);
            // SET UP Contract Duplication Configuration
            this.loadContractDuplicationConfiguration();
            this.mainWrapper = mainWrapper;
            this.loading = false;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    setlabels(fieldsMap) {
        let settingsApiName = this.NEGO_SETTINGS_API.NegoSettings__mdt.replace('__c', '__mdt');
        this.labels.NegoSettings__mdt.contractDuplicationConfigurationLabel = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ContractDuplicationConfiguration__c].label;
        this.labels.NegoSettings__mdt.contractDuplicationConfigurationHelpText = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ContractDuplicationConfiguration__c].inlineHelpText;
        this.labels.NegoSettings__mdt.contractNameConfigurationLabel = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ContractNameConfiguration__c].label;
        this.labels.NegoSettings__mdt.contractNameConfigurationHelpText = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ContractNameConfiguration__c].inlineHelpText;
        this.labels.NegoSettings__mdt.conditionManagerPageConfigurationLabel = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ConditionManagerPageConfiguration__c].label;
        this.labels.NegoSettings__mdt.conditionManagerPageConfigurationHelpText = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ConditionManagerPageConfiguration__c].inlineHelpText;
        this.labels.NegoSettings__mdt.contractConsolidationConfigurationLabel = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ContractConsolidationConfiguration__c].label;
        this.labels.NegoSettings__mdt.contractConsolidationConfigurationHelpText = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ContractConsolidationConfiguration__c].inlineHelpText;
        this.labels.NegoSettings__mdt.productDiscountsConfigurationLabel = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ProductDiscountsConfiguration__c].label;
        this.labels.NegoSettings__mdt.productDiscountsConfigurationHelpText = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.ProductDiscountsConfiguration__c].inlineHelpText;
        this.labels.NegoSettings__mdt.priceListStatementsConfigurationLabel = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.PriceListStatementsConfiguration__c].label;
        this.labels.NegoSettings__mdt.priceListStatementsConfigurationHelpText = fieldsMap[settingsApiName][this.NEGO_SETTINGS_API.PriceListStatementsConfiguration__c].inlineHelpText;
        this.labels.Contract__c.RecordTypeId = fieldsMap[Contract_API.Contract__c][Contract_API.RecordTypeId].label;
        this.labels.Contract__c.Status__c = fieldsMap[Contract_API.Contract__c][Contract_API.Status__c].label;
        this.labels.ProductDiscountStatement__c.LoadPreferencePromoStatement__c = fieldsMap[ProductDiscountStatement_API.objectApiName][ProductDiscountStatement_API.LoadPreferencePromoStatement__c].label;
    }

    refreshPage() {
        this.contractDuplicationConfigurationLines = this.contractDuplicationConfigurationLines.map(item => item);
        this.refreshRTs();
    }

    refreshRTs() {
        let selectedSourceContracts = this.contractDuplicationConfigurationLines.map(item => item.recordType);
        this.UnavailableSourceRTs = this.contractRecordTypesOptions.filter(RT => !selectedSourceContracts.includes(RT.value)).map(RT => RT.label).join(', ');

        let selectedTargetContracts = [];
        this.contractDuplicationConfigurationLines.forEach(row => {
            let selectedTargets = row.targetContractDuplications.filter(target => !selectedTargetContracts.includes(target.recordType)).map(target => target.recordType);
            selectedTargets.forEach(RT => {
                selectedTargetContracts.push(RT);
            })
        });
        this.UnavailableTargetRTs = this.contractRecordTypesOptions.filter(RT => !selectedTargetContracts.includes(RT.value)).map(RT => RT.label).join(', ');
    }


    handleSellInConfigurationActivation(event) {
        const index = event.target.dataset.index;
        const checked = event.target.checked;
        this.sellInConfiguration[index].isActive = checked;
        if (!checked) {
            this.sellInConfiguration[index].isEdit = checked;
        }
        this.sellInConfiguration = [...this.sellInConfiguration];
    }

    handleSellInConfigurationEdit(event) {
        const index = event.target.dataset.index;
        const checked = event.target.checked;
        if (checked) {
            this.sellInConfiguration[index].isEdit = checked;
            this.sellInConfiguration[index].isActive = checked;
        } else {
            this.sellInConfiguration[index].isEdit = checked;
        }
        this.sellInConfiguration = [...this.sellInConfiguration];
    }

    /* CONTRACT DUPLICATION SECTION */
    loadContractDuplicationConfiguration() {
        let self = this;
        if (this.negoSettings.contractDuplicationConfiguration) {
            this.negoSettings.contractDuplicationConfiguration.forEach(item => {
                let row = {
                    recordType: item.recordType,
                    status: item.status,
                    targetContractDuplications: [],
                    handleChange(event) {
                        let field = event.target.dataset.field;
                        let value = event.target.value;
                        row[field] = value;
                    },
                    createNewTargetRow() {
                        let newTargetRow = {
                            recordType: '',
                            status: '',
                            isDuplicated: false,
                            targetAvailableRTs: [],
                            get getClass() {
                                return newTargetRow.isDuplicated ? 'errorDuplicationTarget' : '';
                            },
                            handleChange(event) {
                                let field = event.target.dataset.field;
                                let value = event.target.value;
                                newTargetRow[field] = value;
                                row.checkAvailableContracts();
                            }
                        }
                        let selectedRTs = row.targetContractDuplications.map(item => item.recordType)
                        newTargetRow.targetAvailableRTs = [...self.contractRecordTypesOptions].filter(item => !selectedRTs.includes(item.value))
                        row.targetContractDuplications.push(newTargetRow);
                    },
                    checkAvailableContracts() {
                        let selectedRTs = row.targetContractDuplications.map(item => item.recordType)
                        row.targetContractDuplications.forEach(target => {
                            target.targetAvailableRTs = [...self.contractRecordTypesOptions].filter(item => !selectedRTs.includes(item.value) || item.value == target.recordType)
                        })
                        self.refreshPage();
                    }
                }
                if (item.targetContracts) {
                    item.targetContracts.forEach(targetContract => {
                        let newTargetRow = {
                            recordType: targetContract.recordType,
                            status: targetContract.status,
                            isDuplicated: false,
                            targetAvailableRTs: [],
                            get getClass() {
                                return newTargetRow.isDuplicated ? 'errorDuplicationTarget' : '';
                            },
                            handleChange(event) {
                                let field = event.target.dataset.field;
                                let value = event.target.value;
                                newTargetRow[field] = value;
                                row.checkAvailableContracts();
                            }
                        }
                        row.targetContractDuplications.push(newTargetRow);
                    });
                }
                row.checkAvailableContracts();
                this.contractDuplicationConfigurationLines.push(row);
            });
        }
    }

    get hasContractDuplicationConfigurationLines() {
        return this.contractDuplicationConfigurationLines && this.contractDuplicationConfigurationLines.length > 0;
    }

    handleAddSourceContractDuplication(event) {
        try {
            this.contractDuplicationConfigurationLines.push(this.addSourceContractDuplicationLine());
        } catch (error) {
            console.log(error.message);
        }
    }

    addSourceContractDuplicationLine() {
        let self = this;
        let row = {
            recordType: '',
            status: '',
            targetContractDuplications: [],
            handleChange(event) {
                let field = event.target.dataset.field;
                let value = event.target.value;
                row[field] = value
            },
            createNewTargetRow() {
                let newTargetRow = {
                    recordType: '',
                    status: '',
                    targetAvailableRTs: [],
                    get getClass() {
                        return newTargetRow.isDuplicated ? 'errorDuplicationTarget' : '';
                    },
                    handleChange(event) {
                        let field = event.target.dataset.field;
                        let value = event.target.value;
                        newTargetRow[field] = value;
                        row.checkAvailableContracts();
                    }
                }
                let selectedRTs = row.targetContractDuplications.map(item => item.recordType)
                newTargetRow.targetAvailableRTs = [...self.contractRecordTypesOptions].filter(item => !selectedRTs.includes(item.value))
                row.targetContractDuplications.push(newTargetRow);
            },
            checkAvailableContracts() {
                let selectedRTs = row.targetContractDuplications.map(item => item.recordType)
                row.targetContractDuplications.forEach(target => {
                    target.targetAvailableRTs = [...self.contractRecordTypesOptions].filter(item => !selectedRTs.includes(item.value) || item.value == target.recordType)
                })
                self.refreshPage();
            }
        }
        row.createNewTargetRow();
        return row;
    }

    addTargetContractDuplicationRow(event) {
        try {
            let index = event.target.dataset.index;
            let row = this.contractDuplicationConfigurationLines[index];
            row.createNewTargetRow();
            this.refreshPage();
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, self.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    checkForDuplication() {
        let duplicationMap = {}, key = '';
        for (let item of this.contractDuplicationConfigurationLines) {
            key = item.recordType + '-' + item.status;
            if (!duplicationMap.hasOwnProperty(key)) {
                Object.defineProperty(duplicationMap, key, {
                    enumerable: true,
                    configurable: true,
                    writable: true,
                    value: [],
                });
            }
            duplicationMap[key].push(item);
        }
        for (let item of Object.keys(duplicationMap)) {
            if (duplicationMap[item].length > 1) {
                for (let item2 of duplicationMap[item]) {
                    item2.isDuplicated = true;
                    return true;
                }
            } else if (duplicationMap[item].length == 1) {
                duplicationMap[item][0].isDuplicated = false;
            }
        }
    }

    handleDeleteContractDuplication(event) {
        let index = event.target.dataset.index;
        this.contractDuplicationConfigurationLines.splice(index, 1);
    }

    handleDeleteTargetContractDuplication(event) {
        let index = event.target.dataset.index;
        let targetIndex = event.target.dataset.targetIndex;
        this.contractDuplicationConfigurationLines[index].targetContractDuplications.splice(targetIndex, 1);
    }
    /*  */
    /* NAME CONFIG SECTION */
    /*  */
    handleOnChangeModel(event) {
        this.contractNameConfigurations[event.target.dataset.recordType].template = event.detail.value;
    }

    handleOnChangeAllowNameUpdate(event) {
        this.contractNameConfigurations[event.target.dataset.recordType].allowUpdate = event.detail.checked;
    }

    addContractNameConfig() {
        let self = this;
        let newRow = {
            recordType: '',
            get contractRecordTypeOptions() {
                try {
                    return Object.keys(self.contractRTMap).map(key => {
                        return { value: key, label: self.contractRTMap[key] };
                    }).filter(op => {
                        let newRts = self.newNameConfigurationsList.map(item => item.recordType);
                        return !self.contractNameConfigurations.hasOwnProperty(op.value) && (!newRts.includes(op.value) || this.recordType == op.value);
                    });
                } catch (error) {
                    console.log('%c' + error.message ? error.message : error.body?.message);
                    showNotification(self, self.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
                }
            },
            label: '',
            template: '',
            allowUpdate: false
        };
        this.newNameConfigurationsList.push(newRow);
    }

    handleShowRecordTypeConfig(event) {
        this.showRecordTypeConfig = !this.showRecordTypeConfig;
    }

    handleNewOnChangeAllowNameUpdate(event) {
        let index = event.target.dataset.index;
        this.newNameConfigurationsList[index].allowUpdate = event.target.checked;
    }

    handleNewContractNameOnChangeRT(event) {
        try {
            let index = event.target.dataset.index;
            this.newNameConfigurationsList[index].recordType = event.target.value;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleNewOnChangeModel(event) {
        let index = event.target.dataset.index;
        this.newNameConfigurationsList[index].template = event.target.value;
    }

    handleDeleteContractNameConfig(event) {
        delete this.contractNameConfigurations[event.target.dataset.recordType];
    }

    handleDeleteNewContractNameConfig(event) {
        let index = event.target.dataset.index;
        this.newNameConfigurationsList.splice(index, 1);
    }

    handleChangeContractDefaultModel(event) {
        this.contractNameConfigurations['DEFAULT'].template = event.target.value;
    }

    toggleDefaultContractEditMode() {
        this.isDefaultContractModelEditMode = !this.isDefaultContractModelEditMode;
    }
    toggleDefaultPDSEditMode() {
        this.isDefaultPDSModelEditMode = !this.isDefaultPDSModelEditMode;
    }
    handleShowPDSRecordTypeConfig() {
        this.showPDSRecordTypeConfig = !this.showPDSRecordTypeConfig;
    }
    handleChangePDSDefaultModel(event) {
        if (!this.pdsNameConfigurations.DEFAULT) {
            this.pdsNameConfigurations.DEFAULT = { template: '', allowUpdate: false };
        }
        this.pdsNameConfigurations.DEFAULT.template = event.target.value;
    }
    // PDS name template handlers
    addPDSNameConfig() {
        const self = this;
        const newRow = {
            uid: Math.random().toString(36).slice(2),
            recordType: '',
            get pdsRecordTypeOptions() {
                try {
                    const used = [
                        ...Object.keys(self.pdsNameConfigurations).filter(k => k !== 'DEFAULT'),
                        ...self.newPDSNameConfigurationsList.map(x => x.recordType)
                    ];
                    return Object.keys(self.productDiscountStatementRTMap).map(key => ({
                        value: key, label: self.productDiscountStatementRTMap[key]
                    })).filter(op => !used.includes(op.value) || this.recordType === op.value);
                } catch (error) {
                    console.log('%c' + (error.message ? error.message : error.body?.message));
                    showNotification(self, self.labels.LBL_Error, (error.message ? error.message : error.body?.message), 'error', 'sticky');
                }
            },
            label: '',
            template: '',
            allowUpdate: false
        };
        this.newPDSNameConfigurationsList.push(newRow);
    }
    handleNewPDSOnChangeRT(event) {
        const idx = event.target.dataset.index;
        this.newPDSNameConfigurationsList[idx].recordType = event.target.value;
    }
    handleNewPDSOnChangeModel(event) {
        const idx = event.target.dataset.index;
        this.newPDSNameConfigurationsList[idx].template = event.target.value;
    }
    handleNewPDSOnChangeAllowNameUpdate(event) {
        const idx = event.target.dataset.index;
        this.newPDSNameConfigurationsList[idx].allowUpdate = event.target.checked;
    }
    handleDeleteNewPDSNameConfig(event) {
        const idx = event.target.dataset.index;
        this.newPDSNameConfigurationsList.splice(idx, 1);
        this.newPDSNameConfigurationsList = [...this.newPDSNameConfigurationsList];
    }
    handlePDSOnChangeModel(event) {
        const rt = event.target.dataset.recordType;
        if (!this.pdsNameConfigurations[rt]) this.pdsNameConfigurations[rt] = { template: '', allowUpdate: false };
        this.pdsNameConfigurations[rt].template = event.detail ? event.detail.value : event.target.value;
    }
    handlePDSOnChangeAllowNameUpdate(event) {
        const rt = event.target.dataset.recordType;
        if (!this.pdsNameConfigurations[rt]) this.pdsNameConfigurations[rt] = { template: '', allowUpdate: false };
        this.pdsNameConfigurations[rt].allowUpdate = event.detail ? event.detail.checked : event.target.checked;
    }
    handleDeletePDSNameConfig(event) {
        const rt = event.target.dataset.recordType;
        delete this.pdsNameConfigurations[rt];
    }
    // Change PLS RecordType
    handleChangePLSDefaultRT(event) {
        this.defaultPriceListStatementRecordType = event.target.value;
    }
    // PLS name template handlers
    toggleDefaultPLSEditMode() {
        this.isDefaultPLSModelEditMode = !this.isDefaultPLSModelEditMode;
    }
    handleShowPLSRecordTypeConfig() {
        this.showPLSRecordTypeConfig = !this.showPLSRecordTypeConfig;
    }
    handleChangePLSDefaultModel(event) {
        if (!this.plsNameConfigurations.DEFAULT) {
            this.plsNameConfigurations.DEFAULT = { template: '', allowUpdate: false };
        }
        this.plsNameConfigurations.DEFAULT.template = event.target.value;
    }
    addPLSNameConfig() {
        const self = this;
        const newRow = {
            uid: Math.random().toString(36).slice(2),
            recordType: '',
            get plsRecordTypeOptions() {
                try {
                    const used = [
                        ...Object.keys(self.plsNameConfigurations).filter(k => k !== 'DEFAULT'),
                        ...self.newPLSNameConfigurationsList.map(x => x.recordType)
                    ];
                    return Object.keys(self.priceListStatementRTMap).map(key => ({
                        value: key, label: self.priceListStatementRTMap[key]
                    })).filter(op => !used.includes(op.value) || this.recordType === op.value);
                } catch (error) {
                    console.log('%c' + (error.message ? error.message : error.body?.message));
                    showNotification(self, self.labels.LBL_Error, (error.message ? error.message : error.body?.message), 'error', 'sticky');
                }
            },
            label: '',
            template: '',
            allowUpdate: false
        };
        this.newPLSNameConfigurationsList.push(newRow);
    }
    handleNewPLSOnChangeRT(event) {
        const idx = event.target.dataset.index;
        this.newPLSNameConfigurationsList[idx].recordType = event.target.value;
    }
    handleNewPLSOnChangeModel(event) {
        const idx = event.target.dataset.index;
        this.newPLSNameConfigurationsList[idx].template = event.target.value;
    }
    handleNewPLSOnChangeAllowNameUpdate(event) {
        const idx = event.target.dataset.index;
        this.newPLSNameConfigurationsList[idx].allowUpdate = event.target.checked;
    }
    handleDeleteNewPLSNameConfig(event) {
        const idx = event.target.dataset.index;
        this.newPLSNameConfigurationsList.splice(idx, 1);
        this.newPLSNameConfigurationsList = [...this.newPLSNameConfigurationsList];
    }
    handlePLSOnChangeModel(event) {
        const rt = event.target.dataset.recordType;
        if (!this.plsNameConfigurations[rt]) this.plsNameConfigurations[rt] = { template: '', allowUpdate: false };
        this.plsNameConfigurations[rt].template = event.detail ? event.detail.value : event.target.value;
    }
    handlePLSOnChangeAllowNameUpdate(event) {
        const rt = event.target.dataset.recordType;
        if (!this.plsNameConfigurations[rt]) this.plsNameConfigurations[rt] = { template: '', allowUpdate: false };
        this.plsNameConfigurations[rt].allowUpdate = event.detail ? event.detail.checked : event.target.checked;
    }
    handleDeletePLSNameConfig(event) {
        const rt = event.target.dataset.recordType;
        delete this.plsNameConfigurations[rt];
    }
    /*  */
    /* ConditionManagerPage CONFIG SECTION */
    /*  */
    addConditionManagerPageConfig() {
        let self = this;
        let newRow = {
            recordType: '',
            get contractRecordTypeOptions() {
                try {
                    return Object.keys(self.contractRTMap).map(key => {
                        return { value: key, label: self.contractRTMap[key] };
                    }).filter(op => {
                        let usedRTs = self.conditionManagerPageConfigurations.list.map(item => item.recordType);
                        return !usedRTs.includes(op.value) || this.recordType === op.value;
                    });
                } catch (error) {
                    console.log('%c' + error.message ? error.message : error.body?.message);
                    showNotification(self, self.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
                }
            },
            mainGridSettings: '',
            subDiscountGridSettings: '',
            showSubDiscountColumn: false,
        };
        this.conditionManagerPageConfigurations.list.push(newRow);
    }

    handleDeleteConditionManagerPageConfig(event) {
        let index = event.target.dataset.index;
        this.conditionManagerPageConfigurations.list.splice(index, 1);
    }

    handleChangeConditionManagerPageGrid(event) {
        let field = event.target.dataset.field;
        let type = event.target.dataset.type;
        let index = event.target.dataset.index;
        let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        value = (Array.isArray(value) ? value[0] : value) || null;
        if (type == 'list') {
            this.conditionManagerPageConfigurations.list[index][field] = value;
        } else {
            this.conditionManagerPageConfigurations.DEFAULT[field] = value;
        }
    }

    /*  */
    /* ProductDiscountStatement CONFIG SECTION */
    /*  */

    handleChangeProductDiscountStatementConfigurations(event) {
        let index = event.target.dataset.index;
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.productDiscountsConfigurationsList[index][field] = value;
    }

    handleChangeProductDiscountStatement(event) {
        let field = event.target.dataset.field;
        this.negoSettings.productDiscountsConfiguration[field] = event.target.value;
    }

    handleToggleProductDiscountsConfig(event) {
        const field = event.target.dataset.field;
        this.negoSettings.productDiscountsConfiguration[field] = event.target.checked;
    }

    handleToggleLoadPreferencePromoStatementInfo() {
        this.loadPreferencePromoStatementInfoOpen = !this.loadPreferencePromoStatementInfoOpen;
    }

    // PDS Configuration Modal Handler
    handleTogglePDSConfigModal() {
        this.showPDSConfigModal = !this.showPDSConfigModal;
        if (this.showPDSConfigModal) {
            this.newPDSConfig = {
                recordType: '',
                promoStatementType: '',
                promoAgreementType: '',
                gridSettings: '',
                communityGridSettings: '',
                importSettings: '',
                communityImportSettings: ''
            };
        } else {
            this.newPDSConfig = {};
        }
    }

    handleChangePDSConfig(event) {
        let field = event.target.dataset.field;
        this.newPDSConfig[field] = event.target.value;
        // Reset promo fields when record type changes
        if (this.newPDSConfig.recordType !== 'Promo') {
            this.newPDSConfig.promoStatementType = this.newPDSConfig.promoAgreementType = '';
        }
    }

    handleConfirmPDSConfigModal() {
        if (this.newPDSConfig.recordType === 'Promo') {
            // Unique key for Promo combinations
            const configKey = `Promo_${this.newPDSConfig.promoStatementType}_${this.newPDSConfig.promoAgreementType}`;
            const statementTypeLabel = this.promoStatementTypeOptions.find(option => option.value === this.newPDSConfig.promoStatementType)?.label || this.newPDSConfig.promoStatementType;
            const agreementTypeLabel = this.promoAgreementTypeOptions.find(option => option.value === this.newPDSConfig.promoAgreementType)?.label || this.newPDSConfig.promoAgreementType;
            this.newPDSConfig.recordType = configKey;
            this.newPDSConfig.label = `Promo - ${statementTypeLabel} - ${agreementTypeLabel}`;
        } else {
            this.newPDSConfig.label = this.productDiscountStatementRTMap[this.newPDSConfig.recordType];
        }
        this.productDiscountsConfigurationsList = [...this.productDiscountsConfigurationsList, this.newPDSConfig];
        this.handleTogglePDSConfigModal();
    }

    handleDeleteProductDiscountConfiguration(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.productDiscountsConfigurationsList.splice(index, 1);
    }

    handleSave(event) {
        try {
            //VALIDATE INPUTS
            let consoMap = {};
            this.contractConsolidationConfigurationList.forEach(item => {
                consoMap[item.recordType] = {
                    isActive: item.isActive,
                    executionDate: item.executionDate
                };
            });
            this.negoSettings.contractConsolidationConfiguration = consoMap;
            let isValid = true;
            let elements = this.template.querySelectorAll('.input');
            if (elements.length > 0) {
                for (let element of elements) {
                    isValid &= element.reportValidity();
                }
            }
            if (!isValid) {
                return;
            }
            if (this.checkForDuplication()) {
                showNotification(this, this.labels.LBL_Error, this.labels.MSG_Error_Duplication, 'error', 'sticky');
                return;
            }
            this.loading = true;
            // CONTRACT Duplication CONFIGURATION
            let contractDuplicationConfigurationList = [];
            this.contractDuplicationConfigurationLines.forEach(source => {
                if (source.recordType) {
                    let sourceContract = {
                        recordType: source.recordType,
                        status: source.status,
                        targetContracts: []
                    }
                    source.targetContractDuplications.forEach(target => {
                        if (target.recordType) {
                            sourceContract.targetContracts.push({
                                recordType: target.recordType,
                                status: target.status
                            })
                        }
                    })
                    contractDuplicationConfigurationList.push(sourceContract);
                }
            })
            this.negoSettings.contractDuplicationConfiguration = contractDuplicationConfigurationList;
            // CONTRACT NAME CONFIGURATION
            if (this.showRecordTypeConfig) {
                if (this.newNameConfigurationsList.length > 0) {
                    this.newNameConfigurationsList.forEach(element => {
                        this.contractNameConfigurations[element.recordType] = {
                            template: element.template,
                            allowUpdate: element.allowUpdate
                        }
                    });
                }
                this.negoSettings.contractNameConfiguration = this.contractNameConfigurations;
            } else {
                let defaultContractName = {};
                defaultContractName['DEFAULT'] = this.contractNameConfigurations['DEFAULT'];
                this.negoSettings.contractNameConfiguration = defaultContractName;
            }
            // ConditionManagerPage CONFIGURATION
            let conditionManagerPageConfigurationsMap = {};
            if (this.conditionManagerPageConfigurations) {
                for (let setting of this.conditionManagerPageConfigurations.list) {
                    conditionManagerPageConfigurationsMap[setting.recordType] = setting;
                }
                conditionManagerPageConfigurationsMap['DEFAULT'] = this.conditionManagerPageConfigurations.DEFAULT;
            }
            this.negoSettings.conditionManagerPageConfiguration.gridsConfiguration = conditionManagerPageConfigurationsMap;
            // ProductDiscountStatement CONFIGURATION
            if (this.newPDSNameConfigurationsList.length > 0) {
                this.newPDSNameConfigurationsList.forEach(row => {
                    if (row.recordType) {
                        this.pdsNameConfigurations[row.recordType] = { template: row.template || '', allowUpdate: !!row.allowUpdate };
                    }
                });
            }
            if (!this.showPDSRecordTypeConfig) {
                this.pdsNameConfigurations = {
                    DEFAULT: this.pdsNameConfigurations.DEFAULT || { template: '', allowUpdate: false }
                };
            }
            if (!this.negoSettings.productDiscountsConfiguration) {
                this.negoSettings.productDiscountsConfiguration = {};
            }
            this.negoSettings.productDiscountsConfiguration.nameConfiguration = this.pdsNameConfigurations;
            let productDiscountsConfigurationMap = {};
            for (let pdsConfig of this.productDiscountsConfigurationsList) {
                productDiscountsConfigurationMap[pdsConfig.recordType] = {
                    recordType: pdsConfig.recordType,
                    promoStatementType: pdsConfig.promoStatementType || '',
                    promoAgreementType: pdsConfig.promoAgreementType || '',
                    gridSettings: pdsConfig.gridSettings,
                    communityGridSettings: pdsConfig.communityGridSettings || pdsConfig.gridSettings,
                    importSettings: pdsConfig.importSettings,
                    communityImportSettings: pdsConfig.communityImportSettings,
                };
            }
            this.negoSettings.productDiscountsConfiguration.productDiscountsConfigurationMap = productDiscountsConfigurationMap;
            this.negoSettings.sellInConfiguration = [...this.sellInConfiguration];
            // PriceListStatement CONFIGURATION
            if (this.newPLSNameConfigurationsList.length > 0) {
                this.newPLSNameConfigurationsList.forEach(row => {
                    if (row.recordType) {
                        this.plsNameConfigurations[row.recordType] = {
                            template: row.template || '',
                            allowUpdate: !!row.allowUpdate
                        };
                    }
                });
            }
            if (!this.showPLSRecordTypeConfig) {
                this.plsNameConfigurations = {
                    DEFAULT: this.plsNameConfigurations.DEFAULT || { template: '', allowUpdate: false }
                };
            }
            // PriceListStatement GRID/IMPORT CONFIGURATION
            let priceListStatementsConfigurationMap = {};
            for (let row of this.priceListStatementsConfigurationsList) {
                priceListStatementsConfigurationMap[row.recordType] = {
                    gridSettings: row.gridSettings,
                    communityGridSettings: row.communityGridSettings,
                    importSettings: row.importSettings,
                    communityImportSettings: row.communityImportSettings
                };
            }
            if (!this.negoSettings.priceListStatementsConfiguration) {
                this.negoSettings.priceListStatementsConfiguration = {};
            }
            this.negoSettings.priceListStatementsConfiguration.defaultPriceListStatementRecordType = this.defaultPriceListStatementRecordType;
            this.negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap = priceListStatementsConfigurationMap;
            this.negoSettings.priceListStatementsConfiguration.nameConfiguration = this.plsNameConfigurations;

            //Negotiate Page Configuration Section
            this.negoSettings.negotiatePageConfiguration = this.negotiateConfig;
            save({
                negoSettingsJSON: JSON.stringify(this.negoSettings)
            }).then((result) => {
                this.checkDeployementStatus(result);
            }).catch(error => {
                this.loading = false;
                console.log('ERROR: ' + error.message);
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleNegotiateConfigChange(event) {
        const targetConfig = event.target.dataset.targetConfig;
        const targetYear = event.target.dataset.targetYear;
        this.negotiateConfig[targetConfig][targetYear] = event.detail.value
    }

    checkDeployementStatus(idDeployment) {
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
                        self.loading = false;
                        clearInterval(interval);
                        showNotification(self, self.labels.MSG_Information, self.labels.MSG_Request_Timed_Out + ' ' + self.labels.MSG_Deploy_Last_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            self.loading = false;
                            clearInterval(interval);
                            if (success) {
                                this.newNameConfigurationsList = [];
                                this.isDefaultContractModelEditMode = false;
                                this.newPDSNameConfigurationsList = [];
                                this.isDefaultPDSModelEditMode = false;
                                this.newPLSNameConfigurationsList = [];
                                this.isDefaultPLSModelEditMode = false;
                                showNotification(self, self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
                            } else {
                                showNotification(self, self.labels.MSG_Information, self.labels.MSG_Deploy_Ended_With_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.loading = false;
                this.newNameConfigurationsList = [];
                this.isDefaultContractModelEditMode = false;
                this.newPDSNameConfigurationsList = [];
                this.isDefaultPDSModelEditMode = false;
                this.newPLSNameConfigurationsList = [];
                this.isDefaultPLSModelEditMode = false;
                showNotification(self, self.labels.LBL_Save, self.labels.MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
            }
        });
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

    getRandomInt(min, max) {
        return Math.floor(Math.random() * (9999999999 - 1000000000) + 1000000000);
    }

}