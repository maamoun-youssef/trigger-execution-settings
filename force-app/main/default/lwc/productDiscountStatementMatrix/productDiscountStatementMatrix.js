import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
//APEX
import initData from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.initData";
import loadData from '@salesforce/apex/ProductDiscountStatementMatrixCtrl.loadData';
import processRestForExcel from '@salesforce/apex/ProductDiscountStatementMatrixCtrl.processRestForExcel';
import loadBatchesHistory from '@salesforce/apex/ProductDiscountStatementMatrixCtrl.loadBatchesHistory';
import saveData from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.saveData";
import scanPDSD from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.scanPDSD";
import synchroPDSD from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.synchroPDSD";
import importPDSD from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.importPDSD";
import deletePDSD from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.deletePDSD";
import getImportOutcome from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.getImportOutcome";
import updatePDSDStatus from "@salesforce/apex/ProductDiscountStatementMatrixCtrl.updatePDSDStatus";
//STATIC RESOURCES
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import ValidatedIcon from '@salesforce/resourceUrl/Validated_Icon';
import RejectedIcon from '@salesforce/resourceUrl/Rejected_Icon';
import { labels, ProductDiscountStatement_API, ProductDiscountStatementDetail_API, Product_API, Contract_Discount_API, Batch_API, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES } from './properties.js';
import { checkCompletedBatches, showNotification } from "c/appHelper";
import userLocal from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
// USER
import userId from '@salesforce/user/Id';
import UserContactFIELD from '@salesforce/schema/User.ContactId';
export default class ProductDiscountStatementMatrix extends NavigationMixin(LightningElement) {
    @api recordId;
    @track PDSName = '';
    @track flow = {
        flowApiName: '',
        variables: []
    };
    @track openFlow = false;
    @track hierarchyLabel = '';
    @track PDSObjectName = '';
    @track importSettings = '';
    @track Contract_Discount_API = Contract_Discount_API;
    //labels
    @track labels = {
        ...labels,
        ProductDiscountStatementDetail__c: {
            ScanStatus__c: '',
        },
    }
    @track pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];
    @track records = [];
    @track displayedFields = [];
    @track noOfRecords = 0;
    totalPagesCount = 0;
    @track lookupName = ProductDiscountStatement_API.objectApiName;
    @track detailApiName = ProductDiscountStatementDetail_API.objectApiName;
    @track isEditMode = false;
    @track PdsdToUpdateMap = {};
    isLoading = true;
    pageNumber = 1;
    fileData = {};
    fileDirectoryId;
    importedRecords = [];
    @track gridSettings = {};
    @track pageSize = '25';
    @track reminderMessage = '';
    @track showHistory = false;
    @track showDeletePopup = false;
    @track isAdmin = false;
    @track showScan = false;
    @track showSynchro = false;
    @track havingRequestedLines = false;
    @track allRecordIds = [];
    @track recordIdsToValidate = [];
    @track recordIdsToReject = [];
    @track recordIdsToRespond = [];
    @track recordIdsToSubmit = [];
    @track isUserPortalEnabled = false;
    @track productDiscountStatement = {};
    @track supplierContactUserId = '';
    @track idsToDelete = [];
    @track isFilterOpen = false;
    @track fieldsToFilter = [];
    fieldsToFilterMap = {};
    @track hierarchyMapArray = [];
    @track firstsThStyle = '';
    @track prefix = '';
    @track filters = {
        dynamic: '',
        scanStatus: [],
        isUserPortalEnabled: false,
        sender: ''
    }
    @track firstTime = true;
    @track productHistory = {
        fields: [],
        rows: [],
    };
    allRecordsToExport;
    @track isPortal = false;
    @track selectedRecordIds = [];
    @track statusMessage = '';
    @track WireVariables = {
        objectInfoPDS: false,
        objectInfoPDSD: false,
        objectInfoProduct: false,
        getPageReference: false,
    }
    @track currentFlow = {
        header: '',
        flowApiName: '',
        flowVariables: '',
    }
    @track stringifiedSelectedScanStatus = '["error","warning","success"]';
    @track scanStatusOptions = JSON.stringify([
        { label: labels.LBL_PDS_Matrix_Show_Lines_With_Scan_Error, value: "error" },
        { label: labels.LBL_PDS_Matrix_Show_Lines_With_Scan_Warning, value: "warning" },
        { label: labels.LBL_PDS_Matrix_Show_Lines_With_Scan_Success, value: "success" }
    ]);
    @track initFieldValuesMap = {};
    @track showInstructions = true;

    @track staticResourceUrl = {
        ValidatedIcon: ValidatedIcon,
        RejectedIcon: RejectedIcon,
    }

    Events = {
        handleChangeScanStatus: 'handlechangescanstatus'
    }

    @track customLookups = {
        Contract_Discount__c: {
            event: 'selectdiscountaction',
            fieldName: Contract_Discount_API.Commercial_Reference__c + ',' + Contract_Discount_API.Product_Scope__r + '.Name,Name',
            searchFields: ['Name'],
        },
    }

    @wire(getObjectInfo, { objectApiName: ProductDiscountStatement_API.objectApiName }) objectInfoPDS({ error, data }) {
        if (data) {
            this.PDSObjectName = data.label;
            this.WireVariables.objectInfoPDS = true;
            this.init();
        }
    }

    @wire(getObjectInfo, { objectApiName: ProductDiscountStatementDetail_API.objectApiName }) objectInfoPDSD({ error, data }) {
        if (data) {
            this.labels.ProductDiscountStatementDetail__c.ScanStatus__c = data.fields[ProductDiscountStatementDetail_API.ScanStatus__c].label;
            this.WireVariables.objectInfoPDSD = true;
            this.init();
        }
    }

    @wire(getObjectInfo, { objectApiName: Product_API.objectApiName }) objectInfoProduct({ error, data }) {
        if (data) {
            this.hierarchyLabel = data.fields[Product_API.Hierarchy__c]?.label?.toUpperCase();
            this.WireVariables.objectInfoProduct = true;
            this.init();
        }
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                this.recordId = pageRef.state.c__recordId != null ? pageRef.state.c__recordId : this.recordId;
            }
            this.WireVariables.getPageReference = true;
            this.init();
        } catch (error) {
            this.handleError(error, 'getPageReference');
        }
    }


    /** 
     * quickActionMenu should only render if *either* scan or synchro is on
     */
    get showQuickActionMenu() {
        return this.showScan || this.showSynchro || this.actionFlows.length > 0;
    }

    /** 
     * true whenever neither scan nor synchro is available, and we’re NOT already in edit mode 
     */
    get showStandaloneEdit() {
        return !this.showQuickActionMenu && !this.isEditMode;
    }

    get recordsLength() {
        return this.records.reduce((sum, hierarchy) => {
            return sum + (hierarchy.PDSDList ? hierarchy.PDSDList.length : 0);
        }, 0);
    }

    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.noOfRecords ? this.pageNumber * pageSize + 1 - pageSize : this.noOfRecords - this.recordsLength) + '-' + (this.pageNumber * pageSize > this.noOfRecords ? this.noOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.noOfRecords;
    }

    get isAllSelected() {
        return this.recordsLength > 0 && this.records.every(hierarchy =>
            hierarchy.PDSDList.every(item => item?.isSelected === true)
        );
    }

    get hasFilterSettingsFields() {
        return this.gridSettings && this.gridSettings.gridLayout && this.gridSettings.gridLayout.Filters__c && JSON.parse(this.gridSettings.gridLayout.Filters__c).some(filter => filter.userFilterable === true);
    }

    get hasMaster() {
        return this.gridSettings && this.gridSettings.hasMaster;
    }

    get showDelete() {
        return this.selectedRecordIds.length > 0;
    }

    get showRespond() {
        return this.productDiscountStatement && !this.isUserPortalEnabled && this.recordIdsToRespond && this.recordIdsToRespond.length > 0;
    }

    get showValidate() {
        return this.productDiscountStatement && !this.isUserPortalEnabled && this.recordIdsToValidate && this.recordIdsToValidate.length > 0;
    }

    get showReject() {
        return this.productDiscountStatement && !this.isUserPortalEnabled && this.recordIdsToReject && this.recordIdsToReject.length > 0;
    }

    get showSubmit() {
        return this.productDiscountStatement && this.recordIdsToSubmit && this.recordIdsToSubmit.length > 0 && ((this.isUserPortalEnabled && (this.productDiscountStatement[ProductDiscountStatement_API.Sender__c] == 'Supplier' || (this.productDiscountStatement[ProductDiscountStatement_API.Sender__c] == 'Buyer'))) || (!this.isUserPortalEnabled && this.productDiscountStatement[ProductDiscountStatement_API.Sender__c] == 'Buyer'));
    }

    get showImport() {
        return this.productDiscountStatement && ((this.isUserPortalEnabled && this.productDiscountStatement[ProductDiscountStatement_API.Sender__c] == 'Supplier') || (!this.isUserPortalEnabled && this.productDiscountStatement[ProductDiscountStatement_API.Sender__c] == 'Buyer'));
    }

    get iconFlows() {
        return this.gridSettings && this.gridSettings.actions && this.gridSettings.actions.screenFlows && this.gridSettings.actions.screenFlows.length > 0
            ? this.gridSettings.actions.screenFlows.filter(f => f.value && f.displayType && f.displayType === 'Icon')
            : [];
    }

    get buttonFlows() {
        return this.gridSettings && this.gridSettings.actions && this.gridSettings.actions.screenFlows && this.gridSettings.actions.screenFlows.length > 0
            ? this.gridSettings.actions.screenFlows.filter(f => f.value && f.displayType && f.displayType === 'Button')
            : [];
    }

    get actionFlows() {
        return this.gridSettings && this.gridSettings.actions && this.gridSettings.actions.screenFlows && this.gridSettings.actions.screenFlows.length > 0
            ? this.gridSettings.actions.screenFlows.filter(f => f.value && f.displayType && f.displayType === 'Action')
            : [];
    }

    toggleInstructions() {
        this.showInstructions = !this.showInstructions;
    }

    getIconForScanStatus(scanStatus) {
        switch (scanStatus) {
            case 'Error':
                return { icon: 'utility:error', title: labels.LBL_PDS_Matrix_Scan_Error_Tooltip, class: 'error-icon' };
            case 'Warning':
                return { icon: 'utility:warning', title: labels.LBL_PDS_Matrix_Scan_Warning_Tooltip, class: 'warning-icon' };
            case 'Success':
                return { icon: 'utility:success', title: labels.LBL_PDS_Matrix_Scan_Successful_Tooltip, class: 'success-icon' };
            default:
                return { icon: '', title: '', class: '' };
        }
    }

    renderedCallback() {
        this.setStickyHeader();
        if (this.template.querySelector('.main-panel')) {
            this.changeHeight();
        }
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
            loadScript(this, ExcelJSURL)
        ]).then(() => {
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });
        window.addEventListener('resize', this.changeHeight);
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
    //LIFECYCLE
    init() {
        if (this.WireVariables.getPageReference && this.WireVariables.objectInfoPDS && this.WireVariables.objectInfoPDSD && this.WireVariables.objectInfoProduct) {
            this.initData();
        }
    }

    initData() {
        initData({
            recordId: this.recordId
        }).then(result => {
            let parsedData = JSON.parse(result);
            console.log('initData >>> ' + JSON.stringify(parsedData))
            if (parsedData.errorMessage) {
                showNotification(this, this.labels.LBL_Error, parsedData.errorMessage, 'error');
                console.log('errorMessage %c' + parsedData.errorMessage, 'color : red');
                console.log('errorMessage %c' + parsedData.errorMessage, 'color : red');
                this.isLoading = false;
            } else {
                this.prefix = parsedData.prefix;
                this.isAdmin = parsedData.isAdmin;
                this.showScan = parsedData.showScan;
                this.showSynchro = parsedData.showSynchro;
                this.havingRequestedLines = parsedData.havingRequestedLines;
                this.isUserPortalEnabled = parsedData.isUserPortalEnabled;
                this.productDiscountStatement = parsedData.productDiscountStatement;
                this.supplierContactUserId = parsedData.supplierContactUserId;
                this.isPortal = parsedData.isPortal;
                this.gridSettings = JSON.parse(parsedData.data).gridSettingsManagerPDS;
                const invalidChars = /[\\/*[\]:?]/g;
                this.PDSName = parsedData.name.replace(invalidChars, '-');
                this.importSettings = JSON.parse(parsedData.data).importSettings;
                this.filters.scanStatus = this.stringifiedSelectedScanStatus;
                this.filters.isUserPortalEnabled = this.isUserPortalEnabled;
                this.filters.sender = this.productDiscountStatement[ProductDiscountStatement_API.Sender__c];
                this.buildDisplayedFields();
                let bannerRecord = JSON.parse(parsedData.bannerRecord);
                if (bannerRecord) {
                    this.buildBannerData(bannerRecord);
                }
                this.populateFiltersMap(this.gridSettings.FILTERS);
            }
        }).catch(error => {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('initData %c' + error.message, 'color : red');
            console.log('initData %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    @track bannerValues = [];
    buildBannerData(record) {
        try {
            for (let field of this.gridSettings.BANNER_FIELDS) {
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
                    pickListValues: field.pickListValues,
                    fieldValue: record[field.fieldName],
                }
                if (fieldWrapper.isReference) {
                    fieldWrapper.fieldValue = record[field.fieldName.replace(/__c$/, '__r')]?.Name;
                    fieldWrapper.link = '/' + record[field.fieldName];
                }
                this.bannerValues.push(fieldWrapper);
            }
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildBannerData: %c' + error.message, 'color : red');
            console.log('buildBannerData: %c' + error.body?.message, 'color : red');
        }
    }

    buildDisplayedFields() {
        try {
            this.displayedFields = [];
            for (let field of this.gridSettings.GRID_FIELDS) {
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
                    headerStyle: field.stringHeaderStyle,
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
            this.firstsThStyle = (this.displayedFields[0].headerStyle ? this.displayedFields[0].headerStyle : '') + 'text-align: center;';
            this.loadData();
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    loadData() {
        try {
            this.records = [];
            try {
                this.isLoading = true;
                loadData({
                    recordId: this.recordId,
                    gridSettings: JSON.stringify(this.gridSettings),
                    pageNumber: this.pageNumber,
                    pageSize: this.pageSize,
                    filters: JSON.stringify(this.filters),
                }).then(result => {
                    let parsedResult = JSON.parse(result);
                    console.log('loadData >>> ' + JSON.stringify(parsedResult))
                    this.allRecordIds = parsedResult.allRecordIds;
                    this.recordIdsToValidate = parsedResult.recordIdsToValidate;
                    this.recordIdsToReject = parsedResult.recordIdsToReject;
                    this.recordIdsToRespond = parsedResult.recordIdsToRespond;
                    this.recordIdsToSubmit = parsedResult.recordIdsToSubmit;
                    this.noOfRecords = parsedResult.totalSize;
                    this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
                    this.records = this.buildData(parsedResult.records);
                }).catch(error => {
                    showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                    console.log('loadData: %c' + error.message, 'color : red');
                    console.log('loadData: %c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                })
            } catch (error) {
                showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                console.log('loadData: %c' + error.message, 'color : red');
                console.log('loadData: %c' + error.body?.message, 'color : red');
                this.isLoading = false;
            }
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
        }
    }

    handleChangeScanStatus(event) {
        try {
            let values = [];
            event.detail.selOptions.forEach(item => {
                if (item.hasOwnProperty('value')) {
                    values.push(item.value);
                } else {
                    values.push(item);
                }
            });
            if (values.includes("ALL")) {
                this.filters.scanStatus = [];
            } else {
                this.stringifiedSelectedScanStatus = JSON.stringify(values);
                this.filters.scanStatus = this.stringifiedSelectedScanStatus;
            }

            this.loadData();
        } catch (e) {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('handleChangeScanStatus: %c' + error.message, 'color : red');
            console.log('handleChangeScanStatus: %c' + error.body?.message, 'color : red');
        }
    }



    handleExportExcel() {
        this.allRecordsToExport = [];
        try {
            this.isLoading = true;
            processRestForExcel({
                recordId: this.recordId,
                gridSettings: JSON.stringify(this.gridSettings),
                restURL: null
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.error != null) {
                        showNotification(this, this.labels.LBL_Error, parsedResult.error, 'error');
                        return;
                    }
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                        }
                        if (parsedResult.done) {
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                }
            }).catch((error) => {
                showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.isLoading = false;
            });
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    excelLoadMore(nextRecordsUrl) {
        processRestForExcel({
            restURL: nextRecordsUrl,
        }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result)
                try {
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                        }
                        if (parsedResult.done) {
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                }
            }
        });
    }

    buildExcel() {
        let dataToExport = this.buildData(this.allRecordsToExport);
        try {
            const workbook = new ExcelJS.Workbook();
            workbook.properties.date1904 = true;
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet(this.PDSName, { properties: { tabColor: { argb: 'worksheet' } } });
            let rowCounter = 1;
            const headerRow1 = worksheet.getRow(rowCounter);
            const header1Values = [];
            header1Values.push(this.hierarchyLabel);
            const colWidthStyle = [];
            const headerStyles = [];
            const styles = [];
            for (let field of this.displayedFields) {
                header1Values.push(field.fieldLabel);
                colWidthStyle.push(30);
                headerStyles.push(field.headerStyle);
                styles.push(field.style);
            }
            headerRow1.values = header1Values;
            rowCounter++;
            headerRow1.eachCell(function (cell, colNumber) {
                const style = headerStyles[colNumber - 2] || '';
                const bgMatch = style.match(/(?:^|;)\s*background-color:\s*#([0-9a-fA-F]{6})/);
                const colorMatch = style.match(/(?:^|;)\s*color:\s*#([0-9a-fA-F]{6})/);
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: bgMatch ? bgMatch[1] : 'FFE6E6E6' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: colorMatch ? colorMatch[1] : 'FF000000' },
                }
                cell.border = {
                    top: { style: 'thin', color: { argb: 'FFE6E6E6' } },
                    left: { style: 'thin', color: { argb: 'FFE6E6E6' } },
                    bottom: { style: 'thin', color: { argb: 'FFE6E6E6' } },
                    right: { style: 'thin', color: { argb: 'FFE6E6E6' } }
                };
                cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center' };
            });
            for (let hierarchy of dataToExport) {
                let index = 0;
                for (let record of hierarchy.PDSDList) {
                    let rowLine = worksheet.getRow(rowCounter);
                    let rowValues = [];
                    if (index == 0) {
                        rowValues.push(hierarchy.Name);
                    } else {
                        rowValues.push('');
                    }
                    for (let value of record.values) {
                        if (value.isDate && value.fieldValue != null) {
                            rowValues.push(new Date(value.fieldValue));
                        } else if (value.isDateTime && value.fieldValue != null) {
                            let formatter = new Intl.DateTimeFormat(userLocal);
                            let date = new Date(value.fieldValue);
                            let fullDate;
                            if (formatter) {
                                const easternTime = date.toLocaleString(userLocal, { timeZone: TIME_ZONE });
                                fullDate = easternTime;
                            }
                            rowValues.push(fullDate);
                        } else if (value.isPicklist || value.isReference) {
                            rowValues.push(value.fieldOutputValue || '');
                        } else {
                            rowValues.push(value.fieldValue || '');
                        }
                    }
                    rowLine.height = 35;
                    rowLine.values = rowValues;
                    rowLine.eachCell(function (cell, colNumber) {
                        const style = styles[colNumber - 2] || '';
                        // Color matches
                        const bgMatch = style.match(/(?:^|;)\s*background-color:\s*#([0-9a-fA-F]{6})/);
                        const colorMatch = style.match(/(?:^|;)\s*color:\s*#([0-9a-fA-F]{6})/);
                        // Font matches
                        const fontWeightMatch = style.match(/(?:^|;)\s*font-weight:\s*(\w+)/i);
                        const fontSizeMatch = style.match(/(?:^|;)\s*font-size:\s*(\d+)px/i);
                        const fontStyleMatch = style.match(/(?:^|;)\s*font-style:\s*(\w+)/i);
                        const textDecorationMatch = style.match(/(?:^|;)\s*text-decoration:\s*([^;]+)/i);
                        // Alignment match
                        const textAlignMatch = style.match(/(?:^|;)\s*text-align:\s*(\w+)/i);
                        // Border matches
                        const borderColorMatch = style.match(/(?:^|;)\s*border-color:\s*#([0-9a-fA-F]{6})/);
                        const borderStyleMatch = style.match(/(?:^|;)\s*border-style:\s*([^;]+)/i);
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: bgMatch ? bgMatch[1] : 'FFFFFFFF' },
                        };
                        const isUnderline = textDecorationMatch && textDecorationMatch[1].includes('underline');
                        const isStrikethrough = textDecorationMatch && textDecorationMatch[1].includes('line-through');
                        cell.font = {
                            bold: fontWeightMatch ? fontWeightMatch[1].toLowerCase() === 'bold' : true,
                            italic: fontStyleMatch ? fontStyleMatch[1].toLowerCase() === 'italic' : false,
                            underline: isUnderline,
                            strike: isStrikethrough,
                            size: fontSizeMatch ? parseInt(fontSizeMatch[1]) : 11,
                            color: { argb: colorMatch ? colorMatch[1] : 'FF000000' },
                        }
                        const cssStyle = borderStyleMatch ? borderStyleMatch[1] : 'solid';
                        const styleMap = {
                            'none': null,
                            'unset': null,
                            'dotted': 'dotted',
                            'solid': 'thin',
                            'double': 'double',
                            'dashed': 'dashDot',
                            'ridge': 'medium',
                            'inset': 'medium',
                            'outset': 'medium'
                        };
                        cell.border = {
                            top: { style: styleMap[cssStyle] !== undefined ? styleMap[cssStyle] : 'thin', color: { argb: borderColorMatch ? borderColorMatch[1] : 'FFE6E6E6' } },
                            left: { style: styleMap[cssStyle] !== undefined ? styleMap[cssStyle] : 'thin', color: { argb: borderColorMatch ? borderColorMatch[1] : 'FFE6E6E6' } },
                            bottom: { style: styleMap[cssStyle] !== undefined ? styleMap[cssStyle] : 'thin', color: { argb: borderColorMatch ? borderColorMatch[1] : 'FFE6E6E6' } },
                            right: { style: styleMap[cssStyle] !== undefined ? styleMap[cssStyle] : 'thin', color: { argb: borderColorMatch ? borderColorMatch[1] : 'FFE6E6E6' } }
                        };
                        cell.alignment = {
                            wrapText: true,
                            vertical: 'middle',
                            horizontal: textAlignMatch ? textAlignMatch[1].toLowerCase() : 'center'
                        };
                    });
                    rowCounter++;
                    index++;
                }
            }
            for (let index in colWidthStyle) {
                let colIndex = parseInt(index) + 1;
                const style = styles[index] || '';
                const widthMatch = style.match(/(?:^|;)\s*width:\s*(\d+)px/i);
                worksheet.getColumn(colIndex).width = widthMatch ? Math.round(parseInt(widthMatch[1]) / 7) : colWidthStyle[index];
            }
            rowCounter = 1;
            for (let hierarchy of dataToExport) {
                for (let index = 0; index < hierarchy.PDSDList.length; index++) {
                    if (hierarchy.PDSDList.length > 1) {
                        if (index == 0) {
                            worksheet.mergeCells(rowCounter + 1, 1, rowCounter + hierarchy.PDSDList.length, 1);
                        }
                    }
                    rowCounter++;
                }
            }
            worksheet._rows[0]._cells.forEach(cell => {
                cell.protection = { locked: true, lockText: false };
            });
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                const blob = new Blob([result], { type: 'application/octet-stream' });
                const downloadElement = document.createElement('a');
                downloadElement.style = 'display: none';
                downloadElement.href = window.URL.createObjectURL(blob);
                downloadElement.download = this.PDSName + '.xlsx';
                document.body.appendChild(downloadElement);
                downloadElement.click();
                document.body.removeChild(downloadElement);
            });
            this.isLoading = false;
        } catch (error) {
            console.log('error > ' + error);
        }
    }

    loadBatchesHistory() {
        this.productHistory = {
            fields: [],
            rows: [],
        }
        loadBatchesHistory({
            recordId: this.recordId
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.productHistory.fields = parsedResult.fields;
            for (let record of parsedResult.records) {
                this.productHistory.rows.push(this.buildBatchRecord(record));
            }
        }).catch(error => {
            console.error(error);
        })
    }

    buildBatchRecord(record) {
        let row = {
            Id: record.id,
            fieldValues: [],
        }
        for (let field of this.productHistory.fields) {
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY',
                isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == Batch_API.JobName__c,
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                isText: field.fieldType == 'STRING',
                link: field.fieldName == Batch_API.JobName__c ? '/' + record.Id : '',
                scale: field.scale,
                isHTMLFormatted: field.isHTMLFormatted,
                picklistValues: field.picklistValues,
                fieldValue: record[field.fieldName]
            }
            if (fieldWrapper.isReference && field.fieldName != Batch_API.JobName__c) {
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
        return row;
    }

    buildData(data) {
        let dataMap = {};
        let prepOrRej = ['InPreparation', 'Rejected'];
        let PDSSender = this.productDiscountStatement[ProductDiscountStatement_API.Sender__c];
        let PDSRecipient = this.productDiscountStatement[ProductDiscountStatement_API.Recipient__c];
        for (let item of data) {
            let scanResults = item[ProductDiscountStatementDetail_API.t_ScanResultsByColumn__c] ? JSON.parse(item[ProductDiscountStatementDetail_API.t_ScanResultsByColumn__c]) : {};
            let hierarchy = (item[ProductDiscountStatementDetail_API.Product__c] && item[ProductDiscountStatementDetail_API.Product__r][Product_API.Hierarchy__c] ? item[ProductDiscountStatementDetail_API.Product__r][Product_API.Hierarchy__r] : '') || '---';
            let hierarchyId = (item[ProductDiscountStatementDetail_API.Product__c] ? item[ProductDiscountStatementDetail_API.Product__r][Product_API.Hierarchy__c] : '') || '---';
            let hierarchyWrapper;
            if (!dataMap.hasOwnProperty(hierarchyId)) {
                hierarchyWrapper = {
                    Name: hierarchy.Name || '---',
                    Id: hierarchy.Id || '',
                    link: hierarchy.Id ? '/' + hierarchyId : '',
                    isLink: hierarchy.Id ? true : false,
                    PDSDList: [],
                };
                dataMap[hierarchyId] = hierarchyWrapper;
            }
            hierarchyWrapper = dataMap[hierarchyId];
            let PDSDWrapper = {
                Name: item.Name,
                Id: item.Id,
                link: '/' + item.Id,
                isSelected: this.selectedRecordIds.includes(item.Id),
                values: [],
                isLineEditable: true,
                scanStatus: item[ProductDiscountStatementDetail_API.ScanStatus__c] || '',
                scanStatusIcon: this.getIconForScanStatus(item[ProductDiscountStatementDetail_API.ScanStatus__c]),
                status: item[ProductDiscountStatementDetail_API.Status__c] || ''
            }
            PDSDWrapper.isLineEditable = (this.isUserPortalEnabled && ((prepOrRej.includes(PDSDWrapper.status) && (PDSSender == 'Supplier' || (PDSSender == 'Buyer' && PDSDWrapper.status == 'Rejected'))) || (PDSDWrapper.status == 'Requested' && PDSRecipient == 'Supplier')))
                || (!this.isUserPortalEnabled && (((prepOrRej.includes(PDSDWrapper.status) || PDSDWrapper.status == 'Submitted' || PDSDWrapper.status == 'InProcess') && PDSSender == 'Buyer') || (PDSDWrapper.status == 'Submitted' && PDSRecipient == 'Buyer')));
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
                    isDate: field.isDate,
                    isDateTime: field.isDateTime,
                    isPicklist: field.isPicklist,
                    isBoolean: field.isBoolean,
                    isTextarea: field.isTextarea,
                    isText: field.isText,
                    link: '',
                    scale: field.scale,
                    step: field.step,
                    isInputField: field.isInputField && PDSDWrapper.isLineEditable,
                    pickListValues: [],
                    style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                    iconName: '',
                    iconClass: '',
                }
                if (field.fieldName == ProductDiscountStatementDetail_API.Contract_Discount__c || field.fieldName == ProductDiscountStatementDetail_API.Contract_DiscountSellOut__c || field.fieldName == ProductDiscountStatementDetail_API.Contract_DiscountServices__c) {
                    fieldWrapper.isContractDiscountField = true;
                    fieldWrapper.discountCustomLookupConditions = this.buildCustomLookupContractDiscountConditions(item, field.fieldName);
                }
                if (scanResults.hasOwnProperty(field.fieldName)) {
                    let result = scanResults[field.fieldName];
                    if (result == 'Warning') {
                        fieldWrapper.iconName = 'utility:warning';
                        fieldWrapper.iconClass = 'orange-icon';
                    } else if (result == 'Error') {
                        fieldWrapper.iconName = 'utility:error';
                        fieldWrapper.iconClass = 'red-icon';
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
                if (fieldWrapper.isContractDiscountField) {
                    fieldWrapper.contractDiscountValue = JSON.stringify([{ recId: fieldWrapper.fieldValue, recName: fieldWrapper.fieldOutputValue }]);
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
                if (fieldIndex == 0) {
                    fieldWrapper.first = true;
                }
                fieldIndex++;
                PDSDWrapper.values.push(fieldWrapper);
            }
            hierarchyWrapper.PDSDList.push(PDSDWrapper);
        }
        this.isLoading = false;
        return Object.values(dataMap);
    }

    buildCustomLookupContractDiscountConditions(pdsd, fieldName) {
        let conditions = [];
        let promoStatementList = pdsd[ProductDiscountStatementDetail_API.ProductDiscountStatement__r][ProductDiscountStatement_API.PromoStatementType__c]
            ? pdsd[ProductDiscountStatementDetail_API.ProductDiscountStatement__r][ProductDiscountStatement_API.PromoStatementType__c].split(';')
            : [];
        conditions.push('Contract__c = ' + (pdsd[ProductDiscountStatementDetail_API.Contract__c] ? '\'' + pdsd[ProductDiscountStatementDetail_API.Contract__c] + '\'' : 'NULL'));
        // Allow null OR matching PromoStatementType
        conditions.push('(Condition_Type__r.PromoStatementType__c = null OR Condition_Type__r.PromoStatementType__c IN (\'' + promoStatementList.join('\', \'') + '\'))');
        // Allow null OR matching PromoAgreementType
        conditions.push('(Condition_Type__r.PromoAgreementType__c = null OR Condition_Type__r.PromoAgreementType__c = \'' + pdsd[ProductDiscountStatementDetail_API.ProductDiscountStatement__r][ProductDiscountStatement_API.PromoAgreementType__c] + '\')');
        conditions.push('Condition_Type__r.Capture_Discount_Product_Level__c <> null');
        conditions.push('Condition_Type__r.SetCommercialPlanDetail1__c = true');
        conditions.push('Disc_BDate__c <= ' + pdsd[ProductDiscountStatementDetail_API.BDate__c]);
        conditions.push('Disc_EDate__c >= ' + pdsd[ProductDiscountStatementDetail_API.EDate__c]);
        conditions.push('Status__c <> \'Deleted\'');
        if (fieldName == ProductDiscountStatementDetail_API.Contract_Discount__c) {
            conditions.push('(Condition_Type__r.PromoStatementType__c = null OR Condition_Type__r.PromoStatementType__c =\'SellIn\')');
            if (pdsd[ProductDiscountStatementDetail_API.Pol_Com_Condition__c]) {
                conditions.push('Condition_Type__c = \'' + pdsd[ProductDiscountStatementDetail_API.Pol_Com_Condition__c] + '\'');
            }
        } else if (fieldName == ProductDiscountStatementDetail_API.Contract_DiscountSellOut__c) {
            conditions.push('(Condition_Type__r.PromoStatementType__c = null OR Condition_Type__r.PromoStatementType__c =\'SellOut\')');
            if (pdsd[ProductDiscountStatementDetail_API.Pol_Com_ConditionSellOut__c]) {
                conditions.push('Condition_Type__c = \'' + pdsd[ProductDiscountStatementDetail_API.Pol_Com_ConditionSellOut__c] + '\'');
            }
        } else if (fieldName == ProductDiscountStatementDetail_API.Contract_DiscountServices__c) {
            conditions.push('(Condition_Type__r.PromoStatementType__c = null OR Condition_Type__r.PromoStatementType__c =\'Services\')');
            if (pdsd[ProductDiscountStatementDetail_API.Pol_Com_ConditionServices__c]) {
                conditions.push('Condition_Type__c = \'' + pdsd[ProductDiscountStatementDetail_API.Pol_Com_ConditionServices__c] + '\'');
            }
        }
        return conditions;
    }

    changePageSizeHandler(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.loadData();
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
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    toggleAllSelected(event) {
        const checked = event.detail.checked;
        if (checked) {
            this.selectedRecordIds = JSON.parse(JSON.stringify(this.allRecordIds));
        } else {
            this.selectedRecordIds = [];
        }
        this.records.forEach(hierarchy => {
            hierarchy.PDSDList.forEach(item => {
                item.isSelected = checked;
            });
        });
    }

    toggleSelectedRecords(event) {
        let index = event.currentTarget.dataset.index;
        let hierarchyIndex = event.currentTarget.dataset.hierarchyIndex;
        let item = this.records[hierarchyIndex].PDSDList[index];
        item.isSelected = !item.isSelected;
        if (item.isSelected) {
            this.selectedRecordIds.push(item.Id)
        } else {
            delete this.selectedRecordIds.splice(this.selectedRecordIds.indexOf(item.Id), 1);
        }
    }

    openHistoryPopup() {
        this.showHistory = true;
        this.loadBatchesHistory();
    }

    closeHistory() {
        this.showHistory = false;
    }

    toggleImportPopup() {
        this.template.querySelector('.importSection').classList.toggle('slds-hide');
    }

    uploadExcel(event) {
        console.log(event)
        this.importedRecords = event.detail.value;
        this.fileData = event.detail.fileData;
        console.log('this.fileData >>> ' + JSON.stringify(this.fileData))
        this.confirmImportExcel();
    }

    prepareFile() {
        const child = this.template.querySelector('c-import-settings');
        if (child) {
            child.prepareFile();   // <-- calling child's @api method
        }
    }

    getFileId(event) {
        console.log("getFileId", event.detail.fileDirectoryId)
        this.fileDirectoryId = event.detail.fileDirectoryId;
    }

    confirmImportExcel() {
        try {
            this.isLoading = true;
            console.log('this.recordId >>> ' + this.recordId)
            console.log('this.importedRecords >>> ' + this.importedRecords)
            console.log('this.fileData.fileName >>> ' + this.fileData.fileName)
            console.log('this.fileData.base64 >>> ' + this.fileData.base64)
            console.log('this.fileData.fileType >>> ' + this.fileData.fileType)
            let recordsToUpsert = JSON.parse(this.importedRecords)
            recordsToUpsert.forEach(item => {
                item[ProductDiscountStatementDetail_API.t_SetForceScan__c] = true;
            })
            this.toggleImportPopup();
            this.statusMessage = this.labels.LBL_Importing;
            importPDSD({
                recordId: this.recordId,
                recordsToUpsert: JSON.stringify(recordsToUpsert),
                fileName: this.fileData.fileName,
                base64Data: this.fileData.base64,
                fileType: this.fileData.fileType,
                fileDirectoryId: this.fileDirectoryId,
            }).then(batchId => {
                if (batchId != null) {
                    checkCompletedBatches(this, batchId).then(result => {
                        this.scanPDSD(true, []);
                        getImportOutcome({ jobId: batchId }).then(outcome => {
                            if (outcome.hasOwnProperty('hasError') && outcome.hasError) {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: this.labels.LBL_Import_Failed,
                                    message: "{0}",
                                    variant: 'error',
                                    mode: 'sticky',
                                    messageData: [
                                        {
                                            url: '/' + outcome.logId,
                                            label: outcome.logName,
                                        }
                                    ]
                                }));
                            }
                        }).catch(e => {
                            showNotification(this, this.labels.LBL_Error, e?.body?.message || e?.message, 'error');
                        });
                    }).catch(error => {
                        console.error(error);
                    });
                } else {
                    this.scanPDSD(true, []);
                }
            }).catch(error => {
                // Clear status message on error
                this.statusMessage = '';
                showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                console.log(error);
                this.isLoading = false;
            });
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
        }
    }

    handleScanPDSD() {
        this.isLoading = true;
        this.scanPDSD(false, this.selectedRecordIds);
    }

    scanPDSD(forceScan, selectedRows) {
        // Show scanning status
        this.statusMessage = this.labels.LBL_Scanning;
        this.isLoading = true;
        scanPDSD({
            PDSDListJson: JSON.stringify(selectedRows),
            recordId: this.recordId,
            forceScan: forceScan,
        }).then(batchId => {
            console.log('batchId >> ' + batchId);
            if (batchId != null) {
                console.log('INNN >> ' + batchId);
                checkCompletedBatches(this, batchId).then(result => {
                    console.log('Batch completed:', result);
                    this.loadData();
                    // Clear status message after scanning
                    this.statusMessage = '';
                }).catch(error => {
                    console.error(error);
                });
            } else {
                this.loadData();
                // Clear status message after scanning
                this.statusMessage = '';
            }
        }).catch(error => {
            // Clear status message on error
            this.statusMessage = '';
            console.log(error);
            this.isLoading = false;
        });
    }

    synchroPDSD() {
        // Show synchronization status
        this.statusMessage = this.labels.LBL_Synchronizing;
        this.isLoading = true;
        synchroPDSD({
            PDSDListJson: JSON.stringify(this.selectedRecordIds),
            recordId: this.recordId,
        }).then(batchId => {
            if (batchId != null) {
                checkCompletedBatches(this, batchId).then(result => {
                    this.loadData();
                    // Clear status message after synchronization
                    this.statusMessage = '';
                }).catch(error => {
                    console.error(error);
                });
            } else {
                this.loadData();
                // Clear status message after synchronization
                this.statusMessage = '';
            }
        }).catch(error => {
            // Clear status message on error
            this.statusMessage = '';
            console.log(error);
            this.isLoading = false;
        });
    }

    validateOrRejectPDSD(event) {
        let status = event.target.dataset.status;
        let recordIdsToProcess = status == 'Validated' ? this.recordIdsToValidate : this.recordIdsToReject;
        let validIds = [];
        if (this.selectedRecordIds && this.selectedRecordIds.length > 0) {
            validIds = this.selectedRecordIds.filter(item => recordIdsToProcess.includes(item));
        } else {
            validIds = recordIdsToProcess;
        }
        console.log('status >>> ' + status)
        this.isLoading = true;
        updatePDSDStatus({
            recordIdsToValidateOrReject: validIds,
            status: status,
        }).then(result => {
            showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
            this.loadData();
        }).catch(error => {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('initData %c' + error.message, 'color : red');
            console.log('initData %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        });
    }

    toggleFlow(event) {
        let flow = event.target.dataset.flow;
        if (!flow) {
            this.openFlow = !this.openFlow;
        }
        if (flow == 'submit') {
            let validSubmitedPDSD = [];
            if (this.selectedRecordIds && this.selectedRecordIds.length > 0) {
                validSubmitedPDSD = this.selectedRecordIds.filter(item => this.recordIdsToSubmit.includes(item));
            } else {
                validSubmitedPDSD = this.recordIdsToSubmit;
            }
            let unmatchedRows = 0;
            if (this.selectedRecordIds && this.selectedRecordIds.length > 0) {
                unmatchedRows = this.selectedRecordIds.length - validSubmitedPDSD.length;
            } else {
                unmatchedRows = this.noOfRecords - validSubmitedPDSD.length;
            }
            if (unmatchedRows != 0) {
                if (this.isPortal) {
                    alert(labels.LBL_PDS_Matrix_X_Rows_Not_Submitted.replace('{0}', unmatchedRows));
                } else {
                    showNotification(this, labels.LBL_Warning, labels.LBL_PDS_Matrix_X_Rows_Not_Submitted.replace('{0}', unmatchedRows), 'warning');
                }
            }
            if (validSubmitedPDSD.length) {
                this.currentFlow = {
                    header: this.labels.LBL_Submit,
                    flowApiName: this.prefix + (!this.isUserPortalEnabled ? 'SCREEN_Product_Discount_Statement_Statement_Submission_Review' : 'SCREEN_Product_Discount_Statement_Statement_Submission_Review'),
                    flowVariables: [{
                        name: 'recordIds',
                        type: 'String',
                        value: validSubmitedPDSD
                    }],
                }
                this.openFlow = !this.openFlow;
            }
        } else if (flow == 'respond') {
            this.currentFlow = {
                header: this.labels.LBL_Respond,
                flowApiName: this.prefix + (!this.isUserPortalEnabled ? 'SCREEN_Product_Discount_Statement_Statement_Respond' : 'SCREEN_Product_Discount_Statement_Statement_Respond'),
                flowVariables: [{
                    name: 'input_PDSId',
                    type: 'String',
                    value: this.recordId
                }, {
                    name: 'input_supplierContactUserId',
                    type: 'String',
                    value: this.supplierContactUserId || ''
                }],
            }
            this.openFlow = !this.openFlow;
        }
    }

    handleFlowStatusChange(event) {
        //TODO : store the output values (event.detail.outputVariables)
        if (event.detail.status === "FINISHED") {
            showNotification(this, 'SUCCESS', this.labels.LBL_Success, 'SUCCESS')
            this.openFlow = !this.openFlow;
            this.isEditMode = false;
            this.pageNumber = 1;
            this.loadData();
        }
        if (event.detail.status === "ERROR") {
            showNotification(this, 'ERROR', this.labels.LBL_Error, 'ERROR')
        }
    }

    switchToEditMode() {
        this.isEditMode = !this.isEditMode;
        if (!this.isEditMode) {
            this.PdsdToUpdateMap = {};
        }
    }

    handleFieldEdits(event) {
        let id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let value;
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            value = event.detail.selRecords[0].recId;
        } else {
            value = event.detail && event.detail.checked != null ? event.detail.checked : event.target.value;
        }
        let hierarchyIndex = event.target.dataset.hierarchyIndex;
        let index = event.target.dataset.index;
        let obj;
        if (this.PdsdToUpdateMap.hasOwnProperty(id)) {
            obj = this.PdsdToUpdateMap[id];
        } else {
            obj = {
                attributes: {
                    type: ProductDiscountStatementDetail_API.objectApiName,
                },
                Id: id
            };
        }
        value = value == undefined ? null : value;
        obj[field] = value;
        const originalRecord = this.records[hierarchyIndex]?.PDSDList[index];
        if (originalRecord) {
            let mapKey = `${id}_${field}`;
            if (!this.initFieldValuesMap.hasOwnProperty(mapKey)) {
                const originalValue = originalRecord.values.find(v => v.fieldName === field)?.fieldValue;
                this.initFieldValuesMap[mapKey] = originalValue;
            }
        }
        this.PdsdToUpdateMap[id] = obj;
    }

    handleSave() {
        console.log('this.PdsdToUpdateMap >>> ' + JSON.stringify(this.PdsdToUpdateMap))
        if (!this.PdsdToUpdateMap || Object.keys(this.PdsdToUpdateMap).length == 0) {
            showNotification(this, this.labels.MSG_No_Changes_To_Save, '', 'info');
            return;
        }
        // Show saving status
        this.statusMessage = this.labels.LBL_Saving;
        Object.keys(this.PdsdToUpdateMap).forEach(pdsdId => {
            if (!this.PdsdToUpdateMap[pdsdId].hasOwnProperty(ProductDiscountStatementDetail_API.Status__c)) {
                let originalRecord;
                this.records.forEach(hierarchy => {
                    hierarchy.PDSDList.forEach(item => {
                        if (item.Id == pdsdId) {
                            originalRecord = item;
                            return;
                        }
                    })
                })
                Object.keys(this.PdsdToUpdateMap[pdsdId]).forEach(field => {
                    let mapKey = `${pdsdId}_${field}`;
                    const currentStatus = originalRecord.status;
                    const originalValue = this.initFieldValuesMap[mapKey];
                    const isModified = this.PdsdToUpdateMap[pdsdId][field] !== originalValue;
                    if (isModified && currentStatus === 'Submitted') {
                        this.PdsdToUpdateMap[pdsdId][ProductDiscountStatementDetail_API.Status__c] = 'InProcess';
                    } else if (isModified && currentStatus === 'Rejected') {
                        this.PdsdToUpdateMap[pdsdId][ProductDiscountStatementDetail_API.Status__c] = 'Updated';
                    } else if (!isModified) {
                        delete this.PdsdToUpdateMap[pdsdId][ProductDiscountStatementDetail_API.Status__c];
                    }
                })
            }
        })
        saveData({
            recordId: this.recordId,
            recordsToUpsertJSON: JSON.stringify(Object.values(this.PdsdToUpdateMap))
        }).then((result) => {
            let parsedResult = JSON.parse(result);
            if (Array.isArray(parsedResult)) {
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                this.scanPDSD(false, parsedResult);
            } else {
                showNotification(this, this.labels.LBL_Error, result, 'error');
            }
            this.isLoading = false;
            this.isEditMode = false;
            this.pageNumber = 1;
            // Clear status message after saving
            this.statusMessage = '';
            this.loadData();
        }).catch(error => {
            // Clear status message on error
            this.statusMessage = '';
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
        });
    }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
        requestAnimationFrame(() => {
            this.changeHeight();
        });
    }

    changeHeight = () => this.setTableDimension();
    setTableDimension() {
        let header = this.template.querySelector('.pageHeader');
        let master = this.template.querySelector('.masterStyle');
        let body = this.template.querySelector('.main-panel');
        let footer = this.template.querySelector('.footerDiv');
        // measure the instructions card (if shown)
        let instr = this.template.querySelector('.instructions-card');
        let instrHeight = instr ? instr.getBoundingClientRect().height : 0;
        let baseHeight;
        if (header && body && footer) {
            let headerHeight = header.getBoundingClientRect().height;
            let footerHeight = footer.getBoundingClientRect().height;
            baseHeight = window.innerHeight - headerHeight - footerHeight - instrHeight - (3 * 45);
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

    resetFilter() {
        this.isFilterOpen = false;
        this.filters = {
            dynamic: '',
        }
        this.loadData();
    }

    confirmFilter() {
        let fields = Object.keys(this.fieldsToFilterMap)
            .filter(fieldName =>
            (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
                (this.fieldsToFilterMap[fieldName].values &&
                    (this.fieldsToFilterMap[fieldName].values.length > 1
                        || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
                || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
            .map(fieldName => {
                let item = {};
                item.fieldName = fieldName;
                if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
                    item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
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
        this.isLoading = true;
        this.isFilterOpen = false;
        this.filters.dynamic = JSON.stringify(fields);
        this.loadData();
    }

    populateFiltersMap(fields) {
        this.fieldsToFilterMap = {};
        for (let field of fields) {
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
            if (modeValue === 'multiple') {
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

    handleDeletePDSD(event) {
        this.idsToDelete = [];
        let pdsdId = event.target.dataset.id;
        this.idsToDelete.push(pdsdId);
        this.toggleDeletePopup();
    }

    handleMassDeletePDSD() {
        this.idsToDelete = JSON.parse(JSON.stringify(this.selectedRecordIds));
        this.toggleDeletePopup();
    }

    toggleDeletePopup() {
        this.showDeletePopup = !this.showDeletePopup;
    }

    confirmDeletePDSD() {
        this.deletePDSD();
    }

    deletePDSD() {
        this.isLoading = true;
        console.log('this.idsToDelete >> ' + JSON.stringify(this.idsToDelete))
        deletePDSD({
            selectedIds: this.idsToDelete
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.idsToDelete.forEach(id => {
                    delete this.selectedRecordIds.splice(this.selectedRecordIds.indexOf(id), 1);;
                });
                showNotification(this, this.labels.LBL_Success, this.labels.LBL_PDS_Matrix_X_Rows_Deleted_Success.replace('{0}', this.idsToDelete.length), 'success');
            } else {
                showNotification(this, this.labels.LBL_Error, result, 'error');
            }
            this.loadData();
            this.idsToDelete = [];
        }).catch(error => {
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }).finally(() => {
            this.isLoading = false;
            this.toggleDeletePopup();
        });
    }
    toggleGridSettingsFlow(event) {
        try {
            let flowName = event.target.dataset.flowName;
            let flowLabel = event.target.dataset.flowLabel;
            this.isLoading = true;
            this.currentFlow = {
                header: flowLabel,
                flowApiName: flowName,
                flowVariables: []
            }
            if (this.gridSettings
                && this.gridSettings.actions
                && this.gridSettings.actions.screenFlows) {
                let matchedFlow = this.gridSettings.actions.screenFlows.filter(flow => flow.value == flowName);
                if (matchedFlow && matchedFlow.length > 0) {
                    if (this.recordId && matchedFlow[0].hasRecordId != null && matchedFlow[0].hasRecordId == true) {
                        this.currentFlow.flowVariables.push({
                            name: 'recordId',
                            type: 'String',
                            value: this.recordId
                        })
                    }
                    if (matchedFlow[0].hasRecordIds != null && matchedFlow[0].hasRecordIds == true) {
                        this.currentFlow.flowVariables.push({
                            name: 'recordIds',
                            type: 'String',
                            value: this.selectedRecordIds
                        })
                    }
                }
            }
            this.openFlow = !this.openFlow;
            this.isLoading = false;
        } catch (error) {
            console.log(JSON.stringify(error))
        }
    }
}