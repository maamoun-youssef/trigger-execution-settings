import { LightningElement, track, api, wire } from 'lwc';
import { showNotification } from 'c/appHelper';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import LightningConfirm from 'lightning/confirm';
//APEX
import initData from "@salesforce/apex/PromoAgreementsManagerController.initData";
import loadData from '@salesforce/apex/PromoAgreementsManagerController.loadData';
import save from '@salesforce/apex/PromoAgreementsManagerController.save';
import confirmDeleteCPD from '@salesforce/apex/PromoAgreementsManagerController.confirmDeleteCPD';
//STATIC RESOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';

import { labels, CommercialPlan_API, CommercialPlanDetail_API, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES } from './properties.js';

export default class PromoAgreementsManager extends LightningElement {
    @api recordId;
    @track isLoading = true;
    @track commercialPlan = {};
    @track prefix = '';
    @track displayedFields = [];
    @track CPName = '';
    @track CPPromoType = '';
    @track gridSettingsManager = {};
    @track pageSize = '25';
    @track bannerValues = [];
    @track labels = { ...labels }
    @track records = [];
    @track noOfRecords = 0;
    @track filters = {
        dynamic: '',
    }
    @track isFilterOpen = false;
    @track fieldsToFilter = [];
    // dynamicFilterPanel wiring
    @track dfpConfig = [];
    @track hasValidGridTemplate = true;

    @track isEditMode = false;
    @track CPDToUpdateMap = {};
    @track newRecords = [];
    @track originalValuesById = {};

    get showSaveCancel() {
        return this.isEditMode || ((Object.keys(this.CPDToUpdateMap).length > 0) || (this.newRecords.length > 0));
    }
    totalPagesCount = 0;
    pageNumber = 1;
    CPPicklistValues = {}
    fieldsToFilterMap = {};
    commercialPlanDetailObject = CommercialPlanDetail_API.objectApiName;

    @wire(getPicklistValuesByRecordType, { objectApiName: CommercialPlan_API.object, recordTypeId: '012000000000000AAA' }) picklistValues({ error, data }) {
        if (data) {
            this.CPPicklistValues = data.picklistFieldValues;
            this.initData();
        } else if (error) { console.log('ERROR'); }
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
        this.setStickyHeader();
        if (this.template.querySelector('.main-panel')) {
            this.changeHeight();
        }
    }

    initData() {
        initData({
            recordId: this.recordId
        }).then(result => {
            let parsedData = JSON.parse(result);
            this.prefix = parsedData.prefix;
            console.log('parsedData >> ' + JSON.stringify(parsedData))
            this.gridSettingsManager = parsedData.gridSettingsManager;
            this.hasValidGridTemplate = (this.gridSettingsManager && this.gridSettingsManager.gridLayout !== null
                && Array.isArray(this.gridSettingsManager.GRID_FIELDS) && this.gridSettingsManager.GRID_FIELDS.length > 0);
            if (this.gridSettingsManager.Default_Page_Size) {
                this.pageSize = parseInt(this.gridSettingsManager.Default_Page_Size);
            }
            if (parsedData.commercialPlan) {
                this.commercialPlan = parsedData.commercialPlan;
                this.CPName = parsedData.commercialPlan.Name;
                this.commercialPlanType = parsedData.commercialPlan[CommercialPlan_API.PromoAgreementType__c];
                if (this.CPPicklistValues && this.CPPicklistValues[CommercialPlan_API.PromoAgreementType__c]) {
                    for (let pickVal of this.CPPicklistValues[CommercialPlan_API.PromoAgreementType__c].values) {
                        if (parsedData.commercialPlan[CommercialPlan_API.PromoAgreementType__c] === pickVal.value) {
                            this.CPPromoType = pickVal.label;
                            break;
                        }
                    }
                }
            }
            this.buildDisplayedFields();
            let bannerRecord = JSON.parse(parsedData.bannerRecord);
            if (bannerRecord) {
                this.buildBannerData(bannerRecord);
            }
            // this.populateFiltersMap(this.gridSettingsManager.FILTERS);
            this.dfpConfig = (this.gridSettingsManager && this.gridSettingsManager.FILTERS) || [];
            requestAnimationFrame(() => this.pushFiltersConfigToChild());
        }).catch(error => {
            this.isLoading = false;
        })
    }

    // populateFiltersMap(fields) {
    //     console.log('populateFiltersMap >>> ' + JSON.stringify(fields))
    //     this.fieldsToFilterMap = {};
    //     for (let field of fields) {
    //         let fieldToFilter = {};
    //         if (SUPPORTED_TYPES.includes(field.stringFieldType)
    //             || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
    //             || field.hasOwnProperty('userFilterable')) {
    //             fieldToFilter.fieldLabel = field.fieldLabel;
    //             fieldToFilter.fieldName = field.fieldName;
    //             fieldToFilter.stringFieldType = field.stringFieldType;
    //             fieldToFilter.isMultiLevel = field.hasOwnProperty('isMultiLevel') ? field.isMultiLevel : false;
    //             if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
    //             if (field.stringFieldType == 'ID') {
    //                 if (field.values) fieldToFilter.displayVal = field.values.join(';');
    //                 fieldToFilter.isId = true;
    //             }
    //             fieldToFilter.isText = field.stringFieldType == 'STRING';
    //             fieldToFilter.isReference = field.stringFieldType == 'REFERENCE';
    //             fieldToFilter.isCheckboxGroup = field.stringFieldType == 'BOOLEAN' || ((field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'RECORDTYPE') && (field.pickListValues && field.pickListValues.length > 1));
    //             if (fieldToFilter.isCheckboxGroup) {
    //                 fieldToFilter.options = field.stringFieldType == 'BOOLEAN' ? [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }] : field.pickListValues;
    //             }
    //             fieldToFilter.isNumber = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
    //             if (fieldToFilter.isNumber) {
    //                 if (field.stringFieldType == 'DOUBLE') {
    //                     fieldToFilter.formatter = 'decimal';
    //                 }
    //                 if (field.stringFieldType == 'CURRENCY') {
    //                     fieldToFilter.formatter = 'currency';
    //                 }
    //                 if (field.stringFieldType == 'PERCENT') {
    //                     fieldToFilter.formatter = 'percent-fixed';
    //                 }
    //                 let step = '.';
    //                 for (let i = 0; i < field.scale; i++) {
    //                     if (i == field.scale - 1) {
    //                         step += '1';
    //                         break;
    //                     }
    //                     step += '0';
    //                 }
    //                 fieldToFilter.step = step;
    //             }
    //             fieldToFilter.isDate = field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME';
    //             fieldToFilter.isTime = field.stringFieldType == 'TIME';
    //             if (field.hasOwnProperty('isEncrypted')) {
    //                 fieldToFilter.isEncrypted = field.isEncrypted;
    //             }
    //             if (SUPPORTED_VALUES_TYPES.includes(field.stringFieldType)
    //                 || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
    //                 if (field.values) {
    //                     if (fieldToFilter.isText || fieldToFilter.isReference) {
    //                         fieldToFilter.value = (field.values[0]) ? field.values[0] : '';
    //                         fieldToFilter.values = field.values;
    //                     } else {
    //                         fieldToFilter.values = field.values;
    //                     }
    //                 } else {
    //                     fieldToFilter.values = '';
    //                 }
    //             }
    //             if (SUPPORTED_RANGE_TYPES.includes(field.stringFieldType)) {
    //                 fieldToFilter.value1 = (field.value1) ? field.value1 : '';
    //                 fieldToFilter.value2 = (field.value2) ? field.value2 : '';
    //             }
    //             if (Object.keys(fieldToFilter).length !== 0) {
    //                 this.fieldsToFilterMap[fieldToFilter.fieldName] = fieldToFilter;
    //             }
    //         }
    //     }
    //     this.populateLists(this.fieldsToFilterMap);
    // }

    // populateLists(filtersMap) {
    //     console.log('populateLists >>> ' + JSON.stringify(filtersMap))
    //     this.fieldsToFilter = [];
    //     if (Object.keys(filtersMap).length !== 0) {
    //         this.fieldsToFilter = Object.keys(filtersMap)
    //             .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
    //             .map(fieldName => { return filtersMap[fieldName]; });
    //         //get record type field
    //         var recordTypeField = Object.keys(filtersMap)
    //             .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType == 'RECORDTYPE')
    //             .map(fieldName => { return filtersMap[fieldName]; });
    //         //add record type fields always to the top
    //         if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
    //         this.multilevelFields = Object.keys(filtersMap)
    //             .filter(fieldName => filtersMap[fieldName].isMultiLevel == true)
    //             .map(fieldName => { return filtersMap[fieldName]; });
    //         this.fieldsToFilter.forEach(item => {
    //             if (item.isText || item.isReference) {
    //                 item.value = item.values.length != 0 ? item.values[0] : '';
    //             }
    //         })
    //     }
    // }

    // ===== dynamicFilterPanel integration =====
    handleFilterApply(event) {
        // Child emits normalized array + JSON; backend expects JSON in filters.dynamic
        const json = event?.detail?.dynamicFilterJSON || '[]';
        this.pageNumber = 1;
        this.filters.dynamic = json;
        this.isFilterOpen = false;
        requestAnimationFrame(() => this.pushFiltersConfigToChild());
        this.loadData();
    }

    handleFilterReset() {
        this.pageNumber = 1;
        this.filters.dynamic = '';
        this.isFilterOpen = false;
        requestAnimationFrame(() => this.pushFiltersConfigToChild());
        this.loadData();
    }

    handleFilterChange(/*event*/) {
        // Optional: react to live changes (no-op to avoid chatty reloads).
    }

    // toggleFilter() {
    //     this.isFilterOpen = !this.isFilterOpen;
    //     requestAnimationFrame(() => {
    //         this.changeHeight();
    //     });
    // }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
        // requestAnimationFrame(() => { this.changeHeight(); });
        requestAnimationFrame(() => {
            this.changeHeight();
            if (this.isFilterOpen) this.pushFiltersConfigToChild();
        });
    }

    // resetFilter() {
    //     this.pageNumber = 1;
    //     this.isFilterOpen = false;
    //     this.filters.dynamic = '';
    //     this.fieldsToFilter.forEach(item => {
    //         if (item.isText || item.isReference) {
    //             item.value = '';
    //             item.value1 = '';
    //             item.value2 = '';
    //         }
    //     })
    //     this.loadData();
    // }

    // confirmFilter() {
    //     this.pageNumber = 1;
    //     let fields = Object.keys(this.fieldsToFilterMap)
    //         .filter(fieldName =>
    //         (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
    //             (this.fieldsToFilterMap[fieldName].values &&
    //                 (this.fieldsToFilterMap[fieldName].values.length > 1
    //                     || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
    //             || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
    //             || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
    //         .map(fieldName => {
    //             let item = {};
    //             item.fieldName = fieldName;
    //             if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
    //                 item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
    //             }
    //             if (this.fieldsToFilterMap[fieldName].values &&
    //                 (this.fieldsToFilterMap[fieldName].values.length > 1
    //                     || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== ''))) {
    //                 item.values = this.fieldsToFilterMap[fieldName].values;
    //                 return item;
    //             }
    //             if (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '') {
    //                 item.value1 = this.fieldsToFilterMap[fieldName].value1;
    //             }
    //             if (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '') {
    //                 item.value2 = this.fieldsToFilterMap[fieldName].value2;
    //             }
    //             return item;
    //         }).filter(item => (item.hasOwnProperty('values') || item.hasOwnProperty('value1') || item.hasOwnProperty('value2') || item.hasOwnProperty('userFilterable')));
    //     this.isLoading = true;
    //     this.isFilterOpen = false;
    //     this.filters.dynamic = JSON.stringify(fields);
    //     this.loadData();
    // }

    // setSelectedValues(event) {
    //     var value = event.detail.value;
    //     var fieldName = event.target.name;
    //     var modeValue = event.target.dataset.mode;
    //     if (this.fieldsToFilterMap[fieldName]) {
    //         let field = this.fieldsToFilterMap[fieldName];
    //         field.values = [];
    //         if (modeValue === 'multiple') {
    //             let withoutSpace = value.replaceAll(' ', '');
    //             field.displayVal = withoutSpace;
    //             let idList = withoutSpace.split(';');
    //             for (let id of idList) {
    //                 if (id !== '') {
    //                     field.values.push(id);
    //                 }
    //             }
    //         } else {
    //             field.values = (Array.isArray(value)) ? value : [value];
    //         }
    //         this.fieldsToFilterMap[fieldName] = field;
    //         this.populateLists(this.fieldsToFilterMap);
    //     }
    // }

    buildBannerData(record) {
        for (let field of this.gridSettingsManager.BANNER_FIELDS) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                link: '',
                scale: field.scale,
                step: '',
                pickListValues: field.pickListValues,
                fieldValue: record[field.fieldName],
            }
            if (fieldWrapper.isReference) {
                fieldWrapper.fieldValue = record[field.fieldName.replace(/__c$/, '__r')]?.Name;
                fieldWrapper.link = '/' + record[field.fieldName];
            }
            this.bannerValues.push(fieldWrapper);
        }
    }

    buildDisplayedFields() {
        this.displayedFields = [];
        for (let field of this.gridSettingsManager.GRID_FIELDS) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
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
                headerStyle: field.StringHeaderStyle,
                pickListValues: field.pickListValues,
                isSortable: field.isSortable,
                isFilterable: field.isFilterable,
                isEncrypted: field.isEncrypted,
                filterValue: '',
                sortedField: false,
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
        this.loadData();
    }

    loadData() {
        this.records = [];
        try {
            this.isLoading = true;
            loadData({
                recordId: this.recordId,
                gridSettings: JSON.stringify(this.gridSettingsManager),
                pageSize: this.pageSize,
                pageNumber: this.pageNumber,
                filters: JSON.stringify(this.filters),
                commercialPlanType: this.commercialPlanType,
            }).then(result => {
                let parsedResult = JSON.parse(result);
                this.noOfRecords = parsedResult.totalSize;
                this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
                this.records = this.buildData(parsedResult.records);
                this.reapplyNewRows();
            }).catch(error => {
                this.isLoading = false;
            })
        } catch (error) {
            this.isLoading = false;
        }
    }

    reapplyNewRows() {
        if (!this.newRecords || this.newRecords.length === 0) return;
        this.newRecords.forEach(newRecord => {
            this.records.unshift(this.buildRecord(newRecord, true));
        })
    }

    allowedToEdit(fieldName) {
        const lockedFields = [
            CommercialPlanDetail_API.Supplier__c,
            CommercialPlanDetail_API.NegoScope__c,
            CommercialPlanDetail_API.Contract__c,
        ];
        if (this.commercialPlanType === 'SellIn') {
            lockedFields.push(CommercialPlanDetail_API.CommercialPlanSellIn__c, CommercialPlanDetail_API.Contract_Discount1__c);
        } else if (this.commercialPlanType === 'SellOut') {
            lockedFields.push(CommercialPlanDetail_API.CommercialPlanSellOut__c, CommercialPlanDetail_API.Contract_DiscountSellOut1__c);
        } else if (this.commercialPlanType === 'Services') {
            lockedFields.push(CommercialPlanDetail_API.CommercialPlanServices__c, CommercialPlanDetail_API.Contract_DiscountServices1__c);
        }
        return !lockedFields.includes(fieldName);
    }

    fillDefaultValuesForNew(newRecord) {
        newRecord[CommercialPlanDetail_API.Supplier__c] = this.commercialPlan[CommercialPlan_API.Supplier__c];
        newRecord[CommercialPlanDetail_API.NegoScope__c] = this.commercialPlan[CommercialPlan_API.NegoScope__c];
        newRecord[CommercialPlanDetail_API.Contract__c] = this.commercialPlan[CommercialPlan_API.Contract__c];
        newRecord[CommercialPlanDetail_API.BusinessUnitTarget__c] = this.commercialPlan[CommercialPlan_API.BusinessUnitTarget__c];
        newRecord[CommercialPlanDetail_API.SellOutBDate__c] = this.commercialPlan[CommercialPlan_API.SellOutBDate__c];
        newRecord[CommercialPlanDetail_API.SellOutEDate__c] = this.commercialPlan[CommercialPlan_API.SellOutEDate__c];
        newRecord[CommercialPlanDetail_API.SellInBDate__c] = this.commercialPlan[CommercialPlan_API.SellInBDate__c];
        newRecord[CommercialPlanDetail_API.SellInEDate__c] = this.commercialPlan[CommercialPlan_API.SellInEDate__c];
        const discountId = this.commercialPlan[CommercialPlan_API.Contract_Discount__c];
        if (this.commercialPlanType === 'SellIn') {
            newRecord[CommercialPlanDetail_API.CommercialPlanSellIn__c] = this.commercialPlan.Id;
            if (discountId) {
                newRecord[CommercialPlanDetail_API.Contract_Discount1__c] = discountId;
            }
        } else if (this.commercialPlanType === 'SellOut') {
            newRecord[CommercialPlanDetail_API.CommercialPlanSellOut__c] = this.commercialPlan.Id;
            if (discountId) {
                newRecord[CommercialPlanDetail_API.Contract_DiscountSellOut1__c] = discountId;
            }
        } else if (this.commercialPlanType === 'Services') {
            newRecord[CommercialPlanDetail_API.CommercialPlanServices__c] = this.commercialPlan.Id;
            if (discountId) {
                newRecord[CommercialPlanDetail_API.Contract_DiscountServices1__c] = discountId;
            }
        }
        return newRecord;
    }

    handleAddCPDLine() {
        let newRecord = {
            attributes: {
                type: CommercialPlanDetail_API.objectApiName,
            },
        }
        newRecord = this.fillDefaultValuesForNew(newRecord);
        this.newRecords.unshift(newRecord);
        this.records.unshift(this.buildRecord(newRecord, true));
    }

    toggleEdit() {
        this.isLoading = true;
        this.isEditMode = true;
        this.records.forEach(item => {
            if (!item.isNew) {
                item.isEditable = true;
            }
        })
        this.isLoading = false;
    }

    handleRemoveNewRow(event) {
        const rowIndex = +event.currentTarget.dataset.index;
        const row = this.records[rowIndex];
        if (!row || !row.isNew) return;
        this.records.splice(rowIndex, 1);
        this.newRecords.splice(rowIndex, 1);
    }

    handleInputChange(event) {
        const recordIndex = +event.target.dataset.index;
        const fieldName = event.target.dataset.fieldName;
        let newValue = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        newValue = (Array.isArray(newValue) ? newValue[0] : newValue) || null;
        const record = this.records[recordIndex];
        let obj;
        if (!record.isNew) {
            if (this.CPDToUpdateMap.hasOwnProperty(record.Id)) {
                obj = this.CPDToUpdateMap[record.Id];
            } else {
                obj = {
                    attributes: {
                        type: CommercialPlanDetail_API.objectApiName,
                    },
                    Id: record.Id
                };
            }
            const originalValue = this.originalValuesById[record.Id][fieldName];
            if (originalValue !== newValue) {
                obj[fieldName] = newValue;
            } else {
                if (obj.hasOwnProperty(fieldName)) {
                    delete obj[fieldName];
                }
                const hasAnyChange = Object.keys(obj).some(k => k !== 'attributes' && k !== 'Id');
                if (!hasAnyChange) {
                    delete this.CPDToUpdateMap[record.Id];
                    return;
                }
            }
        } else {
            this.newRecords[recordIndex][fieldName] = newValue;
            return;
        }
        this.CPDToUpdateMap[record.Id] = obj;
    }

    save() {
        try {
            this.isLoading = true;
            if (!this.newRecords.length && !Object.keys(this.CPDToUpdateMap || {}).length) {
                showNotification(this, this.labels.LBL_Warning, this.labels.MSG_No_Changes_To_Save, 'warning');
                this.isLoading = false;
                return;
            }
            save({
                recordsToUpdate: JSON.stringify(Object.values(this.CPDToUpdateMap)),
                recordsToInsert: JSON.stringify(this.newRecords)
            }).then(result => {
                if (result == 'SUCCESS') {
                    showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                    this.newRecords = [];
                    this.CPDToUpdateMap = {};
                    this.isEditMode = false;
                    this.originalValuesById = {};
                    this.pageNumber = 1;
                    this.loadData();
                } else {
                    showNotification(this, this.labels.LBL_Error, result, 'error');
                    this.isLoading = false;
                }
            }).catch(error => {
                showNotification(this, 'Error', error?.body?.message || error?.message || 'Save failed', 'error');
                this.isLoading = false;
            })
        } catch (error) {
            showNotification(this, 'Error', error?.body?.message || error?.message || 'Save failed', 'error');
            this.isLoading = false;
        }
    }

    confirmDeleteCPD(event) {
        this.isLoading = true;
        let selectedRows = this.records.filter(item => item.isSelected).map(item => item.Id);
        confirmDeleteCPD({
            selectedIds: selectedRows,
            commercialPlanType: this.commercialPlanType,
        }).then(result => {
            this.isLoading = false;
            this.loadData();
        }).catch(error => {
            this.isLoading = false;
        })
    }

    handleCancel() {
        this.isEditMode = false;
        this.newRecords = [];
        this.CPDToUpdateMap = {};
        this.originalValuesById = {};
        this.records = this.records.filter(record => !record.isNew).map(record => ({ ...record, isEditable: false }));
    }

    handleSinglePrint(event) {
        try {
            const selectedFields = [];
            this.displayedFields.forEach(field => {
                selectedFields.push(field.fieldName);
            });
            window.open(`/apex/nTemplate__SingleRecordPrint?Id=${this.recordId}`, "_blank");
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    toggleAllSelectedDeleteMode(event) {
        let checked = event.detail.checked;
        this.records.forEach(item => {
            item.isSelected = checked;
        })
    }

    toggleSelectedRecordsDeleteMode(event) {
        let index = event.currentTarget.dataset.index;
        this.records[index].isSelected = !this.records[index].isSelected;
    }

    buildRecord(item, isNew) {
        let self = this;
        let CPDWrapper = {
            Name: item.Name,
            Id: item.Id || 'newRecord' + Date.now(),
            link: '/' + item.Id,
            isSelected: false,
            values: [],
            isNew: isNew,
            isEditable: isNew ? true : this.isEditMode
        }
        let snapshot = {};
        for (let field of this.displayedFields) {
            let fieldWrapper = {
                Id: item.Id,
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextarea: field.isTextarea,
                isText: field.isText,
                link: '',
                scale: field.scale,
                step: field.step,
                isInputField: field.isInputField && self.allowedToEdit(field.fieldName),
                pickListValues: [],
                style: (field.style ? field.style : '') + 'word-wrap: break-word;white-space: break-spaces;',
            }
            if (field.isInputField && this.CPDToUpdateMap.hasOwnProperty(item.Id)) {
                let obj = this.CPDToUpdateMap[item.Id];
                if (obj.hasOwnProperty(field.fieldName)) {
                    item[field.fieldName] = obj[field.fieldName];
                }
            }
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let val = index == 0 ? item : fieldWrapper.fieldValue;
                if (val) {
                    if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                        fieldWrapper.fieldOutputValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                        fieldWrapper.link = '/' + val[values[index]];
                    } else {
                        fieldWrapper.fieldOutputValue = val[values[index]];
                    }
                    fieldWrapper.fieldValue = val[values[index]];
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
            }
            snapshot[fieldWrapper.fieldName] = fieldWrapper.fieldValue;
            CPDWrapper.values.push(fieldWrapper);
        }
        if (!isNew && !this.originalValuesById.hasOwnProperty(CPDWrapper.Id)) {
            this.originalValuesById[CPDWrapper.Id] = snapshot;
        }
        this.isLoading = false;
        return CPDWrapper;
    }

    buildData(data) {
        let records = [];
        for (let item of data) {
            records.push(this.buildRecord(item, false));
        }
        this.isLoading = false;
        return records;
    }

    changePageSizeHandler(event) {
        this.pageSize = parseInt(event.detail.value);
        this.pageNumber = 1;
        this.loadData();
    }

    handleChangePage(event) {
        this.isLoading = true;
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
        this.loadData();
    }

    get previousDisabled() {
        return (this.pageNumber <= 1);
    }

    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.noOfRecords ? this.pageNumber * pageSize + 1 - pageSize : this.noOfRecords - this.records.length) + '-' + (this.pageNumber * pageSize > this.noOfRecords ? this.noOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.noOfRecords;
    }

    get hasMaster() {
        return this.gridSettingsManager && this.gridSettingsManager.hasMaster;
    }

    get iconName() {
        return this.gridSettingsManager && this.gridSettingsManager.iconName && this.gridSettingsManager.iconSection ? this.gridSettingsManager.iconSection + ':' + this.gridSettingsManager.iconName : 'standard:orders';
    }

    //GETTERS
    get pageSizeOptions() {
        return [
            { label: '5', value: 5 },
            { label: '10', value: 10 },
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '75', value: 75 },
            { label: '100', value: 100 }];
    }

    get hasFilterSettingsFields() {
        return this.gridSettingsManager && this.gridSettingsManager.gridLayout && this.gridSettingsManager.gridLayout[this.prefix + 'Filters__c'] && JSON.parse(this.gridSettingsManager.gridLayout[this.prefix + 'Filters__c']).some(filter => filter.userFilterable === true);
    }

    get isAllSelectedDeleteMode() {
        return this.records.length > 0 && this.records.every(item => item.isSelected);
    }

    get colspan() {
        return this.displayedFields.length + 1;
    }

    get showDelete() {
        return this.records.filter(item => item.isSelected).length > 0;
    }

    changeHeight = () => this.setTableDimension();
    setTableDimension() {
        let header = this.template.querySelector('.pageHeader');
        let master = this.template.querySelector('.masterStyle');
        let body = this.template.querySelector('.main-panel');
        let footer = this.template.querySelector('.footerDiv');
        let baseHeight;
        if (header && body && footer) {
            let headerHeight = header.getBoundingClientRect().height;
            let footerHeight = footer.getBoundingClientRect().height;
            baseHeight = window.innerHeight - headerHeight - footerHeight - (3 * 45);
            if (master) {
                let masterHeight = master.getBoundingClientRect().height;
                baseHeight -= masterHeight;
            }
            body.style.height = baseHeight + 'px';
        }
        let minHeight = 300;
        let filterFooter = this.template.querySelector('.filterFooter')?.getBoundingClientRect().height;
        let bodyHeight = parseFloat(baseHeight);
        if (this.template.querySelector('.filterBody')) {
            this.template.querySelector('.filterBody').style.height = (bodyHeight - filterFooter) + 'px';
            this.template.querySelector('.filterBody').style.minHeight = (minHeight - filterFooter) + 'px';
        }
    }

    setStickyHeader() {
        let tableTrs = this.template.querySelector('.main-table')?.rows;
        if (tableTrs) {
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index == 0) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.top = 0 + 'px';
                        childrens[index2].style.zIndex = 3;
                    }
                }
            }
        }
    }

    // ===== dynamicFilterPanel helpers =====
    buildSeedsFromDynamic(jsonStr) {
        try {
            const arr = JSON.parse(jsonStr || '[]');
            if (!Array.isArray(arr) || !arr.length) return {};
            const seeds = {};
            arr.forEach(it => {
                const key = it.fieldName;
                if (!key) return;
                const s = {};
                if (Array.isArray(it.values)) s.values = [...it.values];
                if (it.value1 !== undefined) s.value1 = it.value1;
                if (it.value2 !== undefined) s.value2 = it.value2;
                seeds[key] = s;
            });
            return seeds;
        } catch (_) { return {}; }
    }

    pushFiltersConfigToChild() {
        try {
            const child = this.template.querySelector('c-dynamic-filter-panel');
            if (!child) return;
            const seeds = this.buildSeedsFromDynamic(this.filters.dynamic);
            child.open = this.isFilterOpen;
            child.refreshFilters(this.dfpConfig, seeds);
        } catch (e) { /* no-op */ }
    }

}