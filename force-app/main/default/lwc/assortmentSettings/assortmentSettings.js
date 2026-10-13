import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

import loadAssortmentSettings from '@salesforce/apex/AssortmentSettingsController.loadAssortmentSettings';
import save from '@salesforce/apex/AssortmentSettingsController.save';
import applyHRtoBU from '@salesforce/apex/AssortmentSettingsController.applyHRtoBU';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
// Custom Object
import ASD__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Assortment from '@salesforce/schema/Assortment__c';
import BU__OBJECT from '@salesforce/schema/BusinessUnit__c';
import PRODUCT__OBJECT from '@salesforce/schema/Product2';
import HIERARCHY__OBJECT from '@salesforce/schema/Hierarchy__c';
import SalesCannibalizationType__c from "@salesforce/schema/AssortmentDetail__c.SalesCannibalizationType__c";
import ProductGTIN__c from "@salesforce/schema/AssortmentDetail__c.ProductGTIN__c";
// Custom Labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Status from "@salesforce/label/c.LBL_Status";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_Scope_Settings from "@salesforce/label/c.LBL_Scope_Settings";
import LBL_Page_Layout from "@salesforce/label/c.LBL_Page_Layout";
import LBL_Global from "@salesforce/label/c.LBL_Global";
import LBL_TypeHR from "@salesforce/label/c.LBL_TypeHR";
import LBL_Sales_Cannibalization from "@salesforce/label/c.LBL_Sales_Cannibalization";
import LBL_DescriptionHR from "@salesforce/label/c.LBL_DescriptionHR";
import LBL_API from "@salesforce/label/c.LBL_API";
import LBL_Std_Perc from "@salesforce/label/c.LBL_Std_Perc";
import LBL_IN from "@salesforce/label/c.LBL_IN";
import LBL_OUT from "@salesforce/label/c.LBL_OUT";
import LBL_Keep_Client_Perc from "@salesforce/label/c.LBL_Keep_Client_Perc";
import LBL_Replace_Client_Perc from "@salesforce/label/c.LBL_Replace_Client_Perc";
import LBL_Apply_HR_Config_to_BU from "@salesforce/label/c.LBL_Apply_HR_Config_to_BU";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Import_Field_Name from "@salesforce/label/c.LBL_Import_Field_Name";
import LBL_Import_Field_Label from "@salesforce/label/c.LBL_Import_Field_Label";
import LBL_Import_Field_SysAdmin from "@salesforce/label/c.LBL_Import_Field_SysAdmin";
import LBL_Import_Field_User from "@salesforce/label/c.LBL_Import_Field_User";
import LBL_Scope_Name from "@salesforce/label/c.LBL_Scope_Name";
import LBL_Scope_Attribute from "@salesforce/label/c.LBL_Scope_Attribute";
import LBL_Scope_Hierarchy_Level from "@salesforce/label/c.LBL_Scope_Hierarchy_Level";
import LBL_Assortment_Settings from "@salesforce/label/c.LBL_Assortment_Settings";
import LBL_myOffer from "@salesforce/label/c.LBL_myOffer";
import LBL_NS_Stg_General_Settings from "@salesforce/label/c.LBL_NS_Stg_General_Settings";
import LBL_Available from "@salesforce/label/c.LBL_Available";
import LBL_Selected from "@salesforce/label/c.LBL_Selected";
import LBL_AssortmentSettings_AssortmentSimulatorConfig from "@salesforce/label/c.LBL_AssortmentSettings_AssortmentSimulatorConfig";
import LBL_AssortmentSettings_AssortmentRTsPreviousYear from "@salesforce/label/c.LBL_AssortmentSettings_AssortmentRTsPreviousYear";
import LBL_AssortmentSettings_AssortmentRTsCurrentYear from "@salesforce/label/c.LBL_AssortmentSettings_AssortmentRTsCurrentYear";
import LBL_AssortmentSettings_AssortmentRTsNextYear from "@salesforce/label/c.LBL_AssortmentSettings_AssortmentRTsNextYear";
import LBL_AssortmentSettings_AssortmentBULevel from "@salesforce/label/c.LBL_AssortmentSettings_AssortmentBULevel";
import LBL_AssortmentSettings_OnlyClusters from "@salesforce/label/c.LBL_AssortmentSettings_OnlyClusters";
import LBL_AssortmentSettings_OnlyStores from "@salesforce/label/c.LBL_AssortmentSettings_OnlyStores";
import LBL_AssortmentSettings_Both from "@salesforce/label/c.LBL_AssortmentSettings_Both";

import LBL_AssortmentSettings_KPISetupConfiguration from "@salesforce/label/c.LBL_AssortmentSettings_KPISetupConfiguration";
import LBL_AssortmentSettings_AddKPI from "@salesforce/label/c.LBL_AssortmentSettings_AddKPI";
import LBL_AssortmentSettings_Fields from "@salesforce/label/c.LBL_AssortmentSettings_Fields";
import LBL_AssortmentSettings_AddField from "@salesforce/label/c.LBL_AssortmentSettings_AddField";
import LBL_AssortmentSettings_FieldName from "@salesforce/label/c.LBL_AssortmentSettings_FieldName";
import LBL_Background from "@salesforce/label/c.LBL_Background";
import LBL_Color from "@salesforce/label/c.LBL_Color";
import LBL_AssortmentSettings_FieldNotExist from "@salesforce/label/c.LBL_AssortmentSettings_FieldNotExist";
import LBL_AssortmentSettings_FieldLimitRecommendation from "@salesforce/label/c.LBL_AssortmentSettings_FieldLimitRecommendation";
import LBL_AssortmentSettings_ClusterMovement from "@salesforce/label/c.LBL_AssortmentSettings_ClusterMovement";
import LBL_AssortmentSettings_TodayltStartDate from "@salesforce/label/c.LBL_AssortmentSettings_TodayltStartDate";
import LBL_AssortmentSettings_TodayGtStartDate from "@salesforce/label/c.LBL_AssortmentSettings_TodayGtStartDate";
import LBL_AssortmentSettings_TodayGtStartDateAndPeriod from "@salesforce/label/c.LBL_AssortmentSettings_TodayGtStartDateAndPeriod";
import LBL_AssortmentSettings_PeriodDays from "@salesforce/label/c.LBL_AssortmentSettings_PeriodDays";
import LBL_AssortmentSettings_increase from "@salesforce/label/c.LBL_AssortmentSettings_increase";
import LBL_AssortmentSettings_decrease from "@salesforce/label/c.LBL_AssortmentSettings_decrease";
import LBL_AssortmentSettings_EvolutionArrowsConfiguration from "@salesforce/label/c.LBL_AssortmentSettings_EvolutionArrowsConfiguration";
import LBL_AssortmentSettings_DisplayEvolutionArrows from "@salesforce/label/c.LBL_AssortmentSettings_DisplayEvolutionArrows";

import Invoice_OBJECT from '@salesforce/schema/Invoice__c';

const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const classPrefix = `${PREFIX ? PREFIX + '-' : 'c-'}assortment-settings`;

export default class AssortmentSettings extends NavigationMixin(LightningElement) {
    mainPanelHeight;
    @track labels = {
        LBL_Save,
        LBL_Cancel,
        LBL_Status,
        LBL_None_Picklist_Value,
        LBL_Assortment_Settings,
        LBL_myOffer,
        LBL_Global,
        LBL_Page_Layout,
        LBL_Scope_Settings,
        LBL_TypeHR,
        LBL_Sales_Cannibalization,
        LBL_DescriptionHR,
        LBL_API,
        LBL_Std_Perc,
        LBL_IN,
        LBL_OUT,
        LBL_Keep_Client_Perc,
        LBL_Replace_Client_Perc,
        LBL_Apply_HR_Config_to_BU,
        LBL_Confirm,
        LBL_Import_Field_Name,
        LBL_Import_Field_Label,
        LBL_Import_Field_SysAdmin,
        LBL_Import_Field_User,
        LBL_Scope_Name,
        LBL_Scope_Attribute,
        LBL_Scope_Hierarchy_Level,
        LBL_NS_Stg_General_Settings,
        LBL_Available,
        LBL_Selected,
        LBL_AssortmentSettings_AssortmentSimulatorConfig,
        LBL_AssortmentSettings_AssortmentRTsPreviousYear,
        LBL_AssortmentSettings_AssortmentRTsCurrentYear,
        LBL_AssortmentSettings_AssortmentRTsNextYear,
        LBL_AssortmentSettings_KPISetupConfiguration,
        LBL_AssortmentSettings_AddKPI,
        LBL_AssortmentSettings_Fields,
        LBL_AssortmentSettings_AddField,
        LBL_AssortmentSettings_FieldName,
        LBL_Background,
        LBL_Color,
        LBL_AssortmentSettings_OnlyClusters,
        LBL_AssortmentSettings_OnlyStores,
        LBL_AssortmentSettings_Both,
        LBL_AssortmentSettings_AssortmentBULevel,
        assortmentobjectLabel: '',
        assortmentDetailobjectLabel: '',
        LBL_AssortmentSettings_FieldNotExist,
        LBL_AssortmentSettings_FieldLimitRecommendation,
        assortmentSettings: {
            objectLabel: '',
            applyCalcFullYearQtyP1: '',
            assortmentProductSelectionRespectMarket: '',
            assortmentProductSelectionRespectHierarchy: '',
            assortmentMatrixBudget: '',
            assortmentMatrixNego: '',
            assortmentMatrixTarget: '',
            assortmentProductSelectionGrid: '',
            assortmentProductSelectionRespectBU: '',
            assortmentProductSelectionUNGrid: '',
            assortmentDirectAccessPlugin: '',
            availableImportFields: '',
            salesCannibalizationRates: '',
            kpi: '',
            assortmentBUConfiguration: ''
        },
        LBL_AssortmentSettings_ClusterMovement,
        LBL_AssortmentSettings_TodayltStartDate,
        LBL_AssortmentSettings_TodayGtStartDate,
        LBL_AssortmentSettings_TodayGtStartDateAndPeriod,
        LBL_AssortmentSettings_PeriodDays,
        LBL_AssortmentSettings_increase,
        LBL_AssortmentSettings_decrease,
        LBL_AssortmentSettings_EvolutionArrowsConfiguration,
        LBL_AssortmentSettings_DisplayEvolutionArrows
    }
    ASSORMENT_SETTINGS_API = {
        AssortmentSettings__mdt: 'AssortmentSettings__mdt',
        ApplyCalcFullYearQtyP1__c: 'ApplyCalcFullYearQtyP1__c',
        AssortmentProductSelectionRespectBU__c: 'AssortmentProductSelectionRespectBU__c',
        ASProductSelectionRespectMarket__c: 'ASProductSelectionRespectMarket__c',
        ASProductSelectionRespectHierarchy__c: 'ASProductSelectionRespectHierarchy__c',
        AssortmentDirectAccessPluginGrid__c: 'AssortmentDirectAccessPluginGrid__c',
        KPI__c: 'KPI__c',
        AssortmentMatrixNego__c: 'AssortmentMatrixNego__c',
        AssortmentMatrixTarget__c: 'AssortmentMatrixTarget__c',
        AssortmentMatrixBudget__c: 'AssortmentMatrixBudget__c',
        AssortmentProductSelectionGrid__c: 'AssortmentProductSelectionGrid__c',
        AssortmentProductSelectionUNGrid__c: 'AssortmentProductSelectionUNGrid__c',
        SalesCannibalizationRates__c: 'SalesCannibalizationRates__c',
        AssortmentBUConfiguration__c: 'AssortmentBUConfiguration__c'
    }
    @track loadingData = false;
    @track assortmentSettings = {};
    @track KPIoptions = [];
    @track scopes = [];
    @track assortmentRTsOptions = [];
    @track ASDFields = [];
    @track productFields = [];
    @track replaceOptions = [
        { label: this.labels.LBL_Keep_Client_Perc, value: 'keep' },
        { label: this.labels.LBL_Replace_Client_Perc, value: 'replace' }
    ];
    @track assortmentBUConfigurationOptions = [
        {label: this.labels.LBL_AssortmentSettings_OnlyClusters , value:'onlyClusters'},
        {label: this.labels.LBL_AssortmentSettings_OnlyStores, value:'onlyStores'},
        {label: this.labels.LBL_AssortmentSettings_Both, value:'both'}
    ]; 
    @track replaceValue = 'keep';
    @track buRecordTypesOptions = [];
    @track selectedBURecordTypes = [];
    @track propertiesData = [];
    @track salesCannibalizationRatesRecords = [];
    @track availableImportFields = [];
    @track applyHRtoBU = false;
    @track assortmentBUConfiguration = {};
    @track types = [
        { label: this.labels.LBL_IN, value: 'IN' },
        { label: this.labels.LBL_OUT, value: 'OUT' },
    ]
    @track assortmentSimulatorRTs = {
        previous: [],
        current: [],
        next: []   
    };
    @track kpiFields = [];
    @track selectedKPIWrapperIndex;
    @track selectedKPIWrapper;
    @track assortmentFieldOptions = [];
    @track assortmentDetailFieldOptions = [];
    @track draggedKPIIndex = null;
    @track selectedFieldToAdd = '';
    @track availableKPIFieldOptions = [];
    @track clusterMovementTable = {};
    @track displayEvolutionArrows = false;
    prodTemplates = [];
    asdTemplates = [];
    asTemplates = [];
    newImportField = false;
    wiresIsDone = {
        objectInfoProduct: false,
        salesCannibalizationRatesPicklist: false,
        objectInfoASD: false,
        objectInfoBU: false,
        objectAssortmentObj: false,
    }

    get isAddKPIDisabled() {
        return this.kpiFields.length >= 5;
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: ASD__OBJECT, recordTypeId: "012000000000000AAA" }) salesCannibalizationRatesPicklistValues({ error, data }) {
        if (data) {
            this.picklistValues = data.picklistFieldValues[SalesCannibalizationType__c.fieldApiName].values;
            this.wiresIsDone.salesCannibalizationRatesPicklist = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.log('ERROR');
        }
    }

    @wire(getObjectInfo, { objectApiName: ASD__OBJECT }) objectInfoASD({ error, data }) {
        if (data) {
            this.labels.assortmentDetailobjectLabel = data.label;
            for (let field of Object.values(data.fields)) {
                this.assortmentDetailFieldOptions.push({value: field.apiName, label: field.label})
                if (field.updateable) {
                    this.ASDFields.push({ value: field.apiName, label: field.label });
                }
                this.ASDFields.sort((a, b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));
            }
            this.wiresIsDone.objectInfoASD = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: PRODUCT__OBJECT }) objectInfoProduct({ error, data }) {
        if (data) {
            this.productFields.push({ value: '', label: this.labels.LBL_None_Picklist_Value, isHierarchy: false });
            for (let field of Object.values(data.fields)) {
                if (field.dataType == 'String' || field.dataType == 'Reference') {
                    this.productFields.push({ value: field.apiName, label: field.label, isHierarchy: field.dataType == 'Reference' && field.referenceToInfos[0]?.apiName == HIERARCHY__OBJECT.objectApiName })
                }
            }
            this.wiresIsDone.objectInfoProduct = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: BU__OBJECT }) objectInfoBU({ error, data }) {
        if (data) {
            var recordtypeinfo = data.recordTypeInfos;
            var uiCombobox = [];
            for (var eachRecordtype in recordtypeinfo) {
                if (recordtypeinfo.hasOwnProperty(eachRecordtype))
                    uiCombobox.push({ label: recordtypeinfo[eachRecordtype].name, value: recordtypeinfo[eachRecordtype].recordTypeId })
            }
            this.buRecordTypesOptions = uiCombobox;
            this.wiresIsDone.objectInfoBU = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: Assortment }) assortmentObj({ error, data }) {
        if (data) {
            this.labels.assortmentobjectLabel = data.label;
            for (let field of Object.keys(data.fields)) {
                if (data.fields[field].dataType == 'Percent' || data.fields[field].dataType == 'Currency' || data.fields[field].dataType == 'Double') {
                    let fieldW = { label: data.fields[field].label, value: field };
                    this.assortmentFieldOptions.push(fieldW)
                }
            }
            this.wiresIsDone.objectAssortmentObj = true;
            this.checkIfWireIsDone();
        } else {
            console.log(error);
        }
    }

    checkIfWireIsDone() {
        if (Object.values(this.wiresIsDone).every(it => it)) {
            this.loadData();
        }
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
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                background: white;
                color: #806BBF;
                height: 60px;
                width: 230px;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active:hover {
                background: white;
                color: #806BBF;
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

    renderedCallback() {
        if (this.template.querySelector('.settings-header')) {
            this.changeHeight();
        }
        let lightningTabList = this.template.querySelectorAll('lightning-tab');
        for (let lightningTab of lightningTabList) {
            lightningTab.classList.remove('slds-vertical-tabs__content');
        }
    }

    loadData() {
        this.loadingData = true;
        this.availableImportFields = [];
        this.salesCannibalizationRatesRecords = [];
        this.kpiFields = [];
        this.assortmentRTsOptions = [];
        loadAssortmentSettings().then((result) => {
            let parsedResult = JSON.parse(result);
            console.log('🎰 ~ assortmentSettings.js:428 -> parsedResult: ', JSON.stringify(parsedResult));
            this.ASSORMENT_SETTINGS_API = {
                AssortmentSettings__mdt: parsedResult.prefix + 'AssortmentSettings__mdt',
                ApplyCalcFullYearQtyP1__c: parsedResult.prefix + 'ApplyCalcFullYearQtyP1__c',
                AssortmentProductSelectionRespectBU__c: parsedResult.prefix + 'AssortmentProductSelectionRespectBU__c',
                ASProductSelectionRespectMarket__c: parsedResult.prefix + 'ASProductSelectionRespectMarket__c',
                ASProductSelectionRespectHierarchy__c: parsedResult.prefix + 'ASProductSelectionRespectHierarchy__c',
                KPI__c: parsedResult.prefix + 'KPI__c',
                AssortmentMatrixNego__c: parsedResult.prefix + 'AssortmentMatrixNego__c',
                AssortmentMatrixTarget__c: parsedResult.prefix + 'AssortmentMatrixTarget__c',
                AssortmentMatrixBudget__c: parsedResult.prefix + 'AssortmentMatrixBudget__c',
                AssortmentProductSelectionGrid__c: parsedResult.prefix + 'AssortmentProductSelectionGrid__c',
                AssortmentProductSelectionUNGrid__c: parsedResult.prefix + 'AssortmentProductSelectionUNGrid__c',
                AssortmentDirectAccessPluginGrid__c: parsedResult.prefix + 'AssortmentDirectAccessPluginGrid__c',
                SalesCannibalizationRates__c: parsedResult.prefix + 'SalesCannibalizationRates__c',
                AssortmentBUConfiguration__c: parsedResult.prefix + 'AssortmentBUConfiguration__c',
            }
            this.prodTemplates = parsedResult.prodTemplates;
            this.asdTemplates = parsedResult.ASDTemplates;
            this.asTemplates = parsedResult.ASTemplates;
            this.assortmentSettings = parsedResult.assortmentSettings;
            this.assortmentBUConfiguration = this.assortmentSettings.assortmentBUConfiguration ?? { assortmentBuLevel : 'both', periodDays: 60};
            if(this.assortmentSettings.assortmentBUConfiguration?.periodDays == null) this.assortmentSettings.assortmentBUConfiguration.periodDays = 60;
            if(this.assortmentBUConfiguration.LastCodeConfiguration == null) {
                this.assortmentBUConfiguration.LastCodeConfiguration = {
                            increaseBeforeStart: 'A',
                            increaseWithinPeriod: 'N',
                            increaseAfterPeriod: 'R',
                            decreaseBeforeStart: 'D',
                            decreaseWithinPeriod: 'S',
                            decreaseAfterPeriod: null
                        };
            }
            this.clusterMovementTable = this.assortmentSettings.assortmentBUConfiguration?.LastCodeConfiguration || {};
            console.log('🎰 ~ assortmentSettings.js:466 -> this.assortmentBUConfiguration: ', JSON.stringify(this.assortmentBUConfiguration));
            let salesCannibalizationRates = JSON.parse(this.assortmentSettings.salesCannibalizationRates);
            for (let pickVal of this.picklistValues) {
                let item = salesCannibalizationRates.find(item => item.api == pickVal.value);
                this.salesCannibalizationRatesRecords.push({
                    typeHR: item ? item.typeHR : '',
                    label: item ? item.label : '',
                    description: item ? item.description : '',
                    stdPerc: item ? item.stdPerc : '',
                    api: pickVal.value,
                });
            }
            let availableImportFields = JSON.parse(this.assortmentSettings.availableImportFields);
            if (availableImportFields && availableImportFields.length > 0) {
                availableImportFields.forEach(item => {
                    this.availableImportFields.push({
                        fieldName: item.fieldName,
                        fieldLabel: item.fieldLabel,
                        isAdmin: item.isAdmin,
                        isUser: item.isUser,
                        isEAN: item.fieldName == ProductGTIN__c.fieldApiName,
                    });
                });
            }
            this.scopes = JSON.parse(this.assortmentSettings.scopeSettings);
            this.scopes.forEach(scope => {
                scope.isHierarchy = this.productFields.filter(item => (item.isHierarchy && item.value == scope.Name)).length > 0
            })
            this.setLabels(parsedResult.fieldsMap, parsedResult.picklistLabelsMap);
            // Assortment Simulator Settings
            for (let [key, value] of Object.entries(parsedResult.assortmentRTMap)) {
                if (key === 'Master' || key === 'Principal') {
                    continue;
                }
                this.assortmentRTsOptions.push({ label: value, value: key });
            }
            if (this.assortmentSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs) {
                this.assortmentSimulatorRTs = {
                    previous: this.assortmentSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs?.previous || [],
                    current: this.assortmentSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs?.current || [],
                    next: this.assortmentSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs?.next || []            
                };
            }
            let kpiFields = this.assortmentSettings?.assortmentSimulatorConfiguration?.kpiFields || [];
            const usedFields = new Set();
            kpiFields.forEach(kpi => {
                let KPIWrapper = {
                    backgroundColor: kpi.backgroundColor,
                    textColor: kpi.textColor,
                    fields: [],
                };
                kpi.fields.forEach(field => {
                    const assortmentMatch = this.assortmentFieldOptions.find(f => f.value === field);
                    const asdMatch = this.assortmentDetailFieldOptions.find(f => f.value === field);
                    let fieldWrapper = {
                        fieldName: field,
                        isAssortment: assortmentMatch,
                        isASD: asdMatch,
                        label: assortmentMatch?.label || asdMatch?.label
                    };
                    usedFields.add(field);
                    KPIWrapper.fields.push(fieldWrapper)
                });
                this.kpiFields.push(KPIWrapper)
            });
            this.availableKPIFieldOptions = this.assortmentFieldOptions.filter(option => !usedFields.has(option.value));
            this.reindexKPIs();
            this.displayEvolutionArrows = this.assortmentSettings.assortmentSimulatorConfiguration.displayEvolutionArrows ?? true;
            this.loadingData = false;
        }).catch(error => {
            console.log('error get Data >> ' + error.message);
            console.error(error);
        });
    }

    setLabels(fieldsMap, picklistLabelsMap) {
        let settingsApiName = this.ASSORMENT_SETTINGS_API.AssortmentSettings__mdt.replace('__c', '__mdt')
        // GLOBAL SECTION
        this.labels.assortmentSettings.applyCalcFullYearQtyP1 = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.ApplyCalcFullYearQtyP1__c].label;
        this.labels.assortmentSettings.assortmentProductSelectionRespectBU = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentProductSelectionRespectBU__c].label;
        this.labels.assortmentSettings.assortmentProductSelectionRespectMarket = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.ASProductSelectionRespectMarket__c].label;
        this.labels.assortmentSettings.assortmentProductSelectionRespectHierarchy = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.ASProductSelectionRespectHierarchy__c].label;
        this.labels.assortmentSettings.kpi = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.KPI__c].label;
        // PAGE LAYOUT SECTION
        this.labels.assortmentSettings.assortmentMatrixNego = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentMatrixNego__c].label;
        this.labels.assortmentSettings.assortmentMatrixTarget = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentMatrixTarget__c].label;
        this.labels.assortmentSettings.assortmentMatrixBudget = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentMatrixBudget__c].label;
        this.labels.assortmentSettings.assortmentProductSelectionGrid = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentProductSelectionGrid__c].label;
        this.labels.assortmentSettings.assortmentProductSelectionUNGrid = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentProductSelectionUNGrid__c].label;
        this.labels.assortmentSettings.assortmentDirectAccessPlugin = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentDirectAccessPluginGrid__c].label;
        this.labels.assortmentSettings.salesCannibalizationRates = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.SalesCannibalizationRates__c].label;
        this.labels.assortmentSettings.assortmentBUConfiguration = fieldsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.AssortmentBUConfiguration__c]?.label;

        let KPIoptions = []
        Object.keys(picklistLabelsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.KPI__c]).forEach(option => {
            KPIoptions.push({ value: option, label: picklistLabelsMap[settingsApiName][this.ASSORMENT_SETTINGS_API.KPI__c][option] })
        });
        this.KPIoptions = KPIoptions;
    }

    handleAddImportField(event) {
        this.newImportField = true;
        let newItem = {
            fieldName: '',
            fieldLabel: '',
            isAdmin: false,
            isUser: false,
        };
        this.availableImportFields.push(newItem);
    }

    handleAddScope(event) {
        let newItem = {
            Name: '',
            label: '',
            level: null,
            isHierarchy: false,
        };
        this.scopes.push(newItem);
    }

    handleDeleteImportField(event) {
        let array = event.target.dataset.array;
        let index = event.target.dataset.index;
        this[array].splice(index, 1);
    }

    handleDeleteScopeSettings(event) {
        let index = event.target.dataset.index;
        this.scopes.splice(index, 1);
    }

    handleChangeImportField(event) {
        let value = event.target.value;
        let index = event.target.dataset.index;
        let fieldParam = event.target.dataset.field;
        let key = event.target.dataset.key;
        if (fieldParam == 'isAdmin') {
            let value = event.target.checked;
            this.availableImportFields[index].isAdmin = value;
        } else if (fieldParam == 'isUser') {
            let value = event.target.checked;
            this.availableImportFields[index].isUser = value;
        } else if (key == fieldParam) {
            this.availableImportFields[index].fieldName = value;
            this.availableImportFields[index].fieldLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        }
    }

    handleFieldChangeMdt(event) {
        let field = event.target.dataset.field;
        this.assortmentSettings[field] = event.detail.checked != null ? event.detail.checked : event.target.value;
    }

    handleChangeScope(event) {
        let scopeIndex = event.target.dataset.scopeIndex;
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.scopes[scopeIndex][field] = value;
        if (field == 'Name') {
            this.scopes[scopeIndex].isHierarchy = value != '' ? this.productFields.filter(item => (item.isHierarchy && item.value === value)).length > 0 : false;
            if (!this.scopes[scopeIndex].isHierarchy) {
                this.scopes[scopeIndex].level = null;
            }
        }
        if (field == 'level' && !value) {
            this.scopes[scopeIndex].level = null;
        }
    }

    handleChangeHR(event) {
        let index = event.target.dataset.index;
        let property = event.target.dataset.property;
        let value = event.target.value;
        this.salesCannibalizationRatesRecords[index][property] = value;
    }

    handleChangeBURT(event) {
        this.selectedBURecordTypes = event.target.value;
    }

    handleChangeASBUConfiguration(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        if (field === 'assortmentBuLevel' || field === 'periodDays') {
            this.assortmentBUConfiguration[field] = value;
        } 
        else {
            this.assortmentBUConfiguration.LastCodeConfiguration[field] = value == '' ? null : value;
        }
        console.log('Updated assortmentBUConfiguration: ', JSON.stringify(this.assortmentBUConfiguration));
    }

    handleChangeReplaceValue(event) {
        this.replaceValue = event.target.value;
    }

    applyHRtoBUConfirm(event) {
        let buHR = [];
        for (let hr of this.salesCannibalizationRatesRecords) {
            let item = hr;
            item.clientPerc = hr.stdPerc;
            buHR.push(item);
        }
        applyHRtoBU({ buRTs: this.selectedBURecordTypes, value: JSON.stringify(buHR), keepPercClient: this.replaceValue == 'keep' }).then((result) => {
            console.log('Done')
            this.togglePopup();
        }).catch(error => {
            console.log('applyHRtoBU >> ' + error.message);
            console.error(error);
        });

    }


    togglePopup() {
        this.applyHRtoBU = !this.applyHRtoBU;
    }

    togglePopup() {
        this.applyHRtoBU = !this.applyHRtoBU;
    }

    handleSave() {
        this.loadingData = true;
        this.assortmentSettings.salesCannibalizationRates = JSON.stringify(this.salesCannibalizationRatesRecords);
        this.assortmentSettings.assortmentBUConfiguration = this.assortmentBUConfiguration;
        this.assortmentSettings.availableImportFields = JSON.stringify(this.availableImportFields);
        this.assortmentSettings.scopeSettings = JSON.stringify(this.scopes);
        this.assortmentSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs = this.assortmentSimulatorRTs;
        this.assortmentSettings.assortmentSimulatorConfiguration.kpiFields = [];
        this.kpiFields.forEach(kpi =>{
            let kpiWrapper ={
                backgroundColor: kpi.backgroundColor,
                textColor: kpi.textColor,
                fields: kpi.fields.map(field => field.fieldName)
            }
            this.assortmentSettings.assortmentSimulatorConfiguration.kpiFields.push(kpiWrapper)
        });
        console.log('this.assortmentSettings >>>> ' + JSON.stringify(this.assortmentSettings))
        save({
            assortmentSettingsSerialized: JSON.stringify(this.assortmentSettings),
        }).then((result) => {
            this.loadingData = false;
            /*if (result.length == 0) {
                //this.loadingData = false;
                console.log('success');
            }*/
        }).catch(error => {
            console.log('error get Data >> ' + error.message);
            console.error(error);
        });
    }

    get isAddScopeDisabled() {
        return this.scopes.length == 5;
    }

    get isNewImportFieldDone() {
        return (!this.newImportField || true);
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

    reindexKPIs() {
        this.kpiFields.forEach((kpi, index) => {
            kpi.kpiIndex = index + 1;
        });
    }

    handleAssortmentSimulatorRTsChange(event) {
        const targetYear = event.target.dataset.targetYear;
        this.assortmentSimulatorRTs[targetYear] = event.detail.value
    }

    handleAddNewKPIWrapper() {
        if (this.kpiFields.length >= 5) return;
        let KPIWrapper = {
            backgroundColor: '#ffffff',
            textColor: '#000000',
            fields: [],
            kpiIndex: this.kpiFields.length + 1 
        };
        this.kpiFields.push(KPIWrapper);
    }

    handleChangeKPIWrapper(event) {
        let value = event.target.value;
        let field = event.target.dataset.field;
        let kpiIndex = event.target.dataset.kpiIndex;
        this.kpiFields[kpiIndex][field] = value;
    }

    handleDeleteKPIWrapper(event) {
        let kpiIndex = parseInt(event.target.dataset.kpiIndex, 10);
        this.kpiFields.splice(kpiIndex, 1);
        if (this.selectedKPIWrapperIndex == kpiIndex) {
            this.selectedKPIWrapper = null;
            this.selectedKPIWrapperIndex = null;
        } else if (this.selectedKPIWrapperIndex > kpiIndex) {
            this.selectedKPIWrapperIndex = this.selectedKPIWrapperIndex - 1;
        }
        this.reindexKPIs();
    }

    handleKPIWrapperSelection(event) {
        const kpiIndex = Number(event.currentTarget.dataset.kpiIndex);
        this.selectedKPIWrapperIndex = kpiIndex;
        this.selectedKPIWrapper = this.kpiFields[kpiIndex];
        this.kpiFields = this.kpiFields.map((kpi, index) => {
            return {
                ...kpi,
                rowClass: index === kpiIndex ? 'selected-kpi' : ''
            };
        });
    }

    handleKPIFieldSelection(event) {
        this.selectedFieldToAdd = event.detail.value;
    }

    handleAddNewFieldWrapper() {
        if (!this.selectedFieldToAdd) return;
        let assortmentMatch = this.assortmentFieldOptions.find(f => f.value === this.selectedFieldToAdd);
        let asdMatch = this.assortmentDetailFieldOptions.find(f => f.value === this.selectedFieldToAdd);
        let fieldWrapper = {
            fieldName: this.selectedFieldToAdd,
            isAssortment: !!assortmentMatch,
            isASD: !!asdMatch,
            label: assortmentMatch?.label || asdMatch?.label
        };
        this.kpiFields[this.selectedKPIWrapperIndex].fields.push(fieldWrapper);
        this.availableKPIFieldOptions = this.availableKPIFieldOptions.filter(field => field.value !== this.selectedFieldToAdd);
        this.selectedFieldToAdd = null;
    }

    handleDeleteFieldWrapper(event) {
        const fieldIndex = Number(event.currentTarget.dataset.fieldIndex);
        const removed = this.kpiFields[this.selectedKPIWrapperIndex].fields.splice(fieldIndex, 1)[0];
        const opt = this.assortmentFieldOptions.find(option => option.value === removed.fieldName);
        if (opt) this.availableKPIFieldOptions = [...this.availableKPIFieldOptions, opt];
        this.selectedFieldToAdd = null;
    }

    handleKPIDragStart(event) {
        const row = event.currentTarget.closest('tr');
        this.draggedKPIIndex = parseInt(row.dataset.index, 10);
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedKPIIndex);
        row.classList.add('dragging');
    }

    handleKPIDragEnd(event) {
        event.currentTarget.closest('tr').classList.remove('dragging');
        this.template.querySelectorAll('tr.drag-over').forEach(tr => tr.classList.remove('drag-over'));
    }

    handleKPIDragOver(event) {
        event.preventDefault();
        event.currentTarget.classList.add('drag-over');
    }

    handleKPIDragEnter(event) {
        event.currentTarget.classList.add('drag-over');
    }

    handleKPIDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleKPIDrop(event) {
        event.preventDefault();
        const fromIndex = parseInt(event.dataTransfer.getData('text/plain'), 10);
        const toIndex = parseInt(event.currentTarget.dataset.index, 10);
        event.currentTarget.classList.remove('drag-over');
        if (fromIndex === toIndex) return;
        const movedItem = this.kpiFields.splice(fromIndex, 1)[0];
        this.kpiFields.splice(toIndex, 0, movedItem);
        this.reindexKPIs();
        this.selectedKPIWrapper = this.kpiFields[this.selectedKPIWrapperIndex];
    }

    handleDisplayEvolutionArrowsChange (event) {
        let value = event.target.checked;
        this.assortmentSettings.assortmentSimulatorConfiguration.displayEvolutionArrows = value;
    }
}