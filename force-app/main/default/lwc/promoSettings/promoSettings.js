import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getPicklistValues, getObjectInfo, getObjectInfos } from 'lightning/uiObjectInfoApi';
// Services
import loadPromoSettings from '@salesforce/apex/PromoSettingsController.loadPromoSettings';
import save from '@salesforce/apex/PromoSettingsController.save';
import checkDeploymentStatus from "@salesforce/apex/PromoSettingsController.checkDeploymentStatus";
// Custom Object
import CommercialPlan__OBJECT from '@salesforce/schema/CommercialPlan__c';
import CommercialPlanFollowup__OBJECT from '@salesforce/schema/CommercialPlanFollowup__c';
import CommercialPlanDetail__OBJECT from '@salesforce/schema/CommercialPlanDetail__c';
// CommercialPlan__c Fields
import CP_Status__c from '@salesforce/schema/CommercialPlan__c.Status__c';
import Supplier__c from '@salesforce/schema/CommercialPlan__c.Supplier__c';
import Hierarchy__c from '@salesforce/schema/CommercialPlan__c.Hierarchy__c';
import BusinessUnitTarget__c from '@salesforce/schema/CommercialPlan__c.BusinessUnitTarget__c';
import PromoAgreementType__c from '@salesforce/schema/CommercialPlan__c.PromoAgreementType__c';
// CommercialPlanFollowup__c Fields
import CPF_BudgetType__c from '@salesforce/schema/CommercialPlanFollowup__c.BudgetType__c';
// CommercialPlanDetail__c Fields
import CPD_BudgetType__c from '@salesforce/schema/CommercialPlanDetail__c.BudgetType__c';
import CPD_Status__c from '@salesforce/schema/CommercialPlanDetail__c.Status__c';
// Custom Labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Color from "@salesforce/label/c.LBL_Color";
import LBL_Background from "@salesforce/label/c.LBL_Background";
import LBL_Status from "@salesforce/label/c.LBL_Status";
import LBL_Available from "@salesforce/label/c.LBL_Available";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Promo_Settings from "@salesforce/label/c.LBL_Promo_Settings";
import LBL_myPromo from "@salesforce/label/c.LBL_myPromo";
import LBL_KPI_Filters from "@salesforce/label/c.LBL_KPI_Filters";
import LBL_Status_Colors_Management from "@salesforce/label/c.LBL_Status_Colors_Management";
import LBL_Global from "@salesforce/label/c.LBL_Global";
import LBL_Default from "@salesforce/label/c.LBL_Default";
import LBL_Promo_Calendar from "@salesforce/label/c.LBL_Promo_Calendar";
import LBL_Communication_FDV_PDV from "@salesforce/label/c.LBL_Communication_FDV_PDV";
import LBL_KPI_Setup from "@salesforce/label/c.LBL_KPI_Setup";
import LBL_Update_KPI_Setup from "@salesforce/label/c.LBL_Update_KPI_Setup";
import LBL_CPF_BudgetType from "@salesforce/label/c.LBL_CPF_BudgetType";
import LBL_CPD_BudgetType from "@salesforce/label/c.LBL_CPD_BudgetType";
import LBL_CPF_Field from "@salesforce/label/c.LBL_CPF_Field";
import LBL_Input from "@salesforce/label/c.LBL_Input";
import LBL_CPD_Field_Conso from "@salesforce/label/c.LBL_CPD_Field_Conso";
import LBL_CPD_Status from "@salesforce/label/c.LBL_CPD_Status";
import LBL_Available_Fields from "@salesforce/label/c.LBL_Available_Fields";
import LBL_Promo_Request from "@salesforce/label/c.LBL_Promo_Request";
import LBL_None from "@salesforce/label/c.LBL_None";
import MSG_Warning from "@salesforce/label/c.MSG_Warning";
import MSG_Error from "@salesforce/label/c.MSG_Error";
import MSG_Information from "@salesforce/label/c.MSG_Information";
import MSG_Success from "@salesforce/label/c.MSG_Success";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import LBL_NS_Stg_General_Settings from "@salesforce/label/c.LBL_NS_Stg_General_Settings";
import LBL_Grid_Settings_Template from "@salesforce/label/c.LBL_Grid_Settings_Template";
import LBL_PromoAgreementConfiguration from "@salesforce/label/c.LBL_PromoAgreementConfiguration";
import LBL_PromoAgreementConfiguration_GridManager_Title from "@salesforce/label/c.LBL_PromoAgreementConfiguration_GridManager_Title";
import LBL_PromoAgreementConfiguration_GridManagerHelpText from "@salesforce/label/c.LBL_PromoAgreementConfiguration_GridManagerHelpText";
import LBL_PromoAgreementConfiguration_Promo_Agreement_Grid from "@salesforce/label/c.LBL_PromoAgreementConfiguration_Promo_Agreement_Grid";
import LBL_PromoAgreementConfiguration_Promo_Agreement_Grouped_Fields from "@salesforce/label/c.LBL_PromoAgreementConfiguration_Promo_Agreement_Grouped_Fields";
import LBL_PromoAgreementConfiguration_Available_Fields from "@salesforce/label/c.LBL_PromoAgreementConfiguration_Available_Fields";
import LBL_PromoAgreementConfiguration_Groupable_Fields_Selected from "@salesforce/label/c.LBL_PromoAgreementConfiguration_Groupable_Fields_Selected";
import sortRight from '@salesforce/resourceUrl/sortRight';
import sortLeft from '@salesforce/resourceUrl/sortLeft';

const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';

const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const classPrefix = `${PREFIX ? PREFIX + '-' : 'c-'}promo-settings`;
export default class PromoSettings extends NavigationMixin(LightningElement) {
    // TRACK VARIABLES
    @track Labels = {
        LBL_Save,
        LBL_Color,
        LBL_Background,
        LBL_Status,
        LBL_Available,
        LBL_Error,
        MSG_Warning,
        MSG_Error,
        MSG_Information,
        MSG_Success,
        MSG_Deploy_Ended_With_Status,
        MSG_Save_Complete,
        MSG_Deploy_Last_Status,
        LBL_Promo_Settings,
        LBL_Default,
        LBL_myPromo,
        LBL_KPI_Filters,
        LBL_Status_Colors_Management,
        LBL_Global,
        LBL_Promo_Calendar,
        LBL_Communication_FDV_PDV,
        LBL_KPI_Setup,
        LBL_Update_KPI_Setup,
        LBL_CPF_BudgetType,
        LBL_CPD_BudgetType,
        LBL_CPF_Field,
        LBL_Input,
        LBL_CPD_Field_Conso,
        LBL_CPD_Status,
        LBL_Available_Fields,
        LBL_Promo_Request,
        LBL_None,
        LBL_NS_Stg_General_Settings,
        PromoSettings__mdt: {
            CPLayerNumbers__c: '',
            NumberOfMonthN1__c: '',
        },
        CommercialPlan__c: {
            CPLabel: '',
            Supplier__c: '',
            BusinessUnitTarget__c: '',
            PromoAgreementType__c: '',
            Hierarchy__c: '',
        },
        CommercialPlanFollowup__c: {
            BudgetType__c: '',
        },
        CommercialPlanDetail__c: {
            CPDLabel: '',
            BudgetType__c: '',
        },
        LBL_Grid_Settings_Template,
        LBL_PromoAgreementConfiguration,
        LBL_PromoAgreementConfiguration_GridManager_Title,
        LBL_PromoAgreementConfiguration_GridManagerHelpText,
        LBL_PromoAgreementConfiguration_Promo_Agreement_Grid,
        LBL_PromoAgreementConfiguration_Promo_Agreement_Grouped_Fields,
        LBL_PromoAgreementConfiguration_Available_Fields,
        LBL_PromoAgreementConfiguration_Groupable_Fields_Selected
    }
    @track API_NAMES = {
        PromoSettings__mdt: {
            objectAPIName: 'PromoSettings__mdt',
            CPLayerNumbers__c: 'CPLayerNumbers__c',
            NumberOfMonthN1__c: 'NumberOfMonthN1__c',
        },
        CommercialPlan__c: {
            objectApiName: CommercialPlan__OBJECT.objectApiName,
            Supplier__c: Supplier__c.fieldApiName,
            Hierarchy__c: Hierarchy__c.fieldApiName,
            BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
            PromoAgreementType__c: PromoAgreementType__c.fieldApiName,
            Status__c: CP_Status__c.fieldApiName,
        },
        CommercialPlanFollowup__c: {
            objectApiName: CommercialPlanFollowup__OBJECT.objectApiName,
            BudgetType__c: CPF_BudgetType__c.fieldApiName,
        },
        CommercialPlanDetail__c: {
            objectApiName: CommercialPlanDetail__OBJECT.objectApiName,
            BudgetType__c: CPD_BudgetType__c.fieldApiName,
        },
    }
    @track settings = {};
    @track loadedWireMethods = {
        objectInfosLoaded: false,
        CPFBudgetTypePicklistValues: false,
        CPDBudgetTypePicklistValues: false,
        CPDStatusPicklistValues: false,
        CPStatusValues: false,
        wiredPromoAgreementTypes: false,
        get fullyLoaded() {
            return (
                this.objectInfosLoaded &&
                this.CPFBudgetTypePicklistValues &&
                this.CPDBudgetTypePicklistValues &&
                this.CPDStatusPicklistValues &&
                this.CPStatusValues &&
                this.wiredPromoAgreementTypes
            );
        }
    };

    @track CPFBudgetTypePicklist = [];
    @track selectedCPFBudgetType;
    @track availableCPDBudgetTypes = [];
    @track availableCPFFields = [];
    @track CPDFieldsOptions = [];
    @track stringifiedCPDStatusOptions = '';
    @track loading = false;
    @track promoSettings = {};
    @track budgetTypeCPFOptions = [];
    @track CPFFieldsMap = {};
    @track CPDBudgetTypePicklist = [];
    @track CPDStatusPicklist = [];
    @track loadingCPFBudgetType = false;
    @track promoAgreementTypeOptions = [];
    @track promoAgreementManagerGridOptions = [];
    @track promoAgreementGridGridOptions = [];
    @track promoAgreementConfiguration = {};
    @track selectedPromoAgreementsGrid = '';
    @track CPDGroupableFields = [];
    @track availableGroupableFields = [];
    @track selectedGroupableFields = [];
    @track selectedGroupableFieldsMap = new Set();
    @track groupSearchTerm = '';
    @track sortRight = sortRight;
    @track sortLeft = sortLeft;

    //VARIABLES
    mainPanelHeight;
    decimalFieldTypes = ['CURRENCY', 'PERCENT', 'DOUBLE', 'INTEGER', 'LONG'];
    cpStatusPicklistValues = [];
    objectInfosResult;

    // GETTERS
    get numberOfMonths() {
        return [
            { label: this.Labels.LBL_None, value: null },
            { label: 1, value: 1 },
            { label: 2, value: 2 },
            { label: 3, value: 3 },
            { label: 4, value: 4 },
            { label: 5, value: 5 },
            { label: 6, value: 6 },
            { label: 7, value: 7 },
            { label: 8, value: 8 },
            { label: 9, value: 9 },
            { label: 10, value: 10 },
            { label: 11, value: 11 },
            { label: 12, value: 12 }];
    }

    //WIRES
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: CPF_BudgetType__c }) CPFBudgetTypePicklistValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                let obj = {
                    label: item.label,
                    value: item.value
                }
                this.CPFBudgetTypePicklist.push(obj);
            }
            this.loadedWireMethods.CPFBudgetTypePicklistValues = true;
            this.loadData();
        } else {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: CPD_BudgetType__c }) CPDBudgetTypePicklistValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                let obj = {
                    label: item.label,
                    value: item.value,
                }
                this.CPDBudgetTypePicklist.push(obj);
                this.loadData();
            }
            this.loadedWireMethods.CPDBudgetTypePicklistValues = true;
        } else {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: CPD_Status__c }) CPDStatusPicklistValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                let obj = {
                    label: item.label,
                    value: item.value,
                }
                this.CPDStatusPicklist.push(obj);
            }
            this.stringifiedCPDStatusOptions = JSON.stringify(this.CPDStatusPicklist);
            this.loadedWireMethods.CPDStatusPicklistValues = true;
            this.loadData();
        } else {
            this.stringifiedCPDStatusOptions = '';
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: CP_Status__c }) CPStatusValues({ error, data }) {
        if (data) {
            for (let status of data.values) {
                this.cpStatusPicklistValues.push(status.value);
            }
            this.loadedWireMethods.CPStatusValues = true;
            this.loadData();
        } else {
            console.log(error);
        }
    }

    @wire(getObjectInfos, {
        objectApiNames: [CommercialPlan__OBJECT.objectApiName,
        CommercialPlanDetail__OBJECT.objectApiName,
        CommercialPlanFollowup__OBJECT.objectApiName]
    }) wiredObjectInfos(result) {
        try {
            this.objectInfosResult = result;
            const { data, error } = result;
            if (error) {
                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.Labels.LBL_Error,
                        message: message,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }),
                );
            }
            if (data) {
                this.loadedWireMethods.objectInfosLoaded = true;
            }
            this.processObjectInfosResult(this, this.objectInfosResult);
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: PromoAgreementType__c }) wiredPromoAgreementTypes({ error, data }) {
        if (data) {
            this.promoAgreementTypeOptions = data.values.map(item => {
                return { label: item.label, value: item.value };
            });
            this.loadedWireMethods.wiredPromoAgreementTypes = true;
            this.processObjectInfosResult(this, this.objectInfosResult);
        } else if (error) {
            console.error('Error loading PromoAgreementType__c picklist:', error);
        }
    }

    Events = {
        handleChangeCPDStatusValues: 'handlechangecpdstatusvalues',
    }

    connectedCallback() {
        Promise.all([
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style')
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

    processObjectInfosResult(self, result) {
        try {
            const { data, error } = result;
            if (data && data.results) {
                // CommercialPlan__c fields
                let CPResult = data.results.find(item => item.result.apiName == self.API_NAMES.CommercialPlan__c.objectApiName);
                if (CPResult) {
                    self.Labels.CommercialPlan__c.CPLabel = CPResult.result.label;
                    self.Labels.CommercialPlan__c.Supplier__c = CPResult.result.fields[self.API_NAMES.CommercialPlan__c.Supplier__c].label;
                    self.Labels.CommercialPlan__c.BusinessUnitTarget__c = CPResult.result.fields[self.API_NAMES.CommercialPlan__c.BusinessUnitTarget__c].label;
                    self.Labels.CommercialPlan__c.Hierarchy__c = CPResult.result.fields[self.API_NAMES.CommercialPlan__c.Hierarchy__c].label;
                    self.Labels.CommercialPlan__c.PromoAgreementType__c = CPResult.result.fields[self.API_NAMES.CommercialPlan__c.PromoAgreementType__c].label;
                }
                // CommercialPlanFollowup__c fields
                let CPFResult = data.results.find(item => item.result.apiName == self.API_NAMES.CommercialPlanFollowup__c.objectApiName);
                self.CPFFieldsMap = {};
                if (CPFResult) {
                    self.Labels.CommercialPlanFollowup__c.BudgetType__c = CPFResult.result.fields[self.API_NAMES.CommercialPlanFollowup__c.BudgetType__c].label;
                    Object.values(CPFResult.result.fields).forEach(field => {
                        let dataType = field.dataType.toLocaleUpperCase();
                        if (self.decimalFieldTypes.includes(dataType)) {
                            self.CPFFieldsMap[field.apiName] = {
                                fieldName: field.apiName,
                                fieldLabel: field.label
                            };
                        }
                    });
                }
                // CommercialPlanDetail__c fields
                let CPDResult = data.results.find(item => item.result.apiName == self.API_NAMES.CommercialPlanDetail__c.objectApiName);
                self.CPDFieldsOptions = [];
                if (CPDResult) {
                    self.Labels.CommercialPlanDetail__c.CPDLabel = CPDResult.result.label;
                    self.Labels.CommercialPlanDetail__c.BudgetType__c = CPDResult.result.fields[self.API_NAMES.CommercialPlanDetail__c.BudgetType__c].label;
                    Object.values(CPDResult.result.fields).forEach(field => {
                        let dataType = field.dataType.toLocaleUpperCase();
                        if (self.decimalFieldTypes.includes(dataType)) {
                            let obj = {
                                value: field.apiName,
                                label: field.label
                            };
                            self.CPDFieldsOptions.push(obj);
                        }
                    });
                }
            }
            self.loadData();
        } catch (error) {
            console.log('ERROR: ' + error);
            self.dispatchEvent(new ShowToastEvent({
                title: self.Labels.LBL_Error,
                message: error,
                variant: ERROR_VARIANT,
                mode: STICKY_VARIANT
            }));
        }
    }

    renderedCallback() {
        if (this.template.querySelector('.header')) {
            this.changeHeight();
        }
    }

    loadData() {
        if (this.loadedWireMethods.fullyLoaded) {
            this.loading = true;
            loadPromoSettings().then((result) => {
                let parsedResult = JSON.parse(result);
                this.promoAgreementManagerGridOptions = parsedResult.gridSettingsCPDLayouts || [];
                this.promoAgreementGridGridOptions = parsedResult.gridSettingsCPLayouts || [];
                this.settings = parsedResult.settings;
                this.CPDGroupableFields = (parsedResult.CPDGroupableFields || []).map(f => ({
                    apiName: f.value,
                    label: f.label,
                    isSelected: false
                }));
                const selected = this.settings?.promoAgreementConfiguration?.promoAgreementGroupedFields || [];
                this.selectedGroupableFieldsMap = new Set(selected);
                this.availableGroupableFields = this.CPDGroupableFields
                    .filter(field => !this.selectedGroupableFieldsMap.has(field.apiName))
                    .map(field => ({ ...field, isSelected: false }));
                this.selectedGroupableFields = this.CPDGroupableFields
                    .filter(field => this.selectedGroupableFieldsMap.has(field.apiName))
                    .map(field => ({ ...field, isSelected: false }));

                this.selectedPromoAgreementsGrid = this.settings?.promoAgreementConfiguration?.promoAgreementsGrid || '';
                this.promoAgreementGridConfigurations = this.promoAgreementTypeOptions.map(item => {
                    return {
                        label: item.label,
                        value: item.value,
                        gridSettings: this.settings.promoAgreementConfiguration?.promoAgreementsManagerGrid[item.value] || ''
                    };
                });
                this.API_NAMES.PromoSettings__mdt = {
                    objectAPIName: parsedResult.prefix + 'PromoSettings__mdt',
                    CPLayerNumbers__c: parsedResult.prefix + 'CPLayerNumbers__c',
                    NumberOfMonthN1__c: parsedResult.prefix + 'NumberOfMonthN1__c',
                };
                this.setLabels(parsedResult.fieldsMap);
                this.loading = false;
            }).catch(error => {
                this.loading = false;
                console.log('ERROR: ' + error.message);
                console.error(error);
            });
        }
    }

    handleGridSettingChange(event) {
        const index = event.target.dataset.index;
        const newValue = event.detail.value;
        this.promoAgreementGridConfigurations[index].gridSettings = newValue;
    }

    handlePromoAgreementsGridChange(event) {
        this.selectedPromoAgreementsGrid = event.detail.value;
    }
    handleFieldSelect(event) {
        const id = event.currentTarget.dataset.id;
        this.availableGroupableFields = this.availableGroupableFields.map(f => ({ ...f, isSelected: f.apiName === id ? !f.isSelected : false }));
    }
    handleFieldDeselect(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedGroupableFields = this.selectedGroupableFields.map(f => ({ ...f, isSelected: f.apiName === id ? !f.isSelected : false }));
    }
    handleGroupFieldSearch(event) {
        this.groupSearchTerm = event.target.value.toLowerCase();
        this.availableGroupableFields = this.CPDGroupableFields
            .filter(f =>
                !this.selectedGroupableFieldsMap.has(f.apiName) &&
                f.label.toLowerCase().includes(this.groupSearchTerm)
            )
            .map(f => ({ ...f, isSelected: false }));
    }
    moveSelectedFieldToRight() {
        const selected = this.availableGroupableFields.find(f => f.isSelected);
        if (!selected) return;
        selected.isSelected = false;
        this.availableGroupableFields = this.availableGroupableFields.filter(f => f.apiName !== selected.apiName);
        this.selectedGroupableFields = [...this.selectedGroupableFields, selected];
        this.selectedGroupableFieldsMap.add(selected.apiName);
    }
    moveSelectedFieldToLeft() {
        const selected = this.selectedGroupableFields.find(f => f.isSelected);
        if (!selected) return;
        selected.isSelected = false;
        this.selectedGroupableFields = this.selectedGroupableFields.filter(f => f.apiName !== selected.apiName);
        this.availableGroupableFields = [...this.availableGroupableFields, selected];
        this.selectedGroupableFieldsMap.delete(selected.apiName);
    }

    setLabels(fieldsMap) {
        this.Labels.PromoSettings__mdt.CPLayerNumbers__c = fieldsMap[this.API_NAMES.PromoSettings__mdt.objectAPIName][this.API_NAMES.PromoSettings__mdt.CPLayerNumbers__c].label;
        this.Labels.PromoSettings__mdt.NumberOfMonthN1__c = fieldsMap[this.API_NAMES.PromoSettings__mdt.objectAPIName][this.API_NAMES.PromoSettings__mdt.NumberOfMonthN1__c].label;
    }

    handleChangeCPFBudgetType(event) {
        this.loadingCPFBudgetType = true;
        this.loading = true;
        for (let elm of this.template.querySelectorAll('.row-highlight') || []) {
            elm.classList.remove('row-highlight');
        }
        event.target.closest("tr").classList.add('row-highlight');
        this.selectedCPFBudgetType = event.target.dataset.kpiName;
        this.availableCPDBudgetTypes = [];
        this.availableCPFFields = [];
        this.CPDBudgetTypePicklist.forEach(item => {
            this.availableCPDBudgetTypes.push({ label: item.label, value: item.value, isSelected: false });
        });
        Object.values(this.CPFFieldsMap || {}).forEach(item => {
            this.availableCPFFields.push({
                key: this.selectedCPFBudgetType + '-' + item.fieldName,
                isSelected: false,
                fieldName: item.fieldName,
                fieldLabel: item.fieldLabel,
                isInput: false,
                CPDStatus: [],
                CPDFieldConso: '',
                get multiStatusSelectSerialized() {
                    return JSON.stringify(this.CPDStatus || []);
                },
            });
        });
        try {
            let KPISetup = this.settings.kpiSetups ? this.settings.kpiSetups.filter(item => item.CPFBudgetType == this.selectedCPFBudgetType) : [];
            if (KPISetup && KPISetup.length) {
                this.availableCPDBudgetTypes.forEach(item => {
                    item.isSelected = KPISetup[0].availableCPDBudgetTypes.includes(item.value);
                });
                this.availableCPFFields.forEach(item => {
                    let availableCPFField = KPISetup[0].availableCPFFields.filter(it => it.fieldName === item.fieldName);
                    if (availableCPFField && availableCPFField.length) {
                        item.isSelected = availableCPFField[0].isSelected;
                        item.isInput = availableCPFField[0].isInput;
                        item.CPDStatus = availableCPFField[0].CPDStatus && availableCPFField[0].CPDStatus.length ? availableCPFField[0].CPDStatus : [];
                        item.CPDFieldConso = availableCPFField[0].CPDFieldConso;
                    }
                });
                KPISetup[0].availableCPFFields = this.availableCPFFields;
            } else {
                let newKPISetup = {
                    CPFBudgetType: this.selectedCPFBudgetType,
                    availableCPDBudgetTypes: this.availableCPDBudgetTypes.filter(item => item.isSelected).map(item => item.value),
                    availableCPFFields: this.availableCPFFields,
                }
                this.settings.kpiSetups.push(newKPISetup);
            }
            this.loading = false;
            setTimeout(() => {
                this.loadingCPFBudgetType = false;
            }, 300);

        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeCPDBudgetType(event) {
        let value = event.target.dataset.value;
        let element = this.availableCPDBudgetTypes.find(item => item.value === value);
        element.isSelected = event.target.checked;
        this.availableCPDBudgetTypes = [...this.availableCPDBudgetTypes];
        let KPISetup = this.settings.kpiSetups.filter(item => item.CPFBudgetType === this.selectedCPFBudgetType);
        if (KPISetup && KPISetup.length) {
            KPISetup[0].availableCPDBudgetTypes = this.availableCPDBudgetTypes.filter(item => item.isSelected).map(item => item.value);
        }
    }

    handleChangeCPFField(event) {
        try {
            let CPFFieldName = event.target.dataset.field;
            let isSelected = event.target.checked;
            let KPISetup = this.settings.kpiSetups.filter(item => item.CPFBudgetType === this.selectedCPFBudgetType);
            if (KPISetup && KPISetup.length) {
                let availableCPFFields = KPISetup[0].availableCPFFields;
                if (availableCPFFields && availableCPFFields.length) {
                    let availableCPFField = availableCPFFields.filter(item => item.fieldName === CPFFieldName);
                    if (availableCPFField && availableCPFField.length) {
                        availableCPFField[0].isSelected = isSelected;
                    }
                }
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeCPFFieldInput(event) {
        try {
            let CPFFieldName = event.target.dataset.field;
            let isInput = event.target.checked;
            let KPISetup = this.settings.kpiSetups.filter(item => item.CPFBudgetType === this.selectedCPFBudgetType);
            if (KPISetup && KPISetup.length) {
                let availableCPFFields = KPISetup[0].availableCPFFields;
                if (availableCPFFields && availableCPFFields.length) {
                    let availableCPFField = availableCPFFields.filter(item => item.fieldName === CPFFieldName);
                    if (availableCPFField && availableCPFField.length) {
                        availableCPFField[0].isInput = isInput;
                        if (isInput) {
                            availableCPFField[0].CPDStatus = [];
                            availableCPFField[0].CPDFieldConso = '';
                        }
                    }
                }
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeCPDStatusValues(event) {
        try {
            let CPFFieldName = event.target.dataset.field;
            let statusValues = [];
            event.detail.selOptions.forEach(item => {
                statusValues.push(item.value);
            });
            let KPISetup = this.settings.kpiSetups.filter(item => item.CPFBudgetType === this.selectedCPFBudgetType);
            if (KPISetup && KPISetup.length) {
                let availableCPFFields = KPISetup[0].availableCPFFields;
                if (availableCPFFields && availableCPFFields.length) {
                    let availableCPFField = availableCPFFields.filter(item => item.fieldName === CPFFieldName);
                    if (availableCPFField && availableCPFField.length) {
                        availableCPFField[0].CPDStatus = statusValues;
                    }
                }
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeCPDFieldConso(event) {
        try {
            let CPFFieldName = event.target.dataset.field;
            let value = event.target.value;
            let KPISetup = this.settings.kpiSetups.filter(item => item.CPFBudgetType === this.selectedCPFBudgetType);
            if (KPISetup && KPISetup.length) {
                let availableCPFFields = KPISetup[0].availableCPFFields;
                if (availableCPFFields && availableCPFFields.length) {
                    let availableCPFField = availableCPFFields.filter(item => item.fieldName === CPFFieldName);
                    if (availableCPFField && availableCPFField.length) {
                        availableCPFField[0].CPDFieldConso = value;
                    }
                }
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChange(event) {
        let array = event.target.dataset.array;
        let type = event.target.dataset.type;
        let kpiName = event.target.dataset.kpiName;
        this[array].forEach(item => {
            if (item.name == kpiName) {
                item[type] = event.target.checked;
                if (type == 'isSelected' && !event.target.checked) {
                    item.isDefault = event.target.checked;
                }
            }
        });
    }

    handleStatusColorChange(event) {
        let status = event.target.dataset.status;
        let colorToChange = event.target.dataset.colortochange;
        this.settings.CPStatusColors.forEach(item => {
            if (item.name == status) {
                item[colorToChange] = event.target.value;
            }
        });
    }

    handleFieldChange(event) {
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.settings[field] = value != null ? parseInt(event.detail.value) : null;
    }

    handleSave(event) {
        this.loading = true;
        let KPISetups = [];
        this.settings.kpiSetups.forEach(item => {
            if ((item.availableCPDBudgetTypes && item.availableCPDBudgetTypes.length)
                || (item.availableCPFFields && item.availableCPFFields.length)) {
                let obj = {
                    CPFBudgetType: item.CPFBudgetType,
                    availableCPDBudgetTypes: item.availableCPDBudgetTypes,
                    availableCPFFields: item.availableCPFFields.filter(it => it.isSelected),
                };
                KPISetups.push(obj);
            }
        });
        this.settings.kpiSetups = KPISetups;
        const promoAgreementGridManagerConfigurations = {};
        this.promoAgreementGridConfigurations.forEach(item => {
            promoAgreementGridManagerConfigurations[item.value] = item.gridSettings;
        });
        this.settings.promoAgreementConfiguration.promoAgreementsManagerGrid = promoAgreementGridManagerConfigurations;
        this.settings.promoAgreementConfiguration.promoAgreementsGrid = this.selectedPromoAgreementsGrid;
        this.settings.promoAgreementConfiguration.promoAgreementGroupedFields = this.selectedGroupableFields.map(f => f.apiName);
        save({
            promoSettingsJSON: JSON.stringify(this.settings)
        }).then((result) => {
            this.checkDeployementStatus(result);
            this.loading = false;
        }).catch(error => {
            this.loading = false;
            console.log('ERROR: ' + error.message);
        });
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
                        self.dispatchEvent(new ShowToastEvent({
                            title: self.Labels.MSG_Information,
                            message: self.Labels.MSG_Request_Timed_Out + ' ' + self.Labels.MSG_Deploy_Last_Status + ' ' + status,
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
                            self.loading = false;
                            clearInterval(interval);
                            if (success) {
                                self.dispatchEvent(new ShowToastEvent({
                                    title: self.Labels.LBL_Save,
                                    message: self.Labels.MSG_Save_Complete,
                                    variant: SUCCESS_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            } else {
                                self.dispatchEvent(new ShowToastEvent({
                                    title: self.Labels.MSG_Information,
                                    message: self.Labels.MSG_Deploy_Ended_With_Status + ' ' + status,
                                    variant: INFO_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.loading = false;
                self.dispatchEvent(new ShowToastEvent({
                    title: self.Labels.LBL_Save,
                    message: self.Labels.MSG_Save_Complete,
                    variant: SUCCESS_VARIANT,
                    mode: STICKY_VARIANT
                }));
            }
        });
    }

    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.header') != null) {
            headerHeight = this.template.querySelector('.header').getBoundingClientRect().height;
        }
        let mainPanelHeight = window.innerHeight - headerHeight - 150;
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px;border-left:1.5mm ridge rgb(124 190 139 / 58%);';
    };
}