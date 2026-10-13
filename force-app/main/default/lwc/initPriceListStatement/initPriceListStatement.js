import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
//APEX
import initData from '@salesforce/apex/InitPriceListStatementController.initData';
import loadData from '@salesforce/apex/InitPriceListStatementController.loadData';
import runInitPriceListStatementBatch from '@salesforce/apex/InitPriceListStatementController.runInitPriceListStatementBatch';
import { checkCompletedBatches, showNotification } from 'c/appHelper';
//IMPORTS
import { API_NAMES, Labels, PopupPriceListFields } from './properties.js';

export default class InitPriceListStatement extends LightningElement {
    @api negoScopeId;
    labels = { ...Labels }
    @track API_NAMES = { ...API_NAMES }
    initDataWrapper;
    @track isLoading = false;
    @track pageSize = 50;
    @track pageNumber = 1;
    totalPagesCount = 0;
    panelTop = 0;
    panelHeight = 0;
    get yearOptions() {
        let currentYear = new Date().getFullYear();
        return [
            { label: '' + (currentYear + 2), value: '' + (currentYear + 2) },
            { label: '' + (currentYear + 1), value: '' + (currentYear + 1) },
            { label: '' + (currentYear), value: '' + currentYear },
            { label: '' + (currentYear - 1), value: '' + (currentYear - 1) },
            { label: '' + (currentYear - 2), value: '' + (currentYear - 2) }
        ]
    };
    @track searchBUFields = ['Name'];
    Events = {
        selectBUAction: 'selectbuaction',
        selectNegoScopeAction: 'selectnegoscopeaction',
    }
    get buFilterToken() {
        let conditions = [];
        conditions.push('SetPriceListStatement__c = TRUE');
        return conditions;
    }
    @track fieldsWrapperList = [];
    @track recordsWrapperList = [];
    @track openInitPriceListPopup = false;
    @track openConfirmationPopup = false;
    @track popupPriceListFields = { ...PopupPriceListFields };
    @track filterWrapper = {};
    @track priceListStatementConditions = [];
    @track nsConditions = [];
    @track totalNumbOfRecords = 0;
    @track initPriceListStatementConfirmationMsg = '';
    @track selectedYear;
    @track selectedBUId;
    @track selectedBUName;
    @track sendYear;
    @track sendBUTargetId;
    @track sendBUSourceId;
    @track sendBUTargetName;
    @track sendBUSourceName;
    // Ticket W-009158
    @track sendType = 'RiseRate';
    @track sendApplicationDate;
    @track sendNegoScopeId;
    @track sendNegoScopeName;
    @track typeOptions = [];
    get searchNSFields() {
        return ['Name', API_NAMES.NegoScope__c.CodeLong__c];
    }
    checkStyle = 'background-color: #08484B;';
    negoScopeHeaderStyle = 'background-color: #08484B;color:white;min-width:100px;';
    priceListHeaderStyle = 'background-color: #14B3BB;color:white;';
    pageSizeOptions = [
        { label: '5', value: 5, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        { label: '250', value: 250, isSelected: false }
    ];
    // Prevents duplicate headers when component  mounted twice
    _ownsHeader = false;
    static HEADER_SENTINEL = '__InitPLS_HeaderMounted__';
    @track showHeaderFilters = false;
    @track isFilterOpen = false;
    @wire(getObjectInfo, { objectApiName: API_NAMES.PriceListStatement__c.objectApiName }) wiredPls({ data }) {
        if (!data) return;
        const f = data.fields;
        PopupPriceListFields.ReferenceYear__c.fieldLabel = f[API_NAMES.PriceListStatement__c.ReferenceYear__c]?.label ?? PopupPriceListFields.ReferenceYear__c.fieldLabel;
        PopupPriceListFields.BusinessUnitTarget__c.fieldLabel = f[API_NAMES.PriceListStatement__c.BusinessUnitTarget__c]?.label ?? PopupPriceListFields.BusinessUnitTarget__c.fieldLabel;
        PopupPriceListFields.BusinessUnitSource__c.fieldLabel = f[API_NAMES.PriceListStatement__c.BusinessUnitSource__c]?.label ?? PopupPriceListFields.BusinessUnitSource__c.fieldLabel;
        PopupPriceListFields.ApplicationDateRequested__c.fieldLabel = f[API_NAMES.PriceListStatement__c.ApplicationDateRequested__c]?.label ?? PopupPriceListFields.ApplicationDateRequested__c.fieldLabel;
        PopupPriceListFields.NegoScope__c.fieldLabel = f[API_NAMES.PriceListStatement__c.NegoScope__c]?.label ?? PopupPriceListFields.NegoScope__c.fieldLabel;
    }

    showBusy(msg) {
        this.isLoading = true;
    }
    hideBusy() {
        this.isLoading = false;
    }
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.totalNumbOfRecords ? this.pageNumber * pageSize + 1 - pageSize : this.totalNumbOfRecords - this.recordsLength) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
    }

    get contentRightInsetStyle() {
        return this.isFilterOpen ? 'margin-right:26rem;' : '';
    }
    get filterList() {
        let filter = [];
        let NSfilter = [];
        try {
            for (let field in this.filterWrapper) {
                if (this.filterWrapper[field].isSearchable) {
                    let ffilter = '';
                    if (this.filterWrapper[field].type == 'text' && this.filterWrapper[field].valuesList.length != 0) {
                        ffilter = '(' + this.filterWrapper[field].valuesList.map(item => ` ${field} LIKE '%${item.trim()}%' `).join(' OR ') + ')';
                    } else if (this.filterWrapper[field].type == 'picklist' && this.filterWrapper[field].valuesList.length != 0) {
                        ffilter = '' + field + ' IN (\'' + this.filterWrapper[field].valuesList.join('\', \'') + '\')';
                    } else if (this.filterWrapper[field].type == 'number') {
                        let filter1 = [];
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            // filter1 += '' + field + ' >= ' + this.filterWrapper[field].value1;
                            filter1.push('' + field + ' >= ' + this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            // ffilter += '' + field + ' <= ' + this.filterWrapper[field].value2;
                            filter1.push('' + field + ' <= ' + this.filterWrapper[field].value2);
                        }
                        ffilter = filter1?.join(' AND ');
                    } else if (this.filterWrapper[field].type == 'date') {
                        const isDT = this.filterWrapper[field].isDateTime === true;
                        const v1 = this.filterWrapper[field].value1;
                        const v2 = this.filterWrapper[field].value2;
                        const parts = [];
                        if (v1) {
                            parts.push(isDT ? `${field} >= ${new Date(`${v1}T00:00:00.000Z`).toISOString()}` : `${field} >= ${v1}`);
                        }
                        if (v2) {
                            parts.push(isDT ? `${field} <= ${new Date(`${v2}T23:59:59.999Z`).toISOString()}` : `${field} <= ${v2}`);
                        }
                        ffilter = parts.join(' AND ');
                    }
                    if (ffilter) {
                        this.filterWrapper[field].isNS ? NSfilter.push(ffilter) : filter.push(ffilter);
                    }
                }
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
        return { 'NSFilters': NSfilter, 'priceListStatementFilters': filter };
    };

    get selectedBUIdSerialized() {
        return this.selectedBUId ? JSON.stringify(this.selectedBUId) : '';
    }
    get sendBUTargetIdSerialized() {
        return this.sendBUTargetId ? JSON.stringify(this.sendBUTargetId) : '';
    }
    get sendBUSourceIdSerialized() {
        return this.sendBUSourceId ? JSON.stringify(this.sendBUSourceId) : '';
    }
    get sendNegoScopeIdSerialized() {
        return this.sendNegoScopeId ? JSON.stringify(this.sendNegoScopeId) : '';
    }

    get selectedYearStr() {
        // return this.selectedYear ? this.selectedYear + '' : '';
        return (this.selectedYear || this.selectedYear === 0) ? String(this.selectedYear) : '';
    }

    get colspanDisplayedFields() {
        return this.fieldsWrapperList.length;
    }
    get showHeader() { return this._ownsHeader; }
    //LIFECYCLE
    connectedCallback() {
        this.init();
        addEventListener('resize', this.setPageSize);
        window.addEventListener('resize', this.changeHeight);
        window.addEventListener('scroll', this.changeHeight, { passive: true });
        // Guard: only the first live instance owns the header
        if (!window[InitPriceListStatement.HEADER_SENTINEL]) {
            window[InitPriceListStatement.HEADER_SENTINEL] = true;
            this._ownsHeader = true;
        } else {
            this._ownsHeader = false;
        }
    }
    disconnectedCallback() {
        if (this._ownsHeader) {
            window[InitPriceListStatement.HEADER_SENTINEL] = false;
        }
        window.removeEventListener('resize', this.changeHeight);
        window.removeEventListener('scroll', this.changeHeight);
    }

    renderedCallback() {
        this.setPageSize();
        this.changeHeight();
    }

    changeHeight = () => {
        try {
            const panel = this.template.querySelector('.main-panel');
            if (!panel) return;
            const header = this.template.querySelector('[data-pls-header="true"]');
            const footer = this.template.querySelector('.footerDiv');
            const headerBottomVp = header ? header.getBoundingClientRect().bottom : 0;
            const footerTopVp = footer ? footer.getBoundingClientRect().top : window.innerHeight;
            const h = Math.max(200, footerTopVp - headerBottomVp);
            panel.style.height = h + 'px';
            const host = panel.querySelector('.scrollHost');
            if (host) host.style.height = h + 'px';
            this.panelTop = Math.max(0, headerBottomVp);
            this.panelHeight = h;
            const root = this.template?.host;
            if (root && root.style) {
                root.style.setProperty('--pls-filter-top', `${this.panelTop}px`);
                root.style.setProperty('--pls-filter-height', `${this.panelHeight}px`);
            }
        } catch (e) { /* no-op */ }
    }

    get filterPanelStyle() {
        const top = Math.round(this.panelTop || 0);
        const height = Math.round(this.panelHeight || 0);
        return `position:fixed; right:12px; width:26rem; overflow:auto; z-index:7000; top:${top}px; height:${height}px; display:flex; flex-direction:column;`;
    }

    init() {
        this.showBusy(this.labels?.LBL_Loading);
        initData({ negoScopeId: this.negoScopeId })
            .then(result => {
                let parsedResult = JSON.parse(result);
                this.initDataWrapper = parsedResult;
                this.fieldsWrapperList = this.buildFieldWrapper(parsedResult)
                // W-009158: Set record type options from initData
                if (parsedResult.recordTypes) {
                    this.typeOptions = Object.entries(parsedResult.recordTypes).map(([devName, label]) => ({
                        label: label,
                        value: devName
                    }));
                }
                // W-008811: Year & BU must start EMPTY in header filters
                this.selectedBUId = '';
                this.selectedBUName = '';
                this.selectedYear = null;
                // W-009158: Set defaults for popup fields
                this.resetPopupDefaults();
                this.afterLoad();
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.hideBusy();
            })
    }
    buildFieldWrapper(parsedResult) {
        let fieldsList = [];
        parsedResult.negoScopeFields.forEach(field => {
            fieldsList.push({
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldName: field.fieldName,
                fieldType: field.fieldType,
                fieldScale: field.fieldScale,
                pickListValues: field.pickListValues ? field.pickListValues : [],
                selectedValues: [],
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                isReference: field.fieldType == 'REFERENCE' || field.fieldName == 'Name',
                isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                isDateTime: field.fieldType == 'DATETIME',
                isCreatedDate: field.fieldName === 'CreatedDate',
                filterPopoverClass: 'slds-hide slds-dropdown slds-p-around_x-small filter-popover',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isReferenceText: field.fieldType == 'STRING' || field.fieldType == 'REFERENCE',
                isText: field.fieldType == 'STRING' && field.fieldType == 'REFERENCE',
                headerClass: 'centerText relativeDiv header--nego',
                isNSField: true,
                isPLSField: false,
                filterKey: `NS__${field.fieldName}`,
                isYearRange: field.fieldName === 'ReferenceYear__c',
                value: null,
            });
        });
        (parsedResult.priceListStatementFields || []).forEach(field => {
            fieldsList.push({
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldName: field.fieldName,
                fieldType: field.fieldType,
                fieldScale: field.fieldScale,
                pickListValues: field?.picklistValues ? field?.picklistValues : [],
                selectedValues: [],
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                isReference: field.fieldType == 'REFERENCE' || field.fieldName == 'Name',
                isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                isDateTime: field.fieldType == 'DATETIME',
                isCreatedDate: field.fieldName === 'CreatedDate',
                filterPopoverClass: 'slds-hide slds-dropdown slds-p-around_x-small filter-popover',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isReferenceText: field.fieldType == 'STRING' || field.fieldType == 'REFERENCE',
                isText: field.fieldType == 'STRING',
                headerClass: 'centerText relativeDiv header--pls',
                isNSField: false,
                isPLSField: true,
                filterKey: `PLS__${field.fieldName}`,
                isYearRange: field.fieldName === 'ReferenceYear__c',
                value: null,
            });
        });
        return fieldsList;
    }
    afterLoad() {
        this.showBusy(this.labels.LBL_Loading);
        console.log('priceListStatementConditions >>> ' + JSON.stringify(this.priceListStatementConditions))
        console.log('nsConditions >>> ' + JSON.stringify(this.nsConditions))
        loadData({
            negoScopeId: this.negoScopeId,
            selectedYear: this.selectedYear,
            selectedBUId: this.selectedBUId,
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            priceListStatementConditions: this.priceListStatementConditions,
            nsConditions: this.nsConditions,
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
            this.totalNumbOfRecords = parsedResult.totalSize;
            this.recordsWrapperList = [...this.buildDataWrapper(parsedResult.records)];
            console.log('this.recordsWrapperList >>>> ' + JSON.stringify(this.recordsWrapperList))
            this.hideBusy();
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.hideBusy();
        })
    }

    buildDataWrapper(data) {
        const out = [];
        (data || []).forEach(group => {
            const plsArray = (Array.isArray(group.priceListStatements) && group.priceListStatements.length) ? group.priceListStatements : [{}];
            const row = {
                Id: group.negoScope?.Id,
                columns: [],
                priceListStatements: []
            };
            let fields = JSON.parse(JSON.stringify(this.fieldsWrapperList));
            fields.filter(field => field.isNSField).forEach(field => {
                const rowData = group.negoScope;
                if (!rowData) {
                    field.value = null
                    return;
                }
                if (field.isReference) {
                    if (field.fieldName.endsWith('Id')) {
                        field.value = rowData[field.fieldName.replace('Id', '')]?.Name;
                    } else if (field.fieldName != 'Name') {
                        field.value = rowData[field.fieldName.replace('__c', '__r')]?.Name;
                    } else {
                        field.value = rowData[field.fieldName]
                    }
                    field.link = field.fieldName != 'Name' ? '/' + rowData[field.fieldName] : '/' + rowData.Id;
                } else if (field.isPicklist) {
                    const found = field.pickListValues.find(it => it.value === rowData[field.fieldName]);
                    field.value = found?.label;
                } else {
                    field.value = rowData[field.fieldName];
                }
                row.columns.push(field);
            });
            plsArray.forEach(pls => {
                fields = JSON.parse(JSON.stringify(this.fieldsWrapperList));
                const plsWrapper = {
                    Id: pls.Id,
                    columns: [],
                };
                fields.filter(field => field.isPLSField).forEach(field => {
                    const rowData = pls;
                    if (!rowData) {
                        field.value = null
                        return;
                    }
                    if (field.isReference) {
                        if (field.fieldName.endsWith('Id')) {
                            field.value = rowData[field.fieldName.replace('Id', '')]?.Name;
                        } else if (field.fieldName != 'Name') {
                            field.value = rowData[field.fieldName.replace('__c', '__r')]?.Name;
                        } else {
                            field.value = rowData[field.fieldName]
                        }
                        field.link = field.fieldName != 'Name' ? '/' + rowData[field.fieldName] : '/' + rowData.Id;
                    } else if (field.isPicklist) {
                        const found = field.pickListValues.find(it => it.value === rowData[field.fieldName]);
                        field.value = found?.label;
                    } else {
                        field.value = rowData[field.fieldName];
                    }
                    plsWrapper.columns.push(field);
                });
                row.priceListStatements.push(plsWrapper)
            });
            out.push(row);
        });
        return out;
    }

    toggleFilterPanel(event) {
        try {
            // let field = event.target.dataset.field;
            // this.template.querySelectorAll('[data-filter-field]').forEach(element => {
            //     if (element.dataset.filterField == field) {
            //         element.classList.toggle('slds-hide');
            //     } else {
            //         element.classList.add('slds-hide');
            //     }
            // });
            // Use currentTarget and the unique filterKey bound in HTML
            const fieldKey = (event.currentTarget && event.currentTarget.dataset.field)
                || (event.target && event.target.dataset.field);
            if (!fieldKey) return;
            this.template.querySelectorAll('[data-filter-field]').forEach(el => {
                if (el.dataset.filterField === fieldKey) {
                    el.classList.toggle('slds-hide');
                } else {
                    el.classList.add('slds-hide');
                }
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleChangeFilter(event) {
        try {
            const fieldKey = (event.currentTarget?.dataset?.field) || (event.target?.dataset?.field);
            const dsType = (event.currentTarget?.dataset?.type) || (event.target?.dataset?.type) || event.target?.type;
            const number = (event.currentTarget?.dataset?.number) || (event.target?.dataset?.number);
            const isNS = ((event.currentTarget?.dataset?.nsfield) || (event.target?.dataset?.nsfield)) === 'true';
            const value = (event.detail && event.detail.value !== undefined) ? event.detail.value : event.target?.value;
            const field = this.fieldsWrapperList.find(f => f.filterKey === fieldKey);
            if (!field) return;
            let soqlFieldName = field.fieldName;
            if (field.isReference) {
                if (field.fieldName.endsWith('Id')) {
                    soqlFieldName = field.fieldName.replace('Id', '.Name');
                } else {
                    soqlFieldName = field.fieldName.replace('__c', '__r.Name');
                }
            }
            if (this.filterWrapper[soqlFieldName] == null) {
                this.filterWrapper[soqlFieldName] = {};
            }
            const type = (dsType === 'year') ? 'number' : dsType;
            if (type === 'text') {
                const valuesList = (value != null && value !== '') ? value.split(',') : [];
                this.filterWrapper[soqlFieldName].valuesList = valuesList.map(it => it.trim());
                field.isFiltered = valuesList.length !== 0;
                field.fieldSearchValue = value;
            } else if (type === 'number' || type === 'date' || type === 'datetime') {
                if (type === 'datetime') {
                    const selectedDate = value ? new Date(value) : null;
                    if (selectedDate) {
                        if (number === '1') {
                            selectedDate.setUTCHours(0, 0, 0, 0);
                            field.fieldSearchValue1 = selectedDate.toISOString();
                        } else if (number === '2') {
                            selectedDate.setUTCHours(23, 59, 59, 999);
                            field.fieldSearchValue2 = selectedDate.toISOString();
                        }
                        this.filterWrapper[soqlFieldName][`value${number}`] = selectedDate;
                    }
                } else {
                    field[`fieldSearchValue${number}`] = value;
                    this.filterWrapper[soqlFieldName][`value${number}`] = value;
                }
                if (type === 'date') {
                    const v1 = field.fieldSearchValue1;
                    const v2 = field.fieldSearchValue2;
                    if (v1 && v2 && new Date(v2) < new Date(v1)) {
                        showNotification(this, 'Warning', 'TO date should be after FROM date', 'warning', 'dismissable');
                        if (number === '2') {
                            field.fieldSearchValue2 = '';
                            this.filterWrapper[soqlFieldName].value2 = '';
                        } else {
                            field.fieldSearchValue1 = '';
                            this.filterWrapper[soqlFieldName].value1 = '';
                        }
                    }
                }
                field.isFiltered =
                    (field.fieldSearchValue1 != null && field.fieldSearchValue1 !== '') ||
                    (field.fieldSearchValue2 != null && field.fieldSearchValue2 !== '');
            }
            this.filterWrapper[soqlFieldName].type = type;
            this.filterWrapper[soqlFieldName].isNS = isNS;
            this.filterWrapper[soqlFieldName].isSearchable = true;
            this.filterWrapper[soqlFieldName].isDateTime = !!field.isDateTime;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handlePicklistChange(event) {
        try {
            const fieldKey = (event.currentTarget?.dataset?.field) || (event.target?.dataset?.field);
            const value = event.detail.value;
            const field = this.fieldsWrapperList.find(f => f.filterKey === fieldKey);
            if (!field) return;
            let soqlFieldName = field.fieldName;
            if (field.isReference) {
                if (field.fieldName.endsWith('Id')) {
                    soqlFieldName = field.fieldName.replace('Id', '.Name');
                } else {
                    soqlFieldName = field.fieldName.replace('__c', '__r.Name');
                }
            }
            if (this.filterWrapper[soqlFieldName] == null) {
                this.filterWrapper[soqlFieldName] = {};
            }
            if (this.filterWrapper[soqlFieldName].valuesList == null) {
                this.filterWrapper[soqlFieldName].valuesList = [];
            }
            this.filterWrapper[soqlFieldName].type = 'picklist';
            field.isFiltered = value.length !== 0;
            field.selectedValues = value;
            this.filterWrapper[soqlFieldName].isSearchable = true;
            this.filterWrapper[soqlFieldName].valuesList = value;
            this.filterWrapper[soqlFieldName].isNS = field.isNSField === true;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleApplyFilters(event) {
        try {
            this.showBusy(this.labels.LBL_Loading);
            this.priceListStatementConditions = [...this.filterList.priceListStatementFilters];
            this.nsConditions = [...this.filterList.NSFilters];
            this.pageNumber = 1;
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    resetFilters(skipReload = false) {
        try {
            this.filterWrapper = {};
            this.fieldsWrapperList.forEach(field => {
                if (field.isReferenceText) {
                    field.fieldSearchValue = '';
                } else if (field.isNumberField || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                if (field.isFiltered) {
                    field.isFiltered = false;
                }
            });
            this.priceListStatementConditions = [];
            this.nsConditions = [];
            if (!skipReload) {
                this.pageNumber = 1;
                this.showBusy(this.labels.LBL_Loading);
                this.afterLoad();
            }
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    loadPriceListStatementEmpty() {
        try {
            this.filterWrapper = {};
            this.fieldsWrapperList.forEach(field => {
                if (field.isReferenceText) {
                    field.fieldSearchValue = '';
                } else if (field.isNumberField || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                if (field.isFiltered) {
                    field.isFiltered = false;
                }
            });
            this.showBusy(this.labels.LBL_Loading);
            this.priceListStatementConditions = [];
            this.nsConditions = [];
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleOpenInitPriceListPopup(event) {
        this.openInitPriceListPopup = true;
    }

    resetPopupDefaults() {
        const nextYear = new Date().getFullYear() + 1;
        this.sendYear = String(nextYear);
        this.sendApplicationDate = `${nextYear}-01-01`;
        const hasRiseRate = this.typeOptions.find(opt => opt.value === 'RiseRate');
        this.sendType = hasRiseRate ? 'RiseRate' : (this.typeOptions.length > 0 ? this.typeOptions[0].value : '');
        if (this.negoScopeId && this.initDataWrapper?.negoScopeId) {
            this.sendNegoScopeId = this.initDataWrapper.negoScopeId;
            const nsRecord = this.recordsWrapperList.find(r => r.Id === this.initDataWrapper.negoScopeId);
            if (nsRecord) {
                const nameCol = nsRecord.columns.find(c => c.fieldName === 'Name');
                this.sendNegoScopeName = nameCol?.value || '';
            } else {
                this.sendNegoScopeName = '';
            }
            if (this.initDataWrapper.buId) {
                this.sendBUTargetId = this.initDataWrapper.buId;
                this.sendBUTargetName = this.initDataWrapper.buName || '';
            } else {
                this.sendBUTargetId = this.sendBUTargetName = '';
            }
        } else {
            this.sendNegoScopeId = this.sendNegoScopeName = this.sendBUTargetId = this.sendBUTargetName = '';
        }
        this.sendBUSourceId = this.sendBUSourceName = '';
    }
    handleSendYearChange(event) {
        this.sendYear = event.detail.value;
        if (this.sendYear) {
            this.sendApplicationDate = `${this.sendYear}-01-01`;
        }
    }
    handleSendTypeChange(event) {
        this.sendType = event.detail.value;
    }
    handleSendApplicationDateChange(event) {
        this.sendApplicationDate = event.detail.value;
    }
    selectNegoScopeAction(event) {
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            this.sendNegoScopeName = event.detail.selRecords[0].recName;
            this.sendNegoScopeId = event.detail.selRecords[0].recId;
            this.fetchNSBusinessUnit(this.sendNegoScopeId);
        } else {
            this.sendNegoScopeName = '';
            this.sendNegoScopeId = '';
            this.sendBUTargetId = '';
            this.sendBUTargetName = '';
        }
    }
    fetchNSBusinessUnit(nsId) {
        const nsRecord = this.recordsWrapperList.find(r => r.Id === nsId);
        if (nsRecord && this.initDataWrapper) {
            if (this.initDataWrapper.negoScopeId === nsId && this.initDataWrapper.buId) {
                this.sendBUTargetId = this.initDataWrapper.buId;
                this.sendBUTargetName = this.initDataWrapper.buName || '';
            }
        }
    }
    selectRunBUAction(event) {
        let target = event.target.dataset.target;
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            if (target == 'buTarget') {
                this.sendBUTargetName = event.detail.selRecords[0].recName;
                this.sendBUTargetId = event.detail.selRecords[0].recId;
            } else {
                this.sendBUSourceName = event.detail.selRecords[0].recName;
                this.sendBUSourceId = event.detail.selRecords[0].recId;
            }
        } else {
            if (target == 'buTarget') {
                this.sendBUTargetName = '';
                this.sendBUTargetId = '';
            } else {
                this.sendBUSourceName = '';
                this.sendBUSourceId = '';
            }
        }
    }
    selectBUAction(event) {
        const prevId = this.selectedBUId || '';
        const prevName = this.selectedBUName || '';
        let newId = '';
        let newName = '';
        if (event?.detail?.selRecords && event.detail.selRecords.length > 0) {
            newName = event.detail.selRecords[0].recName || '';
            newId = event.detail.selRecords[0].recId || '';
        }
        this.selectedBUName = newName;
        this.selectedBUId = newId;
        const unchanged = (prevId || '') === (newId || '');
        if (unchanged) {
            return;
        }
        this.pageNumber = 1;
        this.afterLoad();
    }

    // Right panel handlers
    toggleFilter = () => { this.isFilterOpen = !this.isFilterOpen; }
    openFilter = () => { this.isFilterOpen = true; }
    closeFilter = () => { this.isFilterOpen = false; }
    handleHeaderYearChange = (event) => { this.selectedYear = event.detail.value ? parseInt(event.detail.value, 10) : null; }
    handleHeaderBUSelected = (event) => {
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            this.selectedBUName = event.detail.selRecords[0].recName || '';
            this.selectedBUId = event.detail.selRecords[0].recId || '';
        } else {
            this.selectedBUName = ''; this.selectedBUId = '';
        }
    }
    applyHeaderFilters = () => {
        this.pageNumber = 1;
        this.afterLoad();
        this.closeFilter();
    }
    resetAllFilters = () => {
        this.resetFilters(true);
        this.selectedYear = null;
        this.selectedBUId = '';
        this.selectedBUName = '';
        this.pageNumber = 1;
        this.afterLoad();
        this.closeFilter();
    }
    handleGeneratePriceListStatement() {
        const inputs = [...this.template.querySelectorAll('.requiredField')];
        const allValid = inputs.every((cmp) => {
            const canValidate = typeof cmp.reportValidity === 'function' && typeof cmp.checkValidity === 'function';
            return canValidate ? (cmp.reportValidity(), cmp.checkValidity()) : true;
        });
        if (!this.sendType || !this.sendYear || !this.sendApplicationDate || !this.sendNegoScopeId) {
            showNotification(this, this.labels.LBL_Error, this.labels.MSG_Fill_Required_Fields, 'error', 'dismissable');
            return;
        }
        if (allValid) {
            this.openInitPriceListPopup = false;
            this.initPriceListStatementConfirmationMsg = this.labels.MSG_InitPriceListStatementConfirmation.replace('{0}', this.sendYear).replace('{1}', this.sendBUTargetName).replace('{2}', this.sendBUSourceName);
            this.openConfirmationPopup = true;
        }
    }
    handleConfirmInitPriceList(event) {
        this.openConfirmationPopup = false;
        this.showBusy('Sending...');
        this.handleRunInitPriceListStatementBatch();
    }
    handleClosePopup() {
        this.openInitPriceListPopup = false;
        this.openConfirmationPopup = false;
    }
    handleRunInitPriceListStatementBatch() {
        const buTargetIdOrNull = this.sendBUTargetId || null;
        const buSourceIdOrNull = this.sendBUSourceId || null;
        runInitPriceListStatementBatch({
            negoScopeId: this.sendNegoScopeId,
            recordTypeId: this.sendType,
            selectedBUTargetId: buTargetIdOrNull,
            selectedBUSourceId: buSourceIdOrNull,
            selectedYear: this.sendYear,
            applicationDate: this.sendApplicationDate,
        }).then(batchId => {
            if (batchId != null) {
                checkCompletedBatches(this, batchId).then(result => {
                    this.pageNumber = 1;
                    this.afterLoad();
                }).catch(error => {
                    console.error(error);
                });
            } else {
                this.afterLoad();
            }
        }).catch(error => {
            console.log(error);
            this.hideBusy();
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'dismissable');
        });
    }
    handleChangePage(event) {
        this.showBusy(this.labels.LBL_Loading);
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
            const newSize = parseInt(event.target.value, 10);
            if (!Number.isFinite(newSize) || newSize === this.pageSize) {
                return;
            }
            this.showBusy(this.labels.LBL_Loading);
            this.pageSize = newSize;
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value === this.pageSize;
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
                const remainingHeight = windowHeight - headerHeight - FooterHeight - 150;
                pageBodyDiv.style.height = remainingHeight + "px";
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    };
    //Utility Methods

}