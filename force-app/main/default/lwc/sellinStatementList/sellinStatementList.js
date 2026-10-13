import { LightningElement, track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from "lightning/platformResourceLoader";
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
//APEX
import initData from '@salesforce/apex/SellinStatementListController.initData';
import loadData from '@salesforce/apex/SellinStatementListController.loadData';
import { API_NAMES, Labels, PictosNegoptim2, colFieldsStyle } from './properties.js';
export default class SellinStatementList extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = false;
    @track isPortal = false;
    @track prefix = '';
    @track pageSize = 50;
    @track pageNumber = 1;
    labels = { ...Labels }
    totalPagesCount = 0;
    @track fieldsWrapperList = [];
    @track recordsWrapperList;
    @track filterWrapper = {};
    @track totalNumbOfRecords = 0;
    @track conditions = [];
    orderDirectionMap = new Map();
    editIconSource = `${PictosNegoptim2}/PICTOS/PNG/Picto_negOptim2_Readyforwork.png`;
    restitIconSource = `${PictosNegoptim2}/PICTOS/PNG/Picto_negOptim2_summary.png`;
    iconStyle = `width: 25px; height: 25px; cursor: pointer;`;
    @track monthList = [
        { monthNumber: 1, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 2, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 3, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 4, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 5, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 6, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 7, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 8, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 9, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 10, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 11, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', },
        { monthNumber: 12, haveIcon: false, iconSource: '', iconTitle: '', iconStyle: '', periodNumber: '', }
    ];
    get colspanDisplayedFields() {
        return this.fieldsWrapperList.length + this.monthList.length;
    }
    headerStyle = 'background-color: rgb(13, 128, 125); color:white; min-width:40px; max-width:40px; width:40px;';
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
        console.log('filter: ' + JSON.stringify(filter))
        return filter;
    };
    //LIFECYCLE
    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });
        this.init();
        addEventListener('resize', this.setPageSize);
    }
    renderedCallback() {
        this.setPageSize();
    }
    init() {
        console.log('API_NAMES>> ' + JSON.stringify(API_NAMES));
        this.isLoading = true;
        initData().then(result => {
            let parsedResult = JSON.parse(result);
            this.isPortal = parsedResult.isPortal;
            this.prefix = parsedResult.prefix;
            let colFields = parsedResult.fields.filter(field => Object.keys(colFieldsStyle).includes(field.fieldName));
            this.fieldsWrapperList = this.buildFieldWrapper(colFields)
            this.statusPicklistOptions = parsedResult.fields.find(item => item.fieldName === API_NAMES.SellInStatement__c.Status__c).picklistValues;
            this.afterLoad();
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    buildFieldWrapper(colFields) {
        let fieldsList = [];
        colFields.forEach(field => {
            let fieldWrapper = {
                fieldLabel: field.fieldLabel,
                fieldName: field.fieldName,
                fieldType: field.fieldType,
                pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                selectedValues: [],
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                _isNumber: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                isReference: field.fieldType == 'REFERENCE',
                isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextArea: field.fieldType == 'TEXTAREA',
                isText: field.fieldType == 'STRING' && field.fieldType == 'REFERENCE',
                headerStyle: this.headerStyle + '' + colFieldsStyle[field.fieldName],
                isSortedUp: field.fieldName == API_NAMES.SellInStatement__c.ReferenceYear__c ? false : true,
                iconStyle: field.fieldName == API_NAMES.SellInStatement__c.ReferenceYear__c ? 'sortSelected-icon' : '',
                cellTextAlignment: colFieldsStyle[field.fieldName],
                value: null,
            }
            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate
                && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextArea;
            fieldsList.push(fieldWrapper);
        });
        return fieldsList;
    }

    afterLoad() {
        loadData({
            recordId: this.recordId,
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            conditions: this.conditions,
            orderBy: this.orderDirectionMap.size === 0 ? null : [...this.orderDirectionMap].map(([key, value]) => `${key} ${value}`).join(', ')
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
            this.totalNumbOfRecords = parsedResult.totalSize;
            this.recordsWrapperList = [...this.buildDataWrapper(parsedResult.records)];
            this.isLoading = false;
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    buildDataWrapper(data) {
        let sellinStatementRecords = [];
        data.forEach(sellinStatementWrapper => {
            let row = sellinStatementWrapper.sellInStatement;
            let relatedSellInStatements = sellinStatementWrapper.relatedSellInStatements;
            row.columns = [];
            row.iconSource = row[API_NAMES.SellInStatement__c.StatusLogo__c];
            row.iconTitle = this.statusPicklistOptions.find(item => item.value === row[API_NAMES.SellInStatement__c.Status__c]).label;
            let fields = JSON.parse(JSON.stringify(this.fieldsWrapperList));
            fields.forEach(field => {
                if (field.isReference) {
                    if (field.fieldName.endsWith('Id')) {
                        field.value = row[field.fieldName.replace('Id', '')]?.Name;
                    } else {
                        field.value = row[field.fieldName.replace('__c', '__r')]?.Name;
                    }
                    field.link = '/' + row[field.fieldName];
                } else if (field.isPicklist) {
                    let found = field.pickListValues.find(item => item.value === row[field.fieldName]);
                    field.value = found?.label;
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
                } else {
                    field.value = row[field.fieldName];
                }
            });
            row.columns = JSON.parse(JSON.stringify(fields));
            // apply all sellin statements
            let relatedMonths = JSON.parse(JSON.stringify(this.monthList));
            this.populateMonthIcons(row, relatedMonths);
            if (relatedSellInStatements) {
                relatedSellInStatements.forEach(sellInStatement => {
                    this.populateMonthIcons(sellInStatement, relatedMonths);
                });
            }
            row.monthList = JSON.parse(JSON.stringify(relatedMonths));
            sellinStatementRecords.push(row);
        });
        return sellinStatementRecords;
    }

    populateMonthIcons(sellInStatement, relatedMonths) {
        let periodNb = sellInStatement[API_NAMES.SellInStatement__c.PeriodNumber__c];
        let periodType = sellInStatement[API_NAMES.SellInStatement__c.PeriodType__c];
        let relatedMonth;
        if (periodType == 'Month') {
            relatedMonth = periodNb;
        } else if (periodType == 'Semester') {
            relatedMonth = periodNb * 6;
        } else if (periodType == 'Trimester') {
            relatedMonth = periodNb * 3;
        } else if (periodType == 'Annual' && periodNb == 1) {
            relatedMonth = 12;
        }
        relatedMonths[relatedMonth - 1].haveIcon = true;
        relatedMonths[relatedMonth - 1].periodNumber = periodNb;
        relatedMonths[relatedMonth - 1].iconSource = `${PictosNegoptim2}/${sellInStatement[API_NAMES.SellInStatement__c.StatusLogo__c]}.png`;
        relatedMonths[relatedMonth - 1].iconTitle = this.statusPicklistOptions.find(item => item.value === sellInStatement[API_NAMES.SellInStatement__c.Status__c]).label;
        relatedMonths[relatedMonth - 1].iconStyle = this.iconStyle;
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
    handleChangeFilter(event) {
        try {
            let fieldName = event.target.dataset.field;
            let type = event.target.type;
            let value = event.target.value;
            let number = event.target.dataset.number;
            let field = this.fieldsWrapperList.find(field => field.fieldName === fieldName);
            if (!field) return;
            if (field.isReference /*|| field.isReferenceText*/) {
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
            // this.pageNumber = 1;
            this.afterLoad()
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    resetFilters() {
        try {
            this.filterWrapper = {};
            this.fieldsWrapperList.forEach(field => {
                /*if (field.isReferenceText) {
                    field.fieldSearchValue = '';
                } else*/ if (field._isNumber || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                } else {
                    field.fieldSearchValue = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                if (field.isFiltered) {
                    field.isFiltered = false;
                }
            });
            this.isLoading = true;
            this.conditions = [];
            this.orderDirectionMap = new Map();
            this.afterLoad();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleSortColumn(event) {
        this.isLoading = true;
        this.orderDirectionMap.clear()
        let fieldName = event.target.dataset.field;
        let fieldtype = event.target.dataset.fieldtype;
        let index = event.target.dataset.index;
        let direction = event.target.dataset.updirection ? 'DESC' : 'ASC';
        this.fieldsWrapperList.forEach(field => {
            field.isSortedUp = field.fieldName == fieldName ? false : true;
            field.iconStyle = '';
        });
        this.fieldsWrapperList[index].isSortedUp = event.target.dataset.updirection ? false : true;
        this.fieldsWrapperList[index].iconStyle = 'sortSelected-icon';
        if (fieldtype == 'REFERENCE') {
            if (fieldName.endsWith('Id')) {
                fieldName = fieldName.replace('Id', '.Name');
            } else {
                fieldName = fieldName.replace('__c', '__r.Name');
            }
        }
        this.orderDirectionMap.set(fieldName, direction);
        this.afterLoad();
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

    handleOpenSIMatrix(event) {
        let st = event.target.dataset.icon;
        try {
            let index = event.target.dataset.index;
            let periodType = this.recordsWrapperList[index][API_NAMES.SellInStatement__c.PeriodType__c];
            let negoScopeId = this.recordsWrapperList[index][API_NAMES.SellInStatement__c.NegoScope__c];
            let referenceYear = this.recordsWrapperList[index][API_NAMES.SellInStatement__c.ReferenceYear__c];
            let periodnumber = event.target.dataset.periodnumber;
            let filter = [];
            filter.push(`${API_NAMES.SellInStatement__c.NegoScope__c} IN ('${negoScopeId}')`);
            filter.push(`${API_NAMES.SellInStatement__c.ReferenceYear__c} = ${referenceYear}`);
            filter.push(`${API_NAMES.SellInStatement__c.PeriodType__c} IN ('${periodType}')`);
            if (periodnumber) {
                filter.push(`${API_NAMES.SellInStatement__c.PeriodNumber__c} = ${periodnumber}`);
            }
            // Encode filters once
            const encodedFilters = encodeURIComponent(JSON.stringify(filter));
            // Define component definition
            const compDefinition = {
                componentDef: (this.prefix != '' && this.prefix != undefined ? this.prefix.replace('__', ':') : 'c:') + 'sellinStatementMatrix',
                state: {
                    c__componentName: 'sellinStatementMatrix',
                    c__appliedfilters: JSON.stringify(filter), // Already encoded
                    c__negoScopeId: negoScopeId,
                    c__referenceYear: referenceYear,
                    c__periodType: periodType,
                    c__periodNumber: periodnumber,
                },
                attributes: {},
            };
            // Encode the component definition once
            if (!this.isPortal) {
                const encodedCompDefinition = btoa(unescape(encodeURIComponent(JSON.stringify(compDefinition))));
                window.open(`/one/one.app#${encodedCompDefinition}`);
            } else {
                window.open(`/NegoptimConnect/sellin-statement-matrix?c__appliedfilters=${encodedFilters}&c__negoScopeId=${negoScopeId}&c__referenceYear=${referenceYear}&c__periodType=${periodType}&c__periodNumber=${periodnumber}`);
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleOpenRestitMatrix(event) {
        try {
            let index = event.target.dataset.index;
            let PeriodType = this.recordsWrapperList[index][API_NAMES.SellInStatement__c.PeriodType__c];
            let NegoScope = this.recordsWrapperList[index][API_NAMES.SellInStatement__c.NegoScope__c];
            let ReferenceYear = this.recordsWrapperList[index][API_NAMES.SellInStatement__c.ReferenceYear__c];
            let periodnumber = event.target.dataset.periodnumber;
            let filter = [];
            filter.push(`${API_NAMES.SellInStatement__c.NegoScope__c} IN ('${NegoScope}')`);
            filter.push(`${API_NAMES.SellInStatement__c.ReferenceYear__c} = ${ReferenceYear}`);
            filter.push(`${API_NAMES.SellInStatement__c.PeriodType__c} IN ('${PeriodType}')`);
            if (periodnumber) {
                filter.push(`${API_NAMES.SellInStatement__c.PeriodNumber__c} = ${periodnumber}`);
            }
            // Encode filters once
            const encodedFilters = encodeURIComponent(JSON.stringify(filter));
            // Define component definition
            const compDefinition = {
                componentDef: (this.prefix != '' && this.prefix != undefined ? this.prefix.replace('__', ':') : 'c:') + 'sellinCollaborativeRestitution',
                state: {
                    c__appliedfilters: JSON.stringify(filter), // Already encoded
                },
                attributes: {},
            };
            // Encode the component definition once
            if (!this.isPortal) {
                const encodedCompDefinition = btoa(unescape(encodeURIComponent(JSON.stringify(compDefinition))));
                window.open(`/one/one.app#${encodedCompDefinition}`);
            } else {
                window.open(`/NegoptimConnect/sellin-collaborative-restitution?c__appliedfilters=${encodedFilters}`);
            }
        } catch (e) {
            console.log('ERROR: ' + e);
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
    }


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



}