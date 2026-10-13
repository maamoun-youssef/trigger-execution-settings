import { LightningElement, track, api, wire } from 'lwc';
import LBL_First from '@salesforce/label/c.LBL_First';
import LBL_Previous from '@salesforce/label/c.LBL_Previous';
import LBL_Next from '@salesforce/label/c.LBL_Next';
import LBL_Last from '@salesforce/label/c.LBL_Last';
import LBL_Of from '@salesforce/label/c.LBL_Of';
import LBL_No_Item_To_Display from '@salesforce/label/c.LBL_No_Item_To_Display';
import LBL_Apply from '@salesforce/label/c.LBL_Apply';
import LBL_ResetFilters from '@salesforce/label/c.LBL_ResetFilters';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getTemplateData from '@salesforce/apex/GenericLwcTemplateCtrl.getTemplateData';
import { NavigationMixin } from 'lightning/navigation';

export default class GenericLwcTemplate extends NavigationMixin(LightningElement) {

    @api objectApiName;
    @api fields = [];
    @api data;
    @api templateName;
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;
    picklistValuesMap = {};
    labels = {
        LBL_First,
        LBL_Previous,
        LBL_Next,
        LBL_Last,
        LBL_Of,
        LBL_No_Item_To_Display,
        LBL_ResetFilters,
        LBL_Apply
    };

    @track filters = {};
    @track pendingFilters = {};
    @track pageSize = 50;
    @track pageNumber = 1;

    resetFilters() {
        try {
            this.filters = {};
            this.pendingFilters = {};
            this.pageNumber = 1;
        } catch (error) {
            console.error(error?.body?.message || error?.message);
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: '$objectApiName', recordTypeId: '$defaultRecordTypeId' })
    picklistValuesInfo({ error, data }) {
        if (data) {
            this.picklistValuesMap = data.picklistFieldValues;
        } else if (error) {
            console.error(error);
        }
    }

    get defaultRecordTypeId() {
        return this.objectInfo?.data?.defaultRecordTypeId || '012000000000000AAA';
    }

    formatForDatetimeLocal(value) {
        if (!value) return '';
        const date = new Date(value);
        return date.toISOString().slice(0, 16);
    }

    get wrappedColumns() {
        let isTemplateNamePopulated = this.templateName ? true : false;
        if (this.objectInfo?.data && this.fields.length) {
            return this.fields.map((fieldApiName, index) => {
                const _fieldApiName = isTemplateNamePopulated ? fieldApiName.fieldName : fieldApiName;
                const fieldInfo = this.objectInfo.data.fields[_fieldApiName];
                const _fieldInfo = this.fields[index];
                const type = (fieldInfo?.dataType || _fieldInfo?.stringFieldType)?.toUpperCase();
                const isUrl = type === 'URL';
                const isIcon = (
                    isTemplateNamePopulated &&
                    isUrl &&
                    _fieldInfo?.URLOption === 'IconReplace'
                );
                const replaceURLWith = isIcon ? _fieldInfo?.replaceURLWith : null;
                console.log(`Index: ${index}`);
                console.log(`_fieldApiName: ${_fieldApiName}`);
                console.log(`Type: ${type}`);
                console.log(`isUrl: ${isUrl}`);
                console.log(`URLOption: ${_fieldInfo?.URLOption}`);
                console.log(`replaceURLWith: ${replaceURLWith}`);
                console.log(`🚀 ---------------------------------------------------------------------🚀`);
                console.log(`🚀 ~ GenericLwcTemplate ~ getwrappedColumns ~ _fieldApiName:`, _fieldApiName);
                console.log(`🚀 ---------------------------------------------------------------------🚀`);
                return {
                    field: _fieldApiName,
                    label: _fieldInfo?.fieldLabel || fieldInfo?.label || _fieldApiName,
                    fieldType: type,
                    isText: type === 'STRING' || type === 'ID' || type === 'REFERENCE',
                    isNumber: ['DOUBLE', 'CURRENCY', 'INTEGER', 'LONG', 'PERCENT'].includes(type),
                    isPicklist: type === 'PICKLIST',
                    isBoolean: type === 'BOOLEAN',
                    isUrl,
                    isDate: type === 'DATE' || type === 'DATETIME',
                    isDateTime: type === 'DATETIME',
                    inputType: type === 'DATETIME' ? 'datetime-local' : (type === 'DATE' ? 'date' : 'text'),
                    pickListValues: _fieldInfo?.pickListValues || (this.picklistValuesMap && this.picklistValuesMap[_fieldApiName]
                        ? Object.values(this.picklistValuesMap[_fieldApiName].values).map(opt => ({ label: opt.label, value: opt.value }))
                        : []),
                    filterValue: this.pendingFilters[_fieldApiName] || '',
                    filterValue1: this.pendingFilters[_fieldApiName]?.from || '',
                    filterValue2: this.pendingFilters[_fieldApiName]?.to || '',
                    dateFrom: this.formatForDatetimeLocal(this.pendingFilters[_fieldApiName]?.from),
                    dateTo: this.formatForDatetimeLocal(this.pendingFilters[_fieldApiName]?.to),
                    selectedValues: this.pendingFilters[_fieldApiName]?.valuesList || [],
                    selectedBooleanValues: this.pendingFilters[_fieldApiName]?.booleanValues || [],
                    isFiltered: !!this.filters[_fieldApiName],
                    isIcon: isIcon,
                    replaceURLWith: replaceURLWith,
                    canFilter: !isUrl,
                    cellStyle: isTemplateNamePopulated ? _fieldInfo?.style || '' : '',
                    headerStyle: isTemplateNamePopulated ? _fieldInfo?.headerStyle?.style || '' : '',
                    separatorSettingsStyle: isTemplateNamePopulated ? _fieldInfo?.separatorSettings?.style || '' : '',
                    isInputField: isTemplateNamePopulated ? _fieldInfo?.isInputField === true : false,
                };
            });
        }
        return [];
    }

    handleBooleanFilterChange(event) {
        const field = event.target.dataset.field;
        const values = event.detail.value;
        const config = {
            type: 'boolean',
            booleanValues: values
        };
        this.pendingFilters = { ...this.pendingFilters, [field]: config };
    }

    get booleanOptions() {
        return [
            { label: 'True', value: 'true' },
            { label: 'False', value: 'false' }
        ];
    }

    get processedPagedData() {
        return this.pagedData.map(row => {
            return {
                id: row.id,
                cells: this.wrappedColumns.map(col => {
                    const value = row[col.field] ?? '';
                    const isLink = col.fieldType === 'ID' || col.fieldType === 'REFERENCE';
                    const combinedStyle = `${col.cellStyle || ''}; ${col.separatorSettingsStyle || ''}`.trim();
                    return {
                        field: col.field,
                        value: value,
                        isLink: isLink,
                        isUrl: col.isUrl,
                        isIcon: col.isIcon,
                        replaceURLWith: col.replaceURLWith,
                        recordId: isLink ? value : null,
                        // cellStyle: col.cellStyle,
                        // separatorSettingsStyle: col.separatorSettingsStyle
                        tdStyle: combinedStyle,
                        isInputField: col.isInputField,
                    };
                })
            };
        });
    }

    handleInputFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log(`Input changed - Field: ${field}, Value: ${value}`);

    }

    handleRecordClick(event) {
        const recordId = event.currentTarget.dataset.recordId;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }


    pageSizeOptions = [
        { label: '5', value: 5, isSelected: false },
        { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        { label: '75', value: 75, isSelected: false },
        { label: '100', value: 100, isSelected: false }
    ];

    get filteredData() {
        let filtered = this.data;
        if (filtered) {
            for (const [field, config] of Object.entries(this.filters)) {
                if (config.type === 'text') {
                    filtered = filtered.filter(r => String(r[field]).toLowerCase().includes(config.value.toLowerCase()));
                } else if (config.type === 'number') {
                    const from = Number(config.from);
                    const to = Number(config.to);
                    filtered = filtered.filter(r => {
                        const value = Number(r[field]);
                        let isValid = true;

                        if (!isNaN(from)) {
                            isValid = isValid && value >= from;
                        }
                        if (!isNaN(to)) {
                            isValid = isValid && value <= to;
                        }

                        return isValid;
                    });
                } else if (config.type === 'picklist') {
                    filtered = filtered.filter(r => config.valuesList.includes(r[field]));
                } else if (config.type === 'boolean') {
                    filtered = filtered.filter(r => {
                        const value = String(r[field]) === 'true';
                        return config.booleanValues.includes(String(value));
                    });
                } else if (config.type === 'date') {
                    filtered = filtered.filter(r => {
                        const rowDate = new Date(r[field]);
                        let valid = true;
                        if (config.from) {
                            const fromDate = new Date(config.from);
                            valid = valid && rowDate >= fromDate;
                        }
                        if (config.to) {
                            const toDate = new Date(config.to);
                            valid = valid && rowDate <= toDate;
                        }
                        return valid;
                    });
                }
            }
        }
        return filtered || [];
    }

    get pagedData() {
        const start = (this.pageNumber - 1) * this.pageSize;
        return this.filteredData.slice(start, start + this.pageSize);
    }

    get totalPagesCount() {
        return Math.ceil(this.filteredData.length / this.pageSize) || 1;
    }

    get totalNumbOfRecords() {
        return this.filteredData.length;
    }

    get previousDisabled() {
        return this.pageNumber <= 1;
    }

    get nextDisabled() {
        return this.pageNumber >= this.totalPagesCount;
    }

    get pagesBadge() {
        const start = this.pageNumber * this.pageSize + 1 - this.pageSize;
        const end = (this.pageNumber * this.pageSize > this.totalNumbOfRecords)
            ? this.totalNumbOfRecords
            : this.pageNumber * this.pageSize;
        return `${start}-${end} ${this.labels.LBL_Of} ${this.totalNumbOfRecords}`;
    }

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        this.pendingFilters = { ...this.pendingFilters, [field]: event.target.value };
    }

    toggleFilterPanel(event) {
        try {
            const field = event.target.dataset.field;
            this.template.querySelectorAll('[data-filter-field]').forEach(el => {
                if (el.dataset.filterField === field) {
                    el.classList.toggle('slds-hide');
                } else {
                    el.classList.add('slds-hide');
                }
            });
        } catch (error) {
            console.error(error?.message || error);
        }
    }

    handleChangeFilter(event) {
        const field = event.target.dataset.field;
        const type = event.target.dataset.type;
        let config = this.pendingFilters[field] || {};

        if (type === 'text') {
            config.value = event.target.value;
        }
        if (type === 'number') {
            const n = event.target.dataset.number;
            if (n === '1') config.from = event.target.value;
            else if (n === '2') config.to = event.target.value;
        }
        if (type === 'date') {
            const n = event.target.dataset.number;
            if (n === '1') config.from = event.target.value;
            else if (n === '2') config.to = event.target.value;
        }

        config.type = type;
        this.pendingFilters = { ...this.pendingFilters, [field]: config };
    }

    handlePicklistChange(event) {
        const field = event.target.dataset.field;
        const valuesList = event.detail.value;
        const config = { type: 'picklist', valuesList };
        this.pendingFilters = { ...this.pendingFilters, [field]: config };
    }

    handleApplyFilters() {
        this.filters = { ...this.pendingFilters };
        this.pageNumber = 1;
    }

    handleChangePage(event) {
        try {
            const type = event.target.dataset.type;
            if (type === 'Previous' && !this.previousDisabled) {
                this.pageNumber--;
            } else if (type === 'Next' && !this.nextDisabled) {
                this.pageNumber++;
            } else if (type === 'First') {
                this.pageNumber = 1;
            } else if (type === 'Last') {
                this.pageNumber = this.totalPagesCount;
            }
        } catch (error) {
            console.error(error);
        }
    }

    handleChangePageSize(event) {
        try {
            this.pageSize = parseInt(event.target.value, 10);
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value === this.pageSize;
            }
            this.pageNumber = 1;
        } catch (error) {
            console.error('error: ' + error);
        }
    }

    setPageSize = () => {
        try {
            const mainContainer = this.template.querySelector(".mainContainer");
            const header = this.template.querySelector(".header");
            const body = this.template.querySelector(".bodyDiv");
            const footer = this.template.querySelector(".footerDiv");
            if (mainContainer && header && body && footer) {
                const windowHeight = window.innerHeight;
                const headerHeight = header.offsetHeight;
                const footerHeight = footer.offsetHeight;
                const offset = 150;
                const remainingHeight = windowHeight - headerHeight - footerHeight - offset;
                body.style.height = remainingHeight + "px";
            }
        } catch (err) {
            console.error(err);
        }
    };

    @track actions = [];
    @track errorMessages = [];
    @track warningMessages = [];
    @track total = 0;
    loadTemplateData() {
        getTemplateData({
            recordId: null,
            searchTerm: null,
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            metadataDeveloperName: this.templateName,
            filter: null,
            sortedFieldName: null,
            defaultSortDirection: 'ASC'
        }).then(resultJSON => {
            const result = JSON.parse(resultJSON);
            console.log('result.records >>', JSON.stringify(result.records));
            this.objectApiName = result.objectName;
            this.fields = result.gridSettingsManager?.GRID_FIELDS || [];
            console.log('this.fields >>', JSON.stringify(this.fields));
            this.data = result.records || [];
            this.actions = result.actions || [];
            this.total = result.total || 0;
            this.errorMessages = result.errorMessages || [];
            this.warningMessages = result.warningMessages || [];
        }).catch(error => {
            console.error('Error loading data:', error);
        });
    }

    connectedCallback() {
        window.addEventListener('resize', this.setPageSize);
        if (this.templateName && this.templateName.trim() !== '') {
            this.loadTemplateData();
        }
    }

    renderedCallback() {
        this.setPageSize();
    }
}