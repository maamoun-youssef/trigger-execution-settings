import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';

//APEX
import initData from '@salesforce/apex/SellinCollaborativeRestitutionController.initData';
import loadData from '@salesforce/apex/SellinCollaborativeRestitutionController.loadData';
import { API_NAMES, Labels, sellInIcons, PictosNegoptim2, apiFields, RESOURCES } from './properties.js';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_LOCALE from '@salesforce/i18n/locale';

export default class SellinCollaborativeRestitution extends NavigationMixin(LightningElement) {
    labels = { ...Labels }
    @wire(CurrentPageReference)
    pageRef;
    @track isLoading = false;
    resultWrapper = {};
    @track prefix = '';
    @track isPortal = false;
    @track pageSize = 50;
    @track pageNumber = 1;
    @track showModal = false;
    labels = { ...Labels }
    totalPagesCount = 0;
    @track fieldsWrapperList = [];
    @track tables;
    @track filterWrapper = {};
    @track totalNumbOfRecords = 0;
    @track conditions = [];
    @track sellinStatementIds = [];
    @track sellinName = '';
    @track activeMainAccordion;
    @track headerPeriodType;
    newPeriodMap = {} // object contains list of changed records and fields
    edit;
    additionalConditions = []
    orderDirectionMap = new Map();
    headerStyle = 'background-color: rgb(13, 128, 125);color:white;';
    fixedHeaderStyle = 'background-color: rgb(13, 128, 125);color:white; min-width: 130px; max-width: 130px; white-space: normal; text-align: center;'
    statusPicklistOptions;
    pageSizeOptions = [
        // { label: '5', value: 5, isSelected: false },
        // { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        // { label: '75', value: 75, isSelected: false },
        // { label: '100', value: 100, isSelected: false }
        { label: '250', value: 250, isSelected: false }
    ];
    @track discHeaders = [];
    @track subDiscHeaders = [];
    @track disTitles = [];
    sellInRevenueOptions = [];
    @track discFields = [];
    toastEventVariant = {
        error: 'error',
        success: 'success'
    }

    @track popup = {
        visibility: false,
        body: this.labels.MSG_Connect_ConfirmUnsavedSellIn,//this.labels.MSG_Connect_ConfirmUnsavedSellIn,
        title: this.labels.MSG_Warning
    }
    flowApiName = ''
    flowModalContainerStyle = 'margin: auto; padding: 30px; width: fit-content; min-width: 50%;';

    flowInput = {
        recordIds: { name: 'recordIds', type: 'String' }
    }
    flowStatus = {
        FINISHED: 'FINISHED',
        ERROR: 'ERROR'
    }
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }
    get pagesBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
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
    fixedColumnsOptions = [{ value: 1, label: '1' }, { value: 2, label: '2' }, { value: 3, label: '3' }, { value: 4, label: '4' }];
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
            this.discHeaders = [
                { colSpan: 11, style: 'font-weight: bold; background-color: #E76436; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_RegularDiscountableRevenue', title: this.labels.LBL_Connect_RegularDiscountableRevenue.endsWith(':') ? this.labels.LBL_Connect_RegularDiscountableRevenue.slice(0, -1) : this.labels.LBL_Connect_RegularDiscountableRevenue },
                { colSpan: 11, style: 'font-weight: bold; background-color: #E76436; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_PromoDiscountableRevenue', title: this.labels.LBL_Connect_PromoDiscountableRevenue.endsWith(':') ? this.labels.LBL_Connect_PromoDiscountableRevenue.slice(0, -1) : this.labels.LBL_Connect_PromoDiscountableRevenue },
                { colSpan: 11, style: 'font-weight: bold; background-color: #E76436; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_TotalDiscountableRevenue', title: this.labels.LBL_Connect_TotalDiscountableRevenue.endsWith(':') ? this.labels.LBL_Connect_TotalDiscountableRevenue.slice(0, -1) : this.labels.LBL_Connect_TotalDiscountableRevenue },
                { colSpan: 11, style: 'font-weight: bold; background-color: #E76436; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_NonDiscountableRevenue', title: this.labels.LBL_Connect_NonDiscountableRevenue.endsWith(':') ? this.labels.LBL_Connect_NonDiscountableRevenue.slice(0, -1) : this.labels.LBL_Connect_NonDiscountableRevenue },
                { colSpan: 11, style: 'font-weight: bold; background-color: #1D915F; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_RegularDiscountableQuantity', title: this.labels.LBL_Connect_RegularDiscountableQuantity.endsWith(':') ? this.labels.LBL_Connect_RegularDiscountableQuantity.slice(0, -1) : this.labels.LBL_Connect_RegularDiscountableQuantity },
                { colSpan: 11, style: 'font-weight: bold; background-color: #1D915F; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_PromoDiscountableQuantity', title: this.labels.LBL_Connect_PromoDiscountableQuantity.endsWith(':') ? this.labels.LBL_Connect_PromoDiscountableQuantity.slice(0, -1) : this.labels.LBL_Connect_PromoDiscountableQuantity },
                { colSpan: 11, style: 'font-weight: bold; background-color: #1D915F; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_TotalDiscountableQuantity', title: this.labels.LBL_Connect_TotalDiscountableQuantity.endsWith(':') ? this.labels.LBL_Connect_TotalDiscountableQuantity.slice(0, -1) : this.labels.LBL_Connect_TotalDiscountableQuantity },
                { colSpan: 11, style: 'font-weight: bold; background-color: #1D915F; color: white; border-right: #7f350f solid;', label: 'LBL_Connect_NonDiscountableQuantity', title: this.labels.LBL_Connect_NonDiscountableQuantity.endsWith(':') ? this.labels.LBL_Connect_NonDiscountableQuantity.slice(0, -1) : this.labels.LBL_Connect_NonDiscountableQuantity },
            ];

            this.init(this);
            addEventListener('resize', this.setPageSize);

        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    renderedCallback() {
        this.setnumberOfFixedColumns();
        this.setPageSize();
    }
    init(self) {
        self = self || this;
        this.isLoading = true;
        initData().then(result => {
            let parsedResult = JSON.parse(result);
            this.resultWrapper = parsedResult;
            this.isPortal = parsedResult.isPortal;
            this.prefix = parsedResult.prefix;
            this.flowApiName = this.prefix + 'SCREEN_SellIn_Statement_Statement_Validation';
            this.sellInRevenueOptions = parsedResult.sellInRevenueOptions;
            this.statusPicklistOptions = parsedResult.fields.find(item => (item.objectName == API_NAMES.SellInStatementDetail__c.objectApiName && item.fieldName === API_NAMES.SellInStatement__c.Status__c)).picklistValues;
            this.periodTypePicklistOptions = parsedResult.fields.find(item => (item.objectName == API_NAMES.SellInStatement__c.objectApiName && item.fieldName === API_NAMES.SellInStatement__c.PeriodType__c)).picklistValues;
            this.discHeaders = this.discHeaders.filter(item => this.sellInRevenueOptions.includes(item.label))
            let subDiscHeaders = [];
            let disTitles = [];
            this.discHeaders.forEach((sec, index) => {
                [
                    { colSpan: 3, style: 'font-weight: bold;', title: this.labels.LBL_Period },
                    { colSpan: 3, style: 'font-weight: bold;', title: this.labels.LBL_YTD },
                    { colSpan: 5, style: 'font-weight: bold; border-right: #7f350f solid;', title: this.labels.LBL_TTM },
                ].forEach((it, ind) => {
                    it.key = `${index}-${ind}`;
                    subDiscHeaders.push(it);
                });
                [
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_PreviousYear },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_CurrentYear },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_Progression },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_PreviousYear },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_CurrentYear },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_Progression },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_PreviousYear },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_CurrentYear },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_Progression },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px;', title: this.labels.LBL_Forecast },
                    { style: 'font-style: italic;min-width: 130px; max-width: 130px; border-right: #7f350f solid;', title: this.labels.LBL_ForecastGap },
                ].forEach((it, ind) => {
                    it.key = `${index}-${ind}`;
                    disTitles.push(it);
                });
            });
            this.subDiscHeaders = subDiscHeaders;
            this.disTitles = disTitles;
            if (this.pageRef) {
                const { state } = this.pageRef;
                if (state.c__appliedfilters) {
                    let res = JSON.parse(state.c__appliedfilters)
                    res.forEach(filter => {
                        let f = filter;
                        let finalFilter;
                        let char = 'IN (\'';
                        if (!filter.includes(char)) {
                            finalFilter = f.replace('IN (', 'IN (\'');
                            f = finalFilter;
                            finalFilter = f.replace(')', '\')');
                            f = finalFilter;
                        }
                        this.conditions.push(API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + f)
                    });
                }
                if (state.c__negoScopeId) {
                    let filter = '';
                    filter = API_NAMES.SellInStatement__c.NegoScope__c + ' IN (\'' + state.c__negoScopeId + '\')';
                    this.conditions.push(API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + filter);

                }
                if (state.c__referenceYear) {
                    let filter = '';
                    filter = API_NAMES.SellInStatement__c.ReferenceYear__c + ' = ' + state.c__referenceYear;
                    this.conditions.push(API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + filter);
                }
                if (state.c__periodType) {
                    let filter = '';
                    filter = API_NAMES.SellInStatement__c.PeriodType__c + ' IN (\'' + state.c__periodType + '\')';
                    this.conditions.push(API_NAMES.SellInStatementDetail__c.SellInStatement__r + '.' + filter);
                }
            }
            this.statusOptions = this.isPortal ? parsedResult.fields.find(item => item.fieldName == API_NAMES.SellInStatement__c.Status__c)?.picklistValues : parsedResult.fields.find(item => item.fieldName == API_NAMES.SellInStatement__c.Status__c)?.picklistValues.filter(item => item.value != 'In Preparation'); // get status filed 
            let colFields = parsedResult.fields;
            this.fieldsWrapperList = this.buildFieldWrapper(colFields.filter(item => item.fieldName != [API_NAMES.SellInStatement__c.PeriodType__c]));
            self.afterLoad(self);
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    buildFieldWrapper(colFields) {
        let fieldsList = [];
        colFields.forEach((field, index, array) => {
            let fieldWrapper = {
                fieldLabel: field.fieldLabel,
                fieldHelpText: field.fieldHelpText,
                fieldName: field.fieldName,
                fieldType: field.fieldType,
                fieldRow: 3,
                pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                filter: field.fieldType != 'FORMULA',
                selectedValues: [],
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                _isNumber: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.includes('.'),
                isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isReferenceText: field.fieldName.includes('.') && (field.fieldType == 'STRING' || field.fieldType == 'REFERENCE'),
                isText: field.fieldType == 'STRING' && field.fieldType == 'REFERENCE',
                headerStyle: `${this.headerStyle} ${index === array.length - 1 ? 'border-right: #7f350f solid;' : ''}`,
                // isSortedUp: field.fieldName == API_NAMES.SellInStatement__c.ReferenceYear__c ? false : true,
                // cellTextAlignment: ColFieldsStyle[field.fieldName],
                value: field.fieldName == API_NAMES.SellInStatement__c.PeriodNumber__c,
                isDisplay: !field.fieldName.includes(API_NAMES.SellInStatement__c.PeriodNumber__c)
            };
            if (fieldWrapper.isReference) {
                fieldWrapper.headerStyle += 'min-width: 200px; max-width: 200px; '
            } else if (fieldWrapper.isReferenceText) {
                fieldWrapper.headerStyle += 'min-width: 200px; max-width: 200px; '
            } else if (fieldWrapper.isPicklist) {
                if (fieldWrapper.fieldName == API_NAMES.SellInStatementDetail__c.Status__c) {
                    fieldWrapper.headerStyle += 'min-width: 100px; min-height: 45px;';
                } else {
                    fieldWrapper.headerStyle += 'min-width: 130px; max-width: 130px; white-space: normal; '
                }
            } else if (fieldWrapper.fieldName == 'LBL_RequiredAction') {
                fieldWrapper.headerStyle += 'min-width: 160px; max-width: 160px; white-space: normal;'
            } else {
                fieldWrapper.headerStyle += 'min-width: 130px; max-width: 130px; white-space: normal; ';
            }
            fieldsList.push(fieldWrapper);
        });
        return fieldsList;
    }

    afterLoad(self) {
        self = self || this;
        loadData({
            resultWrapperJson: JSON.stringify(self.resultWrapper),
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            conditions: [...this.conditions, ...this.additionalConditions],
            orderBy: null
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.sellinStatementIds = [...new Set(parsedResult.records.map(item => item[API_NAMES.SellInStatementDetail__c.SellInStatement__c]))];;
            this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
            this.totalNumbOfRecords = parsedResult.totalSize;
            this.discFields = parsedResult.discFields;
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
                            class: 'slds-hide',
                            isAssiette: false,
                            isOpen: false,
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
                    if (item[API_NAMES.SellInStatementDetail__c.CustomBDate__c] && item[API_NAMES.SellInStatementDetail__c.CustomEDate__c]) {
                        formattedCustomBDate = new Intl.DateTimeFormat(USER_LOCALE, {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit'
                        }).format(new Date(item[API_NAMES.SellInStatementDetail__c.CustomBDate__c]));
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
                            class: 'slds-hide',
                            isAssiette: true,
                            isOpen: false,
                            records: [],
                        };
                        tmpTables.push(assietteTable);
                    }
                    //item[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodNumber__c] = formattedCustomBDate + ' - ' + formattedCustomEDate;
                    assietteTable.records.push(item);
                }
            });
            tmpTables.forEach(item => {
                item.recordsWrapperList = [...this.buildDataWrapper(item)];
            });
            // open first table
            this.activeMainAccordion = firstKey;
            let firstTable = tmpTables.find(item => item.key == firstKey);
            if (firstTable) {
                firstTable.isOpen = true;
                firstTable.class = 'main-table';
            }
            // add tables
            this.tables = tmpTables;
            self.sellinName = parsedResult.sellinStatementName ? parsedResult.sellinStatementName : self.sellinName;
            this.isLoading = false;
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    /* headrs button*/
    handleBack() {
        const openLink = () => {
            // create a element 
            let link = document.createElement('a');
            link.href = !this.isPortal ? '/lightning/n/' + this.prefix + 'SellinStatementList' : '/NegoptimConnect/sellin-statement-list';
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

    handleOpenModal(event) {
        this.flowInputVariables = [
            {
                name: this.flowInput.recordIds.name,
                type: this.flowInput.recordIds.type,
                value: this.sellinStatementIds
            },
        ]
        console.log('this.flowInputVariables: ' + JSON.stringify(this.flowInputVariables))
        this.showModal = true;
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
            this.handleError(error, 'handleflowStatusChange');
        }
    }

    downloadCSV() {
        let docName = `${this.labels.LBL_Connect_CollaborativeRestitution}-${(new Date()).toISOString().substring(0, 10)}`;

        // Create WorkBook and WorkSheet
        let workbook = new ExcelJS.Workbook();
        let worksheet = workbook.addWorksheet(docName);
        worksheet.properties.defaultRowHeight = 25;
        worksheet.properties.defaultColWidth = 20;
        // get fields
        const headerFields = this.fieldsWrapperList.filter(field => field.isDisplay).map(field => field.fieldLabel);
        const discHeaders = this.discHeaders.reduce((acc, header) => {
            const match = header.style.match(/background-color:\s*#([A-Fa-f0-9]+)/);
            const bgColor = match ? match[1] : null;

            acc[header.title] = {
                color: bgColor,
                title: header.title
            };

            return acc;
        }, {});


        console.log('discHeaders: ', JSON.stringify(discHeaders));
        console.log('discHeaders: ', JSON.stringify(Object.keys(discHeaders)))
        const subDiscHeaders = this.subDiscHeaders.map(header => header.title);
        const mergeRanges = [];
        const data = [];
        //
        let additionalHeaderFields = [this.headerPeriodType];
        this.tables.map(table => {
            const body = table.recordsWrapperList.map(recordWrapperList => {
                return recordWrapperList.columns.map(column => column.value);
            });
            data.push({
                title: table.headerLabel,
                body: body
            });
        });

        const fields = [
            [
                ...additionalHeaderFields,
                ...headerFields,
                ...this.discHeaders.flatMap(header => {
                    let arr = new Array(10).fill(null);
                    arr.unshift(header.title);
                    return arr;
                })
            ],
            [
                ...new Array(4).fill(null),
                ...this.subDiscHeaders.flatMap((header) => {
                    let arr = new Array((this.labels.LBL_TTM == header.title ? 4 : 2)).fill(null);
                    arr.unshift(header.title);
                    return arr;
                })
            ],
            [
                ...new Array(4).fill(null),
                ...this.disTitles.map(header => header.title)
            ]
        ];
        fields.forEach(field => {
            worksheet.addRow(field);
        });
        worksheet.addRow([]);

        // Add rows to the worksheet
        data.forEach(e => {
            // add title
            worksheet.addRow([e.title]);
            // add header
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
                    mergeRange = { startRow: rowNumber, startCol: colNumber, endRow: rowNumber + 2, endCol: colNumber };
                    fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF0D807D' } };
                    font = { color: { argb: 'FFFFFFFF' } };
                } else if (Object.keys(discHeaders).includes(cell.value)) {
                    mergeRange = { startRow: rowNumber, startCol: colNumber, endRow: rowNumber, endCol: colNumber + 10 };
                    const color = discHeaders[cell.value].color;
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
                if (addBorder || colNumber === 4 || (colNumber - 4) % 11 === 0) {
                    cell.border = {
                        right: { style: 'thick', color: { argb: '7f350f' } } // Thin black border on the right
                    };
                }
            });
        });

        mergeRanges.forEach(range => {
            worksheet.mergeCells(range.startRow, range.startCol, range.endRow, range.endCol);
        });

        // Write workbook to buffer and trigger download
        workbook.xlsx.writeBuffer().then(result => {
            self.isLoading = false;
            let a = document.createElement("a");
            document.body.appendChild(a);
            a.style = "display: none";
            let base64Bin = result.toString('base64');
            a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
            a.download = docName + '.xlsx';
            a.click();
        });
    }

    /*  */

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

    buildDataWrapper(data) {
        try {
            let periodNumber = '0';
            let periodType = '';
            data.records.forEach(row => {
                row.columns = [];
                periodType = row[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodNumber__c] > periodNumber ? row[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodType__c] : periodType;
                periodNumber = row[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodNumber__c] > periodNumber ? row[API_NAMES.SellInStatementDetail__c.SellInStatement__r][API_NAMES.SellInStatement__c.PeriodNumber__c] : periodNumber;
                // row.iconSource = row[API_NAMES.SellInStatement__c.StatusLogo__c];
                // row.iconTitle = this.statusPicklistOptions.find(item => item.value === row[API_NAMES.SellInStatement__c.Status__c]).label;
                let fields = JSON.parse(JSON.stringify(this.fieldsWrapperList));
                fields.forEach((field, index, array) => {
                    if (field.isReference) {
                        if (field.fieldName.endsWith('Id')) {
                            field.value = row[field.fieldName.replace(/Id$/, '')]?.Name;
                            field.style = 'min-width: 200px; max-width: 200px; '
                        } else {
                            field.value = row[field.fieldName.replace(/__c$/, '__r')]?.Name;
                            field.style = 'min-width: 200px; max-width: 200px; '
                        }
                        // field.link = '/' + row[field.fieldName];
                    }
                    else if (field.isReferenceText) {
                        let splitted_Field = field.fieldName.split('.');
                        if (field.fieldName.endsWith('Id')) {
                            field.value = row[splitted_Field[0].replace('Id', '')]?.Name;
                            field.style = 'min-width: 200px; max-width: 200px; '
                        } else {
                            field.value = row[splitted_Field[0].replace('__c', '__r')]?.Name;
                            field.style = 'min-width: 200px; max-width: 200px; '
                        }
                    } else if (field.isPicklist) {
                        if (field.fieldName == API_NAMES.SellInStatementDetail__c.Status__c) {
                            const iconName = `Connect_${row[field.fieldName].trim().replace(' ', '_')}`;
                            field.icon = true;
                            field.value = row[API_NAMES.SellInStatementDetail__c.Status__c];
                            field.style = 'min-width: 100px; min-height: 45px;';
                            field.link = `${PictosNegoptim2}/${row[API_NAMES.SellInStatement__c.StatusLogo__c]}.png`
                            field.title = this.statusPicklistOptions.find(item => item.value === row[API_NAMES.SellInStatement__c.Status__c]).label;
                            field.iconStyle =
                                `width: 25px; height: 25px;`
                        } else {
                            let found = field.pickListValues.find(item => item.value === row[field.fieldName]);
                            field.value = found?.label;
                            field.style = 'min-width: 130px; max-width: 130px; white-space: normal; '
                        }
                    } else if (field.fieldName == 'LBL_RequiredAction') {
                        let rawValue;
                        switch (row[API_NAMES.SellInStatementDetail__c.Status__c]) {
                            case 'Submitted':
                                rawValue = this.labels.LBL_SubmittedSellInStatementAction
                                break;
                            case 'Rejected':
                                rawValue = this.labels.LBL_RejectedSellInStatementAction
                                break;
                            case 'Validated':
                                rawValue = this.labels.LBL_ValidatedSellInStatementAction
                                break;
                            case 'In Preparation':
                                rawValue = this.labels.LBL_InPreparationSellInStatementAction
                            default:
                                break;
                        }
                        field.value = rawValue
                        field.style = 'min-width: 160px; max-width: 160px; white-space: normal;'
                    }
                    else {
                        let splitted_Field = field.fieldName.split('.');
                        if (splitted_Field.length > 1) {
                            if (field.isAssiette) {
                                field.value = row[API_NAMES.SellInStatementDetail__c.CustomBDate__c] + " - " + row[API_NAMES.SellInStatementDetail__c.CustomEDate__c]
                            } else {
                                field.value = row;
                                splitted_Field.forEach((key, index) => {
                                    key = index != splitted_Field.length - 1 ? (key.endsWith('Id') ? key.replace('Id', '') : (key.replace(/__c$/, '__r'))) : key;
                                    field.value = field.value[key] || '';
                                });
                            }
                            field.style = 'min-width: 130px; max-width: 130px; white-space: normal; ';
                        } else {
                            field.value = row[field.fieldName];
                            field.style = 'min-width: 130px; max-width: 130px; white-space: normal; ;'
                        }
                    }
                    if (index === array.length - 1)
                        field.style += 'border-right: #7f350f solid;'; // add borde on last field 
                    // center data
                    field.style += 'text-align: center;'
                });

                let discRecords = [];
                this.discFields.forEach((fieldName, index) => {
                    let modind = index % 7;
                    let field = { fieldName: fieldName, isNumber: true };
                    let splitted_Field = fieldName.split('.');
                    const isQuantityField = apiFields.quantityFields.includes(fieldName);
                    data
                    if (splitted_Field.length > 1) {
                        field.value = row;
                        splitted_Field.forEach((key, index) => {
                            key = index != splitted_Field.length - 1 ? (key.endsWith('Id') ? key.replace('Id', '') : (key.replace(/__c$/, '__r'))) : key;
                            field.value = field.value[key] || '';
                            field.style = `min-width: 130px; max-width: 130px; white-space: normal;  background-color: ${!apiFields.quantityFields.includes(key) ? '#e97033' : '#24a46d'}; color: white; font-weight: 700;`;

                        });
                    } else {
                        field.value = row[fieldName];
                        field.style = `min-width: 130px; max-width: 130px; white-space: normal; ${apiFields.ConnectSellInSfx.includes(fieldName) ? (!isQuantityField ? 'background-color: #dacbe7' : 'background-color: #aee3d9') : (!isQuantityField ? 'background-color: #fcf8ec' : 'background-color: #f3fbec')} `
                    }
                    discRecords.push(field);
                    if ([1, 3, 5].includes(modind)) {
                        let v1 = discRecords[discRecords.length - 1].value || 0;
                        let v2 = discRecords[discRecords.length - 2].value || 0;
                        let _field = JSON.parse(JSON.stringify(field));
                        _field.value = (v2 ? (v1 - v2) / v2 : 0) * 100;
                        _field.isStable = (v2 ? (v1 - v2) / v2 : 0) * 100 < 0;
                        _field.isPercent = true;
                        _field.arrowIcon = modind == 1
                        _field.isNumber = false;
                        _field.style = `min-width: 130px; max-width: 130px; white-space: normal;`
                        discRecords.push(_field);
                    }
                    if (modind == 6) {
                        let v1 = discRecords[discRecords.length - 1].value || 0;
                        let v2 = discRecords[discRecords.length - 3].value || 0;
                        let _field = JSON.parse(JSON.stringify(field));
                        _field.value = v2 - v1;
                        _field.style = `min-width: 130px; max-width: 130px; white-space: normal; border-right: #7f350f solid;`
                        discRecords.push(_field);
                    }
                });
                row.columns = [...JSON.parse(JSON.stringify(fields)), ...discRecords];
            });
            //this.buildRullerField(periodNumber, periodType);
            return data.records;
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
            this.tables = [];
            this.afterLoad(this);
        } catch (error) {
            console.error(error)
        }
    }
    handleChangePageSize(event) {
        this.isLoading = true;
        try {
            this.pageSize = parseInt(event.target.value);
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value == this.pageSize;
            }
            this.pageNumber = 1;
            this.tables = [];
            this.afterLoad(this);
        }
        catch (error) {
            console.error('error: ' + error);
        }
    }

    toggleSection(event) {
        let key = event.target.dataset.key;
        let item = this.tables.find(item => item.key == key);
        item.class = item.class == 'main-table' ? 'slds-hide' : 'main-table';
        item.isOpen = !item.isOpen;
    }

    setPageSize = () => {
        try {
            const mainContainer = this.template.querySelector(".mainContainer");
            const mainTemplate = this.template.querySelector(".main-template");
            const pageHeader = this.template.querySelector(".header");
            const pageBodyDiv = this.template.querySelector(".bodyDiv");
            const footerDiv = this.template.querySelector(".footerDiv");

            if (mainTemplate && pageHeader && pageBodyDiv && footerDiv) {
                const windowHeight = window.innerHeight;
                const windorWidth = window.innerWidth;
                const headerHeight = pageHeader.offsetHeight;
                const FooterHeight = footerDiv.offsetHeight;
                if (windorWidth > 1000 && !mainTemplate.classList.contains('mainContainer')) {
                    mainTemplate.classList.add('mainContainer');
                } else if (windorWidth < 1000 && mainTemplate.classList.contains('mainContainer')) {
                    mainTemplate.classList.remove('mainContainer');
                }

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
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        }));
    }
    @track nbOfFixedColumns = 4;
    handleNumberOfFixedColumns(event) {
        this.nbOfFixedColumns = parseInt(event.detail.value);
    }
    setnumberOfFixedColumns() {
        let tables = this.template.querySelectorAll('.main-table');
        let headers = this.template.querySelectorAll('.main-header');
        for (const table of tables) {
            let tableTrs = table?.rows
            if (tableTrs) {
                let top = 0;
                for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                    let childrens = tableTrs[index].children;
                    let left = 0;
                    for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                        if (index2 < this.nbOfFixedColumns) {
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.left = (left - (index2 + 1)) + 'px';
                            childrens[index2].style.zIndex = 1;
                            left += childrens[index2].offsetWidth;
                            childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                        } else {
                            childrens[index2].style.position = 'unset';
                            childrens[index2].style.left = 'unset';
                            childrens[index2].style.zIndex = 'unset';
                        }
                        if (childrens[index2].classList.contains('fixedHeader')) {
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.top = top + 'px';
                            if (index2 == childrens.length - 1) {
                                top += childrens[index2].offsetHeight;
                            }
                            childrens[index2].style.zIndex = childrens[index2].textContent == '' ? 5 : 4;
                        }
                    }
                }
            }
        }
        let left = 0;
        for (let index = 0; headers && index < headers.length; index++) {
            let childrens = headers[index];
            if (index < this.nbOfFixedColumns) {
                childrens.style.position = 'sticky';
                childrens.style.left = ((left - (index + 1)) + 'px');
                childrens.style.zIndex = 1;
                left += childrens.offsetWidth;
            } else {
                childrens.style.position = 'relative';
                childrens.style.left = 'unset';
                childrens.style.zIndex = 'unset';
            }
        }
    }




    // filter 
    statusOptions = [
        {
            "value": "In Preparation",
            "label": "En préparation"
        },
        {
            "value": "Submitted",
            "label": "Soumis"
        },
        {
            "value": "Validated",
            "label": "Validé"
        },
        {
            "value": "Rejected",
            "label": "Rejeté"
        }
    ]
    @track filterState = false;
    filter = {
        status: ''
    }

    openFilter() {
        this.filterState = !this.filterState;
    }
    closeFilter() {
        this.filterState = false;
    }

    handleFilterInput(event) {
        const field = event.target.dataset.field;
        this.filter[field] = event.target.value;
    }
    handleRestFilter() {
        this.filter = {
            status: [],
            businessUnit: '',
            periodNumber: ''
        }
        this.filterState = false;
        this.additionalConditions = [];
        this.init(this);
    }
    handleApplyFilter() {
        const conditions = Object.keys(this.filter)
            .filter(key => {
                const value = this.filter[key];
                return Array.isArray(value) ? value.length > 0 : value;
            })
            .map(key => {
                let condition = '';
                switch (key) {
                    case 'status':
                        condition = `${API_NAMES.SellInStatement__c.Status__c} in (${this.filter[key]
                            .map(val => `'${val}'`).join(',')})`;
                        break;
                    case 'businessUnit':
                        condition = `${API_NAMES.SellInStatementDetail__c.BusinessUnit__c} like '%${this.filter[key]}%'`;
                        break;
                    case 'periodNumber':
                        condition = `${API_NAMES.SellInStatementDetail__c.SellInStatement__r}.${API_NAMES.SellInStatement__c.PeriodNumber__c} = ${this.filter[key]}`;
                        break;
                }
                return condition;
            });
        this.additionalConditions = conditions;
        this.filterState = false;
        this.init(this);

    }

}