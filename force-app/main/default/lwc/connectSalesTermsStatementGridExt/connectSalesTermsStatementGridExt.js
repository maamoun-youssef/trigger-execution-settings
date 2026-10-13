import { LightningElement, track, api, wire  } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from 'lightning/platformResourceLoader';
//APEX
import initData from "@salesforce/apex/ConnectSalesTermsStatementGridExt.initData";
import loadData from '@salesforce/apex/ConnectSalesTermsStatementGridExt.loadData';
import save from '@salesforce/apex/ConnectSalesTermsStatementGridExt.save';
//STATIC RESOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import Plus_Icon from '@salesforce/resourceUrl/Plus_Icon';

import { labels } from './properties.js';
import ServiceStatement__OBJECT from '@salesforce/schema/TMP_ServiceStatement__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class ConnectSalesTermsStatementGridExt extends LightningElement {
    @api flowApiName = 'SCREEN_Connect_Sales_Terms_Statement_Creation';

    @track isLoading = true;
    @track displayedFields = [];
    @track gridSettingsManager = {};
    @track pageSize = 25;
    @track records = [];
    @track noOfRecords = 0;
    @track hasValidGridTemplate = true;
    @track headerTitle = 'Sales Terms Statements';
    @track openFlow = false;
    @track labels = { ...labels }
    @track nbOfFixedColumns = 1;
    @track originalFieldValuesMap = {};
    @track recordsToUpdateMap = {};   
    @track newRecords = [];
    @track serviceStatementObject = ServiceStatement__OBJECT; 
    @track mainPanelHeight;
    @track salesStatementObjectName = '';
    
    totalPagesCount = 0;
    pageNumber = 1;
    @track plusIconUrl = Plus_Icon;
    @track WireVariables = {
        objectInfoServiceStatement: false
    }

    @wire(getObjectInfo, { objectApiName: ServiceStatement__OBJECT.objectApiName }) objectInfoServiceStatement({ error, data }) {
        if (data) {
            this.salesStatementObjectName = data.label;
            this.WireVariables.objectInfoServiceStatement = true;
            this.init();
        }
    }
    init() {
        if (this.WireVariables.objectInfoServiceStatement) {
            this.initData();
        }
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

    get colspan() {
        return this.displayedFields.length + 1;
    }

    get pageSizeOptions() {
        return [
            { label: '5', value: 5 },
            { label: '10', value: 10 },
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '75', value: 75 },
            { label: '100', value: 100 }];
    }
    get objectApiName() {
        return (this.gridSettingsManager && this.gridSettingsManager.OBJECT_NAME) ? this.gridSettingsManager.OBJECT_NAME : null;
    }

    showNotification(title, message, variant = 'info', mode = 'dismissible') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    connectedCallback() {
        Promise.all([loadStyle(this, negOptimGlobalCSS)])
            .then(() => { this.initData(); })
            .catch(error => { console.log('error loading style', error); });
        // window.addEventListener('resize', this.changeHeight);     
       window.addEventListener('resize', this.setPageSize);
    }

    renderedCallback() {
       this.setPageSize();
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

    initData() {
        this.isLoading = true;
        initData().then(result => {
            let parsedData = JSON.parse(result);
            this.gridSettingsManager = parsedData.gridSettingsManager;
            console.log("TEST_TEST",JSON.stringify(this.gridSettingsManager))
            let title = this.labels.LBL_Connect_SalesTermsStatement;
            const gsm = this.gridSettingsManager || {};
            // if (gsm.gridLayout && (gsm.gridLayout.MasterLabel || gsm.gridLayout.Name)) {
            //     title = gsm.gridLayout.MasterLabel || gsm.gridLayout.Name;
            // } else if (gsm.MasterLabel) {
            //     title = gsm.MasterLabel;
            // } else if (gsm.layoutLabel) {
            //     title = gsm.layoutLabel;
            // }
            this.headerTitle = gsm.layoutLabel;
            this.hasValidGridTemplate = (this.gridSettingsManager && this.gridSettingsManager.gridLayout !== null
                && Array.isArray(this.gridSettingsManager.GRID_FIELDS) && this.gridSettingsManager.GRID_FIELDS.length > 0);
            if (this.gridSettingsManager.Default_Page_Size) {
                this.pageSize = parseInt(this.gridSettingsManager.Default_Page_Size);
            }
            this.buildDisplayedFields();
        }).catch(error => {
            this.isLoading = false;
        });
    }

    buildDisplayedFields() {
        this.displayedFields = [];
        for (let field of this.gridSettingsManager.GRID_FIELDS) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: field.fieldType === 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                link: '',
                scale: field.scale,
                step: '',
                //isInputField: field.isInputField,
                style: field.style,
                headerStyle: field.widthStyle + (field.headerStyle ? field.headerStyle.style : ''),
                pickListValues: field.pickListValues,
                isSortable: field.isSortable,
                isFilterable: field.isFilterable,
                isEncrypted: field.isEncrypted,
                filterValue: '',
                sortedField: false,
            };
            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference &&
                                  !fieldWrapper.isDate && !fieldWrapper.isDateTime &&
                                  !fieldWrapper.isPicklist && !fieldWrapper.isBoolean &&
                                  !fieldWrapper.isTextarea;
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
        this.isLoading = true;
        loadData({
        gridSettings: JSON.stringify(this.gridSettingsManager),
        pageSize: this.pageSize,
        pageNumber: this.pageNumber
        })
        .then(result => {
            const parsed = JSON.parse(result);
            this.noOfRecords = parsed.totalSize || 0;
            this.totalPagesCount = Math.ceil(this.noOfRecords / this.pageSize);
            this.records = this.buildData(parsed.records || []);
            this.isLoading = false;                     
        })
        .catch(e => { this.isLoading = false; console.error(e); });
    }

    buildData(data) {
        let records = [];
        for (let item of data) {
            records.push(this.buildRecord(item, false));
        }
        this.isLoading = false;
        return records;
    }

    buildRecord(item) {
        const recordWrapper = {
            Id: item.Id,
            isSelected: false,
            values: []
        };

        for (let field of this.displayedFields) {
            const fieldWrapper = {
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
            //isInputField: field.isInputField,
            link: field.fieldName == 'Name' ? '/' + item.Id : '',
            isNameField: field.fieldName == 'Name',
            scale: field.scale,
            step: field.step,
            pickListValues: field.pickListValues || [],
            style: (field.style ? field.style : '') + 'word-wrap: break-word;white-space: break-spaces;',
            };
            const parts = field.fieldName.split('.');
            for (let i = 0; i < parts.length; i++) {
            const current = (i === 0 ? item : fieldWrapper.fieldValue);
            if (!current) break;

            if (i == parts.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                fieldWrapper.fieldOutputValue =
                current[parts[i].replace('__c', '__r').replace('Id', '')]?.Name;
                fieldWrapper.link = '/' + current[parts[i]];
            } else {
                fieldWrapper.fieldOutputValue = current[parts[i]];
            }
            fieldWrapper.fieldValue = current[parts[i]];
            }
            if (fieldWrapper.isPicklist) {
                const raw = Array.isArray(field.pickListValues) ? field.pickListValues : [];
                const current = (fieldWrapper.fieldValue === null || typeof fieldWrapper.fieldValue === 'undefined') ? '' : String(fieldWrapper.fieldValue);
                fieldWrapper.pickListValues = raw.map(opt => ({
                    label: opt.label,
                    value: String(opt.value),
                    isSelected: String(opt.value) === current,
                    isDisabled: opt.isDisabled === true
                }));
                if (!fieldWrapper.fieldOutputValue) {
                    const hit = fieldWrapper.pickListValues.find(o => o.isSelected);
                    fieldWrapper.fieldOutputValue = hit ? hit.label : current;
                }
            }
            recordWrapper.values.push(fieldWrapper);
        }
        return recordWrapper;
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

    toggleFlow() {
        this.openFlow = !this.openFlow;
    }

    handleFlowStatusChange(event) {
        const status = event.detail?.status;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.pageNumber = 1;
            this.loadData();
            this.openFlow = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Sales Terms Statement created.',
                    variant: 'success'
                })
            );
        } else if (status === 'ERROR') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Flow Error',
                    message: 'The creation flow encountered an error.',
                    variant: 'error'
                })
            );
        }
    }

    handleFieldEdits(event) {
        const id = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const isBoolean = event.target.dataset.isboolean === 'true';
        let rawValue = isBoolean ? event.target.checked : event.target.value;
        const rowIndex = parseInt(event.target.dataset.rowindex, 10);
        const fieldIndex = parseInt(event.target.dataset.fieldindex, 10);
        const row = this.records[rowIndex];
        const meta = row.values[fieldIndex];
        const prevValue = meta.fieldValue;
        const isNumberField = meta && meta.isNumberField === true;
        let newValue = rawValue;
        if (isNumberField) {
            newValue = (newValue === '' || newValue === null || typeof newValue === 'undefined')
                ? null
                : Number(newValue);
        }
        const mapKey = `${id}_${fieldName}`;
        if (!this.originalFieldValuesMap.hasOwnProperty(mapKey)) {
            this.originalFieldValuesMap[mapKey] = prevValue;
        }
        const originalValue = this.originalFieldValuesMap[mapKey];
        const normalize = (v) => (v === '' || typeof v === 'undefined') ? null : v;
        const oldValue = isNumberField
            ? ((originalValue === '' || originalValue === null || typeof originalValue === 'undefined') ? null : Number(originalValue))
            : normalize(originalValue);
        const comparedNew = isNumberField
            ? ((newValue === '' || newValue === null || typeof newValue === 'undefined') ? null : Number(newValue))
            : normalize(newValue);
        meta.fieldValue = Array.isArray(newValue) ? newValue[0] : newValue;
        if (oldValue === comparedNew) {
            const obj = this.recordsToUpdateMap[id];
            if (obj) {
                if (obj.hasOwnProperty(fieldName)) delete obj[fieldName];
                if (Object.keys(obj).length <= 2) { 
                    delete this.recordsToUpdateMap[id];
                }
            }
        } else {
            let obj = this.recordsToUpdateMap[id];
            if (!obj) {
                obj = {
                    attributes: { type: this.serviceStatementObject.objectApiName || 'TMP_ServiceStatement__c' },
                    Id: id
                };
            }
            obj[fieldName] = comparedNew;
            this.recordsToUpdateMap[id] = obj;
        }
    }

    handleSave() {
        this.isLoading = true;
        const payload = [];
        if (this.newRecords?.length) {
            for (const r of this.newRecords) payload.push(r);
        }
        if (this.recordsToUpdateMap && Object.keys(this.recordsToUpdateMap).length > 0) {
         for (const id in this.recordsToUpdateMap) payload.push(this.recordsToUpdateMap[id]);
        }
        const seen = new Set();
        const deduped = [];
        for (const o of payload) {
            const key = o.Id ? `Id:${o.Id}` : `new:${JSON.stringify(o)}`;
            if (seen.has(key)) continue;
            seen.add(key);
            deduped.push(o);
        }
        if (deduped.length === 0) {
            this.isLoading = false;
            this.showNotification('Warning', this.labels.MSG_No_Changes_To_Save || 'No changes to save', 'warning');
            return;
        }
        save({ dataToSave: JSON.stringify(deduped) })
            .then(err => {
            if (!err) {
                this.newRecords = [];
                this.recordsToUpdateMap = {};
                this.originalFieldValuesMap = {};
                this.loadData();
                this.showNotification('Success', this.labels.MSG_Successfully_Saved || 'Saved successfully', 'success');
            } else {
                this.showNotification(this.labels.LBL_Error || 'Error', err, 'error');
            }
            })
            .catch(e => {
            this.showNotification(this.labels.LBL_Error || 'Error', (e?.body?.message || e?.message || 'saving error'), 'error', 'sticky');
            console.error(e);
            })
            .finally(() => { this.isLoading = false; });
    }
}