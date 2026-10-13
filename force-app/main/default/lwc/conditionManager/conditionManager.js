import { LightningElement, track, wire, api } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import {
    API_NAMES,
    Labels,
    showNotification,
    assignSlabsToDiscount,
    gridScrollHandler,
    cloneDiscount,
    setContractDetails,
    buildDiscountPageInfo,
    yearPanelFields,
    amtValueFields,
    nonRepetableFields,
    fakeSaveTrigger
} from './services.js';
import userId from '@salesforce/user/Id';
import createNewDiscount from "@salesforce/apex/ConditionManagerCmpController.createNewDiscount";
import fakeSave from "@salesforce/apex/ConditionManagerCmpController.fakeSave";
import populateFields from "@salesforce/apex/ConditionManagerCmpController.populateFields";
import SaveMultipleDiscounts from "@salesforce/apex/ConditionManagerCmpController.SaveMultipleDiscounts";
import simulateInvoicesGenerationForDiscounts from "@salesforce/apex/ConditionManagerCmpController.simulateInvoicesGenerationForDiscounts";
import loadSimpleData from "@salesforce/apex/ConditionManagerCmpController.loadSimpleData";
import loadGridSettings from "@salesforce/apex/ConditionManagerCmpController.loadGridSettings";
import LoadConditionList from "@salesforce/apex/ConditionManagerCmpController.LoadConditionList";
import smartDivision from "@salesforce/apex/ConditionManagerCmpController.smartDivision";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle } from "lightning/platformResourceLoader";
import { getRecord } from 'lightning/uiRecordApi';
import UserProfileFIELD from '@salesforce/schema/User.ProfileId';
import conditionManager_resources from "@salesforce/resourceUrl/conditionManager";
import negotiate from "@salesforce/resourceUrl/negotiate";
import generateAutomaticDispatch from "@salesforce/apex/ConditionManagerCmpController.generateAutomaticDispatch";
import reachProgressiveSlab from "@salesforce/apex/ConditionManagerCmpController.reachProgressiveSlab";
import DeleteDiscounts from "@salesforce/apex/ConditionManagerCmpController.DeleteDiscounts";
import fillProductScopeLst from "@salesforce/apex/ConditionManagerCmpController.fillProductScopeLst";
import loadSubdiscounts from "@salesforce/apex/ConditionManagerCmpController.loadSubdiscounts";
import refreshIndexValues from "@salesforce/apex/ConditionManagerCmpController.refreshIndexValues";
import consolidateContract from "@salesforce/apex/ConditionManagerCmpController.consolidateContract";
import initializeInvoice from "@salesforce/apex/ConditionManagerCmpController.initializeInvoice";
import generateInvoicesLines from "@salesforce/apex/ConditionManagerCmpController.generateInvoicesLines";
import getProductDiscountStatementDetails from "@salesforce/apex/ConditionManagerCmpController.getProductDiscountStatementDetails";
import synchroAdvancedContracts from "@salesforce/apex/ConditionManagerCmpController.synchroAdvancedContracts";
import { checkCompletedBatches } from 'c/appHelper';
// import getPicklistValuesByRecordType from "@salesforce/apex/ConditionManagerCmpController.getPicklistValuesByRecordType";
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const SUCCESS_VARIANT = 'success';
const INFO_VARIANT = 'info';
const _assignSlabsToDiscount = (wrapper, shouldSort, callback) => {
    assignSlabsToDiscount(wrapper, shouldSort);
    reachProgressiveSlab({ JSON_discount: JSON.stringify(wrapper.discount), JSON_tarrifCondition: JSON.stringify(wrapper.conditionType), JSON_contract: JSON.stringify(wrapper.contract) }).then(result => {
        let data = JSON.parse(result);
        Object.assign(wrapper.discount, data.discount);
        if (callback) callback();
    }).catch(error => {
        if (callback) callback();
        console.error(error);
    });
}
export default class ConditionManager extends NavigationMixin(LightningElement) {
    /**
    * Timeout
    */
    fakeSaveTimeout;
    /* Row Highlighted */
    node;
    prevNode;
    subdiscountNode;
    contractRecordId;
    @api height;
    @api recordId;
    @api objectApiName;
    @track showBannerAndFooter = true;
    @track showIndexSection = false;
    /* Page reference */
    @track isReadOnly = true;
    @track currentPageReference;
    @track errorMessage = "";
    @track gridEditModechanges = false;
    @track disableInvoiceField = false;
    @track ifExiistSbdiscount = false;
    @track requireConso = false;
    @track unableToLockUnlockPopUp = false;
    @track consoRunning = false;
    @track needConso = false;
    @track loadDiscounts = false;
    @track stickyColumnNumber = '3';
    @track API_NAMES = API_NAMES;
    @track negoYear;
    @track sBusinessType;
    @track discountPercentScale;
    get discPercentStep() {
        if (this.discountPercentScale) {
            let step = '.';
            for (let i = 0; i < this.discountPercentScale; i++) {
                if (i == this.discountPercentScale - 1) {
                    step += '1';
                    break;
                }
                step += '0';
            }
            return step;
        }
    }
    @track Allow_Dispatching_in_Condition_List = false;
    @track showWarningPopupBeforeSave = false;
    @track showQuantityManagementWarning = false;
    @track showValuesEmptyWarning = false;
    @track showCAAssietteWarning = false;
    @track negoScopeId;
    @track showPDSDPopup = false;
    @track PDSDWrapper = {
        fields: [],
        PDSWrapper: [],
    }
    /* Page */
    @track contractLink;
    @track supplierNegoLink;
    @track contractBUName;
    @track SupplierNegoscopeName;
    @track contractCommercialBDate;
    @track contractCommercialEDate;
    @track statusContract;
    @track deleteActive;
    @track currentNameContract;
    @track contractBULink;
    @track contractTotalTOTariffNego;
    @track negotiateURL;
    @track negotiateFollowupURL;
    @track hasOverFlow = false;
    @track openSubPanel = false;
    @track openDetailSide = false;
    @track showDispatch = false;
    // @track manualInvoiceEdited = false;
    @track discountChangeEvent = false;
    @track showTariffSelection = false;
    @track detailPageOpen = false;
    @track showNegoScopeSelection = false;
    @track showBUSelection = false;
    @track fromDetailsTab = false;
    @track isFilterOpen = false;
    @track tempSlabs = [];
    @track stencilRowList = [1, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1, 0.05];
    @track loadedWireMethods = {
        contractInfoLoaded: false,
        discountInfoLoaded: false,
        nsInfoLoaded: false,
        nsLinkInfoLoaded: false,
        picklistTranslation1: false,
        picklistTranslation2: false,
        tariffInfoLoaded: false,
        invoiceInfoLoaded: false,
        invoiceDetailsInfoLoaded: false,
        currentUserProfile: false,
        get fullyLoaded() {
            return (
                this.discountInfoLoaded &&
                this.contractInfoLoaded &&
                this.nsInfoLoaded &&
                this.nsLinkInfoLoaded &&
                this.tariffInfoLoaded &&
                this.picklistTranslation1 &&
                this.picklistTranslation2 &&
                this.currentUserProfile &&
                this.invoiceInfoLoaded &&
                this.invoiceDetailsInfoLoaded
            );
        }
    };
    @track labels = {
        ...Labels,
    };
    @track generatedStatus;
    @track printedStatus;
    @track cancelledStatus;
    @track generatedInvoicesArray = [];
    @track tableLabels = [
        Labels.LBL_ContractDiscountDownPayment1,
        Labels.LBL_ContractDiscountDownPayment2,
        Labels.LBL_ContractDiscountDownPayment3,
        Labels.LBL_ContractDiscountDownPayment4,
        Labels.LBL_ContractDiscountDownPayment5,
        Labels.LBL_ContractDiscountDownPayment6,
        Labels.LBL_ContractDiscountDownPayment7,
        Labels.LBL_ContractDiscountDownPayment8,
        Labels.LBL_ContractDiscountDownPayment9,
        Labels.LBL_ContractDiscountDownPayment10,
        Labels.LBL_ContractDiscountDownPayment11,
        Labels.LBL_ContractDiscountDownPayment12
    ];
    @track conditionLabelsLength;
    @track currentContract = {};
    @track wDiscList = [];
    @track numberOfNewDiscount;
    @track newWDiscList = [];
    @track wDiscMap = {};
    @track conditionDetailsMap = [];
    @track subDiscountList = [];
    @track subDiscountMap = {};
    @track pageSettings = {
        mainGridSettings: 'Condition_Grid',
        subDiscountGridSettings: '',
        showSubDiscountColumn: false
    };
    @track pageSize = "300";
    @track offset = 0;
    @track total = 0;
    @track oldCurrentJSDiscountWrapper;
    @track currentJSDiscountWrapper;
    @track previousJSDiscountWrapperIndex;
    @track waitForCalculate = false;
    @track currentJSDiscountWrapperBackup;
    @track currentApexDiscountWrapperBackup;
    @track currentJSDiscountWrapperDetails;
    @track loading = true;
    @track saveLoading = false;
    @track consoLoading = false;
    @track conditionPage = {
        gridSettings: null,
        subGridSettings: null,
        wContractYearsMap: {},
        conditionConfigurations: {
            pickListTranslationStatusMap: {},
            isContractManagedByMaster: false,
            contractManagedByMasterMSG: '',
            showMaster: false,
        },
        objectsInfo: {}
    };
    @track pageHeader;
    @track indexButton;
    @track indexHeader;
    @track IndexPanel = "slds-utility-panel slds-grid slds-grid_vertical";
    @track tableHeader;
    @track icon;
    @track yearHeader;
    @track yearDetail;
    @track yearlabel;
    @track yearElement;
    @track yearInputLabel;
    @track detailHeader;
    @track indexPanelTransform;
    @track indexPanelOpened = false;
    @track mainContainer;
    @track apexNewDiscountWrapper;
    @track indexLoading;
    @track mainDiv = "slds-col slds-size_3-of-3 mainDiv";
    @track grisettingWidth = "25%";
    @track tariffToHasSubtermsMap = {};
    @track showGeneratePopup = false;
    @track currentStatusMSG;
    @track savePopUp = false;
    @track contractDiscountLabel = '';
    get hasPromoDiscs() {
        return this.wDiscList && this.wDiscList.length > 0 && this.wDiscList.some(item => item.isPromoDisc);
    }
    get isEditInvoicingPlanning() {
        return this.gridEditMode && !this.currentJSDiscountWrapper.isDiscountAdvancedOrigin;
    }
    get isManualInvoicingPlanning() {
        return this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c];
    }
    // Manual Configuration
    get isHideDownPaymentYECoverage() {
        if (this.isManualInvoicingPlanning) {
            return this.currentJSDiscountWrapper.Invoice_base__c != 'ActualYTD'
        } else false;
    }

    get hasDiscErrors() {
        return this.wDiscList && this.wDiscList.length > 0 && this.wDiscList.some(item => item.hasErrors);
    }

    get countAndOrderByText() {
        return this.wDiscList ? this.labels.LBL_Condition_Manager_Count_and_OrderBY.replace('{0}', this.wDiscList.length) : '';
    }

    get maxSequence() {
        switch (this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Invoice_period__c]) {
            case 'Month':
                return 12;
                break;

            case 'Trimester':
                return 4;
                break;
            case 'Semester':
                return 2;
                break;

            case 'Year':
                return 1;
                break;

            default:
            // Code to execute if expression doesn't match any case
        }
    };
    //Slabs
    get isSlabsEditable() {
        return this.currentJSDiscountWrapper && ((/*this.gridEditMode &&*/ !this.isReadOnly && !this.currentJSDiscountWrapper.isLockedDiscount) || (this.currentJSDiscountWrapper.isNewDiscount)) && !this.isContractNegobaseInit;
    }
    /**
    * batch control
    */
    get isEnableCalculateTOContractBatch() {
        return this?.conditionPage?.batchControlMap['CalculateTOContractBatch'];
    }
    get isEnableGenerateInvoicesBatch() {
        return this?.conditionPage?.batchControlMap['GenerateInvoicesBatch'];
    }
    get isEnableGenerateGRCRatesBatch() {
        return this?.conditionPage?.batchControlMap['GenerateGRCRatesBatch'];
    }
    get isEnableSimulateAmount() {
        return this?.conditionPage?.batchControlMap['SimulateAmount'];
    }
    get isCPG() {
        return this?.sBusinessType == 'CPG';
    }
    get stickyColumnsOptions() {
        let stickyColumnsOptions = [];
        for (let index = 1; index <= 8; index++) {
            stickyColumnsOptions.push({ value: '' + index, label: '' + index });
        }
        return stickyColumnsOptions;
    }
    get amtErrorMessage() { return Labels.MSG_Error_Subdiscounts_Out_Of_Scope.replace(/\{0\}/gi, this.labels.object.Contract_Discount__c.Value_amt__c) };
    get perErrorMessage() { return Labels.MSG_Error_Subdiscounts_Out_Of_Scope.replace(/\{0\}/gi, this.labels.object.Contract_Discount__c.Value_per__c) };
    get amtWarningMessage() { return Labels.MSG_Warning_Subdiscounts_Out_Of_Scope.replace(/\{0\}/gi, this.labels.object.Contract_Discount__c.Value_amt__c) };
    get perWarningMessage() { return Labels.MSG_Warning_Subdiscounts_Out_Of_Scope.replace(/\{0\}/gi, this.labels.object.Contract_Discount__c.Value_per__c) };
    get massDeleteActive() {
        return this.deleteActive && (this.wDiscList.filter(item => !item.controlledByAdvanced).length > 0 || this.newWDiscList.length > 0);
    }
    get massCloneActive() {
        return this.wDiscList.filter(item => !item.controlledByAdvanced).length > 0 || this.newWDiscList.length > 0;
    }
    get showButtonMenu() {
        return this.massDeleteActive || this.massCloneActive;
    }
    @track showErrorPercent = false;
    @track showErrorAmount = false;
    @track showWarningPercent = false;
    @track showWarningAmount = false;
    /**
    * Grid
    */
    @track gridEditMode = false;
    // @track showaspopup = false;
    @track showaspopup = true;
    @track selectedId;
    @track selectedIndex;
    @track disabledButtonEdit = false;
    // @track checkManagement = false;
    /**
    * Negoscope Selection
    */
    @track negoscopes = [];
    @track negoscopesForSelection = [];
    @track negoscopesLoaded = false;
    @track negoscopeSearch = "";
    /**
    * BU Selection
    */
    get subBUs() {
        return this.BUs.filter(item => item.BU[API_NAMES.BusinessUnit__c.SetAgreementLineSubTerm__c]);
    }
    @track BUs = [];
    @track BUForSelection = [];
    @track BULoaded = false;
    @track BUSearch = "";
    @track tempInvoices = [];
    @track selectionChanged = false;
    @track mapOldDiscounts = {};
    @track currentUserProfile;
    get negoDiscountTypeOptions() {
        // TODO: review => I replaced API_NAMES.Contract_Discount__c.Nego_Discount_Type__c by 'Nego_Discount_Type__c' because it was causing issues in package
        return [{ value: '', label: Labels.LBL_None }, ...this.labels?.picklist?.Contract_Discount__c['Nego_Discount_Type__c']];
    }
    /**
    * Wires
    */
    @wire(getRecord, { recordId: userId, fields: [UserProfileFIELD] })
    currentUserInfo({ error, data }) {
        if (data) {
            this.currentUserProfile = data.fields.ProfileId.value || '';
            this.loadedWireMethods.currentUserProfile = true;
        } else if (error) {
            console.error(error)
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: API_NAMES.Contract_Discount__c.object.objectApiName, recordTypeId: '012000000000000AAA', })
    picklistTranslation1({ error, data }) {
        if (data) {
            Object.keys(API_NAMES.Contract_Discount__c).forEach(key => {
                if (data.picklistFieldValues.hasOwnProperty(API_NAMES.Contract_Discount__c[key])) {
                    this.labels.picklist.Contract_Discount__c[key] = data.picklistFieldValues[API_NAMES.Contract_Discount__c[key]].values;
                }
            });
            this.loadedWireMethods.picklistTranslation1 = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: API_NAMES.Pol_Com_Condition__c.object.objectApiName, recordTypeId: '012000000000000AAA', })
    picklistTranslation2({ error, data }) {
        if (data) {
            Object.keys(API_NAMES.Pol_Com_Condition__c).forEach(key => {
                if (data.picklistFieldValues.hasOwnProperty(API_NAMES.Pol_Com_Condition__c[key])) {
                    this.labels.picklist.Pol_Com_Condition__c[key] = data.picklistFieldValues[API_NAMES.Pol_Com_Condition__c[key]].values;
                }
            });
            this.loadedWireMethods.picklistTranslation2 = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.Contract_Discount__c.object.objectApiName })
    wiredContractDiscountInfo({ error, data }) {
        if (data) {
            this.contractDiscountLabel = data.label;
            this.conditionPage.objectsInfo.Contract_Discount__c = data;
            this.conditionPage.objectsInfo.ScaleFields = {};
            this.conditionPage.objectsInfo.ScaleFields.Contract_Discount__c = {};
            this.conditionPage.objectsInfo.ScaleFields.Contract_Discount__c.Value_per__c = data.fields[API_NAMES.Contract_Discount__c.Value_per__c].scale;
            Object.keys(API_NAMES.Contract_Discount__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.Contract_Discount__c[key])) {
                    this.labels.object.Contract_Discount__c[key] = data.fields[API_NAMES.Contract_Discount__c[key]].label;
                }
            });
            this.loadedWireMethods.discountInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.Invoice__c.object.objectApiName })
    wiredInvoiceInfo({ error, data }) {
        if (data) {
            Object.keys(API_NAMES.Invoice__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.Invoice__c[key])) {
                    this.labels.object.Invoice__c[key] = data.fields[API_NAMES.Invoice__c[key]].label;
                }
            });
            this.loadedWireMethods.invoiceInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.InvoiceDetail__c.object.objectApiName })
    wiredInvoiceDetailInfo({ error, data }) {
        if (data) {
            Object.keys(API_NAMES.InvoiceDetail__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.InvoiceDetail__c[key])) {
                    this.labels.object.InvoiceDetail__c[key] = data.fields[API_NAMES.InvoiceDetail__c[key]].label;
                }
            });
            this.loadedWireMethods.invoiceDetailsInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.Contract__c.object.objectApiName })
    wiredContractInfo({ error, data }) {
        if (data) {
            this.conditionPage.objectsInfo.Contract__c = data;
            Object.keys(API_NAMES.Contract__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.Contract__c[key])) {
                    this.labels.object.Contract__c[key] = data.fields[API_NAMES.Contract__c[key]].label;
                }
            });
            this.loadedWireMethods.contractInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.NegoScope__c.object.objectApiName })
    wiredNegoscopeInfo({ error, data }) {
        if (data) {
            this.conditionPage.objectsInfo.NegoScope__c = data;
            Object.keys(API_NAMES.NegoScope__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.NegoScope__c[key])) {
                    this.labels.object.NegoScope__c[key] = data.fields[API_NAMES.NegoScope__c[key]].label;
                }
            });
            this.loadedWireMethods.nsInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.NSLink__c.object.objectApiName })
    wiredNSLinkInfo({ error, data }) {
        if (data) {
            this.conditionPage.objectsInfo.NSLink__c = data;
            Object.keys(API_NAMES.NSLink__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.NSLink__c[key])) {
                    this.labels.object.NSLink__c[key] = data.fields[API_NAMES.NSLink__c[key]].label;
                }
            });
            this.loadedWireMethods.nsLinkInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.Pol_Com_Condition__c.object.objectApiName })
    wiredTariffInfo({ error, data }) {
        if (data) {
            // this.polComConditionLabel = data.label;
            this.conditionPage.objectsInfo.Pol_Com_Condition__c = data;
            Object.keys(API_NAMES.Pol_Com_Condition__c).forEach(key => {
                if (data.fields.hasOwnProperty(API_NAMES.Pol_Com_Condition__c[key])) {
                    this.labels.object.Pol_Com_Condition__c[key] = data.fields[API_NAMES.Pol_Com_Condition__c[key]].label;
                }
            });
            this.loadedWireMethods.tariffInfoLoaded = true;
            this.loadConditionsList();
        } else if (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.contractRecordId = this.recordId || this.currentPageReference.state.c__recordId;
        if (this.contractRecordId != null) {
            this.recordIdChecked = false;
            this.loadConditionsList();
        }
    }
    /**
    * Getters
    */
    get disableSave() {
        return this.hasOverFlow || this.isReadOnly;
    }
    get subdiscountPanelClassHeader() {
        return this.openSubPanel ? '' : 'slds-hide';
    }
    get subdiscountPanelClass() {
        return this.openSubPanel ? 'slds-card SubDiscounts' : 'slds-card SubDiscounts slds-hide';
    }
    get openedDetailGrid() {
        if ((this.currentJSDiscountWrapper == null && !this.discountChangeEvent) ||
            (this.currentJSDiscountWrapper != null && this.currentJSDiscountWrapper.isNewDiscount == null) ||
            this.currentJSDiscountWrapper != null && !this.openDetailSide) {
            return 'slds-col slds-size_3-of-3';
        }
        return 'slds-col slds-size_2-of-3';
    }
    get contractDiscountInfoLoaded() {
        return this.conditionPage.objectsInfo.Contract_Discount__c != null;
    }
    /**
    * manual invoices getters
    */
    get allowConfirmation() {
        let hasAtleastOneSelected = false;
        for (let invoice of this.tempInvoices) {
            if (invoice.isSelected) {
                hasAtleastOneSelected = true;
                break;
            }
        }
        return !this.selectionChanged || !hasAtleastOneSelected;
    }
    get checkIfcurrentJSDiscountWrapperExists() {
        if (this.currentJSDiscountWrapper != null) {
            return true;
        }
        return false;
    }
    get checkIfDetailTabOpen() {
        if (this.currentJSDiscountWrapper != null && this.currentJSDiscountWrapper.discount.Id) {
            return true;
        }
        return false;
    }
    get previousDisabled() {
        return this.offset == 0;
    }
    //next and last button status
    get nextDisabled() {
        let pageSize = parseInt(this.pageSize, 10);
        return this.offset + pageSize >= this.total;
    }
    get cascadeRankEmpty() {
        if (!this.currentJSDiscountWrapper
            || !(this.currentJSDiscountWrapper?.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c] || this.currentJSDiscountWrapper?.conditionType[API_NAMES.Pol_Com_Condition__c.Index__c] == 'Index1')
            || this.currentJSDiscountWrapper?.discount[API_NAMES.Contract_Discount__c.Rank__c]) {
            return false;
        } else {
            return true;
        }
    }
    get contractStatus() {
        if (API_NAMES.Contract__c.Status__c
            && this.currentContract
            && this.currentContract[API_NAMES.Contract__c.Status__c]
            && this.conditionPage.conditionConfigurations.pickListTranslationStatusMap
            && this.conditionPage.conditionConfigurations.pickListTranslationStatusMap[API_NAMES.Contract__c.Status__c]
            && this.conditionPage.conditionConfigurations.pickListTranslationStatusMap[API_NAMES.Contract__c.Status__c][this.currentContract[API_NAMES.Contract__c.Status__c]]
        ) {
            return this.conditionPage.conditionConfigurations.pickListTranslationStatusMap[API_NAMES.Contract__c.Status__c][this.currentContract[API_NAMES.Contract__c.Status__c]];
        }
    }
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize, 10);
        let offset = parseInt(this.offset, 10);
        if (this.wDiscList.length > 0) {
            return (offset + 1 + "-" + (offset + pageSize < this.total ? offset + pageSize : this.total) + " " + "of" + " " + this.total);
        } else if (this.wDiscList.length === 0) {
            return (offset + "-" + (offset + pageSize < this.total ? offset + 0 : this.total) + " " + "of" + " " + 0);
        }
        return (offset + 1 + "-" + (offset + pageSize < this.total ? offset + pageSize : this.total) + " " + "of" + " " + this.total);
    }
    closePopuUp() {
        this.showWarningPopupBeforeSave = false;
        this.showQuantityManagementWarning = false;
        this.showValuesEmptyWarning = false;
        this.showCAAssietteWarning = false;
        this.saveLoading = false;
    }
    @track showNegoScopeSlab = false;
    loadNegoscopes(event) {
        try {
            let field = event.target.dataset.field;
            this.showNegoScopeSlab = field == API_NAMES.Contract_Discount__c.NegoScopeSlab__c;
            let discount = this.currentJSDiscountWrapper.discount;
            let processSelection = () => {
                this.negoscopesForSelection?.forEach(item => {
                    item.negoscopeClass = item.Id == discount[API_NAMES.Contract_Discount__c.Product_Scope__c] ? 'row-ns-highlight' : '';
                });
            }
            if (!this.negoscopesLoaded) {
                fillProductScopeLst({
                    nsId: this.currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c]
                }).then((result) => {
                    let negoscopes = JSON.parse(result);
                    for (let nego in negoscopes) {
                        negoscopes[nego]["index"] = nego;
                    }
                    this.negoscopes = negoscopes;
                    this.negoscopesForSelection = negoscopes;
                    this.negoscopesLoaded = true;
                    processSelection();
                    this.showNegoScopeSelection = true;
                }).catch((apexError) => {
                    console.error(apexError);
                    showNotification(this, Labels.LBL_Error, apexError?.body?.message || apexError?.message || apexError, ERROR_VARIANT);
                });
            } else {
                processSelection();
                this.showNegoScopeSelection = true;
            }
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    filterNegoscopes(event) {
        this.negoscopeSearch = event.target.value;
        let filteredOptions = [];
        let regex = new RegExp(this.negoscopeSearch, "i");
        //
        for (let option of this.negoscopes) {
            if (regex.test(option.negoscopeName)) {
                filteredOptions.push(option);
            }
        }
        this.negoscopesForSelection = filteredOptions;
    }
    handleNegoscopeChanges(event) {
        try {
            let nsId = event.target.dataset.id;
            let nsIndex = event.target.dataset.index;
            if (this.showNegoScopeSlab) {
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.NegoScopeSlab__c] = nsId;
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.NegoScopeSlab__r] = this.negoscopes[nsIndex].negoScope;
                this.currentJSDiscountWrapper.negoScopeSlab = this.negoscopes[nsIndex].negoScope.Name;
            } else {
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__c] = nsId;
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__r] = this.negoscopes[nsIndex].negoScope;
                for (let gridField of this.currentJSDiscountWrapper.values) {
                    if (gridField.isProductScope) {
                        gridField.link = "/" + nsId;
                        gridField.fieldValue =
                            this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__r]?.Name;
                        break;
                    }
                }
            }
            this.currentJSDiscountWrapper.hasBeenEdited = true;
            this.closeNegoscopeSelection();
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @track showBUSlab = false;
    openBUs(event) {
        try {
            let field = event.target.dataset.field;
            this.showBUSlab = field == API_NAMES.Contract_Discount__c.BusinessUnitSlab__c;
            this.showBUSelection = true;
            this.BUForSelection = this.BUs.filter(item => item.BU[API_NAMES.BusinessUnit__c.SetAgreementLineMainTerm__c]);
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    filterBUs(event) {
        this.BUSearch = event.target.value;
        let filteredOptions = [];
        let regex = new RegExp(this.BUSearch, "i");
        //
        for (let option of this.BUs.filter(item => item.BU[API_NAMES.BusinessUnit__c.SetAgreementLineMainTerm__c])) {
            if (regex.test(option.BUName)) {
                filteredOptions.push(option);
            }
        }
        this.BUForSelection = filteredOptions;
    }
    handleBUChanges(event) {
        try {
            let buId = event.target.dataset.id;
            let buIndex = event.target.dataset.index;
            if (this.showBUSlab) {
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitSlab__c] = buId;
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitSlab__r] = this.BUs[buIndex].BU;
                this.currentJSDiscountWrapper.BUSlab = this.BUs[buIndex].BU.Name;
            } else {
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = buId;
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = this.BUs[buIndex].BU;
                for (let gridField of this.currentJSDiscountWrapper.values) {
                    if (gridField.isBU) {
                        gridField.link = "/" + buId;
                        gridField.fieldValue = this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r]?.Name;
                        break;
                    }
                }
                if (this.currentJSDiscountWrapper.subsLoaded) {
                    for (let sub of this.currentJSDiscountWrapper.subDiscountList) {
                        sub.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = buId;
                        sub.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = this.BUs[buIndex].BU;
                    }
                    this.assignSubDiscountsToLWC();
                }
            }
            this.currentJSDiscountWrapper.hasBeenEdited = true;
            this.closeBUSelection();
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    /**
    * Page settings
    */
    assignSubDiscountsToLWC() {
        setTimeout(() => {
            try {
                this.subDiscountList = this.subDiscountList.sort((it1, it2) => {
                    if (it1?.discount.Id && it2?.discount.Id || !it1?.discount.Id && !it2?.discount.Id) {
                        // return (it1?.isSelected == it2?.isSelected ? it1?.conditionType?.Name?.localeCompare(it2?.conditionType?.Name) : (it1?.isSelected ? -1 : 1));
                        return it1?.conditionType?.Name?.localeCompare(it2?.conditionType?.Name);
                    } else if (it1?.discount.Id && !it2?.discount.Id) {
                        return -1;
                    } else if (!it1?.discount.Id && it2?.discount.Id) {
                        return 1;
                    }
                }).map((item, index) => {
                    item.index = index;
                    return item;
                });
                this.showErrorPercent = this.currentJSDiscountWrapper?.showErrorPercent || false;
                this.showErrorAmount = this.currentJSDiscountWrapper?.showErrorAmount || false;
                this.showWarningPercent = this.currentJSDiscountWrapper?.showWarningPercent || false;
                this.showWarningAmount = this.currentJSDiscountWrapper?.showWarningAmount || false;
                this.template.querySelector('.subDiscountLWC')?.buildDisplayedFields(JSON.stringify(this.subDiscountList));
                this.template.querySelector('.subDiscountLWC')?.setPercentAndAmount(this.currentJSDiscountWrapper?.discount[API_NAMES.Contract_Discount__c.Value_per_Y1__c] || 0, this.currentJSDiscountWrapper?.discount[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] || 0);
            } catch (error) {
                console.error(error);
                showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            }
        }, 200);
    }
    setLoadingInSubLWC(loading) {
        this.template.querySelector('.subDiscountLWC')?.setLoading(loading);
    }
    updateSubdiscount(event) {
        try {
            this.currentJSDiscountWrapper.hasBeenEdited = true;
            let updatedSub = JSON.parse(event.detail);
            let index = updatedSub.index;
            if (index >= this.currentJSDiscountWrapper.subDiscountList.length) {
                this.currentJSDiscountWrapper.subDiscountList.push(updatedSub);
            }
            for (let key of Object.keys(updatedSub.discount)) {
                this.currentJSDiscountWrapper.subDiscountList[index].discount[key] = updatedSub.discount[key];
            }
            this.currentJSDiscountWrapper.subDiscountList[index].isSelected = updatedSub.isSelected;
            this.conditionPage.conditionConfigurations.contractWrapper[!this.currentJSDiscountWrapper.isNewDiscount ? "discounts" : "newDiscounts"]
            [!this.currentJSDiscountWrapper.isNewDiscount ? this.currentJSDiscountWrapper.Id : this.currentJSDiscountWrapper.Index]
                .subDiscountsMap[this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]]
            [updatedSub.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]] = [...this.currentJSDiscountWrapper.subDiscountList].filter(item => item.discount[API_NAMES.Contract_Discount__c.Condition_Type__c] == updatedSub.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]);
            this.subDiscountList = this.currentJSDiscountWrapper.subDiscountList;
            this.assignSubDiscountsToLWC();
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
        this.showErrorPercent = this.currentJSDiscountWrapper?.showErrorPercent || false;
        this.showErrorAmount = this.currentJSDiscountWrapper?.showErrorAmount || false;
        this.showWarningPercent = this.currentJSDiscountWrapper?.showWarningPercent || false;
        this.showWarningAmount = this.currentJSDiscountWrapper?.showWarningAmount || false;
    }
    closeSubConditionPopUp(event) {
        this.openSubPanel = false;
        try {
            let rebuiltDiscount = buildDiscountPageInfo(this, this.oldCurrentJSDiscountWrapper, this.oldCurrentJSDiscountWrapper.discount, this.oldCurrentJSDiscountWrapper.Index, false, this.discountPercentScale);
            this.wDiscList[this.currentJSDiscountWrapper.Index] = rebuiltDiscount;
            if (this.currentJSDiscountWrapper != null && (this.currentJSDiscountWrapper.discount.Id === rebuiltDiscount.discount.Id || this.currentJSDiscountWrapper.Index === rebuiltDiscount.Index)) {
                this.conditionPage.conditionConfigurations.contractWrapper["discounts"][this.currentJSDiscountWrapper.discount.Id] = rebuiltDiscount;
                this.currentJSDiscountWrapper = rebuiltDiscount;
                this.subDiscountList = this.currentJSDiscountWrapper.subDiscountList;
                this.assignSubDiscountsToLWC();
            }
        } catch (exception) {
            console.error(exception);
            showNotification(this, Labels.LBL_Error, exception?.body?.message || exception?.message || exception, ERROR_VARIANT);
        }
        this.currentJSDiscountWrapper.loading = false;
    }
    confirmSubConditionPopUp(event) {
        let errorMessages = [];
        if (this?.currentJSDiscountWrapper?.showMessageOnSubDiscounts) {
            if (this.showErrorAmount) {
                errorMessages.push(this.amtErrorMessage);
            }
            if (this.showErrorPercent) {
                errorMessages.push(this.perErrorMessage);
            }
            if (!this.isCPG) {
                if (this.showWarningAmount) {
                    errorMessages.push(this.amtWarningMessage);
                }
                if (this.showWarningPercent) {
                    errorMessages.push(this.perWarningMessage);
                }
            }
        }
        if (errorMessages?.length) {
            showNotification(this, Labels.LBL_Error, errorMessages.join('\n'), ERROR_VARIANT, false);
        } else {
            // this.showaspopup = !this.showaspopup;
            this.openSubPanel = false;
            let rebuiltDiscount = buildDiscountPageInfo(this, this.currentJSDiscountWrapper, this.currentJSDiscountWrapper.discount, this.currentJSDiscountWrapper.Index, false, this.discountPercentScale);
            rebuiltDiscount.hasBeenEdited = true;
            this.oldCurrentJSDiscountWrapper = JSON.parse(JSON.stringify(rebuiltDiscount));
            if (this.currentJSDiscountWrapper) {
                setTimeout(() => {
                    this.assignSubDiscountsToLWC();
                    setTimeout(() => {
                        this.setPageSize();
                    }, 200);
                }, 200);
            }
        }
    }
    overflow(event) {
        try {
            let errors = JSON.parse(event.detail);
            this.currentJSDiscountWrapper.tariffHasSubDiscountsErrors = true;
            this.currentJSDiscountWrapper.hasOverflow = true;
            this.currentJSDiscountWrapper.subErrors = JSON.parse(event.detail);
            if (!this.currentJSDiscountWrapper.isNewDiscount) {
                this.wDiscList[this.currentJSDiscountWrapper.Index].tariffHasSubDiscountsErrors = true;
                this.wDiscList[this.currentJSDiscountWrapper.Index].hasOverflow = true;
                this.wDiscList[this.currentJSDiscountWrapper.Index].subErrors = errors;
            } else {
                this.newWDiscList[this.currentJSDiscountWrapper.Index].tariffHasSubDiscountsErrors = true;
                this.newWDiscList[this.currentJSDiscountWrapper.Index].hasOverflow = true;
                this.newWDiscList[this.currentJSDiscountWrapper.Index].subErrors = errors;
            }
            this.checkRemainingOverFlows();
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    equality() {
        try {
            this.currentJSDiscountWrapper.tariffHasSubDiscountsErrors = false;
            this.currentJSDiscountWrapper.hasOverflow = false;
            this.currentJSDiscountWrapper.subErrors = [];
            if (!this.currentJSDiscountWrapper.isNewDiscount) {
                this.wDiscList[this.currentJSDiscountWrapper.Index].tariffHasSubDiscountsErrors = false;
                this.wDiscList[this.currentJSDiscountWrapper.Index].hasOverflow = false;
                this.wDiscList[this.currentJSDiscountWrapper.Index].subErrors = [];
            } else {
                this.newWDiscList[this.currentJSDiscountWrapper.Index].tariffHasSubDiscountsErrors = false;
                this.newWDiscList[this.currentJSDiscountWrapper.Index].hasOverflow = false;
                this.newWDiscList[this.currentJSDiscountWrapper.Index].subErrors = [];
            }
            this.checkRemainingOverFlows();
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    checkRemainingOverFlows() {
        try {
            this.hasOverFlow = false;
            for (let wrap of this.wDiscList) {
                if (wrap.hasOverflow) {
                    this.hasOverFlow = true;
                    break;
                }
            }
            for (let wrap of this.newWDiscList) {
                if (wrap.hasOverflow) {
                    this.hasOverFlow = true;
                    break;
                }
            }
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @track loadingSubDiscounts = false;
    loadDiscountSubs(JSWrapper) {
        try {
            this.loadingSubDiscounts = true;
            // let currentJSWrapper = this.currentJSDiscountWrapper;
            if (this.previousJSDiscountWrapperIndex != null) {
                this.wDiscList[this.previousJSDiscountWrapperIndex].subsOpened = false;
                this.conditionPage.conditionConfigurations.contractWrapper["discounts"][this.wDiscList[this.previousJSDiscountWrapperIndex].Id].subsOpened = false;
            }
            if (JSWrapper.subsLoaded) {
                JSWrapper.subsOpened = true;
                this.conditionPage.conditionConfigurations.contractWrapper["discounts"][JSWrapper.Id].subsOpened = true;
                this.previousJSDiscountWrapperIndex = JSWrapper.Index;
                this.subDiscountList = JSWrapper.subDiscountList;
                this.assignSubDiscountsToLWC();
                this.loadingSubDiscounts = false;
            } else {
                // JSWrapper.subsOpened = true;
                let currentApexDiscountWrapper = JSON.parse(JSON.stringify(this.conditionPage.conditionConfigurations.contractWrapper[!JSWrapper.isNewDiscount ? "discounts" : "newDiscounts"][!JSWrapper.isNewDiscount ? JSWrapper.Id : JSWrapper.Index]));
                this.setLoadingInSubLWC(true);
                this.previousJSDiscountWrapperIndex = JSWrapper.Index;
                loadSubdiscounts({
                    discountWrappers_JSON: JSON.stringify([currentApexDiscountWrapper]),
                    discountWrappers: null,
                    contract_JSON: JSON.stringify(this.currentContract),
                    contract: null,
                    gridSettingsManager_JSON: JSON.stringify(this.conditionPage.gridSettings),
                    gridSettingsManager: null
                }).then((result) => {
                    try {
                        let updatedDiscountWrapper = JSON.parse(result)[0];
                        this.conditionPage.conditionConfigurations.contractWrapper[!JSWrapper.isNewDiscount ? "discounts" : "newDiscounts"][!JSWrapper.isNewDiscount ? JSWrapper.discount.Id : JSWrapper.Index] = updatedDiscountWrapper;
                        let rebuiltDiscount = buildDiscountPageInfo(this, updatedDiscountWrapper, updatedDiscountWrapper.discount, JSWrapper.Index, false, this.discountPercentScale);
                        rebuiltDiscount.hasBeenEdited = true;
                        if (!JSWrapper.isNewDiscount) {
                            this.wDiscList[JSWrapper.Index] = rebuiltDiscount;
                        } else {
                            this.newWDiscList[JSWrapper.Index] = rebuiltDiscount;
                        }
                        if ((this.currentJSDiscountWrapper.Id && JSWrapper.Id == this.currentJSDiscountWrapper.Id) ||
                            (this.currentJSDiscountWrapper.Id && this.currentJSDiscountWrapper.Index == JSWrapper.Index)) {
                            this.currentJSDiscountWrapper = rebuiltDiscount;
                            this.subDiscountList = this.currentJSDiscountWrapper.subDiscountList;
                            this.assignSubDiscountsToLWC();
                            if (this.currentJSDiscountWrapperBackup) {
                                this.currentJSDiscountWrapperBackup.subsLoaded = true;
                                this.currentJSDiscountWrapperBackup.subDiscountList = this.currentJSDiscountWrapper.subDiscountList;
                                this.currentApexDiscountWrapperBackup.subsLoaded = true;
                                this.currentApexDiscountWrapperBackup.subDiscountsMap = updatedDiscountWrapper.subDiscountsMap;
                            }
                            this.oldCurrentJSDiscountWrapper = JSON.parse(JSON.stringify(rebuiltDiscount));
                        }
                        this.loadingSubDiscounts = false;
                    } catch (error) {
                        this.loadingSubDiscounts = false;
                        console.error(error);
                        showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                    }
                }).catch((apexError) => {
                    this.loadingSubDiscounts = false;
                    console.error(apexError);
                    showNotification(this, Labels.LBL_Error, apexError?.body?.message || apexError?.message || apexError, ERROR_VARIANT);
                });
            }
        } catch (error) {
            this.loadingSubDiscounts = false;
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    returnToContractPage(event) {
        try {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.recordId || this.contractRecordId,
                    actionName: "view"
                }
            });
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleDiscountSelection(event) {
        let index = event.target.dataset.index;
        let id = event.target.dataset.id;
        // this[id ? "wDiscList" : "newWDiscList"][index].isSelected = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        this[id ? "wDiscList" : "newWDiscList"][index].isSelected = event.target.checked ? true : false;
    }
    reorderListAndMap(index, reorderNew, reorderOld) {
        if (reorderNew) {
            this.newWDiscList.forEach((item) => {
                if (item.Index > index) {
                    item.Index = item.Index - 1;
                }
            });
            Object.keys(this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts).forEach((key) => {
                if (key > index) {
                    delete Object.assign(this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts, { [key - 1]: this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[key] })[key];
                    this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[key - 1].JSIndex = key - 1;
                }
            });
        }
        if (reorderOld) {
            this.wDiscList.forEach((item) => {
                if (item.Index > index) {
                    item.Index = item.Index - 1;
                }
            });
            for (let discount of Object.values(this.conditionPage.conditionConfigurations.contractWrapper.discounts)) {
                if (discount.JSIndex > index) {
                    discount.JSIndex -= 1;
                }
            }
        }
    }
    // cloneDiscount(newApexWrapper) {
    // let newIndex = this.numberOfNewDiscount++;
    // let buildJSWrapper = buildDiscountPageInfo(this, newApexWrapper, newApexWrapper.discount, newIndex, false);
    // buildJSWrapper.isInline = true;
    // return buildJSWrapper;
    // }
    handleDiscountClone(event) {
        try {
            this.openSubPanel = false;
            if (this.checkIfDetailTabOpen) {
                let self = this;
                this.closeEditPage();
                this.wDiscList.forEach(disc => {
                    disc.isSelected = false;
                });
                for (let elm of self?.template?.querySelectorAll('.row-highlight') || []) {
                    elm.classList.remove('row-highlight');
                }
            }
            let index = event.target.dataset.index;
            let id = event.target.dataset.id;
            let newApexWrapper = JSON.parse(JSON.stringify(this.conditionPage.conditionConfigurations.contractWrapper[id ? "discounts" : "newDiscounts"][id || index]));
            if (id) {
                delete newApexWrapper.discount.Id;
                delete newApexWrapper.discount.attributes.url;
                newApexWrapper.initialDiscount = {};
                Object.values(newApexWrapper.subDiscountsMap)?.forEach(it => {
                    Object.values(it).forEach(itt => {
                        itt.forEach(ittt => {
                            delete ittt.discount.Id;
                            delete ittt.discount.attributes.url;
                            ittt.initialDiscount = {};
                        })
                    });
                });
                newApexWrapper.discount[API_NAMES.Contract__c.Status__c] = 'Open';
            }
            let newIndex = this.numberOfNewDiscount;
            this.newWDiscList.push(buildDiscountPageInfo(this, {}, {}, newIndex, true, this.discountPercentScale));
            loadSubdiscounts({
                discountWrappers_JSON: JSON.stringify([newApexWrapper]),
                discountWrappers: null,
                contract_JSON: JSON.stringify(this.currentContract),
                contract: null,
                gridSettingsManager_JSON: JSON.stringify(this.conditionPage.gridSettings),
                gridSettingsManager: null
            }).then((result) => {
                try {
                    let updatedDiscountWrapper = JSON.parse(result)[0];
                    let buildJSWrapper = cloneDiscount(this, updatedDiscountWrapper);
                    this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[buildJSWrapper.Index] = updatedDiscountWrapper;
                    this.newWDiscList[buildJSWrapper.Index] = buildJSWrapper;
                } catch (error) {
                    console.error(error);
                    showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                }
            }).catch((apexError) => {
                console.error(apexError);
                showNotification(this, Labels.LBL_Error, apexError?.body?.message || apexError?.message || apexError, ERROR_VARIANT);
            });
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    massClone(event) {
        try {
            this.openSubPanel = false;
            let discountsToClone = [];
            let newApexWrapper;
            for (let discount of this.wDiscList) {
                if (discount.isSelected) {
                    newApexWrapper = JSON.parse(JSON.stringify(this.conditionPage.conditionConfigurations.contractWrapper.discounts[discount.discount.Id]));
                    delete newApexWrapper.discount.Id;
                    delete newApexWrapper.discount.attributes.url;
                    newApexWrapper.initialDiscount = {};
                    Object.values(newApexWrapper.subDiscountsMap)?.forEach(it => {
                        Object.values(it).forEach(itt => {
                            itt.forEach(ittt => {
                                delete ittt.discount.Id;
                                delete ittt.discount.attributes.url;
                                ittt.initialDiscount = {};
                            })
                        });
                    });
                    discountsToClone.push(newApexWrapper);
                    discount.isSelected = false;
                }
            }
            for (let discount of this.newWDiscList) {
                if (discount.isSelected) {
                    discount.isSelected = false;
                    discountsToClone.push(JSON.parse(JSON.stringify(this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[discount.Index])));
                }
            }
            let newJSWrappersToAdd = [];
            if (discountsToClone?.length) {
                for (newApexWrapper of discountsToClone) {
                    let newJSWrapper = cloneDiscount(this, newApexWrapper);
                    newJSWrappersToAdd.push(newJSWrapper);
                    this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[newJSWrapper.Index] = newApexWrapper;
                }
                this.newWDiscList = this.newWDiscList.concat(newJSWrappersToAdd);
            }
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleErrorMessagePopover(event) {
        try {
            let index = event.target.dataset.index;
            let id = event.target.dataset.id;
            let suberror = event.target.dataset.suberror;
            let JSWrapper;
            if (id) {
                JSWrapper = this.wDiscList[index];
            } else {
                JSWrapper = this.newWDiscList[index];
            }
            try {
                if (JSWrapper?.errors?.forEach) {
                    JSWrapper?.errors?.forEach(error => {
                        console.log(`error`, error);
                        showNotification(this, Labels.LBL_Error, error, ERROR_VARIANT);
                    });
                }
            } catch (___error) {
                console.error(___error);
                showNotification(this, Labels.LBL_Error, ___error?.body?.message || ___error?.message || ___error, ERROR_VARIANT);
            }
            try {
                if (JSWrapper?.subErrors?.forEach) {
                    JSWrapper?.subErrors?.forEach(error => {
                        console.log(`error`, error);
                        showNotification(this, Labels.LBL_Error, error, ERROR_VARIANT);
                    });
                }
            } catch (_error) {
                console.error(_error);
                showNotification(this, Labels.LBL_Error, _error?.body?.message || _error?.message || _error, ERROR_VARIANT);
            }
        } catch (__error) {
            console.error(__error);
            showNotification(this, Labels.LBL_Error, __error?.body?.message || __error?.message || __error, ERROR_VARIANT);
        }
    }
    toggleGridEditMode(event) {
        this.gridEditMode = !this.gridEditMode;
        this.showDone = this.gridEditMode;
    }
    toggleMenu(event) {
        let toggleButton = this.template.querySelector(".settings-menu");
        if (toggleButton) {
            toggleButton.classList.toggle("slds-is-open");
        }
    }
    hideMenu(event) {
        setTimeout(() => {
            this.template?.querySelector(".settings-menu")?.classList?.remove("slds-is-open");
        }, 200);
    }
    setPageSize = () => {
        try {
            let maindiscountDiv = this.template.querySelector(".MainDiscounts");
            // if (!this.subdiscountNode) {
            // this.subdiscountNode = this.template.querySelector(".SubDiscounts");
            // }
            // let subdiscountDiv = this.subdiscountNode;
            let mainContainer = this.template.querySelector(".mainContainer");
            this.mainContainer = mainContainer;
            // let paginationDiv = this.template.querySelector(".paginationDiv");
            let pageHeader = this.template.querySelector(".pageHeader");
            let ContractManagedByMasterMSG = this.template.querySelector(".Contract-Managed-By-Master-MSG");
            let gridDiv = this.template.querySelector(".gridSettings");
            let mainDiv = this.template.querySelector(".mainDiv");
            let mainDiscounts = this.template.querySelector(".MainDiscounts");
            let dockDiv = this.template.querySelector(".slds-utility-bar");
            let detailHeaderDiv = this.template.querySelector(".detailHeader");
            let subMessagesHeader = this.template.querySelector(".sub-messages");
            let detailFooterDiv = this.template.querySelector(".detailFooter");
            let detailBodyDiv = this.template.querySelector(".detailBody");
            let IndexPanel = this.template.querySelector(".IndexPanel");
            let manualDomDiv = this.template.querySelector(".injectLabel");
            if (pageHeader && mainContainer && maindiscountDiv/*  && subdiscountDiv */) {
                //
                let remaining = (mainContainer?.offsetHeight || 0)
                    - (ContractManagedByMasterMSG?.offsetHeight || 0)
                    - (pageHeader?.offsetHeight || 0)
                    - (dockDiv?.offsetHeight || 0)
                    - (subMessagesHeader?.offsetHeight || 0); /* * 2 */
                if (gridDiv) {
                    gridDiv.style.height = remaining - 24 /*+ paginationDiv.offsetHeight */ + "px";
                    if (detailFooterDiv) {
                        detailBodyDiv.style.height = parseFloat((gridDiv?.offsetHeight || 0) - (detailHeaderDiv?.offsetHeight || 0) - (detailFooterDiv?.offsetHeight || 0)) + "px";
                    } else {
                        detailBodyDiv.style.height = parseFloat((gridDiv?.offsetHeight || 0) - (detailHeaderDiv?.offsetHeight || 0) - 20) + "px";
                    }
                }
                if (mainDiv) {
                    mainDiv.style.height = remaining - 24 /*+ paginationDiv.offsetHeight */ + "px";
                }
                if (mainDiscounts) {
                    mainDiscounts.style.height = remaining - 24 /*+ paginationDiv.offsetHeight */ + "px";
                }
                // if (!subdiscountDiv.classList.value.includes('slds-hide')) {
                // maindiscountDiv.style.height = parseFloat(remaining) / 1.5 - 16 + "px";
                // maindiscountDiv.style.height = parseFloat(remaining) / 1.05 - 16 + "px";
                // subdiscountDiv.style.height = parseFloat(remaining) - parseFloat(remaining) / 1.5 - 16 + "px";
                // } else {
                // maindiscountDiv.style.height = parseFloat(remaining) - 16 + "px";
                // subdiscountDiv.style.height = 0 + "px";
                // }
                this.indexPanelTransform = `translate(${parseFloat((mainContainer?.offsetWidth || 0) - (IndexPanel?.offsetWidth || 0))}px, 0)`;
                if (this.indexPanelOpened) {
                    IndexPanel.style.transform = this.indexPanelTransform;
                }
                if (manualDomDiv) {
                    manualDomDiv.innerHTML = this.labels.Description_Manual_Invoice_PopUp;
                }
            }
        } catch (error) {
            console.log(`🚀 ---------------------------------------------------🚀`);
            console.log(`🚀 ~ file: conditionManager.js:1071 ~ error:`, error);
            console.log(`🚀 ---------------------------------------------------🚀`);
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    };
    closeEditPage(event) {
        if (this.gridEditMode && this?.currentJSDiscountWrapper?.hasBeenEdited) {
            this.handleCancel();
        }
        this.closeDetailPage();
    }
    closeDetailPage(event) {
        this.DetailPageOpen = false;
        this.discountChangeEvent = false;
        this.gridEditMode = false;
        this.invoicesArray = null;
        if (this.node != null) {
            this.node.style.backgroundColor = this.prevNodeColor;
            this.node.style.border = this.prevNodeBorder;
            this.node = null;
        }
        let gridDiv = this.template.querySelector(".gridSettings");
        let mainDiv = this.template.querySelector(".mainDiv");
        if (gridDiv != null && !gridDiv.classList.value.includes("slds-hide")) {
            gridDiv.classList.toggle("slds-hide");
            mainDiv.classList.toggle("slds-size_3-of-3");
            mainDiv.classList.toggle("slds-size_2-of-3");
        }
    }
    openDetailPage(event) {
        this.DetailPageOpen = true;
        this.invoicesArray = null;
        let gridDiv = this.template.querySelector(".gridSettings");
        let mainDiv = this.template.querySelector(".mainDiv");
        if (gridDiv != null && gridDiv.classList.value.includes("slds-hide")) {
            gridDiv.classList.remove("slds-hide");
            mainDiv.classList.toggle("slds-size_3-of-3");
            mainDiv.classList.toggle("slds-size_2-of-3");
        }
    }
    /**
    * manual Invoice methods
    */
    handleManualInvoiceReset(event) {
        this.tempInvoices = [];
    }
    /**
    * Not used
    */
    saveManualInvoices(event) {
        // this.currentJSDiscountWrapper.manualInvoices.invoices = JSON.parse(JSON.stringify(this.tempInvoices));
        this.currentJSDiscountWrapper.manualInvoices.invoices = JSON.parse(JSON.stringify(this.tempInvoices.filter(item => item.isSelected)));
        this.currentJSDiscountWrapper.hasBeenEdited = true;
        this.tempInvoices = [];
    }
    calculateManualInvoicesValues(e, callback) {
        try {
            if (this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] != null) {
                let YTD = this.currentJSDiscountWrapper.discount != null && this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego__c] != null ? this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego__c] : 0;
                let selectedMonths = this.tempInvoices.length; // included in calculation
                for (let wrapperInvoice of this.tempInvoices) {
                    if (wrapperInvoice.isReadOnly) {
                        YTD -= this.currentJSDiscountWrapper?.wInvoiceMap[wrapperInvoice.key]?.invoiceDetail[API_NAMES.InvoiceDetail__c.DetailAmount__c] != null ? this.currentJSDiscountWrapper?.wInvoiceMap[wrapperInvoice.key]?.invoiceDetail[API_NAMES.InvoiceDetail__c.DetailAmount__c] : 0;
                    }
                    if (wrapperInvoice.isReadonly || !wrapperInvoice.isSelected) {
                        selectedMonths--;
                    }
                }
                if (selectedMonths > 0) {
                    let currentJSWrapper = this.currentJSDiscountWrapper;
                    let plannedSummary = {};
                    ////
                    let currentApexDiscountWrapper = this.conditionPage.conditionConfigurations.contractWrapper["discounts"][currentJSWrapper.discount.Id];
                    generateAutomaticDispatch({
                        DiscountWrapper_JSON: JSON.stringify(currentApexDiscountWrapper),
                        contract_JSON: JSON.stringify(this.currentContract),
                        YTD: YTD,
                        selectedMonths: selectedMonths
                    }).then((result) => {
                        let amountArray = JSON.parse(result);
                        for (let wrapperInvoice of this.tempInvoices) {
                            let item;
                            if (currentJSWrapper?.wInvoiceMap.hasOwnProperty(wrapperInvoice.key)) {
                                item = currentJSWrapper.wInvoiceMap[wrapperInvoice.key];
                            }
                            if (!wrapperInvoice.isReadOnly) {
                                if (wrapperInvoice.isSelected && amountArray.length) {
                                    wrapperInvoice.value = amountArray[0];
                                    if (item) {
                                        item.invoiceDetail[API_NAMES.InvoiceDetail__c.DetailAmount__c] = amountArray[0];
                                    }
                                    plannedSummary[wrapperInvoice.date + ""] = wrapperInvoice.value + "";
                                } else if (!wrapperInvoice.isSelected) {
                                    wrapperInvoice.value = null;
                                    if (item) {
                                        item.invoiceDetail[API_NAMES.InvoiceDetail__c.DetailAmount__c] = null;
                                    }
                                }
                            } else {
                                wrapperInvoice.value = null;
                                if (item) {
                                    item.invoiceDetail[API_NAMES.InvoiceDetail__c.DetailAmount__c] = null;
                                }
                            }
                        }
                        currentJSWrapper.hasBeenEdited = true;
                        // currentJSWrapper.manualInvoiceEdited = false;
                        currentApexDiscountWrapper.manualInvoiceSummary = plannedSummary;
                        this.waitForCalculate = false;
                        //this.handleFakeSave();
                        if (callback) {
                            callback();
                        }
                    }).catch((error) => {
                        console.error(error);
                        showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                    });
                } else {
                    if (callback) {
                        callback();
                    }
                }
            } else {
                if (callback) {
                    callback();
                }
            }
            this.selectionChanged = false;
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleManualInvoicesSelection(event) {
        try {
            let index = event?.target?.dataset?.index;
            let type = event?.target?.dataset?.type;
            if (type === "selection") {
                this.tempInvoices[index].isSelected = !this.tempInvoices[index].isSelected;
                this.selectionChanged = true;
            } else if (type === "date") {
                this.tempInvoices[index].date = event.detail.value;
            }
            else if (type === 'amount') {
                this.tempInvoices[index].amount = event.detail.value;
            }
            // this.currentJSDiscountWrapper.manualInvoiceEdited = true;
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    /**
    * Slab methods
    */
    handleSlabMethods(event) {
        let self = this;
        try {
            this.currentJSDiscountWrapper.discount[event.target.dataset.field] = event.detail.value;
            _assignSlabsToDiscount(this.currentJSDiscountWrapper, false, () => {
                self.currentJSDiscountWrapper.hasBeenEdited = true;
            });
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleTargetChange(event) {
        let self = this;
        try {
            let newTargetPosition = event.target.dataset.position;
            let currentSlabs = this.currentJSDiscountWrapper.slabs.slabList;
            currentSlabs.forEach(it => {
                it.isTarget = it.isTarget && it.no == newTargetPosition ? false : (it.no == newTargetPosition ? true : false);
            });
            this.currentJSDiscountWrapper.slabs.targetNb = currentSlabs.find(it => it.isTarget) ? currentSlabs.find(it => it.isTarget).no : 0;
            _assignSlabsToDiscount(this.currentJSDiscountWrapper, true, () => {
                self.currentJSDiscountWrapper.hasBeenEdited = true;
            });
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleSlabData(event) {
        let self = this;
        try {
            let fieldvalue = event.target.dataset.fieldvalue;
            let targetPosition = event.target.dataset.position;
            this.currentJSDiscountWrapper.slabs.slabList[targetPosition - 1][fieldvalue] = event.detail.value;
            _assignSlabsToDiscount(this.currentJSDiscountWrapper, false, () => {
                self.currentJSDiscountWrapper.hasBeenEdited = true;
            });
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    toggleIndexPanelSection(event) {
        this.showIndexSection = true;
        this.refreshIndexValues(event, this);
        let IndexPanel = this.template.querySelector(".IndexPanel");
        if (this.indexPanelOpened) {
            IndexPanel.style.transform = "";
        } else {
            IndexPanel.style.transform = this.indexPanelTransform = `translate(${parseFloat(this.mainContainer.offsetWidth - IndexPanel.offsetWidth)}px, 0)`;
        }
    }
    toggleIndexPanel(event) {
        this.refreshIndexValues(event, this);
        let IndexPanel = this.template.querySelector(".IndexPanel");
        if (this.indexPanelOpened) {
            IndexPanel.style.transform = "";
        } else {
            IndexPanel.style.transform = this.indexPanelTransform = `translate(${parseFloat(this.mainContainer.offsetWidth - IndexPanel.offsetWidth)}px, 0)`;
        }
        // this.indexPanelOpened = !this.indexPanelOpened;
    }
    closeIndexPanel(event) {
        let IndexPanel = this.template.querySelector(".IndexPanel");
        if (IndexPanel) {
            IndexPanel.style.transform = "";
        }
        this.indexPanelOpened = false;
    }
    closeIndexSection(event) {
        this.showIndexSection = false;
    }
    refreshIndexValues(event, self, callback) {
        self = self || this;
        let acceptedIds = self.wDiscList.map(item => item.discount.Id);
        let oldDiscountWrapperList = JSON.parse(JSON.stringify(Object.values(self.conditionPage.conditionConfigurations.contractWrapper.discounts).filter(f => acceptedIds.includes(f.discount.Id))));
        let newDiscountWrapperList = JSON.parse(JSON.stringify(Object.values(self.conditionPage.conditionConfigurations.contractWrapper.newDiscounts)));
        let discountWrapperList = oldDiscountWrapperList.concat(newDiscountWrapperList);
        discountWrapperList.forEach(it => {
            delete it.availableTariff;
            if (!it.discount.Id) {
                Object.keys(it.discount).forEach(key => {
                    if (key.endsWith('__c') && it.discount[key] === '') {
                        it.discount[key] = null;
                    }
                });
            }
        });
        self.indexLoading = true;
        refreshIndexValues({
            contract_JSON: JSON.stringify(self.currentContract),
            discounts_JSON: JSON.stringify(discountWrapperList)
        }).then((result) => {
            let wrapper = JSON.parse(result);
            let wIndex = wrapper.wIndex;
            let updatedDiscountList = wrapper.discountWrappers;
            self.currentContract = { ...self.currentContract, ...wrapper.contract };
            setContractDetails(self, self.currentContract);
            // for (let item of updatedDiscountList) {
            let __index = 0;
            let __index2 = 0;
            for (let index = 0; index < updatedDiscountList.length; index++) {
                let item = updatedDiscountList[index];
                if (item.discount.Id) {
                    self.conditionPage.conditionConfigurations.contractWrapper.discounts[item.discount.Id] = item;
                    let rebuiltDiscount = buildDiscountPageInfo(self, item, item.discount, __index, false, this.discountPercentScale);
                    rebuiltDiscount.hasBeenEdited = self.wDiscList[__index].hasBeenEdited;
                    if (!rebuiltDiscount.hasBeenEdited) {
                        let oldFieldMap = {};
                        self.wDiscList[__index].values.forEach(it => {
                            oldFieldMap[it.fieldName] = it.fieldValue;
                        });
                        rebuiltDiscount.hasBeenEdited |= rebuiltDiscount.values.some(it => oldFieldMap[it.fieldName] != it.fieldValue);
                    }
                    if (!rebuiltDiscount.hasBeenEdited) {
                        rebuiltDiscount.hasBeenEdited |= [
                            API_NAMES.Contract_Discount__c.Base_TO_Nego__c,
                            API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
                            API_NAMES.Contract_Discount__c.Base_TO_Tariff_Nego__c,
                            API_NAMES.Contract_Discount__c.Index_perc__c,
                            API_NAMES.Contract_Discount__c.Index_val__c,
                            API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c,
                        ].some(_key => self.wDiscList[__index].discount[_key] != rebuiltDiscount.discount[_key]);
                    }
                    self.wDiscList[__index] = rebuiltDiscount;
                    if (self.currentJSDiscountWrapper != null && self.currentJSDiscountWrapper.Index == __index) {
                        self.currentJSDiscountWrapper = rebuiltDiscount;
                    }
                    // to check
                    // self.wDiscList[item.JSIndex].hasBeenEdited = true;
                    if (item.discount[API_NAMES.Contract_Discount__c.Display_Order__c] != discountWrapperList[index].discount[API_NAMES.Contract_Discount__c.Display_Order__c]) {
                        self.wDiscList[__index].hasBeenEdited = true;
                    }
                    __index++;
                } else {
                    self.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[__index2] = item;
                    let rebuiltDiscount = buildDiscountPageInfo(self, item, item.discount, __index2, false, this.discountPercentScale);
                    rebuiltDiscount.hasBeenEdited = self.newWDiscList[__index2].hasBeenEdited;
                    if (!rebuiltDiscount.hasBeenEdited) {
                        let oldFieldMap = {};
                        self.newWDiscList[__index2].values.forEach(it => {
                            oldFieldMap[it.fieldName] = it.fieldValue;
                        });
                        rebuiltDiscount.hasBeenEdited |= rebuiltDiscount.values.some(it => oldFieldMap[it.fieldName] != it.fieldValue);
                    }
                    if (!rebuiltDiscount.hasBeenEdited) {
                        rebuiltDiscount.hasBeenEdited |= [
                            API_NAMES.Contract_Discount__c.Base_TO_Tariff_Nego__c,
                            API_NAMES.Contract_Discount__c.Index_perc__c,
                            API_NAMES.Contract_Discount__c.Index_val__c,
                            API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c,
                        ].some(_key => self.wDiscList[__index].discount[_key] != rebuiltDiscount.discount[_key]);
                    }
                    self.newWDiscList[__index2] = rebuiltDiscount;
                    // self.newWDiscList[item.JSIndex].hasBeenEdited = true;
                    __index2++;
                }
            }
            let negotiateIndexesCmp = self.template.querySelector('[data-id="negotiate-indexes-cmp"]');
            if (negotiateIndexesCmp && negotiateIndexesCmp.setCalculation) {
                negotiateIndexesCmp.setCalculation(JSON.stringify(wIndex));
            }
            let wDiscList = [...self.wDiscList];
            let newWDiscList = [...self.newWDiscList];
            self.indexLoading = false;
            self.wDiscList = [];
            self.newWDiscList = [];
            setTimeout(() => {
                self.wDiscList = wDiscList;
                self.newWDiscList = newWDiscList;
                if (callback) {
                    callback();
                }
            }, 0);
        }).catch((error) => {
            self.error = error;
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        });
    }
    resetpage() {
        /* Row Highlighted */
        if (this.node != null) {
            this.node.style.backgroundColor = this.prevNodeColor;
            this.node.style.border = this.prevNodeBorder;
            this.node = null;
        }
        /**
        * Contract Info
        */
        this.numberOfNewDiscount = 0;
        this.subDiscountList = [];
        this.subDiscountMap = {};
        this.offset = 0;
        this.total = 0;
        this.currentJSDiscountWrapper = null;
        this.currentJSDiscountWrapperDetails = null;
        this.conditionPage.conditionConfigurations = null;
        yearPanelFields[0] = [
            API_NAMES.Contract_Discount__c.unit_amount__c,
            API_NAMES.Contract_Discount__c.Unit_Amount_Type__c,
            API_NAMES.Contract_Discount__c.Rank__c,
        ];
        /**
        * Grid
        */
        this.gridEditMode = false;
        this.closeDetailPage();
        this.loadConditionsList();
    }
    toggleFilterPanel(event) {
        this.isFilterOpen = !this.isFilterOpen;
    }
    handleStickyColumnsChange(event) {
        this.stickyColumnNumber = event.target.value;
        gridScrollHandler(this);
    }
    setSticky(self) {
        self = (self || this);
        let maxSticky = 8;
        let scrollLeft = self?.template?.querySelector('.main-table-div')?.scrollLeft || 0;
        let stickyColumnNumber = +self.stickyColumnNumber || 1;
        if (stickyColumnNumber) {
            let headerTrs = self.template.querySelectorAll('.main-table thead tr');
            let yearPanelHeaderCount = self?.labels?.conditionLabels?.length || 0;
            let leftHeader1 = 0;
            let leftHeader2 = 0;
            let bodyTrs = self.template.querySelectorAll('.main-table tbody tr');
            for (let index = 0; bodyTrs && index < bodyTrs.length; index++) {
                let childrens = bodyTrs[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length && index2 < maxSticky; index2++) {
                    if (index2 < stickyColumnNumber) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = 3 + bodyTrs.length - index;
                        if (!childrens[index2].classList.contains('slds-hide')) {
                            left += childrens[index2].offsetWidth;
                        }
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.left = 'unset';
                        childrens[index2].style.zIndex = 'unset';
                    }
                }
                leftHeader2 = left;
            }
            for (let index = 0; headerTrs && index < headerTrs.length; index++) {
                let childrens = headerTrs[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length && index2 < maxSticky; index2++) {
                    if ((index2 <= 4) && (index2 < 4 + yearPanelHeaderCount - 1) && yearPanelHeaderCount && yearPanelHeaderCount != 1) {
                        continue;
                    }
                    childrens[index2].style.position = 'sticky';
                    let alreadySet = false;
                    if (index2 < stickyColumnNumber) {
                        if (index == 0) {
                            if (index2 < 4) {
                                childrens[index2].style.zIndex = 5;
                                childrens[index2].style.left = left + 'px ';
                                alreadySet = true;
                            } else if (index2 == 4) {
                                childrens[index2].style.zIndex = 4;
                                childrens[index2].style.left = (leftHeader2 - childrens[index2].clientWidth) + 'px ';
                                if (scrollLeft < childrens[index2].clientWidth - (leftHeader2 - left)) {
                                    childrens[index2].style.paddingLeft = scrollLeft + 'px ';
                                } else {
                                    childrens[index2].style.paddingLeft = (childrens[index2].clientWidth - (leftHeader2 - left)) + 'px ';
                                }
                                alreadySet = true;
                            }
                        }
                        if (index == 1 && index2 < (stickyColumnNumber - 4)) {
                            childrens[index2].style.zIndex = 5;
                            childrens[index2].style.left = leftHeader1 + left + 'px ';
                            alreadySet = true;
                        }
                        left += childrens[index2].offsetWidth;
                        if (index == 0 && index2 < 4) {
                            leftHeader1 += childrens[index2].offsetWidth;
                        }
                    }
                    if (!alreadySet) {
                        childrens[index2].style.zIndex = 'unset';
                        childrens[index2].style.left = 'unset';
                    }
                }
            }
        }
    }
    renderedCallback() {
        let mainTableDiv = this.template.querySelector('.main-table-div');
        let self = this;
        let _gridScrollHandler = (event) => {
            gridScrollHandler(self);
        };
        if (mainTableDiv) {
            mainTableDiv?.removeEventListener('scroll', _gridScrollHandler, false);
            mainTableDiv?.addEventListener('scroll', _gridScrollHandler);
        }
        let mainContainer = this.template.querySelector(".mainContainer");
        let pageHeader = this.template.querySelector(".pageHeader");
        let maindiscountLoadingDiv = this.template.querySelector(".MainDiscountsLoading");
        if (pageHeader && mainContainer && maindiscountLoadingDiv) {
            let remaining = (mainContainer?.offsetHeight || 0) - (pageHeader?.offsetHeight || 0);
            maindiscountLoadingDiv.style.height = parseFloat(remaining) - 16 + "px";
        }
        let tableTrs = this.template.querySelector('.main-table')?.rows;
        for (let index = 0; tableTrs && index < tableTrs.length; index++) {
            if (index != 1) {
                let childrens = tableTrs[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < 3) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = 5;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                    }
                }
            }
        }
        this.setPageSize();
        this.setSticky(this);
    }
    @track heightProperty = `height: 86vh;`;
    @track wrappopupClass = ``;
    connectedCallback() {
        if (this.height) {
            this.heightProperty = `height: ${this.height};`;
        }
        this.showBannerAndFooter = this.objectApiName != API_NAMES.Contract__c.object.objectApiName;
        this.wrappopupClass = (this.objectApiName != API_NAMES.Contract__c.object.objectApiName ? '' : ' wrap-popups');
        try {
            // this.getDiscountData();
            this.newWDiscList = [];
            this.numberOfNewDiscount = 0;
            Promise.all([
                loadStyle(this, conditionManager_resources + "/customStyle.css"),
                loadStyle(this, negotiate + "/customStyle.css")
            ]);
            // window.onresize = this.setPageSize;
            window.addEventListener("resize", this.setPageSize);
            window.addEventListener("keyup", this.closePopupsEsc);
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    loadConditionsList(self) {
        self = self || this;
        try {
            if (this.contractRecordId == null && !this.recordIdChecked) {
                this.recordIdChecked = true;
                this.errorMessage = Labels.MSG_No_Record_ID;
            }
            if (this.contractRecordId != null && this.loadedWireMethods.fullyLoaded) {
                let callback2 = () => {
                    let currentContract = this.currentContract;
                    loadGridSettings({ contractId: this.contractRecordId, contract_JSON: JSON.stringify(currentContract) }).then((result) => {
                        let data = JSON.parse(result);
                        this.conditionPage.gridSettings = data.gridSettings;
                        let yearPanelArray = [];
                        let fieldsToRemove = [];
                        if (this.labels.contractYears.length === 0) {
                            for (let year of Object.keys(this.conditionPage.wContractYearsMap)) {
                                let yearInfo = this.conditionPage.wContractYearsMap[year];
                                this.labels.contractYears.push(yearInfo.year);
                                for (let field of (this.conditionPage.gridSettings.GRID_FIELDS || [])) {
                                    if (yearPanelArray[year] == null) {
                                        yearPanelArray[year] = {
                                            year: yearInfo.year,
                                            get count() {
                                                return this.fields.length;
                                            },
                                            get display() {
                                                return this.fields.length ? true : false;
                                            },
                                            fields: [],
                                        };
                                    }
                                    if (yearPanelFields[0].includes(field.fieldName)) {
                                        yearPanelArray[year].fields.push({
                                            fieldName: field.fieldName,
                                            fieldLabel: field.fieldLabel,
                                            headerStyle: field.headerStyle ? ((field.headerStyle.bgColor ? 'background-color:' + field.headerStyle.bgColor + ' !important;' : '') + (field.headerStyle.color ? 'color:' + field.headerStyle.color + ' !important;' : '')) : '',
                                            ...field,
                                        });
                                        fieldsToRemove.push(field.fieldName);
                                        yearPanelFields[0] = yearPanelFields[0].filter((value) => value !== field.fieldName);
                                    }
                                    if (yearPanelFields[year].includes(field.fieldName)) {
                                        yearPanelArray[year].fields.push({
                                            fieldName: field.fieldName,
                                            fieldLabel: field.fieldLabel,
                                            headerStyle: field.headerStyle ? ((field.headerStyle.bgColor ? 'background-color:' + field.headerStyle.bgColor + ' !important;' : '') + (field.headerStyle.color ? 'color:' + field.headerStyle.color + ' !important;' : '')) : '',
                                            ...field,
                                        });
                                        fieldsToRemove.push(field.fieldName);
                                    }
                                }
                            }
                            /**
                            * Build Grid table header labels
                            */
                            if (this.labels.gridFieldsLabels.length === 0) {
                                for (let field of (this.conditionPage.gridSettings.GRID_FIELDS || [])) {
                                    let regex = /(Value_amt_Y[1-5]__c)|(Disc_BDate_y[1-5]__c)|(Disc_EDate_y[1-5]__c)|(Value_per_Y[1-5]__c)|(unit_amount)|(rank)/gi;
                                    if (!nonRepetableFields.includes(field.fieldName) && field.fieldName.match(regex) == null) {
                                        this.labels.gridFieldsLabels.push({
                                            fieldLabel: field.fieldLabel,
                                            helpText: field.helpText,
                                            hasHelpText: field.helpText ? true : false,
                                            headerStyle: 'z-index: 1;' + (field.headerStyle ? ((field.headerStyle.bgColor ? 'background-color:' + field.headerStyle.bgColor + ' !important;' : '') + (field.headerStyle.color ? 'color:' + field.headerStyle.color + ' !important;' : '')) : '') + (field.widthStyle ? field.widthStyle : ''),
                                        });
                                    } else {
                                        fieldsToRemove.push(field.fieldName);
                                    }
                                }
                            }
                            this.conditionPage.gridSettings.GRID_FIELDS = this.conditionPage.gridSettings.GRID_FIELDS.filter((field) => { if (!fieldsToRemove.includes(field.fieldName)) { return field; } });
                            this.labels.conditionLabels = yearPanelArray.filter((value) => value != null);
                        }
                        setTimeout(() => {
                            callback3();
                        }, 0);
                    }).catch(error => {
                        // showNotification(this, 'Attention', `Id du contract n'existe plus`, ERROR_VARIANT);
                        showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                    });
                };
                let callback3 = () => {
                    let currentContract = this.currentContract;
                    let gridSettings = this.conditionPage.gridSettings;
                    LoadConditionList({ contractId: this.contractRecordId, contract_JSON: JSON.stringify(currentContract), gridSettings_JSON: JSON.stringify(gridSettings) }).then((result) => {
                        // this.setPageSize();
                        this.conditionPage.conditionConfigurations = { ...this.conditionPage.conditionConfigurations, ...JSON.parse(result) };
                        this.conditionPage.gridSettings = this.conditionPage.conditionConfigurations.gridSettings;
                        this.conditionPage.subGridSettings = this.conditionPage.conditionConfigurations.subGridSettings;
                        this.isReadOnly = this.conditionPage.conditionConfigurations.gridSettings.isReadOnly /*|| this.conditionPage.conditionConfigurations.isContractManagedByMaster*/;
                        this.conditionPage.batchControlMap = this.conditionPage.conditionConfigurations.batchControlMap;
                        delete this.conditionPage.gridSettings.FILTER_FIELDS;
                        delete this.conditionPage.gridSettings.FILTERS;
                        this.sBusinessType = this.conditionPage.conditionConfigurations.sBusinessType;
                        this.discountPercentScale = this.conditionPage.conditionConfigurations.discountPercentScale;
                        this.Allow_Dispatching_in_Condition_List = this.conditionPage.conditionConfigurations.Allow_Dispatching_in_Condition_List;
                        this.currentContract = { ...this.currentContract, ...this.conditionPage.conditionConfigurations.contractWrapper.contract };
                        this.conditionPage.conditionConfigurations.showMaster = this.currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__r].RecordType.DeveloperName == 'Advanced';
                        this.picklistLabelsMap = this.conditionPage.conditionConfigurations.picklistLabelsMap;
                        let tempInvoiceBaseOptions = [];
                        for (let key in this.picklistLabelsMap[API_NAMES.Contract_Discount__c.object.objectApiName + '-' + API_NAMES.Contract_Discount__c.Invoice_base__c]) {
                            let value = this.picklistLabelsMap[API_NAMES.Contract_Discount__c.object.objectApiName + '-' + API_NAMES.Contract_Discount__c.Invoice_base__c][key];
                            tempInvoiceBaseOptions.push({ label: value, value: key })
                        }
                        this.invBaseOptions = tempInvoiceBaseOptions;
                        let temInvoicePeriodOptions = [];
                        for (let key in this.picklistLabelsMap[API_NAMES.Contract_Discount__c.object.objectApiName + '-' + API_NAMES.Contract_Discount__c.Invoice_period__c]) {
                            let value = this.picklistLabelsMap[API_NAMES.Contract_Discount__c.object.objectApiName + '-' + API_NAMES.Contract_Discount__c.Invoice_period__c][key];
                            temInvoicePeriodOptions.push({ label: value, value: key })
                        }
                        temInvoicePeriodOptions = temInvoicePeriodOptions.filter((item, index) => {
                            return (item.value == 'Month' || item.value == 'Semester' || item.value == 'Trimester' || item.value == 'Year')
                        });
                        this.invPeriodOptions = temInvoicePeriodOptions;
                        // Invoices Options
                        let InvoiceStatusOptions = [];
                        for (let key in this.picklistLabelsMap[API_NAMES.Invoice__c.object.objectApiName + '-' + API_NAMES.Invoice__c.Status__c]) {
                            let value = this.picklistLabelsMap[API_NAMES.Invoice__c.object.objectApiName + '-' + API_NAMES.Invoice__c.Status__c][key];
                            InvoiceStatusOptions.push({ label: value, value: key })
                        }
                        this.invStatusOptions = InvoiceStatusOptions;
                        this.generatedStatus = this.invStatusOptions.find(opt => opt.value == 'Generated');
                        this.printedStatus = this.invStatusOptions.find(opt => opt.value == 'Printed');
                        this.cancelledStatus = this.invStatusOptions.find(opt => opt.value == 'Cancelled');
                        let InvoiceDocTypeOptions = [];
                        for (let key in this.picklistLabelsMap[API_NAMES.Invoice__c.object.objectApiName + '-' + API_NAMES.Invoice__c.AccDoc__c]) {
                            let value = this.picklistLabelsMap[API_NAMES.Invoice__c.object.objectApiName + '-' + API_NAMES.Invoice__c.AccDoc__c][key];
                            InvoiceDocTypeOptions.push({ label: value, value: key })
                        }
                        this.invDocTypeOptions = InvoiceDocTypeOptions;
                        this.isValidatedContractNegobaseInit = ((this.currentContract?.RecordType?.DeveloperName == "Nego_Base_Init") && this.currentContract[API_NAMES.Contract__c.Status__c] == "Validated");
                        if (this.conditionPage.conditionConfigurations.contractWrapper.availableContractTariff != null) {
                            for (let tariffWrapperList of Object.values(this.conditionPage.conditionConfigurations.contractWrapper.availableContractTariff)) {
                                for (let tariffWrapper of tariffWrapperList) {
                                    this.tariffToHasSubtermsMap[tariffWrapper.tariff.Id] = tariffWrapper.hasSubTerms;
                                }
                            }
                        }
                        this.loadDiscounts = true;
                        let discounts = [];
                        let index = 0;
                        for (let discountWrapper of Object.values(this.conditionPage.conditionConfigurations.contractWrapper.discounts)) {
                            discounts.push(buildDiscountPageInfo(this, discountWrapper, discountWrapper.discount, index++, false, this.discountPercentScale));
                        }
                        this.wDiscList = discounts;
                        /**
                        * Load BUs
                        */
                        for (let bu in this.conditionPage.conditionConfigurations.contractWrapper.availableBU) {
                            this.conditionPage.conditionConfigurations.contractWrapper.availableBU[bu]["index"] = bu;
                        }
                        this.BUs = this.conditionPage.conditionConfigurations.contractWrapper.availableBU;
                        this.newWDiscList = [];
                        this.loading = false;
                        this.saveLoading = false;
                        this.setPageSize();
                    }).catch(error => {
                        // showNotification(this, 'Attention', `Id du contract n'existe plus`, ERROR_VARIANT);
                        showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                    });
                };
                let callback1 = () => {
                    this.loadDiscounts = false;
                    loadSimpleData({ contractId: this.contractRecordId }).then((result) => {
                        let data = JSON.parse(result);
                        let currentContract = { ...this.currentContract, ...data.contract };
                        this.currentContract = currentContract;
                        
                        // Load page settings for sub discounts
                        if (data.pageSettings) {
                            this.pageSettings = {
                                mainGridSettings: data.pageSettings.mainGridSettings || 'Condition_Grid',
                                subDiscountGridSettings: data.pageSettings.subDiscountGridSettings || '',
                                showSubDiscountColumn: data.pageSettings.showSubDiscountColumn || false
                            };
                        }
                        
                        let date = new Date(currentContract[API_NAMES.Contract__c.Contract_BDate__c]);
                        this.negoYear = date.getFullYear();
                        this.negoScopeId = currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
                        this.conditionPage.wContractYearsMap = data.wContractYearsMap;
                        this.conditionPage.batchControlMap = data.batchControlMap;
                        setContractDetails(this, currentContract);
                        let recordType = this.currentContract.RecordType.DeveloperName.replace(/_/g, "-").toLocaleLowerCase();
                        if (this.currentContract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && (recordType == "simulation" || recordType == "signed" || recordType == "to-be-signed")) {
                            recordType = "on-top";
                        }
                        /* NEGOTIATE COLORS */
                        this.indexButton = "slds-button slds-utility-bar__action hmp_" + recordType;
                        this.indexHeader = "slds-utility-panel__header slds-grid slds-shrink-none hmp_" + recordType;
                        this.pageHeader = "slds-page-header slds-m-bottom_small pageHeader " + "header_" + recordType;
                        this.icon = "slds-avatar " + "index_" + recordType;
                        this.tableHeader = "slds-text-align_center " + "hmp_" + recordType;
                        this.yearHeader = "slds-text-align_center " + "hmp_" + recordType;
                        this.yearBody = "slds-text-align_center basicYearColor";
                        // this.amountBody = "slds-text-align_center basicYearColor";
                        this.yearDetail = "slds-p-around_small slds-grid slds-wrap basicYearColor slds-p-left_none";
                        this.yearlabel = "slds-form-element__label basicYearColor";
                        this.yearElement = "slds-form-element__static basicYearColor";
                        this.yearInputLabel = "slds-form-element__static basicYearColor";
                        this.detailHeader = "slds-p-around_medium slds-border_bottom header_" + recordType;
                        this.newInlineColor = "slds-text-align_center basicYearColor";
                        let discounts = [];
                        if (this.labels.generalLabels.length === 0) {
                            this.labels.generalLabels.push({
                                fieldlabel: this.labels.object.Contract_Discount__c.Nego_Discount_Type__c,
                                key: 0
                            });
                            this.labels.generalLabels.push({
                                fieldlabel: this.labels.object.Contract_Discount__c.Condition_Type__c,
                                key: 1
                            });
                            this.labels.generalLabels.push({
                                fieldlabel: this.labels.object.Pol_Com_Condition__c.Long_Name__c,
                                key: 2
                            });
                            this.labels.negoDiscountLabel = this.labels.object.Contract_Discount__c.Nego_Discount_Type__c;
                            this.labels.codeBudgetLabel = this.labels.object.Contract_Discount__c.Condition_Type__c;
                        }
                        let yearPanelSection = [];
                        for (let yearIndex = (currentContract[API_NAMES.Contract__c.Multi_Year_Index__c] || 1); yearIndex <= (currentContract[API_NAMES.Contract__c.Multi_Year_Total__c] || 1); yearIndex++) {
                            let section = {
                                year: +currentContract[API_NAMES.Contract__c.Reference_Year__c] + yearIndex - 1,
                                get count() {
                                    return this.fields.length;
                                },
                                get display() {
                                    return this.fields.length ? true : false;
                                },
                                fields: [
                                ],
                            }
                            section.fields.push({ fieldName: API_NAMES.Contract_Discount__c['Disc_BDate_Y' + yearIndex + '__c'], fieldLabel: self.labels.object.Contract_Discount__c['Disc_BDate_Y' + yearIndex + '__c'], isInputField: true, fieldType: "DATE", });
                            section.fields.push({ fieldName: API_NAMES.Contract_Discount__c['Disc_EDate_Y' + yearIndex + '__c'], fieldLabel: self.labels.object.Contract_Discount__c['Disc_EDate_Y' + yearIndex + '__c'], isInputField: true, fieldType: "DATE", });
                            section.fields.push({ fieldName: API_NAMES.Contract_Discount__c['Value_amt_Y' + yearIndex + '__c'], fieldLabel: self.labels.object.Contract_Discount__c['Value_amt_Y' + yearIndex + '__c'], isInputField: true, });
                            section.fields.push({ fieldName: API_NAMES.Contract_Discount__c['Value_per_Y' + yearIndex + '__c'], fieldLabel: self.labels.object.Contract_Discount__c['Value_per_Y' + yearIndex + '__c'], isInputField: true, });
                            if (yearIndex == (currentContract[API_NAMES.Contract__c.Multi_Year_Index__c] || 1)) {
                                section.fields.push({
                                    fieldName: API_NAMES.Contract_Discount__c.unit_amount__c,
                                    fieldLabel: this.labels.object.Contract_Discount__c.unit_amount__c,
                                    isInputField: true,
                                });
                                section.fields.push({
                                    fieldName: API_NAMES.Contract_Discount__c.Unit_Amount_Type__c,
                                    fieldLabel: this.labels.object.Contract_Discount__c.Unit_Amount_Type__c,
                                    isInputField: true,
                                });
                                section.fields.push({
                                    fieldName: API_NAMES.Contract_Discount__c.Rank__c,
                                    fieldLabel: this.labels.object.Contract_Discount__c.Rank__c,
                                    isInputField: true,
                                });
                            }
                            yearPanelSection.push(section);
                        }
                        if (this.labels.conditionLabels.length === 0) {
                            this.labels.conditionLabels = yearPanelSection;
                        }
                        // Multi_Year_Index__c
                        // Multi_Year_Total__c
                        // Disc_BDate_Y
                        // Disc_EDate_Y
                        // Value_amt_Y
                        // Value_per_Y
                        // Rank__c
                        // Unit_Amount_Type__c
                        // unit_amount__c
                        let index = 0;
                        data.discounts.forEach(item => {
                            discounts.push(buildDiscountPageInfo(this, {}, item, index++, false, this.discountPercentScale));
                        });
                        this.wDiscList = discounts;
                        this.newWDiscList = [];
                        this.loading = false;
                        this.saveLoading = false;
                        setTimeout(() => {
                            callback2();
                            // callback3();
                        }, 0);
                    });
                };
                // setTimeout(() => {
                //     callback1();
                // }, 0);
                setTimeout(() => {
                    callback1();
                }, 0);
            }
        } catch (error) {
            // showNotification(this, 'Attention', `Id du contract n'existe plus`, ERROR_VARIANT);
            showNotification(this, Labels.LBL_Error, Labels.MSG_Invalid_Record, ERROR_VARIANT);
            this.loading = false;
            this.saveLoading = false;
        }
    }
    /**
    * Close tariff seletion popup
    */
    closeTariffPopup() {
        this.showTariffSelection = false;
    }
    closepopup(event) {
        this.handleCancel(event);
        // this.currentJSDiscountWrapper = null;
        // this.oldCurrentJSDiscountWrapper = null;
        // this.gridEditMode = false;
        this.gridEditModechanges = false;
    }
    /**
    * Close ManualInvoicingPopuppopup
    */
    showDispatchButton(event) {
        this.showDispatch = true;
        this.showDone = true;
        this.initialiseDistributionMonth();
    }
    initialiseDistributionMonth() {
        let conditionBDate = new Date(this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c]);
        let conditionBMonth = conditionBDate.getMonth() + 1;
        if (this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] && this.sBusinessType != 'CPG') {
            if (conditionBMonth < 10
                && ((!this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c]
                    && !this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_event_M10__c]) || !this.currentJSDiscountWrapper.discount.Id)) {
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c] = Math.round(0.4 * this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c]);
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_event_M10__c] = '40%';
                this.currentJSDiscountWrapper.dispatchValues[9].value = this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c];
            }
            if (conditionBMonth < 7
                && ((!this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M7__c]
                    && !this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_event_M7__c]) || !this.currentJSDiscountWrapper.discount.Id)) {
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M7__c] = Math.round(this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c]) - this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c];
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_event_M7__c] = '60%';
                this.currentJSDiscountWrapper.dispatchValues[6].value = this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M7__c];
            }
        }
    }
    autoDistributeMonths(event) {
        try {
            let conditionBDate = new Date(this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c]);
            let conditionEDate = new Date(this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Disc_EDate__c]);
            let conditionBMonth = conditionBDate.getMonth() + 1;
            let conditionEMonth = conditionEDate.getMonth() + 1;
            if (this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] && this.sBusinessType != 'CPG') {
                for (let discMonth = conditionBMonth; discMonth <= conditionEMonth; discMonth++) {
                    this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c['Value_amt_disp_M' + discMonth + '__c']] = null;
                    if (this.currentJSDiscountWrapper.dispatchValues[discMonth].enabled == true) {
                        this.currentJSDiscountWrapper.dispatchValues[discMonth].value = 0;
                    }
                }
                this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M13__c] = null;
                if (this.currentJSDiscountWrapper.dispatchValues[12].enabled == true) {
                    this.currentJSDiscountWrapper.dispatchValues[12].value = 0;
                }
                if (conditionBMonth < 10) {
                    this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c] = Math.round(0.4 * this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c]);
                    this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_event_M10__c] = '40%';
                    this.currentJSDiscountWrapper.dispatchValues[9].value = this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c];
                }
                if (conditionBMonth < 7) {
                    this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M7__c] = Math.round(this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c]) - this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M10__c];
                    this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_event_M7__c] = '60%';
                    this.currentJSDiscountWrapper.dispatchValues[6].value = this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt_disp_M7__c];
                }
            }
            if (this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] && this.sBusinessType == 'CPG') {
                let monthDiff = 0;
                let currentDate = new Date();
                let currentMonth = currentDate.getMonth() + 1;
                for (let discMonth = conditionBMonth; discMonth <= conditionEMonth; discMonth++) {
                    if ((discMonth >= currentMonth && conditionBDate.getFullYear() <= currentDate.getFullYear()) || conditionBDate.getFullYear() > currentDate.getFullYear()) {
                        monthDiff++;
                    }
                }
                let monthShare = (this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] / monthDiff);
                for (let discMonth = conditionBMonth; discMonth <= conditionEMonth; discMonth++) {
                    if ((discMonth >= currentMonth && conditionBDate.getFullYear() <= currentDate.getFullYear()) || conditionBDate.getFullYear() > currentDate.getFullYear()) {
                        this.currentJSDiscountWrapper.discount.put([API_NAMES.Contract_Discount__c['Value_amt_disp_M' + discMonth + '__c', monthShare]]);
                    } else {
                        this.currentJSDiscountWrapper.discount.put([API_NAMES.Contract_Discount__c['Value_amt_disp_M' + discMonth + '__c', null]]);
                    }
                }
            }
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    /**
    * Close negoscope Selectionpopup
    */
    closeNegoscopeSelection() {
        this.showNegoScopeSelection = false;
        this.negoscopesForSelection = this.negoscopes;
    }
    /**
    * Close negoscope Selectionpopup
    */
    closeBUSelection() {
        this.showBUSelection = false;
        this.BUForSelection = this.BUs.filter(item => item.BU[API_NAMES.BusinessUnit__c.SetAgreementLineMainTerm__c]);
    }
    /**
    * Close tariff seletion popup
    */
    closePopupsEsc = (event) => {
        if (event.keyCode === 27) {
            if (this.showTariffSelection) {
                this.closeTariffPopup();
            }
            if (this.popups.newSlabs.isOpen) {
                this.closeSlabPopUp();
            }
            if (this.showNegoScopeSelection) {
                this.closeNegoscopeSelection();
            }
            if (this.showBUSelection) {
                this.closeBUSelection();
            }
        }
    };
    /**
    * Detail page handling
    */
    handleClickDetail(event) {
        if (!this.loadDiscounts) return;
        try {
            this.openSubPanel = false;
            let target = event.target;
            let dataset = target.dataset;
            let field = target.dataset.field;
            if (this.currentJSDiscountWrapper
                && this.wDiscList[dataset.index]
                && ((dataset.id
                    && this.currentJSDiscountWrapper.discount.Id === this.wDiscList[dataset.index].discount.Id
                    && this.DetailPageOpen == true)
                    || (!this.currentJSDiscountWrapper.discount.Id
                        && !dataset.id
                        && this.currentJSDiscountWrapper.Index === this.newWDiscList[dataset.index].Index))
                && field !== API_NAMES.Contract_Discount__c.Condition_Type__c
                //&& !dataset.slab
                && !dataset.subview
                && !dataset.manualinvoice
                && !dataset.dispatching
                || dataset.islink
                || !dataset.id
                && !dataset.index) {
                return;
            }
            if (this.DetailPageOpen && this.gridEditMode && (!this.currentJSDiscountWrapper || this?.currentJSDiscountWrapper?.hasBeenEdited)) {
                this.gridEditModechanges = true;
                return;
            }
            this.gridEditMode = false;
            if (!dataset.slab && !dataset.manualinvoice && !dataset.dispatching) {
                this.oldCurrentJSDiscountWrapper = null;
                this.currentJSDiscountWrapper = null;
                if (dataset.id) {
                    this.discountChangeEvent = true;
                }
            }
            let self = this;
            setTimeout(() => {
                for (let elm of self?.template?.querySelectorAll('.row-highlight') || []) {
                    elm.classList.remove('row-highlight');
                }
                let subsLaunched = false;
                try {
                    let datasetid = dataset.id || target?.closest('td')?.dataset?.id;
                    if (datasetid) {
                        self.oldCurrentJSDiscountWrapper = JSON.parse(JSON.stringify(self.wDiscList[dataset.index]));
                        self.currentJSDiscountWrapper = self.wDiscList[dataset.index];
                        let currentApexDiscountWrapper = self.conditionPage.conditionConfigurations.contractWrapper.discounts[self.currentJSDiscountWrapper.Id];
                        if (!dataset.slab && !dataset.manualinvoice && !dataset.subview && !dataset.dispatching) {
                            //NORMAL CLICK
                            this.openDetailPage();
                            self.currentJSDiscountWrapperBackup = JSON.parse(JSON.stringify(self.currentJSDiscountWrapper));
                            self.currentApexDiscountWrapperBackup = JSON.parse(JSON.stringify(currentApexDiscountWrapper));
                        } else if (dataset.slab) {
                            //SLAB CLICK
                            /*this.closeDetailPage();
                            this.openDetailPage();
                            setTimeout(() => { this.template.querySelector("lightning-tabset").activeTabValue = "Slabs"; }, 1);
                            this.gridEditMode = true && !this.isReadOnly && self?.wDiscList[dataset.index] && !self?.wDiscList[dataset.index].isLockedDiscount;
                            this.showDone = this.gridEditMode;*/
                        } else if (dataset.manualinvoice) {
                            //MANUAL INVOICE CLICK
                            this.openDetailPage();
                            this.loadManualInvoice();
                            setTimeout(() => { this.template.querySelector("lightning-tabset").activeTabValue = "Manual Invoice"; }, 1);
                        } else if (dataset.subview) {
                            //SUBDISCOUNT CLICK
                            subsLaunched = true;
                            this.openSubPanel = true;
                            let JSWrapper = self.wDiscList[dataset.index];
                            self.loadDiscountSubs(JSWrapper);
                        } else if (dataset.dispatching) {
                            //DISPATCHING CLICK
                            this.closeDetailPage();
                            this.openDetailPage();
                            setTimeout(() => { this.template.querySelector("lightning-tabset").activeTabValue = "Dispatch Detail"; }, 1);
                            this.gridEditMode = true && !this.isReadOnly && self?.wDiscList[dataset.index] && !self?.wDiscList[dataset.index].isLockedDiscount;
                            this.showDone = this.gridEditMode;
                        }
                    } else {
                        self.oldCurrentJSDiscountWrapper = JSON.parse(JSON.stringify(self.newWDiscList[dataset.index]));
                        self.currentJSDiscountWrapper = self.newWDiscList[dataset.index];
                    }
                    self.subDiscountList = self?.currentJSDiscountWrapper?.subDiscountList || [];
                    if (!datasetid) {
                        this.closeDetailPage();
                        self.subDiscountList = self?.currentJSDiscountWrapper?.subDiscountList || [];
                    }
                    if (!dataset.fromdetail) {
                        self.node = target.closest("tr");
                        self.node.classList.add('row-highlight');
                        self.discountChangeEvent = false;
                    }
                    if (field === API_NAMES.Contract_Discount__c.Condition_Type__c) {
                        self.fromDetailsTab = false;
                        self.showTariffSelection = true;
                        self.currentJSDiscountWrapper.availableTariff.filteredList = self.currentJSDiscountWrapper.availableTariff.list;
                    }
                    if (this.openSubPanel && !dataset.subview) {
                        let JSWrapper = self.wDiscList[dataset.index];
                        //BUGS
                        if (JSWrapper?.tariffHasSubDiscounts) {
                            self.loadDiscountSubs(JSWrapper);
                        } else {
                            this.openSubPanel = false;
                            if (this.previousJSDiscountWrapperIndex != null) {
                                this.wDiscList[this.previousJSDiscountWrapperIndex].subsOpened = false;
                                this.conditionPage.conditionConfigurations.contractWrapper["discounts"][this.wDiscList[this.previousJSDiscountWrapperIndex].Id].subsOpened = false;
                                this.previousJSDiscountWrapperIndex = null;
                            }
                        }
                    }
                } catch (exception) {
                    console.error(exception);
                    showNotification(this, Labels.LBL_Error, exception?.body?.message || exception?.message || exception, ERROR_VARIANT);
                }
            }, 1);
            event.stopPropagation();
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleOpenTariffTab(event) {
        this.fromDetailsTab = false;
        this.currentJSDiscountWrapper.availableTariff.filteredList = this.currentJSDiscountWrapper.availableTariff.list;
        this.showTariffSelection = true;
    }
    /*handleOpenTariffTab2(event) {
        this.fromDetailsTab = true;
        this.currentJSDiscountWrapper.availableTariff.filteredList = this.currentJSDiscountWrapper.availableTariff.list;
        this.showTariffSelection = true;
    }*/
    first() {
        let newoffset = 0;
        if (this.offset !== newoffset) {
            this.offset = newoffset;
            this.getDiscountData();
        }
    }
    //open previous page
    previous() {
        let pageSize = parseInt(this.pageSize, 10);
        let newoffset =
            this.offset - pageSize >= 0 ? this.offset - pageSize : this.offset;
        if (this.offset != newoffset) {
            this.offset = newoffset;
            this.getDiscountData();
        }
    }
    //open next page
    next() {
        let pageSize = parseInt(this.pageSize, 10);
        let newoffset =
            this.offset + pageSize < this.total ?
                this.offset + pageSize :
                this.offset;
        if (this.offset != newoffset) {
            this.offset = newoffset;
            this.getDiscountData();
        }
    }
    //open last page
    last() {
        let pageSize = parseInt(this.pageSize, 10);
        let newoffset =
            (Math.floor(this.total / pageSize) == this.total / pageSize ?
                Math.floor(this.total / pageSize) - 1 :
                Math.floor(this.total / pageSize)) * pageSize;
        if (this.offset != newoffset) {
            this.offset = newoffset;
            this.getDiscountData();
        }
    }
    /**
    * handle tariff changes
    */
    handleTariffSelection(event) {
        try {
            this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__c] = event.target.dataset.value;
            this.currentJSDiscountWrapper.errors = this?.currentJSDiscountWrapper?.errors?.filter(it => it != Labels.MSG_Invalid_Code_Budget_For_Nego_DiscountType) || [];
            this.currentJSDiscountWrapper.loading = true;
            let selectedConditionType = this.currentJSDiscountWrapper.availableTariff.filteredList.filter(f => f.Id == event.target.dataset.value);
            let _selectedConditionType = JSON.parse(JSON.stringify(selectedConditionType[0]));
            delete _selectedConditionType.hasMasterBU;
            delete _selectedConditionType.masterBUName;
            delete _selectedConditionType.masterBULink;
            delete _selectedConditionType.Long_Name;
            delete _selectedConditionType.Capture_Discount_Product_Level;
            delete _selectedConditionType.Index;
            delete _selectedConditionType.IndexLabel;
            delete _selectedConditionType.Is_Conditional;
            delete _selectedConditionType.Condition_Mode;
            delete _selectedConditionType.Condition_Mode_Label;
            this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r] = _selectedConditionType;
            if (this.fromDetailsTab) {
            } else {
                this.template.querySelector(`[data-lookupkey="${this.currentJSDiscountWrapper.conditionLookUpKey}"]`).value = event.target.dataset.name;
                // this.currentJSDiscountWrapper.loading = true;
                // this.hasOverFlow = true;
                this.showTariffSelection = false;
                let currentApexDiscountWrapper = this.conditionPage.conditionConfigurations.contractWrapper["newDiscounts"][this.currentJSDiscountWrapper.Index];
                currentApexDiscountWrapper.discount = this.currentJSDiscountWrapper.discount;
                currentApexDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r] = _selectedConditionType;
                this.populateFields(currentApexDiscountWrapper, _selectedConditionType, false)
            }
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    populateFields(currentApexDiscountWrapper, _selectedConditionType, onlyInvoiceFields) {
        populateFields({
            DiscountWrapperJSON: JSON.stringify(currentApexDiscountWrapper),
            tarrifConditionJSON: JSON.stringify(_selectedConditionType),
            onlyInvoiceFields: onlyInvoiceFields,
        }).then((result) => {
            let currentJSWrapper = this.currentJSDiscountWrapper;
            let updatedDiscountWrapper = JSON.parse(result);
            this.conditionPage.conditionConfigurations.contractWrapper["newDiscounts"][this.currentJSDiscountWrapper.Index] = updatedDiscountWrapper;
            let rebuiltDiscount = buildDiscountPageInfo(this, updatedDiscountWrapper, updatedDiscountWrapper.discount, currentJSWrapper.Index, false, this.discountPercentScale);
            rebuiltDiscount.hasBeenEdited = true;
            this.newWDiscList[currentJSWrapper.Index] = rebuiltDiscount;
            this.currentJSDiscountWrapper = rebuiltDiscount;
            if (rebuiltDiscount?.errors?.length) {
                showNotification(this, Labels.LBL_Error, rebuiltDiscount?.errors?.join('\n'), ERROR_VARIANT);
            }
            this.currentJSDiscountWrapper.loading = false;
        }).catch((error) => {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        });
    }
    handleFieldEdits(event) {
        let dataset = event.target.dataset;
        let id = dataset.id;
        let index = dataset.index;
        let field = dataset.field;
        let fieldIndex = dataset.fieldindex;
        let yearpanel = dataset.yearpanel || false;
        let fromDispatch = dataset.dispatch;
        let oldValue, newValue;
        let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        // if (field == API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c) {
        //     console.log('this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] : ' + this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] )
        //     this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] = !this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c];
        //     console.log('this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] AFT: ' + this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] )
        // }   
        try {
            if ((id || index || this.apexNewDiscountWrapper) && field) {
                // this.hasOverFlow = true;
                let currentDiscount;
                if (this.apexNewDiscountWrapper) {
                    currentDiscount = this.currentJSDiscountWrapper;
                } else {
                    currentDiscount = id ? this.wDiscList[index] : this.newWDiscList[index];
                }
                //check if field is manual invoicing
                if (!currentDiscount) {
                    return;
                }
                let oldRespectScope = currentDiscount.respectScope;
                // if (field == API_NAMES.Contract_Discount__c.Invoice_period__c) {
                //     let ffield = currentDiscount.values.find(it => it.fieldDescription.fieldName == API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c);
                //     let res = value ? true : false;
                //     if (ffield) {
                //         currentDiscount.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] = !res;
                //         if (!currentDiscount.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c]) {
                //             currentDiscount.manualInvoiceSummary = {};
                //             Object.values(currentDiscount?.wInvoiceMap || {}).forEach(it => {
                //                 it.isSelected = false;
                //                 it.invoiceDetail[API_NAMES.InvoiceDetail__c.DetailAmount__c] = null;
                //             });
                //         }
                //         ffield.fieldValue = !res;
                //     }
                // }
                if (fromDispatch) {
                    currentDiscount.discount[field] = parseFloat(value) || null;
                    currentDiscount.sumOfAmount = 0;
                    for (let amtIndex = 0; amtIndex < 13; amtIndex++) {
                        if (currentDiscount.discount[amtValueFields[amtIndex]] != null) {
                            currentDiscount.sumOfAmount += currentDiscount.discount[amtValueFields[amtIndex]];
                        }
                    }
                } else if (field == API_NAMES.Contract_Discount__c.Down_Payment_YE_Coverage__c
                    || field == API_NAMES.Contract_Discount__c.Invoice_period__c
                    || field == API_NAMES.Contract_Discount__c.Invoice_base__c
                    || field == API_NAMES.Contract_Discount__c.Invoice_sequence__c
                    || field == API_NAMES.Contract_Discount__c.First_invoice_date__c) {
                    currentDiscount.discount[field] = value;
                    if (value && field == API_NAMES.Contract_Discount__c.Invoice_base__c) {
                        if (this.isManualInvoicingPlanning) {
                            if (value != 'ActualYTD') {
                                currentDiscount.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Coverage__c] = null;
                            }
                            if (this.invoicesArray) {
                                this.invoicesArray.forEach(item => {
                                    item.invoiceBase = value;
                                    if (item.invoice.Status.value == 'Generated' && value == 'ActualYTD') {
                                        item.Amount = null;
                                    }
                                });
                            }
                        }
                    }
                } else if (field == API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c) {
                    let res = value ? true : false;
                    currentDiscount.discount[field] = res;
                } else {
                    oldValue = currentDiscount.discount[field];
                    currentDiscount.discount[field] = Array.isArray(value) ? value[0] : value == '' ? typeof value == 'boolean' ? value : null : value;
                    newValue = currentDiscount.discount[field];
                }
                currentDiscount.errors = currentDiscount?.errors?.filter(it => it != Labels.MSG_Rank_IsRequired) || [];
                if (this.sBusinessType != 'CPG' && !currentDiscount.discount[API_NAMES.Contract_Discount__c.Rank__c]
                    && (currentDiscount?.discount[API_NAMES.Contract_Discount__c.Index__c] == 'Index1'
                        || currentDiscount?.discount[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c])) {
                    currentDiscount.errors.push(Labels.MSG_Rank_IsRequired)
                }
                currentDiscount.hasBeenEdited = true;
                if (fieldIndex) {
                    if (yearpanel) {
                        currentDiscount.yearValues[fieldIndex].fieldValue = value;
                    } else if (index) {
                        currentDiscount.values[fieldIndex].fieldValue = value;
                    }
                }
                this.hasOverFlow = false;
                if (currentDiscount.discount[API_NAMES.Contract_Discount__c.Condition_Type__c] && (fakeSaveTrigger.includes(field) && oldValue != newValue)/*&& currentDiscount.isNewDiscount*/) {
                    if (field == API_NAMES.Contract_Discount__c.Nego_Discount_Type__c) {
                        let currentError = [];
                        currentError.push(Labels.MSG_Invalid_Code_Budget_For_Nego_DiscountType);
                        // this.currentJSDiscountWrapper.errors = currentError;
                        currentDiscount.errors = currentError;
                    }
                }
                if ([
                    API_NAMES.Contract_Discount__c.Value_per_Y1__c,
                    API_NAMES.Contract_Discount__c.Value_per_Y2__c,
                    API_NAMES.Contract_Discount__c.Value_per_Y3__c,
                    API_NAMES.Contract_Discount__c.Value_per_Y4__c,
                    API_NAMES.Contract_Discount__c.Value_per_Y5__c,
                ].includes(field)) {
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Value_per__c] = currentDiscount.discount[field] || null;
                }
                if ([
                    API_NAMES.Contract_Discount__c.Value_amt_Y1__c,
                    API_NAMES.Contract_Discount__c.Value_amt_Y2__c,
                    API_NAMES.Contract_Discount__c.Value_amt_Y3__c,
                    API_NAMES.Contract_Discount__c.Value_amt_Y4__c,
                    API_NAMES.Contract_Discount__c.Value_amt_Y5__c,
                ].includes(field)) {
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Value_amt__c] = currentDiscount.discount[field] || null;
                }
                if ([
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y2__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y3__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y4__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y5__c,
                ].includes(field)) {
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c] = currentDiscount.discount[field];
                }
                if ([
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y2__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y3__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y4__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y5__c,
                ].includes(field)) {
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Disc_EDate__c] = currentDiscount.discount[field];
                }
                // populate Base_TO_Nego__c, Base_Quantity_Nego__c
                if (currentDiscount.respectScope) {
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = this.currentContract[API_NAMES.Contract__c.Total_TO__c];
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = this.currentContract[API_NAMES.Contract__c.Total_Qty__c];
                } else if (oldRespectScope != currentDiscount.respectScope) {
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = null;
                    currentDiscount.discount[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = null;
                }
                this.newWDiscList = [...this.newWDiscList];
            }
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            this.hasOverFlow = false;
        }
    }
    handleFieldEditsBlur() {
        let currentApexDiscountWrapper = this.conditionPage.conditionConfigurations.contractWrapper["newDiscounts"][this.currentJSDiscountWrapper.Index];
        currentApexDiscountWrapper.discount = this.currentJSDiscountWrapper.discount;
        this.populateFields(currentApexDiscountWrapper, currentApexDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r], true);
    }
    filterTariff(event) {
        let regex = new RegExp(event.target.value, "i");
        this.currentJSDiscountWrapper.availableTariff.filteredList = this.currentJSDiscountWrapper.availableTariff.list.filter(it => regex.test(it.Name));
    }
    createNewDiscount(event) {
        let newIndex = this.numberOfNewDiscount++;
        createNewDiscount({
            contractJSON: JSON.stringify(this.currentContract),
            wContractYearsMapJSON: JSON.stringify(this.conditionPage.wContractYearsMap)
        }).then((result) => {
            let newDiscount = JSON.parse(result);
            this.apexNewDiscountWrapper = newDiscount;
            this.currentJSDiscountWrapper = buildDiscountPageInfo(this, newDiscount, newDiscount.discount, null, false, this.discountPercentScale);
            this.gridEditMode = true;
        }).catch((error) => {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        });
    }
    createNewDiscountInline(event) {
        try {
            this.openSubPanel = false;
            let newIndex = this.numberOfNewDiscount++;
            let self = this;
            if (this.checkIfDetailTabOpen) {
                this.closeEditPage();
                this.wDiscList.forEach(disc => {
                    disc.isSelected = false;
                });
                for (let elm of self?.template?.querySelectorAll('.row-highlight') || []) {
                    elm.classList.remove('row-highlight');
                }
            }
            this.newWDiscList.push(buildDiscountPageInfo(this, {}, {}, newIndex, true, this.discountPercentScale));
            createNewDiscount({
                contractJSON: JSON.stringify(this.currentContract),
                wContractYearsMapJSON: JSON.stringify(this.conditionPage.wContractYearsMap)
            }).then((result) => {
                let newDiscount = JSON.parse(result);
                this.currentJSDiscountWrapper = buildDiscountPageInfo(this, newDiscount, newDiscount.discount, null, false, this.discountPercentScale);
                this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[newIndex] = newDiscount;
                /**
                * Build new lines
                */
                let discount = buildDiscountPageInfo(this, newDiscount, newDiscount.discount, newIndex, false, this.discountPercentScale);
                discount.isInline = true;
                this.newWDiscList[newIndex] = discount;
            }).catch((error) => {
                console.error(error);
                showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            });
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    simulateInvoicesGenerationForDiscounts(event) {
        // let self = this;
        // this.loading = true;
        let wDiscList = this.wDiscList;
        wDiscList.forEach(it => {
            it.loading = true;
        });
        let _wDiscList = JSON.parse(JSON.stringify(wDiscList));
        _wDiscList = _wDiscList.map(it => {
            delete it.availableTariff;
            return it;
        });
        let currentContract = this.currentContract;
        simulateInvoicesGenerationForDiscounts({ wDiscList_JSON: JSON.stringify(_wDiscList), contract_JSON: JSON.stringify(currentContract) }).then(result => {
            let newWDiscList = JSON.parse(result);
            newWDiscList.forEach((it, ind) => {
                if (wDiscList[ind] && wDiscList[ind].discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Value_Reference__c] != it.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Value_Reference__c]) {
                    wDiscList[ind].hasBeenEdited = true;
                    wDiscList[ind].discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Value_Reference__c] = it.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Value_Reference__c];
                }
            });
            wDiscList.forEach(it => {
                it.loading = false;
            });
        }).catch((error) => {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            wDiscList.forEach(it => {
                it.loading = false;
            });
        });
    }
    @track savingInProgress = false;
    saveDiscount(event) {
        let self = this;
        this.savingInProgress = true;
        let handler = () => {
            self.closeIndexPanel();
            self.closeDetailPage();
            self.saveLoading = true;
            self.openSubPanel = false;
            let discountToSave = [];
            try {
                for (let index in self.wDiscList) {
                    let pageDiscount = self.wDiscList[index].discount;
                    let JSWrapper = self.wDiscList[index];
                    if (JSWrapper.hasBeenEdited && JSWrapper.conditionType && JSWrapper.conditionTypeId) {
                        let discountW = self.conditionPage.conditionConfigurations.contractWrapper.discounts[pageDiscount.Id];
                        discountW.respectScope = JSWrapper.respectScope;
                        discountToSave.push(discountW);
                    }
                }
                for (let index in self.newWDiscList) {
                    let pageDiscount = self.newWDiscList[index].discount;
                    let JSWrapper = self.newWDiscList[index];
                    if (JSWrapper.conditionType && JSWrapper.conditionTypeId) {
                        self.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[index].discount = pageDiscount;
                        let discountW = self.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[index];
                        discountW.respectScope = JSWrapper.respectScope;
                        discountToSave.push(discountW);
                    }
                }
                if (self.apexNewDiscountWrapper) {
                    discountToSave.push(self.apexNewDiscountWrapper);
                }
                self.subDiscountList = [];
                self.assignSubDiscountsToLWC();
                let IsRankError = false;
                let valuesEmpty = false;
                let qtyMng = false;
                let NonRespectMng = false;
                // let checkManagement = false;
                let errorsFound = false;
                let IsInvoiceAmountError = false;
                let subDiscountValidationMessages = [];
                for (let index in discountToSave) {
                    let discountWrapper = discountToSave[index];
                    let valuePerEmpty = false;
                    let valueAmtEmpty = false;
                    let UnitAmtEmpty = false;
                    let slabsEmpty = false;
                    if (self.sBusinessType != 'CPG' && !discountWrapper.discount[API_NAMES.Contract_Discount__c.Rank__c]
                        && (discountWrapper?.discount[API_NAMES.Contract_Discount__c.Index__c] == 'Index1'
                            || discountWrapper?.discount[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c])) {
                        IsRankError = true;
                        // discountWrapper.hasErrors = true;
                        discountWrapper.errors = [Labels.MSG_Rank_IsRequired];
                        errorsFound = true;
                    }
                    // check invoices amount for manual invoicing
                    let isManualInvoicing = discountWrapper.discount && discountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] ? discountWrapper.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] : '';
                    if (isManualInvoicing) {
                        discountWrapper?.invoiceDetails?.forEach(element => {
                            if (element.invoice.AccDoc
                                && ['CNCancelRequest', 'BalanceCNCancelRequest', 'BalanceCreditNote', 'CreditNote'].includes(element.invoice.AccDoc)
                                && element.Amount
                                && element.Amount < 0) {
                                IsInvoiceAmountError = true;
                                discountWrapper.errors = [Labels.MSG_Invalid_Invoice_Amount];
                                errorsFound = true;
                            }
                        });
                    }
                    let matchingJSWrapper = self.wDiscList.find(w => w?.discount?.Id && discountWrapper?.discount?.Id && w.discount.Id === discountWrapper.discount.Id);
                    if (matchingJSWrapper?.showMessageOnSubDiscounts) {
                        if (matchingJSWrapper.showErrorAmount) {
                            subDiscountValidationMessages.push(self.amtErrorMessage);
                            errorsFound = true;
                        }
                        if (matchingJSWrapper.showErrorPercent) {
                            subDiscountValidationMessages.push(self.perErrorMessage);
                            errorsFound = true;
                        }
                        if (!self.isCPG) {
                            if (matchingJSWrapper.showWarningAmount) {
                                subDiscountValidationMessages.push(self.amtWarningMessage);
                                errorsFound = true;
                            }
                            if (matchingJSWrapper.showWarningPercent) {
                                subDiscountValidationMessages.push(self.perWarningMessage);
                                errorsFound = true;
                            }
                        }
                    }
                    for (let year of this.labels.conditionLabels) {
                        for (let field of year.fields) {
                            if (!valuePerEmpty && field.fieldName.toLowerCase().includes('value_per')) {
                                valuePerEmpty = !discountWrapper.discount[field.fieldName] || discountWrapper.discount[field.fieldName] == 0;
                            }
                            if (!valueAmtEmpty && field.fieldName.toLowerCase().includes('value_amt')) {
                                valueAmtEmpty = !discountWrapper.discount[field.fieldName] || discountWrapper.discount[field.fieldName] == 0;
                            }
                            if (!UnitAmtEmpty && field.fieldName.toLowerCase().includes('unit_amount')) {
                                UnitAmtEmpty = !discountWrapper.discount[field.fieldName] || discountWrapper.discount[field.fieldName] == 0;
                            }
                        }
                    }
                    if (!slabsEmpty && discountWrapper.discount[API_NAMES.Contract_Discount__c.is_Conditional__c]) {
                        slabsEmpty = (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_1__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_1__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_2__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_2__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_3__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_3__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_4__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_4__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_5__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_5__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_6__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_6__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_7__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_7__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_8__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_8__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_9__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_9__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_10__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_10__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_1__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_1__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_2__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_2__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_3__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_3__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_4__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_4__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_5__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_5__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_6__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_6__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_7__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_7__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_8__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_8__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_9__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_9__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_10__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_per_10__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_1__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_1__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_2__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_2__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_3__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_3__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_4__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_4__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_5__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_5__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_6__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_6__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_7__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_7__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_8__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_8__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_9__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_9__c] == 0)
                            && (discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_10__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Val_10__c] == 0)
                    }
                    if (!qtyMng) {
                        let A = discountWrapper.discount[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] == 0;
                        let B = discountWrapper.discount[API_NAMES.Contract_Discount__c.unit_amount__c] != null && discountWrapper.discount[API_NAMES.Contract_Discount__c.unit_amount__c] != 0;
                        let C = discountWrapper.discount[API_NAMES.Contract_Discount__c.IsSlabRespectConditionScope__c] == true;
                        let D = discountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Is_Conditional__c]
                            && discountWrapper.discount[API_NAMES.Contract_Discount__c.Slab_Calc_Method_TO_Origin__c] == 'Nego'
                            && ['Qty', 'Prog Qty', 'Inc Qty', 'Inc Prog Qty'].includes(discountWrapper.discount[API_NAMES.Contract_Discount__c.slab_calc_method__c]);
                        let E = discountWrapper.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyNego__c] == null || discountWrapper.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyNego__c] == 0;
                        qtyMng = (A && (B || (C && D))) || (!C && D && E);
                    }
                    if (!NonRespectMng) {
                        NonRespectMng = !discountWrapper.respectScope && (!discountWrapper.discount[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] || (discountWrapper.discount[API_NAMES.Contract_Discount__c.unit_amount__c] && !discountWrapper.discount[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c]));
                    }
                    if (!valuesEmpty) {
                        valuesEmpty = ((!discountWrapper.discount[API_NAMES.Contract_Discount__c.is_Conditional__c] && valuePerEmpty && valueAmtEmpty && UnitAmtEmpty) || (discountWrapper.discount[API_NAMES.Contract_Discount__c.is_Conditional__c] && slabsEmpty)) && !discountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c];
                    }
                    // if (discountWrapper.checkForQuantityManagementConditions) {
                    //     checkManagement = true;
                    // }
                }
                if (IsInvoiceAmountError) {
                    showNotification(self, Labels.LBL_Error, Labels.MSG_Invalid_Invoice_Amount, ERROR_VARIANT);
                }
                if (IsRankError) {
                    showNotification(self, Labels.LBL_Error, Labels.MSG_Rank_IsRequired, ERROR_VARIANT);
                }
                if (subDiscountValidationMessages.length) {
                    showNotification(self, Labels.LBL_Error, [...new Set(subDiscountValidationMessages)].join('\n'), ERROR_VARIANT, false);
                }
                // if (checkManagement) {
                //     showNotification(this, Labels.LBL_Warning, Labels.MSG_Quantity_Mandatory_For_Unit_Amount, WARNING_VARIANT);
                // }
                if (errorsFound) {
                    // showNotification(this, 'Attention', `Certaines conditions ont échoué, veuillez résoudre le problème et réessayer d'enregistrer`, 'warning');
                    showNotification(self, Labels.LBL_Warning, Labels.LBL_Conditions_Failed, WARNING_VARIANT);
                    self.saveLoading = false;
                    self.savingInProgress = false;
                } else {
                    let runSave = true;
                    if (!self.showWarningPopupBeforeSave) {
                        self.showValuesEmptyWarning = valuesEmpty;
                        self.showQuantityManagementWarning = qtyMng;
                        self.showCAAssietteWarning = NonRespectMng;
                        if (self.showValuesEmptyWarning || self.showQuantityManagementWarning || self.showCAAssietteWarning) {
                            runSave = false;
                            self.savingInProgress = false;
                        }
                    }
                    self.showWarningPopupBeforeSave = self.showQuantityManagementWarning || self.showCAAssietteWarning || self.showValuesEmptyWarning;
                    if (runSave) {
                        this.savePopUp = true;
                        this.currentStatusMSG = this.labels.LBL_Save;
                        self.showWarningPopupBeforeSave = false;
                        self.showQuantityManagementWarning = false;
                        self.showValuesEmptyWarning = false;
                        self.showCAAssietteWarning = false;
                        // Clean up relationship fields to avoid "Cannot specify both an external ID reference and a salesforce id" error
                        discountToSave.forEach(discountWrapper => {
                            // Clean parent discount relationship fields
                            if (discountWrapper.discount) {
                                discountWrapper.discount.Condition_Type__r = null;
                                discountWrapper.discount.Product_Scope__r = null;
                                discountWrapper.discount.BusinessUnitScope__r = null;
                                discountWrapper.discount.Contract__r = null;
                                discountWrapper.discount.NegoScopeSlab__r = null;
                                discountWrapper.discount.BusinessUnitSlab__r = null;
                            }
                            // Clean subdiscounts relationship fields
                            if (discountWrapper.subDiscountsMap) {
                                Object.values(discountWrapper.subDiscountsMap).forEach(subArray => {
                                    if (Array.isArray(subArray)) {
                                        subArray.forEach(subDiscountWrapper => {
                                            if (subDiscountWrapper && subDiscountWrapper.discount) {
                                                subDiscountWrapper.discount.Condition_Type__r = null;
                                                subDiscountWrapper.discount.Product_Scope__r = null;
                                                subDiscountWrapper.discount.BusinessUnitScope__r = null;
                                                subDiscountWrapper.discount.Contract__r = null;
                                                subDiscountWrapper.discount.NegoScopeSlab__r = null;
                                                subDiscountWrapper.discount.BusinessUnitSlab__r = null;
                                            }
                                        });
                                    }
                                });
                            }
                        });
                        SaveMultipleDiscounts({
                            wDiscList_JSON: JSON.stringify(discountToSave),
                            contract_JSON: JSON.stringify(self.currentContract),
                            availableContractTariff_JSON: JSON.stringify(self.conditionPage.conditionConfigurations.contractWrapper.availableContractTariff),
                            gridSettings_JSON: JSON.stringify(self.conditionPage.gridSettings)
                        }).then((result) => {
                            if (result) {
                                let data = JSON.parse(result);
                                let retrievedDiscount = data.wDiscList;
                                let apexWrappersOldMap = {};
                                let apexWrappersNewMap = {};
                                let dbDiscounts = [];
                                let newDiscounts = [];
                                let newIndex = 0;
                                let oldIndex = 0;
                                self.currentContract = { ...self.currentContract, ...retrievedDiscount[0]?.contract };
                                setContractDetails(self, self.currentContract);
                                let errorMessages = [];
                                for (let discountWrapper of retrievedDiscount) {
                                    if (self.sBusinessType != 'CPG' && !discountWrapper.discount[API_NAMES.Contract_Discount__c.Rank__c]
                                        && (discountWrapper?.discount[API_NAMES.Contract_Discount__c.Index__c] == 'Index1'
                                            || discountWrapper?.discount[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c])) {
                                        discountWrapper.errors = [...(discountWrapper?.errors || []), Labels.MSG_Rank_IsRequired];
                                    }
                                    errorMessages = [...errorMessages, ...(discountWrapper?.errors || [])];
                                    if (discountWrapper?.errors?.length) {
                                        errorsFound = true;
                                    }
                                    if (discountWrapper?.discount?.Id) {
                                        discountWrapper.JSIndex = oldIndex++;
                                        apexWrappersOldMap[discountWrapper.discount.Id] = discountWrapper
                                        dbDiscounts.push(buildDiscountPageInfo(self, discountWrapper, discountWrapper.discount, discountWrapper.JSIndex, false, this.discountPercentScale));
                                    } else {
                                        discountWrapper.JSIndex = newIndex++;
                                        apexWrappersNewMap[discountWrapper.JSIndex] = discountWrapper
                                        newDiscounts.push(buildDiscountPageInfo(self, discountWrapper, discountWrapper.discount, discountWrapper.JSIndex, false, this.discountPercentScale));
                                    }
                                }
                                self.conditionPage.conditionConfigurations.contractWrapper.discounts = apexWrappersOldMap;
                                self.conditionPage.conditionConfigurations.contractWrapper.newDiscounts = apexWrappersNewMap;
                                self.wDiscList = dbDiscounts;
                                self.newWDiscList = newDiscounts;
                                self.numberOfNewDiscount = newDiscounts.length;
                                // consolidate contract
                                // if (data.hasSuccess && self.conditionPage.conditionConfigurations.contractConsoRequired) {
                                //     self.unableToLockUnlockPopUp = true;
                                //     self.consoRunning = true;
                                // }
                                self.saveLoading = false;
                                if (!data.hasSuccess) {
                                    showNotification(self, Labels.LBL_Error, data.errors, ERROR_VARIANT);
                                }
                                if (errorMessages?.length) {
                                    // showNotification(this, 'Attention', `Certaines conditions ont échoué, veuillez résoudre le problème et réessayer d'enregistrer`, 'warning');
                                    // showNotification(this, Labels.LBL_Warning, Labels.LBL_Conditions_Failed, WARNING_VARIANT);
                                    showNotification(self, Labels.LBL_Error, errorMessages.join('\n'), ERROR_VARIANT);
                                } else {
                                    showNotification(self, '', Labels.LBL_Success, SUCCESS_VARIANT);
                                    this.consolidateContract();
                                }
                            } else {
                                self.resetpage();
                            }
                            self.savingInProgress = false;
                        }).catch((error) => {
                            self.savingInProgress = false;
                            self.saveLoading = false;
                            console.error(error);
                            showNotification(self, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                        });
                    } else {
                        self.saveLoading = false;
                    }
                }
            } catch (error) {
                self.savingInProgress = false;
                console.error(error);
                showNotification(self, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                self.saveLoading = false;
            }
        }
        self.refreshIndexValues(event, self, handler);
    }

    togglePDSDPopup(event) {
        console.log('togglePDSDPopup')
        console.log('this.showPDSDPopup >> ' + this.showPDSDPopup)
        let index = event.target.dataset.index;
        let id = event.target.dataset.id;
        this.currentJSDiscountWrapper = this.wDiscList[index];
        console.log('1 >> ')
        if (!this.showPDSDPopup) {
            console.log('2 >> ')
            this.currentJSDiscountWrapper.loading = true;
            this.PDSDWrapper = {
                fields: [],
                PDSWrapper: [],
            }
            console.log('3 >> ')
            getProductDiscountStatementDetails({
                discountId: id
            }).then((result) => {
                let parsedResult = JSON.parse(result);
                this.PDSDWrapper.fields = parsedResult.fields;
                this.PDSDWrapper.PDSWrapper = this.buildPDSD(parsedResult.records);
                this.currentJSDiscountWrapper.loading = false;
            }).catch((error) => {
                this.error = error;
                showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                this.currentJSDiscountWrapper.loading = false;
            });
        }
        this.showPDSDPopup = !this.showPDSDPopup;
    }

    buildPDSD(records) {
        console.log('buildPDSD')
        let dataMap = {};
        for (let record of records) {
            let PDSWrapper;
            if (!dataMap.hasOwnProperty(record[API_NAMES.ProductDiscountStatementDetail__c.ProductDiscountStatement__c])) {
                PDSWrapper = {
                    Id: record[API_NAMES.ProductDiscountStatementDetail__c.ProductDiscountStatement__c],
                    Name: record[API_NAMES.ProductDiscountStatementDetail__c.ProductDiscountStatement__r].Name,
                    PDSDList: [],
                }
                dataMap[record[API_NAMES.ProductDiscountStatementDetail__c.ProductDiscountStatement__c]] = PDSWrapper;
            }
            PDSWrapper = dataMap[record[API_NAMES.ProductDiscountStatementDetail__c.ProductDiscountStatement__c]];
            let row = {
                Id: record.id,
                fieldValues: [],
            }
            for (let field of this.PDSDWrapper.fields) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY',
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')),
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    isText: field.fieldType == 'STRING',
                    link: '',
                    scale: field.scale,
                    isHTMLFormatted: field.isHTMLFormatted,
                    picklistValues: field.picklistValues,
                    fieldValue: record[field.fieldName]
                }
                if (fieldWrapper.isReference) {
                    fieldWrapper.fieldValue = record[field.fieldName.replace(/__c$/, '__r')]?.Name;
                    fieldWrapper.link = '/' + record[field.fieldName];
                }
                if (fieldWrapper.isPicklist) {
                    let value = record[field.fieldName];
                    let picklist = fieldWrapper.picklistValues.find(item => item.value = value);
                    fieldWrapper.fieldValue = picklist ? picklist.label : '';
                }
                row.fieldValues.push(fieldWrapper)
            }
            PDSWrapper.PDSDList.push(row);
        }
        return Object.values(dataMap);
    }

    consolidateContract(event) {
        this.currentStatusMSG = this.labels.LBL_Consolidate_Contracts;
        this.savePopUp = true;           // ensure modal is visible
        this.saveLoading = true;
        this.consoLoading = true;
        consolidateContract({
            contract_JSON: JSON.stringify(this.currentContract)
        }).then((result) => {
            // Consolidation finished successfully
            this.consoLoading = false;
            // NSA guard in JS: only sync if the contract’s NegoScope is Advanced
            const isAdvanced = this.currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__r]?.RecordType?.DeveloperName === 'Advanced';
            if (!isAdvanced) {
                // Non-Advanced: close popup as before
                this.closeSavePopup();
                return;
            } else {
                this.synchroAdvancedContracts();
            }
        }).catch((error) => {
            // Consolidation failed
            this.closeSavePopup();
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        });
    }

    synchroAdvancedContracts() {
        this.savePopUp   = true;
        this.saveLoading = true;
        this.currentStatusMSG = this.labels.LBL_Synchro || 'Synchronizing...';
        synchroAdvancedContracts({ contractId: this.recordId }).then((batchId) => {
            if (batchId != null) {
                checkCompletedBatches(this, batchId).then(result => {
                    // Batch finished – close the popup
                    this.closeSavePopup();
                }).catch(error => {
                    this.closeSavePopup();
                    console.error(error);
                });
            } else {
                // Nothing to poll (not enqueued / already handled) – close gracefully
                this.closeSavePopup();
                return;
            }
        }).catch((error) => {
            this.closeSavePopup();
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        });
    }

    closeSavePopup() {
        this.savePopUp = false;
        this.saveLoading = false;
        this.unableToLockUnlockPopUp = false;
        this.currentStatusMSG = '';
    }

    handleCancel(event) {
        let currentJSDiscountWrapper = this.currentJSDiscountWrapper;
        let oldCurrentJSDiscountWrapper = this.oldCurrentJSDiscountWrapper;
        Object.keys(oldCurrentJSDiscountWrapper.discount).forEach(field => currentJSDiscountWrapper.discount[field] = oldCurrentJSDiscountWrapper.discount[field] || null);
        Object.keys(oldCurrentJSDiscountWrapper.yearValues).forEach(field => currentJSDiscountWrapper.yearValues[field].fieldValue = oldCurrentJSDiscountWrapper.yearValues[field].fieldValue || null);
        Object.keys(oldCurrentJSDiscountWrapper.values).forEach(field => currentJSDiscountWrapper.values[field].fieldValue = oldCurrentJSDiscountWrapper.values[field].fieldValue || null);
        try {
            this.currentJSDiscountWrapper.loading = true;
            let subsLoaded = currentJSDiscountWrapper.subsLoaded;
            let tempSubsList;
            if (subsLoaded) {
                for (let sub of currentJSDiscountWrapper.subDiscountList) {
                    sub.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = this.oldCurrentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
                    sub.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = this.oldCurrentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r];
                }
                tempSubsList = JSON.parse(JSON.stringify(currentJSDiscountWrapper.subDiscountList));
            }
            if (this.oldCurrentJSDiscountWrapper) {
                currentJSDiscountWrapper = JSON.parse(JSON.stringify(this.oldCurrentJSDiscountWrapper));
            }
            let currentApexDiscountWrapper = JSON.parse(JSON.stringify(this.oldCurrentJSDiscountWrapper));
            if (currentJSDiscountWrapper.subsLoaded) {
                currentApexDiscountWrapper.subDiscountList = JSON.parse(JSON.stringify(tempSubsList));
                this.subDiscountList = currentApexDiscountWrapper.subDiscountList;
                this.assignSubDiscountsToLWC();
            }
            let currentJSWrapper = currentJSDiscountWrapper;
            delete currentApexDiscountWrapper.availableTariff;
            fakeSave({
                DiscountWrapperJSON: JSON.stringify(currentApexDiscountWrapper),
                contractJSON: JSON.stringify(this.currentContract),
                gridSettingsJSON: JSON.stringify(this.conditionPage.gridSettings),
                wContractYearsMapJSON: JSON.stringify(this.conditionPage.wContractYearsMap)
            }).then((result) => {
                let updatedDiscountWrapper = JSON.parse(result);
                this.conditionPage.conditionConfigurations.contractWrapper["discounts"][currentJSWrapper.discount.Id] = updatedDiscountWrapper;
                let rebuiltDiscount = buildDiscountPageInfo(this, updatedDiscountWrapper, updatedDiscountWrapper.discount, currentJSWrapper.Index, false, this.discountPercentScale);
                rebuiltDiscount.hasBeenEdited = true;
                this.wDiscList[currentJSWrapper.Index] = rebuiltDiscount;
                if (currentJSDiscountWrapper != null && (currentJSDiscountWrapper.discount.Id === rebuiltDiscount.discount.Id || currentJSDiscountWrapper.Index === rebuiltDiscount.Index)) {
                    this.currentJSDiscountWrapper = rebuiltDiscount;
                    this.subDiscountList = this.currentJSDiscountWrapper.subDiscountList;
                    this.gridEditMode = false;
                }
            }).catch((error) => {
                console.error(error);
                showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            });
        } catch (exception) {
            console.error(exception);
            showNotification(this, Labels.LBL_Error, exception?.body?.message || exception?.message || exception, ERROR_VARIANT);
        }
    }
    handleFakeSave(event) {
        // this.refreshIndexValues();
        // to check
        this.gridEditModechanges = false;
        // to check
        this.DetailPageOpen = false;
        // to check
        this.gridEditMode = false;
        try {
            if (this.isManualInvoicingPlanning) {
                console.log('manual>>>>>>>>');
                this.handleSaveManualDisc();
            }
            this.handleFakeSaveFunction(event);
        } catch (error) {
            console.error(error);
            showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    handleFakeSaveFunction(event) {
        let currentJSWrapper = this.currentJSDiscountWrapper;
        let currentApexDiscountWrapper = this.conditionPage.conditionConfigurations.contractWrapper.discounts[currentJSWrapper.discount.Id];
        this.currentJSDiscountWrapper.loading = true;
        currentApexDiscountWrapper.wInvoiceMap = currentJSWrapper.wInvoiceMap;
        this.hasOverFlow = true;
        let toSaveManualInvoices = [];
        console.log('this.invoicesArray >>> ' + JSON.stringify(this.invoicesArray));
        if (this.invoicesArray) {
            this.invoicesArray?.forEach(element => {
                toSaveManualInvoices.push({
                    // Id: inv?.Id,
                    Amount: element.Amount ? element.Amount : 0,
                    invoice: {
                        AccDoc: element.invoice.AccDoc.value,
                        PrintDate: element.invoice.PrintDate,
                        Status: element.invoice.Status.value
                    },
                    invoiceBase: this.currentJSDiscountWrapper.Invoice_base__c,
                    get isEnableAmount() {
                        return this.invoice.Status == 'Generated' && this.invoiceBase != 'ActualYTD';
                    }
                })
            });
            currentApexDiscountWrapper.invoiceDetails = toSaveManualInvoices;
        }
        let self = this;
        let processtherest = () => {
            currentApexDiscountWrapper.discount = currentJSWrapper.discount;
            delete currentApexDiscountWrapper.availableTariff;
            fakeSave({
                DiscountWrapperJSON: JSON.stringify(currentApexDiscountWrapper),
                contractJSON: JSON.stringify(self.currentContract),
                gridSettingsJSON: JSON.stringify(self.conditionPage.gridSettings),
                wContractYearsMapJSON: JSON.stringify(self.conditionPage.wContractYearsMap)
            }).then((result) => {
                let updatedDiscountWrapper = JSON.parse(result);
                let errorMessages = [];
                self.conditionPage.conditionConfigurations.contractWrapper.discounts[currentJSWrapper.discount.Id] = updatedDiscountWrapper;
                let rebuiltDiscount = buildDiscountPageInfo(self, updatedDiscountWrapper, updatedDiscountWrapper.discount, currentJSWrapper.Index, false, self.discountPercentScale);
                rebuiltDiscount.hasBeenEdited = currentJSWrapper.hasBeenEdited;
                // rebuiltDiscount.hasBeenEdited = true;
                rebuiltDiscount.subsOpened = currentJSWrapper.subsOpened;
                self.wDiscList[currentJSWrapper.Index] = rebuiltDiscount;
                errorMessages = [...errorMessages, ...(rebuiltDiscount?.errors || [])];
                if (errorMessages?.length) {
                    showNotification(self, Labels.LBL_Error, errorMessages.join('\n'), ERROR_VARIANT);
                }
                updatedDiscountWrapper?.invoiceDetails?.forEach(element => {
                    element.Amount = element.Amount == 0 ? null : element.Amount;
                });
                self.getManualInvoices(updatedDiscountWrapper);
                self.currentJSDiscountWrapperBackup = self.currentJSDiscountWrapper;
                self.currentApexDiscountWrapperBackup = updatedDiscountWrapper;
                if (self.currentJSDiscountWrapper != null && (self.currentJSDiscountWrapper.discount.Id === rebuiltDiscount.discount.Id || self.currentJSDiscountWrapper.Index === rebuiltDiscount.Index)) {
                    self.currentJSDiscountWrapper = rebuiltDiscount;
                    self.subDiscountList = self.currentJSDiscountWrapper.subDiscountList;
                    self.gridEditMode = false;
                    self.hasOverFlow = false;
                }
                self.refreshIndexValues(event, self);
            }).catch((error) => {
                console.error(error);
                showNotification(self, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            });
        }
        if (currentJSWrapper.isConditional) {
            _assignSlabsToDiscount(self.currentJSDiscountWrapper, true, processtherest);
        } else {
            processtherest();
        }
    }
    @track popups = {
        newSlabs: {
            isOpen: false,
            loading: false,
            open(event) {
                this.popups.newSlabs.isOpen = true;
            },
            close(event) {
                this.popups.newSlabs.isOpen = false;
            },
            confirm(event) {
                let self = this;
                try {
                    _assignSlabsToDiscount(self.currentJSDiscountWrapper, true, () => {
                        self.currentJSDiscountWrapper.hasBeenEdited = true;
                        self.popups.newSlabs.isOpen = false;
                        self.currentJSDiscountWrapper.loading = true;
                        self.hasOverFlow = true;
                        let currentJSWrapper = self.currentJSDiscountWrapper;
                        let currentApexDiscountWrapper;
                        if (self.currentJSDiscountWrapper.isNewDiscount) {
                            currentApexDiscountWrapper = self.conditionPage.conditionConfigurations.contractWrapper["newDiscounts"][self.currentJSDiscountWrapper.Index];
                        } else {
                            currentApexDiscountWrapper = self.conditionPage.conditionConfigurations.contractWrapper.discounts[self.currentJSDiscountWrapper.Id];
                        }
                        // fakeSave({
                        //     DiscountWrapperJSON: JSON.stringify(currentApexDiscountWrapper),
                        //     contractJSON: JSON.stringify(self.currentContract),
                        //     gridSettingsJSON: JSON.stringify(self.conditionPage.gridSettings),
                        //     wContractYearsMapJSON: JSON.stringify(self.conditionPage.wContractYearsMap)
                        // }).then((result) => {
                        // let updatedDiscountWrapper = JSON.parse(result);
                        let updatedDiscountWrapper = self.currentJSDiscountWrapper;
                        let rebuiltDiscount = buildDiscountPageInfo(self, updatedDiscountWrapper, updatedDiscountWrapper.discount, currentJSWrapper.Index, false, self.discountPercentScale);
                        rebuiltDiscount.hasBeenEdited = true;
                        if (self.currentJSDiscountWrapper.isNewDiscount) {
                            self.newWDiscList[currentJSWrapper.Index] = rebuiltDiscount;
                            self.conditionPage.conditionConfigurations.contractWrapper["newDiscounts"][currentJSWrapper.Index] = updatedDiscountWrapper;
                        } else {
                            self.wDiscList[currentJSWrapper.Index] = rebuiltDiscount;
                            self.conditionPage.conditionConfigurations.contractWrapper.discounts[currentJSWrapper.Id] = updatedDiscountWrapper;
                        }
                        if (self.currentJSDiscountWrapper != null) {
                            self.currentJSDiscountWrapper.loading = false;
                            self.hasOverFlow = false;
                        }
                        self.currentJSDiscountWrapper = rebuiltDiscount;
                        self.refreshIndexValues(event, self);
                        // }).catch((error) => {
                        //     console.error(error);
                        //     showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                        // });
                    });
                } catch (error) {
                    console.error(error);
                    showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                }
            },
        },
        delete: {
            isOpen: false,
            loading: false,
            isOpenSingle: false,
            isOpenMultiple: false,
            open(event) {
                this.popups.delete.selectedIndex = event.target.dataset.index;
                this.popups.delete.selectedId = event.target.dataset.id;
                this.popups.delete.isOpen = true;
                this.popups.delete.isOpenSingle = true;
            },
            openMultiple(event) {
                this.popups.delete.isOpen = true;
                this.popups.delete.isOpenMultiple = true;
            },
            close(event) {
                this.popups.delete.isOpen = false;
                this.popups.delete.isOpenMultiple = false;
                this.popups.delete.isOpenSingle = false;
            },
            confirmSingle(event) {
                this.popups.delete.isOpen = false;
                this.popups.delete.isOpenSingle = false;
                let selectedIndex = this.popups.delete.selectedIndex;
                let selectedId = this.popups.delete.selectedId;
                try {
                    let self = this;
                    this.popups.delete.loading = true;
                    if (selectedId != null) {
                        this.currentStatusMSG = (this.labels.LBL_Deleting || 'Deleting…');
                        this.saveLoading = true;
                        this.savePopUp = true;
                        let apexWrapper = this.conditionPage.conditionConfigurations.contractWrapper.discounts[selectedId];
                        let jsWrapper = this.wDiscList[selectedIndex];
                        jsWrapper.loading = true;
                        /**
                        * Should be merged
                        * We could merge this between mass and solo clone
                        */
                        DeleteDiscounts({
                            discountsList_JSON: JSON.stringify([apexWrapper.discount])
                        }).then((result) => {
                            if (result != "") {
                                let invalidDiscounts = JSON.parse(result);
                                if (invalidDiscounts != null) {
                                    for (let invalidDiscount of invalidDiscounts) {
                                        let rebuiltJSWrapper = buildDiscountPageInfo(this, invalidDiscount, invalidDiscount.discount, invalidDiscount.JSIndex, false, this.discountPercentScale);
                                        if (invalidDiscount.discount.Id) {
                                            this.conditionPage.conditionConfigurations.contractWrapper.discounts[invalidDiscount.discount.Id] = invalidDiscount;
                                            this.wDiscList[invalidDiscount.JSIndex] = rebuiltJSWrapper;
                                            this.wDiscList[invalidDiscount.JSIndex].loading = false;
                                        } else {
                                            this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[invalidDiscount.discount.JSIndex] = invalidDiscount;
                                            this.newWDiscList[invalidDiscount.JSIndex] = rebuiltJSWrapper;
                                            this.newWDiscList[invalidDiscount.JSIndex].loading = false;
                                        }
                                    }
                                }
                            }
                            this.wDiscList = this.wDiscList.filter((item) => item.Index != selectedIndex);
                            delete this.conditionPage.conditionConfigurations.contractWrapper.discounts[selectedId];
                            this.reorderListAndMap(selectedIndex, false, true);
                            if (this.currentJSDiscountWrapper != null && selectedId == this.currentJSDiscountWrapper.Id) {
                                this.closeDetailPage();
                            }
                            this.popups.delete.loading = false;
                            self.refreshIndexValues(event, self);
                             const isAdvanced = self.currentContract?.[API_NAMES.Contract__c.Supplier_Nego_Scope__r]?.RecordType?.DeveloperName === 'Advanced';
                             if (isAdvanced) {
                               self.synchroAdvancedContracts();
                             }
                             else {
                                self.closeSavePopup();
                             }
                        }).catch((errorApex) => {
                            jsWrapper.loading = false;
                            jsWrapper.errors = [errorApex?.body?.message || errorApex?.message || errorApex];
                            console.error(errorApex);
                            this.popups.delete.loading = false;
                        });
                    } else {
                        if (selectedIndex != null) {
                            this.newWDiscList = this.newWDiscList.filter((item) => item.Index != selectedIndex);
                            delete this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[selectedIndex];
                            this.reorderListAndMap(selectedIndex, true, false);
                            this.numberOfNewDiscount = this.newWDiscList.length;
                            this.popups.delete.loading = false;
                        }
                    }
                } catch (error) {
                    console.error(error);
                    showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                }
            },
            confirmMultiple(event) {
                try {
                    let self = this;
                    this.popups.delete.isOpen = false;
                    this.popups.delete.isOpenMultiple = false;
                    this.newWDiscList = this.newWDiscList.filter(it => !it.isSelected).map((it, index) => { it.Index = index; it.JSIndex = index; it.loading = false; return it; });
                    this.conditionPage.conditionConfigurations.contractWrapper.newDiscounts = {};
                    this.newWDiscList.forEach(it => self.conditionPage.conditionConfigurations.contractWrapper.newDiscounts[it.JSIndex] = it);
                    let discountsWPToDelete = this.wDiscList.filter(it => it.isSelected && it.discount.Id);
                    let discountsToDelete = this.wDiscList.filter(it => it.isSelected && it.discount.Id).map(it => it.discount);
                    let deletedIds = this.wDiscList.filter(it => it.isSelected && it.discount.Id).map(it => it.discount.Id);
                    if (discountsToDelete.length) {
                        this.currentStatusMSG = (this.labels.LBL_Deleting || 'Deleting…');
                        this.saveLoading = true;
                        this.savePopUp = true;
                        discountsWPToDelete.forEach(item => item.loading = true);
                        DeleteDiscounts({
                            discountsList_JSON: JSON.stringify(discountsToDelete)
                        }).then((result) => {
                            let filtered = self.wDiscList.filter(it => !deletedIds.includes(it.discount.Id)).map((it, index) => { it.Index = index; it.JSIndex = index; return it; });
                            self.wDiscList = filtered;
                            self.conditionPage.conditionConfigurations.contractWrapper.discounts = {};
                            filtered.forEach(it => self.conditionPage.conditionConfigurations.contractWrapper.discounts[it.discount.Id] = it);
                            discountsWPToDelete.forEach(item => item.loading = false);
                            self.refreshIndexValues(event, self);
                             if (deletedIds.length) {
                               const isAdvanced = self.currentContract?.[API_NAMES.Contract__c.Supplier_Nego_Scope__r]?.RecordType?.DeveloperName === 'Advanced';                               
                                if (isAdvanced) {
                                 self.synchroAdvancedContracts();
                               }
                               else {
                                    self.closeSavePopup();
                               }
                             }
                             else {
                                self.closeSavePopup();
                             }
                        }).catch((errorApex) => {
                            self.closeSavePopup();
                            discountsWPToDelete.forEach(item => item.loading = false);
                            console.error(errorApex);
                            showNotification(this, Labels.LBL_Error, errorApex?.body?.message || errorApex?.message || errorApex, ERROR_VARIANT);
                        });
                    }
                } catch (error) {
                    console.error(error);
                    showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                }
            }
        }
    }

    blockSubmit(event) {
        if (event.keyCode == 13) {
            event.preventDefault();
            return false;
        }
    }
    invoiceSummaryMap
    get invoiceTabOpen() {
        return this.template.querySelector("lightning-tabset").activeTabValue == "Manual Invoice";
    }
    loadManualInvoice(event) {
        try {
            this.showDispatch = false;
            this.showManualInvoicing = true;
            this.invoiceSummary = [];
            this.tempInvoices = [];
            let currentApexDiscountWrapper = this.conditionPage.conditionConfigurations.contractWrapper.discounts[this.currentJSDiscountWrapper.Id];
            currentApexDiscountWrapper.discount = this.currentJSDiscountWrapper.discount;
            this.currentJSDiscountWrapper.loading = true;
            if (currentApexDiscountWrapper.invoiceDetails == null) {
                initializeInvoice({
                    DiscountWrapperJSON: JSON.stringify(currentApexDiscountWrapper),
                    contractJSON: JSON.stringify(this.currentContract)
                }).then((result) => {
                    let updatedDiscountWrapper = JSON.parse(result);
                    // combobox/picklist Options
                    this.invoiceSummaryMap = JSON.parse(updatedDiscountWrapper.invoiceSummaryMap);
                    updatedDiscountWrapper.manualInvoiceLoaded = true;
                    this.conditionPage.conditionConfigurations.contractWrapper.discounts[this.currentJSDiscountWrapper.discount.Id] = updatedDiscountWrapper;
                    let rebuiltDiscount = buildDiscountPageInfo(this, updatedDiscountWrapper, updatedDiscountWrapper.discount, this.currentJSDiscountWrapper.Index, false, this.discountPercentScale);
                    //
                    this.wDiscList[this.currentJSDiscountWrapper.Index] = rebuiltDiscount;
                    this.currentJSDiscountWrapper = rebuiltDiscount;
                    this.subDiscountList = this.currentJSDiscountWrapper.subDiscountList != null ? this.currentJSDiscountWrapper.subDiscountList : [];
                    this.loading = false;
                    this.currentJSDiscountWrapper.manualInvoiceLoaded = true;
                    this.currentJSDiscountWrapper.loading = false;
                    this.getManualInvoices(updatedDiscountWrapper);
                }).catch((error) => {
                    console.error(error);
                    showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                });
            }
            else {
                this.getManualInvoices(currentApexDiscountWrapper);
                this.currentJSDiscountWrapper.loading = false;
            }
        } catch (exception) {
            console.error(exception);
            showNotification(this, Labels.LBL_Error, exception?.body?.message || exception?.message || exception, ERROR_VARIANT);
        }
    }
    @track invoicesArray;
    getManualInvoices(discountWrapper) {
        let invoiceDetails = discountWrapper.invoiceDetails;
        let tempArr = [];
        let invoiceBase = discountWrapper.discount && discountWrapper.discount[API_NAMES.Contract_Discount__c.Invoice_base__c] ? discountWrapper.discount[API_NAMES.Contract_Discount__c.Invoice_base__c] : '';
        invoiceDetails?.forEach(inv => {
            let invoiceReadOnly = inv?.invoice?.Status == this.generatedStatus.value ? false : true;
            tempArr.push({
                Id: inv?.Id,
                Amount: inv?.Amount == 0 ? null : inv?.Amount,
                invoice: {
                    hasId: inv?.invoice?.invoice?.Id ? true : false,
                    Name: inv?.invoice?.invoice?.Name,
                    AccDoc: this.invDocTypeOptions.find(opt => opt.value == inv?.invoice?.AccDoc),
                    PrintDate: inv?.invoice?.PrintDate,
                    Status: this.invStatusOptions.find(opt => opt.value == inv?.invoice?.Status),
                    link: `/lightning/r/${API_NAMES.Invoice__c.Invoice__c}/${inv?.invoice?.invoice?.Id}/view`
                },
                invoiceIsReadOnly: invoiceReadOnly,
                invoiceBase: invoiceBase,
                isEditable: this.gridEditMode && invoiceReadOnly,
                // isNotGenerated: status != this.generatedStatus && status != this.cancelledStatus
                get isEnableAmount() {
                    return this.invoice.Status.value == 'Generated' && this.invoiceBase != 'ActualYTD' && !this.invoiceIsReadOnly;
                }
            });
        });
        this.invoicesArray = [...tempArr];
    }

    handleManualInvoiceChange(event) {
        let index = event.target.dataset.index;
        let type = event.target.dataset.type;
        let value = event.detail.value;
        if (type == 'date') {
            this.invoicesArray[index].invoice.PrintDate = value;
        }
        if (type == 'amount') {
            this.invoicesArray[index].Amount = value;
        }
        // if (type == 'status') {
        //     this.invoicesArray[index].Status = value;
        // }
        // this.handleSaveManualDisc();
    }
    handleAddNewInvoice(event) {
        try {
            let accdoc = this.currentJSDiscountWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Acc_Document_Type__c]
            this.invoicesArray.push({
                invoice: {
                    AccDoc: this.invDocTypeOptions.find(opt => opt.value == accdoc),
                    PrintDate: '',
                    Status: this.generatedStatus,
                },
                Amount: null,
                invoiceIsReadOnly: false,
                invoiceBase: this.currentJSDiscountWrapper.Invoice_base__c,
                get isEnableAmount() {
                    return this.invoice.Status.value == 'Generated' && this.invoiceBase != 'ActualYTD' && !this.invoiceIsReadOnly;
                }
            })
        } catch (error) {
            console.log('error' + error)
        }
    }
    handleSaveManualDisc(event) {
        this.invoicesArray = this.invoicesArray.filter(inv => inv.invoice.PrintDate);
        this.currentJSDiscountWrapper.invoiceDetails = this.invoicesArray;
    }
    handleShowGenerateInvoicesPopup() {
        this.showGeneratePopup = true;
    }
    handleCancelGeneratePopover() {
        this.showGeneratePopup = false;
    }
    handleGenerateInvoices(event) {
        this.showGeneratePopup = false;
        this.currentJSDiscountWrapper.loading = true;
        this.handleGenerateInvoicesLines();
    }
    handleCancelManualDisc(event) {
        this.loadManualInvoice();
    }

    handleGenerateInvoicesLines() {
        generateInvoicesLines({
            contract_Serialized: JSON.stringify(this.currentContract),
            condition_Serialized: JSON.stringify(this.currentJSDiscountWrapper.discount)
        })
            .then((result) => {
                let res = JSON.parse(result);
                res.invoiceDetails.forEach(el => {
                    el.Amount = el.Amount == 0 ? null : el.Amount;
                });
                res.invoiceDetails.sort((a, b) => a.invoice.Sequence - b.invoice.Sequence);
                this.getManualInvoices(res)
                this.currentJSDiscountWrapper.loading = false;
            }).catch((error) => {
                this.error = error;
                showNotification(this, Labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                this.currentJSDiscountWrapper.loading = false;
            });
    }
}