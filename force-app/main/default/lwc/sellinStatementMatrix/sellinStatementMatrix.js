import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import Toast from 'lightning/toast';
import ToastContainer from 'lightning/toastContainer';
//APEX
import initData from '@salesforce/apex/SellinStatementMatrixController.initData';
import loadData from '@salesforce/apex/SellinStatementMatrixController.loadData';
import savePeriods from '@salesforce/apex/SellinStatementMatrixController.savePeriods';
import { API_NAMES, Labels, PictosNegoptim2, sellInIcons, periodKeys, RESOURCES } from './properties.js';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_LOCALE from '@salesforce/i18n/locale';
import getCustomLabel from '@salesforce/apex/NegoptimLabels.getCustomLabel';

export default class SellinStatementMatrix extends NavigationMixin(LightningElement) {
    labels = { ...Labels }
    @wire(CurrentPageReference)
    pageRef;
    @track isLoading = false;
    @track showWarningPopupBeforeSave = false;
    @track isPortal = false;
    @track prefix = '';
    @track pageSize = 50;
    @track pageNumber = 1;
    totalPagesCount = 0;
    @track fieldsWrapperList = [];
    @track filterWrapper = {};
    @track totalNumbOfRecords = 0;
    @track conditions = [];
    @track tables = [];
    @track showModal = false;
    @track sellinStatementName = this.labels.LBL_SellInStatementMatrixHeader;
    newPeriodMap = {} // object contains list of changed records and fields
    sellInWelcomeMessage;
    restitIconSource = `${PictosNegoptim2}/PICTOS/PNG/Picto_negOptim2_summary.png`;
    iconStyle = `width: 25px; height: 25px;`
    edit;
    flowApiName;
    orderDirectionMap = new Map();
    headerStyle = 'background-color: rgb(13, 128, 125);color:white;';
    statusPicklistOptions;
    sellinStatementStatusPicklistOptions;
    sellinStatementPeriodTypePicklistOptions;
    pageSizeOptions = [
        // { label: '5', value: 5, isSelected: false },
        // { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        // { label: '75', value: 75, isSelected: false },
        // { label: '100', value: 100, isSelected: false }
        { label: '250', value: 250, isSelected: false }
    ];
    toastEventVariant = {
        error: 'error',
        success: 'success',
        warning: 'warning'
    }
    flowModalContainerStyle = 'margin: auto; padding: 30px; width: fit-content; min-width: 50%;';

    flowInput = {
        recordIds: { name: 'recordIds', type: 'String' }
    }
    flowStatus = {
        FINISHED: 'FINISHED',
        ERROR: 'ERROR'
    }
    rullerFields = {}
    @track popup = {
        visibility: false,
        body: this.labels.MSG_Connect_ConfirmUnsavedSellIn,
        title: this.labels.MSG_Warning
    }
    @track sellInStatementRecords;
    @track negoScopeId;
    @track referenceYear;
    @track periodType;
    @track periodNumber;
    @track canEditRecords = true;
    @track availableSellinTypes = [{
        // value: 'LBL_Connect_RegularDiscountableRevenue',
        name: this.labels.LBL_Connect_RegularDiscountableRevenue
    }, {
        // value: 'LBL_Connect_PromoDiscountableRevenue',
        name: this.labels.LBL_Connect_PromoDiscountableRevenue
    }, {
        // value: 'LBL_Connect_TotalDiscountableRevenue',
        name: this.labels.LBL_Connect_TotalDiscountableRevenue
    }, {
        // value: 'LBL_Connect_NonDiscountableRevenue',
        name: this.labels.LBL_Connect_NonDiscountableRevenue
    }, {
        // value: 'LBL_Connect_RegularDiscountableQuantity',
        name: this.labels.LBL_Connect_RegularDiscountableQuantity
    }, {
        // value: 'LBL_Connect_PromoDiscountableQuantity',
        name: this.labels.LBL_Connect_PromoDiscountableQuantity
    }, {
        // value: 'LBL_Connect_TotalDiscountableQuantity',
        name: this.labels.LBL_Connect_TotalDiscountableQuantity
    }, {
        // value: 'LBL_Connect_NonDiscountableQuantity',
        name: this.labels.LBL_Connect_NonDiscountableQuantity
    },
    ];
    fieldWithoutFilter = [`${API_NAMES.SellInStatementDetail__c.NegoScopeReference__r}.${API_NAMES.NegoScope__c.Comment__c}`]
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }
    get pagesBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + (this.tables?.length > 0 ? 1 : 0) - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
    }
    get colspanDisplayedFields() {
        let colspan = this.fieldsWrapperList.length;
        this.periodFields.map(field => {
            colspan += field.fields.length;
        });
        return colspan;
    }
    get filterList() {
        let filter = [];
        try {
            for (let field in this.filterWrapper) {
                if (this.filterWrapper[field].isSearchable) {
                    if (this.filterWrapper[field].type == 'text' && this.filterWrapper[field].valuesList.length != 0) {
                        filter.push('(' + this.filterWrapper[field].valuesList.map(item => ` ${field} LIKE '%${item.trim()}%' `).join(' OR ') + ')');
                    } else if (this.filterWrapper[field].type == 'picklist' && this.filterWrapper[field].valuesList.length != 0) {
                        filter.push('' + field + ' IN (\'' + this.filterWrapper[field].valuesList.join('\', \'') + '\')');
                    } else if (this.filterWrapper[field].type == 'number') {
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + field + ' >= ' + this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + field + ' <= ' + this.filterWrapper[field].value2);
                        }
                    } else if (this.filterWrapper[field].type == 'date') {
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + field + ' >= ' + this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + field + ' <= ' + this.filterWrapper[field].value2);
                        }
                    } else if (this.filterWrapper[field].type == 'datetime') {
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + field + ' >= ' + new Date(this.filterWrapper[field].value1).toISOString());
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + field + ' <= ' + new Date(this.filterWrapper[field].value2).toISOString());
                        }
                    }
                }
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
        return filter;
    };

    get inputState() {
        return !this.edit;
    }

    extractLabel(data) {
        const regex = /\{\!\$Label\.(.*?)\}/;
        const match = data.match(regex);
        return match ? match[1] : null;
    }

    //LIFECYCLE
    connectedCallback() {
        try {
            loadScript(this, RESOURCES.ExcelJSScript).then(() => {
            }).catch(error => {
                console.log(error?.body?.message || error?.message);
            });
            loadScript(this, RESOURCES.xlsx + '/js-xlsx-master/dist/jszip.js').then(() => {
                loadScript(self, RESOURCES.xlsx + '/js-xlsx-master/dist/xlsx.js').then(() => {
                }).catch(error => {
                    console.log(error?.body?.message || error?.message);
                });
            }).catch(error => {
                console.log(error?.body?.message || error?.message);
            });
            // declare toast container
            const toastContainer = ToastContainer.instance();
            toastContainer.maxToasts = 5;
            toastContainer.toastPosition = 'top-center';
            this.init();
            this._beforeUnloadHandler = this.handleBeforeUnload.bind(this);
            window.addEventListener('beforeunload', this._beforeUnloadHandler);
            addEventListener('resize', this.setPageSize);
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    renderedCallback() {
        this.setPageSize();
    }

    disconnectedCallback() {
        window.removeEventListener('beforeunload', this._beforeUnloadHandler);
    }

    handleBeforeUnload(event) {
        if (Object.keys(this.newPeriodMap).length !== 0) {
            event.preventDefault();
        }
    }

    init() {
        this.isLoading = true;
        initData().then(result => {
            let parsedResult = JSON.parse(result);
            this.labels.MSG_Warning_SellInDiscRegularP_Empty = parsedResult.warningMsg;
            this.labels.LBL_SellinStepMismatchMsg = parsedResult.stepMismatchMsg;
            this.prefix = parsedResult.prefix;
            this.isPortal = parsedResult.isPortal;
            this.flowApiName = parsedResult.sellInSubmissionFlow;
            this.periodTypePicklistOptions = parsedResult.fields.find(item => (item.objectName == API_NAMES.SellInStatement__c.objectApiName && item.fieldName === API_NAMES.SellInStatement__c.PeriodType__c)).picklistValues;
            if (parsedResult.sellInWelcomeMessage) {
                const extractedLabel = this.extractLabel(parsedResult.sellInWelcomeMessage);
                if (extractedLabel != null) {
                    getCustomLabel({
                        labelName: extractedLabel,
                        hardcodedLabel: 'Invalid Data'
                    }).then((res) => {
                        this.sellInWelcomeMessage = res;
                    });
                } else {
                    this.sellInWelcomeMessage = parsedResult.sellInWelcomeMessage;
                }
            }
            this.statusPicklistOptions = parsedResult.fields.find(item => (item.objectName == API_NAMES.SellInStatementDetail__c.objectApiName && item.fieldName === API_NAMES.SellInStatementDetail__c.Status__c)).picklistValues;
            this.sellinStatementStatusPicklistOptions = parsedResult.fields.find(item => (item.objectName == API_NAMES.SellInStatement__c.objectApiName && item.fieldName === API_NAMES.SellInStatement__c.Status__c)).picklistValues;
            this.sellinStatementPeriodTypePicklistOptions = parsedResult.fields.find(item => (item.objectName == API_NAMES.SellInStatement__c.objectApiName && item.fieldName === API_NAMES.SellInStatement__c.PeriodType__c)).picklistValues;
            if (this.pageRef) {
                const { state } = this.pageRef;
                if (state.c__appliedfilters) {
                    let res = JSON.parse(state.c__appliedfilters)
                    res.forEach(filter => {
                        this.conditions.push(API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + filter);
                    });
                }
                if (state.c__negoScopeId) {
                    this.negoScopeId = state.c__negoScopeId;
                }
                if (state.c__referenceYear) {
                    this.referenceYear = state.c__referenceYear;
                }
                if (state.c__periodType) {
                    this.periodType = state.c__periodType;
                }
                if (state.c__periodNumber) {
                    this.periodNumber = state.c__periodNumber;
                }
            }
            let colFields = parsedResult.fields.filter(item => item.objectName == API_NAMES.SellInStatementDetail__c.objectApiName);
            this.sellInRevenueOptions = parsedResult.sellInRevenueOptions;
            this.fieldsWrapperList = this.buildFieldWrapper(colFields)
            this.extraFields(this.sellInRevenueOptions)
            this.afterLoad();
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    buildFieldWrapper(colFields) {
        try {
            let fieldsList = [];

            colFields.forEach(field => {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldHelpText: field.fieldHelpText,
                    fieldType: field.fieldType,
                    pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                    selectedValues: [],
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    _isNumber: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                    isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextArea: field.fieldType == 'TEXTAREA',
                    hideFilter: this.fieldWithoutFilter.includes(field.fieldName),
                    link: '',
                    style: '',
                    //isReferenceText: field.fieldName.includes('.') && (field.fieldType == 'STRING' || field.fieldType == 'REFERENCE'),
                    //isText: field.fieldType == 'STRING' && field.fieldType == 'REFERENCE',
                    headerStyle: this.headerStyle,
                    value: null,
                }
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate
                    && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextArea;
                if (field.fieldName == API_NAMES.SellInStatementDetail__c.ExtId__c) {
                    fieldWrapper.style = 'min-width: 200px; max-width: 200px; width: 200px;';
                    fieldWrapper.headerStyle += fieldWrapper.style;
                    fieldWrapper.fieldLabel = this.labels.LBL_Connect_ScopeCode;
                }
                if (field.fieldName == API_NAMES.SellInStatementDetail__c.SellInStatementBase__c) {
                    fieldWrapper.style = 'min-width: 200px; max-width: 200px; width: 200px;';
                    fieldWrapper.headerStyle += fieldWrapper.style;
                    fieldWrapper.fieldLabel = this.labels.LBL_Connect_ScopeName;
                }
                if (field.fieldName == API_NAMES.SellInStatementDetail__c.NegoScopeReference__r + '.' + API_NAMES.NegoScope__c.Comment__c) {
                    fieldWrapper.style = 'min-width: 200px; max-width: 200px; width: 200px;overflow: hidden;text-overflow: ellipsis;';
                    fieldWrapper.headerStyle += fieldWrapper.style;
                }
                if (field.fieldName == API_NAMES.SellInStatementDetail__c.BusinessUnit__c) {
                    fieldWrapper.style = 'min-width: 150px; max-width: 150px; width: 150px;';
                    fieldWrapper.headerStyle += fieldWrapper.style;
                }
                if (field.fieldName == API_NAMES.SellInStatementDetail__c.CurrencyIsoCode) {
                    fieldWrapper.style = 'min-width: 100px; max-width: 100px; width: 100px;';
                    fieldWrapper.headerStyle += fieldWrapper.style;
                    fieldWrapper.fieldLabel = this.labels.LBL_Currency;
                }
                if (field.fieldName == API_NAMES.SellInStatementDetail__c.Status__c) {
                    fieldWrapper.style = 'min-width: 100px; max-width: 100px; width: 100px;';
                    fieldWrapper.headerStyle += fieldWrapper.style;
                }

                fieldsList.push(fieldWrapper);
            });
            return fieldsList;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    extraFields(sellInRevenueOptions) {
        const header = new Set();
        for (const item of sellInRevenueOptions) {
            for (const [key, values] of Object.entries(periodKeys.header)) {
                if (values.includes(item)) {
                    header.add(key);
                }
            }
        }
        const orderedHeader = Object.keys(periodKeys.header).filter(key => header.has(key));
        const subType = orderedHeader.map(key => {
            const fields = [];
            for (const label of sellInRevenueOptions) {
                if (!periodKeys.header[key].includes(label))
                    continue;
                for (const [subtype, values] of Object.entries(periodKeys.subHeader)) {
                    if (values.includes(label)) {
                        fields.push({
                            value: subtype,
                            label: this.labels[subtype],
                            style: `background-color: ${periodKeys.colors[key].subtype}; color: white; min-width: 160px; max-width: 160px; width: 160px;`,
                            fieldHelpText: this.labels[periodKeys.descriptions[label]],
                        })
                    }
                }
            }
            return {
                title: key,
                label: this.labels[key],
                style: `background-color: ${periodKeys.colors[key].title}; color: white`,
                colspan: fields.length,
                fields: fields
            }
        })
        this.periodFields = subType;
    }

    handleChangePeriodNumber(event) {
        try {
            this.isLoading = true;
            let value = event.target.dataset.value;
            this.periodNumber = value;
            this.conditions = [];
            this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.NegoScope__c + ' = \'' + this.negoScopeId + '\'');
            this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.ReferenceYear__c + ' = ' + this.referenceYear);
            this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.PeriodType__c + ' = \'' + this.periodType + '\'');
            this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.PeriodNumber__c + ' = ' + value);
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    afterLoad() {
        loadData({
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            negoScopeId: this.negoScopeId,
            referenceYear: this.referenceYear,
            periodType: this.periodType,
            periodNumber: this.periodNumber,
            conditions: this.conditions,
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
            this.totalNumbOfRecords = parsedResult.totalSize;
            this.sellinStatementName = parsedResult.sellinStatementName ? parsedResult.sellinStatementName : this.sellinStatementName;
            this.sellInStatementRecords = parsedResult.sellInStatementRecords;
            console.log('this.periodType: ' + this.periodType)
            console.log('this.periodNumber: ' + this.periodNumber)
            if (this.periodType && this.periodNumber) {
                this.buildRullerField();
            }

            //
            let tmpTables = [];
            let firstKey;
            let i = 0;
            // Add All non Assiettes
            parsedResult.records.forEach(item => {
                let periodType = item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodType__c];
                if (!this.headerPeriodType) {
                    this.headerPeriodType = periodType;
                }
                console.log('periodType: ' + periodType)
                if (!item[API_NAMES.SellInStatementDetail__c.IsCustomDateRange__c] &&
                    (item[API_NAMES.SellInStatementDetail__c.NegoScopeReference__c] == item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.NegoScope__c])) {
                    let mainYear = item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.ReferenceYear__c];
                    let key = item[API_NAMES.SellInStatementDetail__c.NegoScopeReference__c] + '-' + mainYear;
                    firstKey = !firstKey ? key : firstKey;
                    let nonAssietteTable = tmpTables.find(item => item.key == key);
                    if (!nonAssietteTable) {
                        nonAssietteTable = {
                            key: key,
                            headerPeriodType: this.periodTypePicklistOptions.find(item => item.value === periodType).label,
                            headerLabel: this.labels.LBL_Connect_ScopeName + ' - ' + item[API_NAMES.SellInStatementDetail__c.NegoScopeReference__r].Name + ' - ' + mainYear,
                            headerIconSrc: `${sellInIcons}/resource/crown.png`,
                            class: '',
                            isAssiette: false,
                            isOpen: true,
                            records: [],
                            showHeader: i == 0,
                        };
                        tmpTables.push(nonAssietteTable);
                        i++;
                    }
                    nonAssietteTable.records.push(item);
                }
            });
            // Add all Assiettes tables
            parsedResult.records.forEach(item => {
                let periodType = item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodType__c];
                console.log('periodType: ' + periodType)
                if (item[API_NAMES.SellInStatementDetail__c.IsCustomDateRange__c] ||
                    (item[API_NAMES.SellInStatementDetail__c.NegoScopeReference__c] != item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.NegoScope__c])) {
                    let formattedCustomBDate = '';
                    let formattedCustomEDate = '';
                    if (item[API_NAMES.SellInStatementDetail__c.CustomBDate__c]) {
                        formattedCustomBDate = new Intl.DateTimeFormat(USER_LOCALE, {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit'
                        }).format(new Date(item[API_NAMES.SellInStatementDetail__c.CustomBDate__c]));
                    }
                    if (item[API_NAMES.SellInStatementDetail__c.CustomEDate__c]) {
                        formattedCustomEDate = new Intl.DateTimeFormat(USER_LOCALE, {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit'
                        }).format(new Date(item[API_NAMES.SellInStatementDetail__c.CustomEDate__c]));
                    }
                    let key = item[API_NAMES.SellInStatementDetail__c.NegoScopeReference__c] + '-' + item[API_NAMES.SellInStatementDetail__c.CustomBDate__c] + '-' + item[API_NAMES.SellInStatementDetail__c.CustomEDate__c];
                    let assietteTable = tmpTables.find(item => item.key == key);
                    if (!assietteTable) {
                        assietteTable = {
                            key: key,
                            headerLabel: this.labels.LBL_Connect_ScopeName + ' - ' + item[API_NAMES.SellInStatementDetail__c.NegoScopeReference__r].Name + ' - ' + formattedCustomBDate + ' - ' + formattedCustomEDate,
                            //headerPeriodType: this.labels.LBL_Period,
                            headerPeriodType: this.periodTypePicklistOptions.find(item => item.value === periodType).label,
                            headerIconSrc: `${sellInIcons}/resource/target.png`,
                            class: '',
                            isAssiette: true,
                            isOpen: true,
                            records: [],
                        };
                        tmpTables.push(assietteTable);
                    }
                    //item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodNumber__c] = formattedCustomBDate + ' - ' + formattedCustomEDate;
                    assietteTable.records.push(item);
                }
            });
            tmpTables.forEach(item => {
                item.recordsWrapperList = [...this.buildDataWrapper(item.records)];
            });
            // open first table
            this.activeMainAccordion = firstKey;
            // let firstTable = tmpTables.find(item => item.key == firstKey);
            // firstTable.isOpen = true;
            // firstTable.class = '';
            // tmpTables[0].isOpen = true;
            // tmpTables[0].class = '';
            // add tables
            this.tables = tmpTables;

            this.isLoading = false;
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    toggleSection(event) {
        let key = event.target.dataset.key;
        let item = this.tables.find(item => item.key == key);
        item.class = item.class == '' ? 'slds-hide' : '';
        item.isOpen = !item.isOpen;
    }

    buildRullerField() {
        console.log('buildRullerField')
        console.log('this.sellinStatementPeriodTypePicklistOptions: ' + JSON.stringify(this.sellinStatementPeriodTypePicklistOptions))
        console.log('this.periodType: ' + this.periodType)
        this.rullerFields.title = this.sellinStatementPeriodTypePicklistOptions.find(item => item.value === this.periodType).label;
        this.rullerFields.fields = [];
        let totalPeriod = this.periodType == 'Month' ? 12 : (this.periodType == 'Trimester' ? 4 : (this.periodType == 'Semester' ? 2 : (this.periodType == 'Annual' ? 1 : 0)));
        for (let periodNb = 1; periodNb <= totalPeriod; periodNb++) {
            let periodNumberRule = {
                value: periodNb,
                status: '',
                class: 'header-ruller bg-white',
                disabled: false,
            }
            let sellinStatement = this.sellInStatementRecords && this.sellInStatementRecords.find(item => item[API_NAMES.SellInStatement__c.PeriodNumber__c] == periodNb);
            if (sellinStatement) {
                periodNumberRule.status = this.sellinStatementStatusPicklistOptions.find(item => item.value === sellinStatement[API_NAMES.SellInStatement__c.Status__c]).label;
                if (sellinStatement[API_NAMES.SellInStatement__c.Status__c] == 'Submitted' || sellinStatement[API_NAMES.SellInStatement__c.Status__c] == 'Closed') {
                    periodNumberRule.class = 'header-ruller header-ruller-period-disabled';
                    periodNumberRule.disabled = false;///true;
                } else if (sellinStatement[API_NAMES.SellInStatement__c.Status__c] == 'Requested') {
                    periodNumberRule.class = 'header-ruller bg-white';
                }
            } else {
                periodNumberRule.class = 'header-ruller';
                periodNumberRule.disabled = true;
            }
            if (/*!periodNumberRule.disabled &&*/ this.periodNumber == periodNb) {
                periodNumberRule.class = 'header-ruller header-ruller-period-enable';
                //this.canEditRecords = !periodNumberRule.disabled;
                this.canEditRecords = sellinStatement && sellinStatement[API_NAMES.SellInStatement__c.Status__c] != 'Submitted' && sellinStatement[API_NAMES.SellInStatement__c.Status__c] != 'Closed';
            }
            if (this.periodNumber == periodNb) {
            }
            this.rullerFields.fields.push(periodNumberRule);
            /*this.rullerFields.fields.push({
                value: index + 1,
                class: `header-ruller ${index + 1 == this.periodNumber ? 'header-ruller-period-enable' : (index + 1 < this.periodNumber ? 'header-ruller-period-disabled' : 'bg-white')} `,
                disabled: index + 1 <= this.periodNumber
            })*/
        }
        this.rullerFields.active = true;
    }

    buildDataWrapper(data) {
        const extraField = [];
        this.periodFields.map(field => {
            field.fields.map(key => {
                extraField.push({ fieldName: periodKeys.lookupFields[field.title][key.value], fieldLabel: key.value })
            })
        })
        data.forEach(row => {
            row.columns = [];
            if (!this.periodNumber) {
                this.periodNumber = row[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodNumber__c];
            }
            let fields = JSON.parse(JSON.stringify(this.fieldsWrapperList));
            fields.forEach(field => {
                if (field.isReference) {
                    if (field.fieldName.endsWith('Id')) {
                        field.value = row[field.fieldName.replace('Id', '')]?.Name;
                        field.style = 'min-width: 100px'
                    } else {
                        if (field.Name == API_NAMES.NegoScope__c.Comment__c) {
                            field.value = row[field.fieldName.replace('__c', '__r')][field.Name];
                        }
                        else {
                            field.value = row[field.fieldName.replace('__c', '__r')]?.Name;
                        }
                        field.style = 'min-width: 150px;'
                    }
                    field.link = '/' + field.value;
                } else if (field.isPicklist) {
                    if (field.fieldName == API_NAMES.SellInStatement__c.Status__c) {
                        field.icon = true;
                        field.style = 'min-width: 100px; min-height: 45px;';
                        field.title = this.statusPicklistOptions.find(item => item.value === row[API_NAMES.SellInStatementDetail__c.Status__c]).label;
                        field.link = `${PictosNegoptim2}/${row[API_NAMES.SellInStatementDetail__c.StatusLogo__c]}.png`
                        field.iconStyle = this.iconStyle;
                        field.value = row[API_NAMES.SellInStatement__c.Status__c];
                    } else {
                        let found = field.pickListValues.find(item => item.value === row[field.fieldName]);
                        field.value = found?.label;
                        field.style = 'min-width: 100px;'
                    }
                } else if (field.fieldName.includes('.')) {
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let val = index == 0 ? row : field.value;
                        if (val) {
                            if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || field.fieldName.endsWith('RecordTypeId'))) {
                                field.value = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                field.value = '/' + val[values[index]];
                            } else {
                                field.value = val[values[index]];
                            }
                        }
                    }
                } else if (field.fieldName == API_NAMES.SellInStatementDetail__c.SellInStatementBase__c) {
                    field.isStatementBase = true;
                    field.value = row[field.fieldName];
                    field.style = 'min-width: 200px; max-width: 200px; text-wrap: auto;';
                }
                else {
                    field.value = row[field.fieldName];
                    field.style = 'min-width: 200px; max-width: 200px; text-wrap: auto;';
                }
            });
            const periodRecords = extraField.map(field => {
                const value = this?.newPeriodMap[row.Id]?.[field.fieldName] ?
                    this?.newPeriodMap[row.Id]?.[field.fieldName] : (row[field.fieldName] ? row[field.fieldName] : 0)
                return {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isInput: true,
                    value: value,
                    style: 'text-align:right; min-width: 160px; white-space: normal;'
                }
            })
            row.columns = [...JSON.parse(JSON.stringify(fields)), ...periodRecords];
        });
        return data;
    }

    handleBack() {
        const openLink = () => {
            // create a element 
            let link = document.createElement('a');
            link.href = !this.isPortal ? '/lightning/n/' + this.prefix + 'SellinStatementList' : '/NegoptimConnect/sellin-statement-list';
            console.log('link.href: ' + link.href)
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
        if (Object.keys(this.newPeriodMap).length === 0) {
            openLink();
            return;
        }
        this.popupNotification().then(submmited => {
            if (submmited) {
                openLink();
            }
            this.popup.visibility = false;
        })
    }

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

    handleEdit(event) {
        //get closest th
        const title = event.target.closest('th').dataset.id;
        const state = event.target.dataset.type ? true : false;
        const lookupFields = Object.values(periodKeys.lookupFields[title]);
        if (lookupFields.length == 0)
            return;
        this.tables.forEach(table => {
            table.records.forEach(record => {
                const canEddit = !['Submitted', 'Validated'].includes(record[API_NAMES.SellInStatementDetail__c.Status__c]);
                record.columns.forEach(column => {
                    if (lookupFields.includes(column?.fieldName)) {
                        column.isEdit = state && canEddit;
                        column.style = 'text-align:left; min-width: 160px; max-width: 160px; white-space: normal;'
                        this.periodFields.forEach(element => {
                            if (element.title == title) {
                                element.edit = state
                                element.focus = false;
                            } else {
                                //element.focus = state === false ? false : true;
                            }
                        });
                    }
                });
            })
        });
    }

    onChangePeriodInput(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        const record = this.tables.find(table => table?.records.find(record => record?.Id == id))?.records.find(record => record.Id == id);
        record[field] = value;
        if (record && record.columns) {
            // Update only the column that matches the provided field.
            record.columns.forEach(column => {
                if (column.fieldName === field) {
                    column.value = value;
                    column.modifiedStyle = 'background-color: #FBF3E0 !important;';
                }
            });
        }
        this.newPeriodMap[id] = {
            ...(this.newPeriodMap[id] || {}),
            id: id,
            [field]: value
        }
        this.tables = [...this.tables];
    }

    closePopuUp() {
        this.showWarningPopupBeforeSave = !this.showWarningPopupBeforeSave;
    }

    handleSave() {
        let itemFound = this.tables.find(table => table?.records.find(item => (!item[API_NAMES.SellInStatementDetail__c.SellInDiscTotalP__c] || item[API_NAMES.SellInStatementDetail__c.SellInDiscTotalP__c] == 0)))?.records.find(item => (!item[API_NAMES.SellInStatementDetail__c.SellInDiscTotalP__c] || item[API_NAMES.SellInStatementDetail__c.SellInDiscTotalP__c] == 0));
        this.showWarningPopupBeforeSave = itemFound;
        if (!this.showWarningPopupBeforeSave) {
            this.applySave();
        }
    }
    applySave() {
        this.isLoading = true;
        this.showWarningPopupBeforeSave = false;
        let dataToSave = Object.values(this.newPeriodMap);
        dataToSave.forEach(element => {
            element[API_NAMES.SellInStatementDetail__c.Status__c] = 'In Preparation';
        });
        this.periodFields.forEach(element => {
            element.edit = false;
            element.focus = false;
        });
        savePeriods({ jsonString: JSON.stringify(dataToSave) }).then(result => {
            this.tables.forEach(table => {
                table.records.forEach(record => {
                    if (this.newPeriodMap[record.Id]) {
                        record[API_NAMES.SellInStatementDetail__c.Status__c] = 'In Preparation';
                        record.columns.forEach(column => {
                            if (column.fieldName == API_NAMES.SellInStatementDetail__c.Status__c) {
                                column.value = 'In Preparation';
                                column.title = this.statusPicklistOptions.find(item => item.value === 'In Preparation')?.label;
                                column.link = `${PictosNegoptim2}/PICTOS/PNG/Picto_negOptim2_ReadyToWork2.png`;
                            }
                            column.isModified = false;
                        });
                    }
                });
            });
            this.newPeriodMap = {};
            //this.isLoading = false;
            this.showNotification(this.labels.LBL_Warning, this.labels.LBL_ReminderSentMsgSellInStatementAction, this.toastEventVariant.warning, 'sticky');
            this.showNotification(this.labels.LBL_Success, 'Success', this.toastEventVariant.success);
            this.afterLoad();
        }).catch(error => {
            this.isLoading = false;
            this.showNotification(this.labels.LBL_Error, 'Error', this.toastEventVariant.error);

        })
    }

    toggleFilterPanel(event) {
        try {
            let field = event.target.dataset.field;
            this.template.querySelectorAll('[data-filter-field]').forEach(element => {
                if (element.dataset.filterField == field) {
                    element.classList.toggle('slds-hide');
                } else {
                    element.classList.add('slds-hide');
                }
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handleOpenRestitMatrix(event) {
        try {
            let PeriodType = this.periodType;
            let NegoScope = this.negoScopeId;
            let ReferenceYear = this.referenceYear;
            let periodnumber = this.periodNumber;
            let filter = [];
            filter.push(`${API_NAMES.SellInStatement__c.NegoScope__c} IN ('${NegoScope}')`);
            filter.push(`${API_NAMES.SellInStatement__c.ReferenceYear__c} = ${ReferenceYear}`);
            filter.push(`${API_NAMES.SellInStatement__c.PeriodType__c} IN ('${PeriodType}')`);
            // if (periodnumber) {
            //     filter.push(`${API_NAMES.SellInStatement__c.PeriodNumber__c} = ${periodnumber}`);
            // }
            console.log('filter: ' + JSON.stringify(filter))
            // Encode filters once
            const encodedFilters = encodeURIComponent(JSON.stringify(filter));
            // Define component definition
            // Encode the component definition once
            if (!this.isPortal) {
                window.open(`/lightning/n/` + this.prefix + `SellinCollaborativeRestitution?c__appliedfilters=${encodedFilters}`, '_self');
            } else {
                window.open(`/NegoptimConnect/sellin-collaborative-restitution?c__appliedfilters=${encodedFilters}`, '_self');
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeFilter(event) {
        try {
            let fieldName = event.target.dataset.field;
            let type = event.target.dataset?.type || event.target.type;
            let value = event.target.value;
            let number = event.target.dataset.number;
            let field = this.fieldsWrapperList.find(field => field.fieldName === fieldName);
            if (!field) return;
            if (field.isReference) {
                if (field.fieldName.endsWith('Id')) {
                    fieldName = field.fieldName.replace('Id', '.Name');
                } else {
                    fieldName = field.fieldName.replace('__c', '__r.Name');
                }
            }
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (type === 'text') {
                let valuesList = (value != null && value !== '') ? value.split(",") : [];
                this.filterWrapper[fieldName].valuesList = valuesList.map(it => it.trim());
                field.isFiltered = valuesList.length !== 0;
                field.fieldSearchValue = value;
            } else if (type === 'number' || type === 'date' || type === 'datetime') {
                if (type === 'datetime') {
                    let selectedDate = new Date(value);
                    if (number === '1') {
                        selectedDate.setUTCHours(0, 0, 0, 0);
                        field.fieldSearchValue1 = selectedDate.toISOString();
                    } else if (number === '2') {
                        selectedDate.setUTCHours(23, 59, 59, 999);
                        field.fieldSearchValue2 = selectedDate.toISOString();
                    }
                    this.filterWrapper[fieldName][`value${number}`] = selectedDate;
                } else {
                    field[`fieldSearchValue${number}`] = value;
                    this.filterWrapper[fieldName][`value${number}`] = value;
                }
                field.isFiltered = (field.fieldSearchValue1 != null && field.fieldSearchValue1 !== '') || (field.fieldSearchValue2 != null && field.fieldSearchValue2 !== '');
            }
            this.filterWrapper[fieldName].type = type;
            this.filterWrapper[fieldName].isSearchable = true;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handlePicklistChange(event) {
        try {
            let fieldName = event.target.dataset.field;
            let value = event.detail.value;
            let field = this.fieldsWrapperList.find(field => field.fieldName === fieldName);
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (this.filterWrapper[fieldName].valuesList == null) {
                this.filterWrapper[fieldName].valuesList = [];
            }
            this.filterWrapper[fieldName].type = 'picklist';
            if (field) {
                field.isFiltered = value.length != 0;
                field.selectedValues = value;
                this.filterWrapper[fieldName].isSearchable = true;
            }
            this.filterWrapper[fieldName].valuesList = value;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handleApplyFilters(event) {
        try {
            this.isLoading = true;
            this.conditions = this.filterList;
            if (this.negoScopeId) {
                this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.NegoScope__c + ' = \'' + this.negoScopeId + '\'');
            }
            if (this.referenceYear) {
                this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.ReferenceYear__c + ' = ' + this.referenceYear);
            }
            if (this.periodType) {
                this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.PeriodType__c + ' = \'' + this.periodType + '\'');
            }
            if (this.periodNumber) {
                this.conditions.push('' + API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + API_NAMES.SellInStatement__c.PeriodNumber__c + ' = ' + this.periodNumber);
            }
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handleChangePage(event) {
        this.isLoading = true;
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.totalPagesCount;
            }
            this.afterLoad();
        } catch (error) {
            console.error(error)
        }
    }

    handleChangePageSize(event) {
        try {
            this.pageSize = parseInt(event.target.value);
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value == this.pageSize;
            }
            this.pageNumber = 1;
            this.afterLoad();
        }
        catch (error) {
            console.error('error: ' + error);
        }
    }

    setPageSize = () => {
        try {
            const mainContainer = this.template.querySelector(".mainContainer");
            const pageHeader = this.template.querySelector(".header");
            const pageBodyDiv = this.template.querySelector(".bodyDiv");
            const footerDiv = this.template.querySelector(".footerDiv");

            if (mainContainer && pageHeader && pageBodyDiv && footerDiv) {
                const windowHeight = window.innerHeight;
                const headerHeight = pageHeader.offsetHeight;
                const FooterHeight = footerDiv.offsetHeight;

                const remainingHeight = windowHeight - headerHeight - FooterHeight - (this.isPortal ? 100 : 150);

                pageBodyDiv.style.height = remainingHeight + "px";
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    };

    //Utility Methods
    /**
     * @description This Method to alert the user
     * @param {String} title message title
     * @param {String} message the message content
     * @param {String} variant the message type (success, warning, ..)
     */
    showNotification(title, message, variant, mode) {
        let errorMessage = message?.body?.message || message?.message || message;
        // create and show the alert
        Toast.show({
            label: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        }, this);
    }

    handleOpenModal(event) {
        try {
            console.log('this.flowApiName: ' + this.flowApiName)
            let recordIds = [...new Set(this.sellInStatementRecords.map(item => item.Id))];;
            this.flowInputVariables = [
                {
                    name: this.flowInput.recordIds.name,
                    type: this.flowInput.recordIds.type,
                    value: recordIds
                },
            ]
            console.log('this.flowInputVariables: ' + JSON.stringify(this.flowInputVariables))
            this.showModal = true;

        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleflowStatusChange(event) {
        try {
            let status = event.detail.status;
            if (status == this.flowStatus.FINISHED) {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_SellInStatement_FlowUpdated, this.toastEventVariant.success);
                this.handleCloseModal();
                this.isLoading = true;
                this.afterLoad();
            } else if (status == this.flowStatus.ERROR) {
                this.showNotification(this.labels.LBL_Error, this.labels.MSG_SellInStatement_FlowError, this.toastEventVariant.error);
                this.handleCloseModal();
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
    }

    downloadCSV() {
        let docName = `${this.sellinStatementName}-${(new Date()).toISOString().substring(0, 10)}`;
        // Create WorkBook
        let workbook = new ExcelJS.Workbook();
        // Create WorkSheet
        let worksheet = workbook.addWorksheet(docName);
        worksheet.properties.defaultRowHeight = 25;
        worksheet.properties.defaultColWidth = 20;
        const headerFields = this.fieldsWrapperList.map(field => field.fieldLabel);
        const discHeaders = this.periodFields.reduce((acc, header) => {
            const match = header.style.match(/background-color:\s*#([A-Fa-f0-9]+)/);
            const bgColor = match ? match[1] : null;

            acc[header.label] = {
                color: bgColor,
                title: header.label,
                colNumber: header.fields.length - 1,
            };

            return acc;
        }, {});


        const subDiscHeaders = this.periodFields.map(periodField => {
            periodField.fields.map(field => {
                return field.label
            })
        });
        const mergeRanges = [];
        const data = [];
        //
        let additionalHeaderFields = [];
        this.tables.map(table => {
            additionalHeaderFields.push(table?.headerPeriodType)
            let fields = [];
            fields = [
                [
                    ...headerFields,
                    ...this.periodFields.flatMap(periodField => {
                        let arr = new Array(periodField.fields.length - 1).fill(null);
                        arr.unshift(periodField.label);
                        return arr;
                    })
                ],
                [
                    ...new Array(headerFields.length).fill(null),
                    ...this.periodFields.flatMap(periodField =>
                        periodField.fields.map(field => field.label)
                    )
                ]
            ];
            const body = table.records.map(record => {
                return record.columns.map(column => column.value)
            }
            )
            data.push({
                title: table.headerLabel,
                fields: fields,
                body: body
            });
        });


        // add header 
        [
            [
                ...headerFields,
                ...this.periodFields.flatMap(periodField => {
                    let arr = new Array(periodField.fields.length - 1).fill(null);
                    arr.unshift(periodField.label);
                    return arr;
                })
            ],
            [
                ...new Array(headerFields.length).fill(null),
                ...this.periodFields.flatMap(periodField =>
                    periodField.fields.map(field => field.label)
                )
            ]
        ].forEach(field => {
            worksheet.addRow(field);
        });
        ;

        // Add rows to the worksheet
        data.forEach(e => {
            // add title
            worksheet.addRow([e.title]);
            // add header
            // e.fields.forEach(field => {
            // worksheet.addRow(field);
            // });
            // add body
            e.body.forEach(body => {
                worksheet.addRow(body);
            });
            worksheet.addRow([]); // separator empty row
        });
        console.log(data);// this.periodTypePicklistOptions.find(item => item.value === periodType).label

        worksheet.eachRow((row, rowNumber) => {
            row.eachCell((cell, colNumber) => {
                let mergeRange = null;
                let fill = null;
                let font = null;
                let addBorder = false
                const alignment = { vertical: 'middle', horizontal: 'center' };

                if ((headerFields.includes(cell.value)) || (additionalHeaderFields.includes(cell.value) && colNumber === 1)) {
                    mergeRange = { startRow: rowNumber, startCol: colNumber, endRow: rowNumber + 1, endCol: colNumber };
                    fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF0D807D' } };
                    font = { color: { argb: 'FFFFFFFF' } };
                } else if (Object.keys(discHeaders).includes(cell.value)) {
                    mergeRange = { startRow: rowNumber, startCol: colNumber, endRow: rowNumber, endCol: colNumber + discHeaders[cell.value].colNumber };
                    const color = 'FF' + discHeaders[cell.value].color.toUpperCase();
                    fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: color } };
                    font = { color: { argb: 'FFFFFFFF' } };
                    addBorder = true;
                } else if (subDiscHeaders.includes(cell.value)) {
                    addBorder = this.labels.LBL_TTM === cell.value
                    mergeRange = { startRow: rowNumber, startCol: colNumber, endRow: rowNumber, endCol: colNumber + (addBorder ? 4 : 2) };
                }

                if (mergeRange) {
                    mergeRanges.push(mergeRange);
                    cell.alignment = alignment;
                }
                if (fill) cell.fill = fill;
                if (font) cell.font = font;
            });
        });

        mergeRanges.forEach(range => {
            worksheet.mergeCells(range.startRow, range.startCol, range.endRow, range.endCol);
        });

        workbook.xlsx.writeBuffer().then(result => {
            self.isLoading = false;
            let a = document.createElement("a");
            document.body.appendChild(a);
            a.style = "display: none";
            let base64Bin = result.toString('base64');
            a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
            a.download = docName + '.xlsx'; //File name Here
            a.click();
        })
    }

}