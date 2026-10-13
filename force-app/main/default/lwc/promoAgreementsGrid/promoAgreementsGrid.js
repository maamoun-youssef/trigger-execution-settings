/**
* @author ULiT
* @date 07-05-2025
* @description PromoAgreementsGrid
*******************************************************************************************************************************************
*/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { showNotification, checkCompletedBatches } from 'c/appHelper';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

//APEX
import getData from "@salesforce/apex/PromoAgreementsGridController.getData";
import initData from "@salesforce/apex/PromoAgreementsGridController.initData";
import saveRecords from "@salesforce/apex/PromoAgreementsGridController.save";
import generateCommercialInvoice from "@salesforce/apex/PromoAgreementsGridController.generateCommercialInvoice";
//STATIC RESSOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { labels, API_NAMES, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES } from './properties.js';

import SUPPLIER_OBJECT from '@salesforce/schema/Supplier__c';
const PREFIX__ = SUPPLIER_OBJECT.objectApiName.replace(/Supplier__c/gi, '');
const PREFIX = PREFIX__.replace(/__/gi, '');
export default class PromoAgreementsGrid extends NavigationMixin(LightningElement) {
    //API
    @api templateName;
    @api recordId;
    @api promoAgreementTypes;
    @api promoStatementTypes;
    @track hasSupplierId = false;
    @track gridSettings = {};
    @track prefix = '';
    //labels
    @track labels = { ...labels }
    @track API_NAMES = { ...API_NAMES }
    // FILTERS Variables
    @track showAdvancedSearch = false;
    @track detailApiName = API_NAMES.CommercialPlan__c.objectApiName;
    @track firstThStyle = '';
    @track filters = {
        promoAgreementTypes: '',
        promoStatementTypes: '',
        get selectedSuppliersSerialized() {
            return JSON.stringify(this.selectedSuppliers);
        },
        selectedSuppliers: [],
        supplierIds: [],
        get selectedNegoScopesSerialized() {
            return JSON.stringify(this.selectedNegoScopes);
        },
        selectedNegoScopes: [],
        negoScopeIds: [],
        get selectedCommercialPlansSerialized() {
            return JSON.stringify(this.selectedCommercialPlans);
        },
        selectedCommercialPlans: [],
        commercialPlanIds: [],
        year: '',
        status: '',
        dynamic: '',
        isInvoiceable: false,
    }
    @track isInvoiceable = false;
    //TRACK variables
    @track promoAgreementTypeOptions = [];
    @track promoStatementTypeOptions = [];
    @track CPStatusOptions = [];
    @track displayedFields = [];
    @track sortField = '';
    @track sortDirection = 'DESC';
    @track isSortASC = false;
    @track records = [];
    @track noOfRecords = 0;
    @track flows = {
        Screen_PromoAgreementCreation: false,
    }
    @track popup = {
        visibility: false,
        title: '',
        body: '',
        subBody: '',
        submitBtnClass: '',
        submitBtn: '',
        cancelBtn: '',
        get footerStyle() {
            return this.cancelBtn ? 'padding-right: 0px;' : '';
        }
    }

    //Variables
    isLoading = true;
    isFilterOpen = false;
    @track readOnlyView = true;
    @track CPToUpdateMap = {};
    @track hasChanges = false;
    sortFieldApi = '';
    isSearchingStage = true;
    hasSearched = false;
    title = '';
    // PAGINATION Variables
    @track pageSize = '25';
    pageNumber = 1;
    pageCount = 0;
    // Custom Lookup Variables
    stringifiedSelectedCPStatus = '';
    stringifiedSelectedYears = '';
    stringifiedSelectedTypes = '';
    stringifiedSelectedPromoStatementTypes = '';
    fieldsToFilterMap = {};
    @track fieldsToFilter = [];
    API_Screen_PromoAgreementCreation;
    Screen_PromoAgreementCreation_Variables;
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    }
    advancedFieldsFilter = [
        API_NAMES.CommercialPlan__c.PromoAgreementType__c,
        API_NAMES.CommercialPlan__c.PromoStatementType__c,
        API_NAMES.CommercialPlan__c.Supplier__c,
        API_NAMES.CommercialPlan__c.NegoScope__c,
        API_NAMES.CommercialPlan__c.Year__c,
        API_NAMES.CommercialPlan__c.Status__c,
    ];
    @track wireIsDone = {
        ContractDiscountInfo: false,
        CommercialPlanInfo: false,
        CurrentPageReference: false,
    }
    @wire(getObjectInfo, { objectApiName: API_NAMES.CommercialPlan__c.objectApiName }) objectInfoCommercialPlan({ error, data }) {
        if (data) {
            this.labels.CommercialPlanLabel = data.label;
            this.labels.CommercialPlan__c.PromoAgreementType__c = data.fields[API_NAMES.CommercialPlan__c.PromoAgreementType__c].label;
            this.labels.CommercialPlan__c.PromoStatementType__c = data.fields[API_NAMES.CommercialPlan__c.PromoStatementType__c].label;
            this.labels.CommercialPlan__c.Status__c = data.fields[API_NAMES.CommercialPlan__c.Status__c].label;
            this.labels.CommercialPlan__c.Supplier__c = data.fields[API_NAMES.CommercialPlan__c.Supplier__c].label;
            this.labels.CommercialPlan__c.NegoScope__c = data.fields[API_NAMES.CommercialPlan__c.NegoScope__c].label;
            this.labels.CommercialPlan__c.Year__c = data.fields[API_NAMES.CommercialPlan__c.Year__c].label;
            this.labels.CommercialPlan__c.Code__c = data.fields[API_NAMES.CommercialPlan__c.Code__c].label;
            this.wireIsDone.CommercialPlanInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: API_NAMES.Contract_Discount__c.objectApiName }) objectInfoContractDiscount({ error, data }) {
        if (data) {
            this.wireIsDone.ContractDiscountInfo = true;
            this.labels.Contract_Discount__c.t_IsInvoiceable__c = data.fields[API_NAMES.Contract_Discount__c.t_IsInvoiceable__c].label;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__promoAgreementTypes')) {
            this.filters.promoAgreementTypes = this.currentPageReference.state.c__promoAgreementTypes;
            this.stringifiedSelectedTypes = JSON.stringify(this.filters.promoAgreementTypes.replaceAll('\'', '').split(','));
        }
        if (currentPageReference.state.hasOwnProperty('c__promoStatementTypes')) {
            this.filters.promoStatementTypes = this.currentPageReference.state.c__promoStatementTypes;
            this.stringifiedSelectedPromoStatementTypes = JSON.stringify(this.filters.promoStatementTypes.replaceAll('\'', '').split(','));
        }
        if (currentPageReference.state.hasOwnProperty('c__selectedSuppliers')) {
            this.filters.selectedSuppliers = JSON.parse(this.currentPageReference.state.c__selectedSuppliers);
        }
        if (currentPageReference.state.hasOwnProperty('c__selectedNegoScopes')) {
            this.filters.selectedNegoScopes = JSON.parse(this.currentPageReference.state.c__selectedNegoScopes);
        }
        if (currentPageReference.state.hasOwnProperty('c__selectedCommercialPlans')) {
            this.filters.selectedCommercialPlans = JSON.parse(this.currentPageReference.state.c__selectedCommercialPlans);
        }
        if (currentPageReference.state.hasOwnProperty('c__year')) {
            this.filters.year = this.currentPageReference.state.c__year;
            this.stringifiedSelectedYears = JSON.stringify(this.filters.year.split(','));
        }
        if (currentPageReference.state.hasOwnProperty('c__status')) {
            this.filters.status = this.currentPageReference.state.c__status;
            this.stringifiedSelectedCPStatus = JSON.stringify(this.filters.status.replaceAll('\'', '').split(','));
        }
        if (currentPageReference.state.hasOwnProperty('c__hasSearched')) {
            this.hasSearched = this.currentPageReference.state.c__hasSearched;
            this.isSearchingStage = !this.hasSearched;
        }
        if (currentPageReference.state.hasOwnProperty('c__templateName')) {
            this.templateName = this.currentPageReference.state.c__templateName;
        }
        this.wireIsDone.CurrentPageReference = true;
        this.checkIfWireIsDone();
    }
    checkIfWireIsDone() {
        if (Object.values(this.wireIsDone).every(it => it)) {
            this.initData();
        }
    }
    // GETTERS
    get pageRecordCount() {
        if (this.noOfRecords == 0) {
            return '0';
        }
        let pageSize = parseInt(this.pageSize)
        let firstPart = (this.pageNumber * pageSize) + 1 - pageSize;
        let string = '' + firstPart;
        string += '-'
        if ((this.pageNumber * pageSize) > this.noOfRecords) {
            string += this.noOfRecords;
        } else {
            string += this.pageNumber * pageSize;
        }
        return string;
    }

    get pageSizeOptions() {
        return [
            { label: '5', value: '5' },
            { label: '10', value: '10' },
            { label: '25', value: '25' },
            { label: '50', value: '50' },
            { label: '75', value: '75' },
            { label: '100', value: '100' }];
    }

    get nextDisabled() {
        return ((this.pageNumber >= this.pageCount || this.tableLoading));
    }

    get previousDisabled() {
        return ((this.pageNumber <= 1 || this.tableLoading));
    }

    get lastDisabled() {
        return ((this.pageNumber == this.pageCount || this.tableLoading || this.pageCount == 0));
    }

    get firstDisabled() {
        return ((this.pageNumber == 1 || this.tableLoading));
    }

    get supplierFilterToken() {
        let conditions = [];
        conditions.push('RecordType.DeveloperName = \'Supplier\'');
        return conditions;
    }

    get negoscopeFilterToken() {
        let conditions = [];
        conditions.push('RecordType.DeveloperName <> \'SubNS\'');
        if (this.filters.supplierIds && this.filters.supplierIds.length > 0) {
            conditions.push(this.API_NAMES.NegoScope__c.Supplier__c + '  IN (\'' + this.filters.supplierIds.join('\',\'') + '\')');
        }
        return conditions;
    }

    get commercilaEventFilterToken() {
        let conditions = [];
        conditions.push('RecordType.DeveloperName  = \'CommercialEvent\'');
        if (this.filters.year && this.filters.year.length > 0) {
            conditions.push(this.API_NAMES.CommercialPlan__c.Year__c + '  IN (' + this.filters.year + ')');
        }
        return conditions;
    }

    get yearOptions() {
        let currentYear = new Date().getFullYear();
        return JSON.stringify([
            { label: '' + (currentYear + 2), value: '' + (currentYear + 2) },
            { label: '' + (currentYear + 1), value: '' + (currentYear + 1) },
            { label: '' + (currentYear), value: '' + currentYear },
            { label: '' + (currentYear - 1), value: '' + (currentYear - 1) },
            { label: '' + (currentYear) - 2, value: '' + (currentYear - 2) }
        ])
    };

    get showNegoScopeLookup() {
        return this.filters.selectedSuppliers.length > 0;
    }

    get showCommercialEventLookup() {
        return this.filters.year.length > 0;
    }

    handleSearchVisibility(event) {
        this.showAdvancedSearch = !this.showAdvancedSearch;
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });
        window.addEventListener('resize', this.changeHeight);
    }

    renderedCallback() {
        this.setnumberOfFixedColumns();
        this.changeHeight();
    }

    @track customLookups = {
        Supplier__c: {
            event: 'selectsupplieraction',
            fieldName: 'Name',
            searchFields: ['Name', this.API_NAMES.Supplier__c.Code__c],
            handler: (event) => {
                try {
                    this.filters.selectedSuppliers = [];
                    this.filters.selectedNegoScopes = [];
                    this.filters.supplierIds = [];
                    this.filters.negoScopeIds = [];
                    if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
                        event.detail.selRecords.forEach(selectedSupp => {
                            this.filters.supplierIds.push(selectedSupp.recId);
                            this.filters.selectedSuppliers.push(selectedSupp);
                        })
                    }
                    //this.loadData();
                } catch (error) {
                    console.log('%c' + error.message ? error.message : error.body?.message);
                    showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
                }
            }
        },
        NegoScope__c: {
            event: 'selectnegoscopeaction',
            fieldName: 'Name',
            searchFields: ['Name', this.API_NAMES.NegoScope__c.CodeLong__c],
            handler: (event) => {
                try {
                    this.filters.selectedNegoScopes = [];
                    this.filters.negoScopeIds = [];
                    if (event.detail && event.detail.selRecords.length > 0) {
                        event.detail.selRecords.forEach(selectedNs => {
                            this.filters.negoScopeIds.push(selectedNs.recId);
                            this.filters.selectedNegoScopes.push(selectedNs);
                        })
                    }
                } catch (error) {
                    console.log('%c' + error.message ? error.message : error.body?.message);
                    showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
                }
            }
        },
        CommercialPlan__c: {
            event: 'selectcommercialplanaction',
            fieldName: 'Name',
            searchFields: ['Name', this.API_NAMES.CommercialPlan__c.Code__c],
            handler: (event) => {
                try {
                    this.filters.selectedCommercialPlans = [];
                    this.filters.commercialPlanIds = [];
                    if (event.detail && event.detail.selRecords.length > 0) {
                        event.detail.selRecords.forEach(selectedCP => {
                            this.filters.commercialPlanIds.push(selectedCP.recId);
                            this.filters.selectedCommercialPlans.push(selectedCP);
                        })
                    }
                } catch (error) {
                    console.log('%c' + error.message ? error.message : error.body?.message);
                    showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
                }
            }
        },
    }

    handleChangeMultiPicklistValues(event) {
        let filterName = event.target.dataset.filterName;
        let values = [];
        this.filters[filterName] = '';
        event?.detail?.selOptions?.forEach(item => {
            if (item.hasOwnProperty('value')) {
                values.push(item.value);
            } else {
                values.push(item);
            }
        })
        if (values && values.length > 0) {
            if (filterName == 'year') {
                this.filters[filterName] = values.join(',');
            } else {
                this.filters[filterName] = '\'' + values.join('\',\'') + '\'';
            }
        }
        if (filterName == 'status') {
            this.stringifiedSelectedCPStatus = JSON.stringify(values);
        } else if (filterName == 'year') {
            this.stringifiedSelectedYears = JSON.stringify(values);
        } else if (filterName == 'promoAgreementTypes') {
            this.stringifiedSelectedTypes = JSON.stringify(values);
        } else if (filterName == 'promoStatementTypes') {
            this.stringifiedSelectedPromoStatementTypes = JSON.stringify(values);
        }
        if (filterName == 'isInvoiceable') {
            this.isInvoiceable = event.target.checked
            this.filters[filterName] = this.isInvoiceable;
        }
    }

    initData() {
        console.log('this.recordId >>> ' + this.recordId);
        this.selectedRows = [];
        let promoAgreementTypeOptions = [];
        let promoStatementTypeOptions = [];
        initData({ recordId: this.recordId, gridSettingsName: this.templateName }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result);
                this.gridSettings = parsedResult.gridSettingsManager;
                if (this.gridSettings) {
                    this.templateName = this.gridSettings.gridLayout.DeveloperName;
                }
                this.prefix = parsedResult.prefix;
                this.API_Screen_PromoAgreementCreation = this.prefix + 'SCREEN_Commercial_Plan_Promo_Agreement_Creation';
                this.Screen_PromoAgreementCreation_Variables = [];
                // Fill Options of Promo Agreement Type
                Object.keys(parsedResult.promoAgreementTypePicklistValues).forEach((key) => {
                    if (key != 'CommercialEvent') {
                        promoAgreementTypeOptions.push({ label: parsedResult.promoAgreementTypePicklistValues[key], value: key });
                    }
                });
                this.promoAgreementTypeOptions = JSON.stringify(promoAgreementTypeOptions);
                if (!this.currentPageReference || !this.currentPageReference.state.hasOwnProperty('c__promoAgreementTypes')) {
                    if (this.promoAgreementTypes) {
                        this.filters.promoAgreementTypes = '\'' + this.promoAgreementTypes.replaceAll(',', '\',\'') + '\'';
                        this.stringifiedSelectedTypes = JSON.stringify(this.promoAgreementTypes.split(','));
                    } else {
                        let values = [];
                        for (let item of promoAgreementTypeOptions) {
                            values.push(item.value);
                        }
                        this.filters.promoAgreementTypes = '\'' + values.join('\',\'') + '\'';
                        this.stringifiedSelectedTypes = JSON.stringify(values);
                    }
                }
                // Fill Options of Promo Statement Type
                Object.keys(parsedResult.promoStatementTypePicklistValues).forEach((key) => {
                    if (key != 'CommercialEvent') {
                        promoStatementTypeOptions.push({ label: parsedResult.promoStatementTypePicklistValues[key], value: key });
                    }
                });
                this.promoStatementTypeOptions = JSON.stringify(promoStatementTypeOptions);
                if (!this.currentPageReference || !this.currentPageReference.state.hasOwnProperty('c__promoStatementTypes')) {
                    if (this.promoStatementTypes) {
                        this.filters.promoStatementTypes = '\'' + this.promoStatementTypes.replaceAll(',', '\',\'') + '\'';
                        this.stringifiedSelectedPromoStatementTypes = JSON.stringify(this.promoStatementTypes.split(','));
                    } else {
                        let values = [];
                        for (let item of promoStatementTypeOptions) {
                            values.push(item.value);
                        }
                        this.filters.promoStatementTypes = '\'' + values.join('\',\'') + '\'';
                        this.stringifiedSelectedPromoStatementTypes = JSON.stringify(values);
                    }
                }
                var uiCombobox = [];
                if (parsedResult.statusPicklistValues) {
                    parsedResult.statusPicklistValues.forEach((item) => {
                        uiCombobox.push({ label: item.label, value: item.value })
                    });
                }
                this.CPStatusOptions = JSON.stringify(uiCombobox);
                this.populateFiltersMap(this.gridSettings.FILTERS);
                if (this.gridSettings.Default_Page_Size) {
                    this.pageSize = this.gridSettings.Default_Page_Size + '';
                }
                this.buildDisplayedFields();
                this.hasSupplierId = !!(this.recordId && parsedResult.supplier != {});
                if (this.hasSupplierId) {
                    this.filters.selectedSuppliers.push({ 'recId': this.recordId, 'recName': parsedResult.supplier ? parsedResult.supplier.Name : '' });
                    this.handleSearch();
                    return;
                }
                if (this.hasSearched) {
                    this.loadData();
                } else {
                    this.isLoading = false;
                }
            }
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }

    handleSearch() {
        this.isLoading = true;
        this.hasSearched = true;
        console.log('this.hasSupplierId >>> ' + this.hasSupplierId)
        console.log('this.prefix >>> ' + this.prefix)
        console.log(typeof this.hasSupplierId)
        if (this.hasSupplierId == true) {
            this.isSearchingStage = false;
            this.loadData();
        } else {
            this.updateUrlWithFilters();
        }
    }
    updateUrlWithFilters() {
        const state = {
            c__templateName: this.templateName ? this.templateName : '',
            c__promoAgreementTypes: this.filters.promoAgreementTypes || '',
            c__promoStatementTypes: this.filters.promoStatementTypes || '',
            c__year: this.filters.year,
            c__status: this.filters.status,
            c__selectedSuppliers: JSON.stringify(this.filters.selectedSuppliers) || '[]',
            c__selectedNegoScopes: JSON.stringify(this.filters.selectedNegoScopes) || '[]',
            c__selectedCommercialPlans: JSON.stringify(this.filters.selectedCommercialPlans) || '[]',
            c__hasSearched: this.hasSearched
        };

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: this.prefix + 'PromoAgreementsGrid'
            },
            state
        }, false);
    }

    handleCancel() {
        this.isSearchingStage = true;
        this.hasSearched = false;
    }

    handleCpInvPoppup() {
        const commercialPlanIds = this.records.filter(item => item.checked).map(item => item.Id);
        if (commercialPlanIds.length === 0) {
            showNotification(this, this.labels.MSG_Error, this.labels.LBL_commercialPlan_SelectError, 'error')
            return;
        }
        this.popup = {
            title: this.labels.LBL_CPGeneratePopupTitle,
            body: this.labels.LBL_CPGeneratesPopupSMsg,
            submitBtn: this.labels.LBL_Generate,
            submitBtnClass: 'slds-button slds-button_brand',
            cancelBtn: this.labels.LBL_Back,
        }
        this.popupNotification().then(submmited => {
            if (submmited) {
                this.popup = {
                    title: this.labels.LBL_CPGeneratePopupTitle,
                    body: this.labels.LBL_CPGeneratesPopupEMsg,
                    cancelBtn: this.labels.LBL_OK,
                    submitBtnClass: 'slds-hide',
                }
                this.popupNotification().then(submmited => {
                    this.popup.visibility = false;
                    this.isLoading = true;
                    generateCommercialInvoice({
                        commercialPlanIds: commercialPlanIds
                    }).then(batchId => {
                        if (batchId != null) {
                            checkCompletedBatches(this, batchId, false).then(result => {
                                this.isLoading = false;
                                window.location.reload();
                            }).catch(error => {
                                console.error(error);
                            });
                        } else {
                            this.isLoading = false;
                            showNotification(this, this.labels.MSG_Error, '', 'error')
                            this.popup.visibility = false;
                        }
                    }).catch(err => {
                        this.isLoading = false;
                        showNotification(this, this.labels.MSG_Error, '', 'error')
                        this.popup.visibility = false;
                    })
                })
            } else {
                this.popup.visibility = false;
                this.isLoading = false;
            }
        })
    }

    //LOAD
    loadData() {
        this.selectAll = false;
        this.selectedRows = [];
        this.records = [];
        try {
            this.isLoading = true;
            let filteredFields = this.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
            let filterData = {
                promoAgreementTypes: this.filters.promoAgreementTypes,
                promoStatementTypes: this.filters.promoStatementTypes,
                supplierIds: this.filters.selectedSuppliers.map(item => item.recId),
                negoScopeIds: this.filters.selectedNegoScopes.map(item => item.recId),
                commercialPlanIds: this.filters.selectedCommercialPlans.map(item => item.recId),
                year: this.filters.year,
                status: this.filters.status,
                dynamic: this.filters.dynamic,
                isInvoiceable: this.filters.isInvoiceable,
            }
            getData({
                fields: JSON.stringify(this.gridSettings.ALL_FIELDS),
                filters: JSON.stringify(filterData),
                filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
                pageNumber: this.pageNumber,
                pageSize: this.pageSize,
                sortField: this.sortField,
            }).then((result) => {
                let parsedresult = JSON.parse(result);
                this.noOfRecords = parsedresult.numberOfRecords;
                this.pageCount = Math.ceil(parsedresult.numberOfRecords / this.pageSize);
                if (result) {
                    this.records = this.buildData(parsedresult.records);
                }
                this.isSearchingStage = false;
                this.isLoading = false;
                setTimeout(() => {
                    this.changeHeight();
                }, 200)
            }).catch((error) => {
                this.isLoading = false;
                console.log('%c' + error.message, 'color : red');
                console.error(error.message)
                showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            });
        } catch (error) {
            this.isLoading = false;
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    buildDisplayedFields() {
        this.displayedFields = [];
        for (let field of this.gridSettings.GRID_FIELDS) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isHTMLFormatted: field.isHTMLFormatted,
                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                isName: field.fieldName.toLowerCase() == 'name',
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                link: '',
                scale: field.scale,
                step: '',
                isInputField: field.isInputField,
                style: field.style,
                headerStyle: (field.stringHeaderStyle || '') + (field.widthStyle || ''),
                pickListValues: field.pickListValues,
                isSortable: field.isSortable,
                isFilterable: field.isFilterable,
                isEncrypted: field.isEncrypted,
                filterValue: '',
                sortedField: false,
                picklistColorsMap: field.picklistColorsMap || {},
            }
            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
            if (fieldWrapper.isNumberField) {
                fieldWrapper.style += 'text-align:right;';
            }
            if (fieldWrapper.scale) {
                let step = '.';
                for (let i = 0; i < fieldWrapper.scale; i++) {
                    if (i == fieldWrapper.scale - 1) {
                        step += '1';
                        break;
                    }
                    step += '0';
                }
                fieldWrapper.step = step;
            }
            this.displayedFields.push(fieldWrapper);
        }
        this.firstThStyle = (this.gridSettings.GRID_FIELDS[0].stringHeaderStyle ? this.gridSettings.GRID_FIELDS[0].stringHeaderStyle : '') + 'text-align: center;';
    }

    handleChangeSortField(event) {
        this.isLoading = true;
        let fieldName = event.target.dataset.field;
        if (this.sortFieldApi.startsWith(fieldName)) {
            if (this.sortDirection == 'ASC') {
                this.sortDirection = 'DESC';
            } else {
                this.sortDirection = 'ASC';
            }
        } else {
            this.sortDirection = 'ASC';
        }
        this.isSortASC = this.sortDirection == 'ASC'
        this.sortField = fieldName + ' ' + this.sortDirection + ' NULLS ' + (this.isSortASC ? 'FIRST' : 'LAST');
        this.sortFieldApi = fieldName;
        this.displayedFields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.sortedField = true;
                if (field.isReference && field.fieldName.endsWith('__c')) {
                    this.sortField = fieldName.replace('__c', '__r.Name') + ' ' + this.sortDirection + ' NULLS ' + (this.isSortASC ? 'FIRST' : 'LAST');
                }
            } else {
                field.sortedField = false;
            }
        })
        this.loadData();
    }

    buildData(data) {
        let records = [];
        for (let item of data) {
            let commercialPlanWrapper = {
                Name: item.Name,
                Id: item.Id,
                link: '/' + item.Id,
                values: [],
                checked: this.selectedRows != [] ? this.selectedRows.includes(item?.Id) : false,
                hasInvoiceDetails: item[PREFIX__ + 'INVDCommercialPlan__r'] ? true : false,
                firstTdStyle: '',
                lastTdStyle: '',
                rowColor: '',
            }
            let fieldIndex = 0;
            for (let field of this.displayedFields) {
                let fieldWrapper = {
                    Id: item.Id,
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: '',
                    fieldOutputValue: '',
                    isNumberField: field.isNumberField,
                    isReference: field.isReference,
                    isName: field.isName,
                    isDate: field.isDate,
                    isDateTime: field.isDateTime,
                    isPicklist: field.isPicklist,
                    isBoolean: field.isBoolean,
                    isTextarea: field.isTextarea,
                    isText: field.isText,
                    isHTMLFormatted: field.isHTMLFormatted,
                    link: field.isName ? '/' + item.Id : '',
                    scale: field.scale,
                    step: field.step,
                    isInputField: field.isInputField,
                    pickListValues: [],
                    style: field.style ? field.style : '',
                    class: field.isInputField ? '' : 'slds-truncate'
                }
                let values = field.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let val = index == 0 ? item : fieldWrapper.fieldValue;
                    console.log('val >>> ' + JSON.stringify(val))
                    if (val) {
                        if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                            fieldWrapper.fieldOutputValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                            fieldWrapper.fieldValue = val[values[index]];
                            fieldWrapper.link = '/' + val[values[index]];
                        } else {
                            fieldWrapper.fieldValue = val[values[index]];
                        }
                    }
                }
                if (fieldWrapper.isPicklist) {
                    for (let pickVal of field.pickListValues) {
                        fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                        if (fieldWrapper.fieldValue == pickVal.value) {
                            fieldWrapper.fieldOutputValue = pickVal.label;
                        }
                    }
                    fieldWrapper.pickListValues.unshift({
                        label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                    })
                    if (commercialPlanWrapper.rowColor == '') {
                        commercialPlanWrapper.rowColor = field.picklistColorsMap && fieldWrapper.fieldValue !== '' && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue) && field.picklistColorsMap[fieldWrapper.fieldValue] !== '' ? field.picklistColorsMap[fieldWrapper.fieldValue] : '';
                    }
                }
                if (fieldIndex == 0) {
                    fieldWrapper.first = true;
                }
                fieldIndex++;
                commercialPlanWrapper.values.push(fieldWrapper);
            }
            this.applyRowStyle(commercialPlanWrapper);
            records.push(commercialPlanWrapper);
        }
        console.log('records >>>> ' + JSON.stringify(records))
        return records;
    }

    applyRowStyle(commercialPlanWrapper) {
        if (commercialPlanWrapper.values && commercialPlanWrapper.values.length > 0) {
            for (const fieldWrapper of commercialPlanWrapper.values) {
                if (commercialPlanWrapper.rowColor !== '') {
                    fieldWrapper.style = this.setStyleProp(fieldWrapper.style, 'background-color', commercialPlanWrapper.rowColor)
                }
            }
            commercialPlanWrapper.firstTdStyle = this.getStyleProp(commercialPlanWrapper.values[0].style, 'background-color');
            commercialPlanWrapper.lastTdStyle = this.getStyleProp(commercialPlanWrapper.values[commercialPlanWrapper.values.length - 1].style, 'background-color');
        }
    }

    setStyleProp(style, prop, value) {
        const regex = new RegExp(`${prop}\\s*:\\s*[^;]+`, 'i');
        if (regex.test(style)) {
            return style.replace(regex, `${prop}: ${value}`);
        }
        return style + `${prop}: ${value};`;
    }

    getStyleProp(style, prop) {
        const regex = new RegExp(`${prop}\\s*:\\s*([^;]+)`, 'i');
        const match = style.match(regex);
        return match ? (prop + ':' + match[1].trim() + ';') : null;
    }

    @track selectAll = false;
    @track selectedRows = [];
    handleSelectAll() {
        this.selectAll = !this.selectAll;
        this.records.forEach(item => {
            item.checked = this.selectAll;
            if (!item.checked) {
                this.selectedRows = [];
            } else {
                !this.selectedRows.includes(item.Id) ? this.selectedRows.push(item.Id) : this.selectedRows;
            }
        });
    }

    //get selected lines
    setSelectedCP(event) {
        let id = event.target.dataset.id;
        let index = event.target.dataset.index;
        this.records[index].checked = event.target.checked;
        if (event.target.checked == false) {
            this.selectedRows = this.selectedRows.filter(item => item != id);
        } else {
            this.selectedRows.push(id);
        }
    }

    populateFiltersMap(fields) {
        this.fieldsToFilterMap = {};
        for (let field of fields) {
            if (this.advancedFieldsFilter.includes(field.fieldName)) continue;
            let fieldToFilter = {};
            if (SUPPORTED_TYPES.includes(field.stringFieldType)
                || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
                || field.hasOwnProperty('userFilterable')) {
                fieldToFilter.fieldLabel = field.fieldLabel;
                fieldToFilter.fieldName = field.fieldName;
                fieldToFilter.stringFieldType = field.stringFieldType;
                fieldToFilter.isMultiLevel = field.hasOwnProperty('isMultiLevel') ? field.isMultiLevel : false;
                if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
                if (field.stringFieldType == 'ID') {
                    if (field.values) fieldToFilter.displayVal = field.values.join(';');
                    fieldToFilter.isId = true;
                }
                fieldToFilter.isText = field.stringFieldType == 'STRING';
                fieldToFilter.isReference = field.stringFieldType == 'REFERENCE';
                fieldToFilter.isCheckboxGroup = field.stringFieldType == 'BOOLEAN' || ((field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'RECORDTYPE') && (field.pickListValues && field.pickListValues.length > 1));
                if (fieldToFilter.isCheckboxGroup) {
                    fieldToFilter.options = field.stringFieldType == 'BOOLEAN' ? [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }] : field.pickListValues;
                }
                fieldToFilter.isNumber = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
                if (fieldToFilter.isNumber) {
                    if (field.stringFieldType == 'DOUBLE') {
                        fieldToFilter.formatter = 'decimal';
                    }
                    if (field.stringFieldType == 'CURRENCY') {
                        fieldToFilter.formatter = 'currency';
                    }
                    if (field.stringFieldType == 'PERCENT') {
                        fieldToFilter.formatter = 'percent-fixed';
                    }
                    let step = '.';
                    for (let i = 0; i < field.scale; i++) {
                        if (i == field.scale - 1) {
                            step += '1';
                            break;
                        }
                        step += '0';
                    }
                    fieldToFilter.step = step;
                }
                fieldToFilter.isDate = field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME';
                fieldToFilter.isTime = field.stringFieldType == 'TIME';
                if (field.hasOwnProperty('isEncrypted')) {
                    fieldToFilter.isEncrypted = field.isEncrypted;
                }
                if (SUPPORTED_VALUES_TYPES.includes(field.stringFieldType)
                    || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
                    if (field.values) {
                        if (fieldToFilter.isText || fieldToFilter.isReference) {
                            fieldToFilter.value = (field.values[0]) ? field.values[0] : '';
                            fieldToFilter.values = field.values;
                        } else {
                            fieldToFilter.values = field.values;
                        }
                    } else {
                        fieldToFilter.values = '';
                    }
                }
                if (SUPPORTED_RANGE_TYPES.includes(field.stringFieldType)) {
                    fieldToFilter.value1 = (field.value1) ? field.value1 : '';
                    fieldToFilter.value2 = (field.value2) ? field.value2 : '';
                }
                if (Object.keys(fieldToFilter).length !== 0) {
                    this.fieldsToFilterMap[fieldToFilter.fieldName] = fieldToFilter;
                }
            }
        }
        this.populateLists(this.fieldsToFilterMap);
    }

    populateLists(filtersMap) {
        this.fieldsToFilter = [];
        if (Object.keys(filtersMap).length !== 0) {
            this.fieldsToFilter = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //get record type field
            var recordTypeField = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType == 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //add record type fields always to the top
            if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
            this.multilevelFields = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel == true)
                .map(fieldName => { return filtersMap[fieldName]; });
            this.fieldsToFilter.forEach(item => {
                if (item.isText || item.isReference) {
                    item.value = item.values.length != 0 ? item.values[0] : '';
                }
            })
        }
    }
    setSelectedValues(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var modeValue = event.target.dataset.mode;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field.values = [];
            if (modeValue == 'multiple') {
                let withoutSpace = value.replaceAll(' ', '');
                field.displayVal = withoutSpace;
                let idList = withoutSpace.split(';');
                for (let id of idList) {
                    if (id !== '') {
                        field.values.push(id);
                    }
                }
            } else {
                field.values = (Array.isArray(value)) ? value : [value];
            }
            this.fieldsToFilterMap[fieldName] = field;
            this.populateLists(this.fieldsToFilterMap);
        }
    }
    setSelectedRangeValue(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var rangeValue = event.target.dataset.range;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field[rangeValue] = value;
            this.fieldsToFilterMap[fieldName] = field;
            this.populateLists(this.fieldsToFilterMap);
        }
    }
    confirmFilter() {
        this.pageNumber = 1;
        let selection = [];
        try {
            selection = Object.keys(this.fieldsToFilterMap).filter(fieldName =>
            (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
                (this.fieldsToFilterMap[fieldName].values &&
                    (this.fieldsToFilterMap[fieldName].values.length > 1
                        || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
                || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
                .map(fieldName => {
                    let item = {};
                    item.fieldName = fieldName;
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('stringFieldType')) {
                        item.stringFieldType = this.fieldsToFilterMap[fieldName].stringFieldType;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
                        item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('isEncrypted')) {
                        item.isEncrypted = this.fieldsToFilterMap[fieldName].isEncrypted;
                    }
                    if (this.fieldsToFilterMap[fieldName].values &&
                        (this.fieldsToFilterMap[fieldName].values.length > 1
                            || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== ''))) {
                        item.values = this.fieldsToFilterMap[fieldName].values;
                        return item;
                    }
                    if (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '') {
                        item.value1 = this.fieldsToFilterMap[fieldName].value1;
                    }
                    if (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '') {
                        item.value2 = this.fieldsToFilterMap[fieldName].value2;
                    }
                    return item;
                }).filter(item => (item.hasOwnProperty('values') || item.hasOwnProperty('value1') || item.hasOwnProperty('value2') || item.hasOwnProperty('userFilterable')));
            this.filters.dynamic = JSON.stringify(selection);
            this.loadData();
        } catch (error) {
            console.log(error);
        }
    }

    handleChangeFlow(event) {
        let flow = event.target.dataset.flow;
        this.flows[flow] = !this.flows[flow];
    }

    handleExitFlow(event) {
        let flow = event.target.dataset.flow;
        if (event.detail.status == 'FINISHED') {
            this.flows[flow] = !this.flows[flow];
            if (event.detail.outputVariables) {
                for (let outputVar of event.detail.outputVariables) {
                    if (outputVar.name == 'createdCommercialPlanId') {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'PromoAgreementsManager&a__recordId=' + outputVar.value
                            },
                        });
                    }
                }
            }
        }
    }

    handlePrint(event) {
        try {
            let recordId = event.target.dataset.id;
            const selectedFields = [];
            this.displayedFields.forEach(field => {
                selectedFields.push(field.fieldName);
            });
            const a = document.createElement('a');
            a.href = `/apex/nTemplate__SingleRecordPrint?Id=${recordId}`;
            a.target = '_blank';
            a.click();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    handleMassPrint(event) {
        try {
            if (this.records.filter(item => item.checked).length) {
                const selectedFields = [];
                selectedFields.push('Name');
                this.displayedFields.forEach(field => {
                    if (field.fieldName != 'Name') {
                        selectedFields.push(field.fieldName);
                    }
                });
                const a = document.createElement('a');
                a.href = `/one/one.app#/alohaRedirect/apex/CommercialPlanMassPrint?object=` + this.prefix + `CommercialPlan__c&selectedIds=${this.records.filter(item => item.checked).map(item => item.Id)}&selectedFields=${selectedFields.join(',')}`;
                a.target = '_blank';
                a.click();
            } else {
                showNotification(this, this.labels.LBL_Info, this.labels.MSG_SelectOneLine, 'warning');
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    handleOpenPAGManager(event) {
        try {
            let recordId = event.target.dataset.id;
            let url = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'PromoAgreementsManager';
            url += '&a__recordId=' + recordId;
            const a = document.createElement('a');
            a.href = url;
            a.target = '_blank';
            a.click();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    handleOpenInvoiceVisualiser(event) {
        try {
            let recordId = event.target.dataset.id;
            let url = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (PREFIX ? PREFIX : 'c') + ':invoiceManager';
            url += '&a__recordId=' + recordId;
            const a = document.createElement('a');
            a.href = url;
            a.target = '_blank';
            a.click();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    toggleEditMode() {
        this.readOnlyView = !this.readOnlyView;
    }

    handleCancelEditMode() {
        this.CPToUpdateMap = {};
        this.hasChanges = false;
        this.readOnlyView = true;
        this.pageNumber = 1;
        this.loadData();
    }

    handleFieldEdits(event) {
        let index = event.target.dataset.index;
        let id = event.target.dataset.id;
        let fieldName = event.target.dataset.field;
        let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        value = (Array.isArray(value) ? value[0] : value) || null;
        let obj;
        if (this.CPToUpdateMap.hasOwnProperty(id)) {
            obj = this.CPToUpdateMap[id];
        } else {
            obj = {
                attributes: { type: this.API_NAMES.CommercialPlan__c.objectApiName },
                Id: id
            };
        }
        obj[fieldName] = value;
        this.CPToUpdateMap[id] = obj;
        let record = this.records[index]
        let displayedField = this.displayedFields.find(field => field.fieldName === fieldName);
        if (displayedField.picklistColorsMap && value !== '' && displayedField.picklistColorsMap.hasOwnProperty(value)) {
            record.rowColor = displayedField.picklistColorsMap[value];
        }
        this.applyRowStyle(record);
        this.hasChanges = true;
    }

    handleSave() {
        if (!this.CPToUpdateMap || Object.keys(this.CPToUpdateMap).length === 0) {
            showNotification(this, this.labels.LBL_Info, this.labels.MSG_No_Changes_To_Save, 'info');
            return;
        }
        this.isLoading = true;
        saveRecords({
            recordsToUpsertJSON: JSON.stringify(Object.values(this.CPToUpdateMap))
        }).then((result) => {
            if (result === 'SUCCESS') {
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                this.CPToUpdateMap = {};
                this.hasChanges = false;
                this.readOnlyView = true;
                this.pageNumber = 1;
                this.loadData();
            } else {
                showNotification(this, this.labels.LBL_Error, result, 'error');
                this.isLoading = false;
            }
        }).catch((error) => {
            showNotification(this, this.labels.LBL_Error, error.body?.message || error.message, 'error');
            this.isLoading = false;
        });
    }

    handleReset() {
        this.pageNumber = 1;
        this.filters.promoAgreementTypes = '';
        this.filters.promoStatementTypes = '';
        this.filters.supplierIds = [];
        this.filters.selectedSuppliers = [];
        this.filters.negoScopeIds = [];
        this.filters.selectedNegoScopes = [];
        this.filters.commercialPlanIds = [];
        this.filters.selectedCommercialPlans = [];
        this.filters.year = '';
        this.filters.status = '';
        this.filters.dynamic = '';
        this.selectAll = false;
        this.loadData();
    }

    handleSearchCommercialPlan(event) {
        const searchTerm = event.target.value;
        this.selectAll = false;
        this.displayedFields.forEach(field => {
            if (field.isFilterable && !field.isNumberField && !field.isDate && !field.isDateTime) {
                field.filterValue = searchTerm;
            }
        });
    }

    handleEnterKeyPress(event) {
        // Check if the Enter key was pressed
        if (event.keyCode === 13) {
            this.handleSearchCommercialPlan(event);
        }
    }

    handleChangeSearch(event) {
        let field = event.target.dataset.field;
        this.filters[field] = event.target.value;
    }

    // PAGINATION Variables
    changePageSizeHandler(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.loadData();
    }

    handlePrevious() {
        try {
            this.selectAll = false;
            this.pageNumber--;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleNext() {
        try {
            this.selectAll = false;
            this.pageNumber++;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleFirst() {
        try {
            this.selectAll = false;
            this.pageNumber = 1;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleLast() {
        try {
            this.selectAll = false;
            this.pageNumber = this.pageCount;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleChangeScopePanelFilter(event) {
        switch (event.target.dataset.field) {
            case this.API_NAMES.CommercialPlan__c.PromoAgreementType__c:
                this.filters.promoAgreementTypes = event.target.value;
                break;
            case this.API_NAMES.CommercialPlan__c.PromoStatementType__c:
                this.filters.promoStatementTypes = event.target.value;
                break;
            case this.API_NAMES.CommercialPlan__c.Year__c:
                this.filters.year = event.detail.value;
                break;
        }
    }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }

    setnumberOfFixedColumns() {
        // Sticky / Fixed columns for first Table
        if (this.template.querySelector('.main-table')) {
            let tableTrs = this.template.querySelector('.main-table').rows;
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = 5;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
        }
    }

    @track tableStyleHeight;
    changeHeight = () => {
        try {
            let mainContainer = this.template.querySelector('.mainContainer');
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBody = this.template.querySelector(".pageBody");
            let pageFooter = this.template.querySelector(".footerDiv");
            if (mainContainer != null &&
                pageHeader != null &&
                pageBody != null) {
                pageBody.style.height = window.innerHeight - pageHeader.offsetHeight - (pageFooter != null ? pageFooter.offsetHeight : 0) - (4 * 40) + "px";
                this.tableStyleHeight = 'background-color: #FFFFFF !important; width: -webkit-fill-available; height:' + (pageBody.style.height) + 'px';
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            console.error(error.message)
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    };

    // 🚀 ~ popup
    popupNotification() {
        this.popup.visibility = true;
        return new Promise((resolve, reject) => {
            this._PopupResolve = resolve
        });
    }

    submitPopUp(event) {
        const state = event.target.dataset.id == 'confirm' ? true : false;
        this._PopupResolve(state)
    }

    get modalFooterStyle() {
        return this.popup && !this.popup.cancelBtn ? 'padding-right: 0px;' : '';
    }

}