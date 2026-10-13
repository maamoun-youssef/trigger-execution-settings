import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import xlsxLibJS from '@salesforce/resourceUrl/xlsxLib';
// Services
import initData from '@salesforce/apex/PriceListStatementMatrixController.initData';
import processRestForExcel from '@salesforce/apex/PriceListStatementMatrixController.processRestForExcel';
import loadData from '@salesforce/apex/PriceListStatementMatrixController.loadData';
import changePriceListStatementStatus from '@salesforce/apex/PriceListStatementMatrixController.changePriceListStatementStatus';
import save from '@salesforce/apex/PriceListStatementMatrixController.save';
import importPLSD from '@salesforce/apex/PriceListStatementMatrixController.importPLSD';
//import uploadFile from "@salesforce/apex/PriceListStatementMatrixController.uploadFile";
import { checkCompletedBatches, showNotification } from 'c/appHelper';
// CUSTOM Objects
import PriceListStatement__OBJECT from '@salesforce/schema/PriceListStatement__c';
import PriceListStatementDetail__OBJECT from '@salesforce/schema/PriceListStatementDetail__c';
import Product2 from "@salesforce/schema/Product2";
import LOG__OBJECT from '@salesforce/schema/Log__c';
// PriceListStatement__c CUSTOM FIELDS
import ReferenceYear__c from '@salesforce/schema/PriceListStatement__c.ReferenceYear__c';
import BusinessUnitTarget__c from "@salesforce/schema/PriceListStatement__c.BusinessUnitTarget__c";
import ExtId__c from "@salesforce/schema/PriceListStatement__c.ExtId__c";
// PriceListStatementDetail__c CUSTOM Fields
import Hierarchy__c from "@salesforce/schema/PriceListStatementDetail__c.Hierarchy__c";
import Product__c from "@salesforce/schema/PriceListStatementDetail__c.Product__c";
// Product2 CUSTOM FIELDS
import GTIN__c from "@salesforce/schema/Product2.GTIN__c";
import ProductCode from "@salesforce/schema/Product2.ProductCode";
//IMPORTS
import { API_NAMES, Labels } from './properties.js';
import formulonLibUrl from '@salesforce/resourceUrl/formulonLib';

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
export default class PriceListStatementMatrix extends NavigationMixin(LightningElement) {
    //API Variables
    @api recordId;
    @api gridLayout;
    @api isExportExcel;
    // TRACK Variables
    @track labels = {
        ...Labels,
        LBL_Validate: 'Validate',
        PriceListStatementLabel: '',
        ProductFields: {
            GTIN__c: '',
            ProductCode: '',
        },
        LBL_PriceListStatement_Modify_Status_to_Validate: '',

    }
    @track filters = {
        searchValue: '',
        dynamicSearch: '',
    }
    @track originalValuesById = {};
    fixedColumnsOptions = [
        { value: 1, label: '1' },
        { value: 2, label: '2' },
        { value: 3, label: '3' },
        { value: 4, label: '4' },
        { value: 5, label: '5' }
    ];
    pageSizeOptions = [
        { label: '5', value: 5, isSelected: false },
        { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        { label: '75', value: 75, isSelected: false },
        { label: '100', value: 100, isSelected: false }
    ];
    @track loading = true;
    @track pageSize = 25;
    @track pageNumber = 1;
    @track nbOfFixedColumns = 1;
    @track priceListStatementName;
    @track file;
    @track off = 0;
    @track totalSize = 0;
    @track logs = [];
    @track records = [];
    @track displayedFields = [];
    @track displayedTreeFields = [];
    // Map fieldName -> { headerStyle, style }
    fieldStyleMap = {};
    priceListStatementFields = {};
    @track allDisplayedGridFields = [];
    @track dynamicTaxesFields = [];
    @track displayedDynamicFields = [];
    @track fieldsToFilter = [];
    @track PLSDToUpdateMap = {};
    @track productPanelVisibility = false;
    @track PLSDFieldsType = {};

    //EXCEL
    allRecordsToExport;
    rowCounter = 0;
    @track totalExportSize = 0;
    @track fileGenerationValue = 0;
    @track fileDownloadValue = 0;
    @track showFileGenerationBar = false;
    @track showFileDownloadBar = false;
    PLSDPicklistValues = {};
    fieldsToFilterMap = {};
    totalNumbOfRecords = 0;
    validateDisabled = false;
    logData = {};
    XL_row_object = [];
    data = {};
    fileContent = '';
    rendered = false;
    @track priceListStatementDetailsData = [];
    @track newpriceListStatementDetails = [];
    @track PriceListStatementDetailObject = PriceListStatementDetail__OBJECT;
    @track lookupName = PriceListStatement__OBJECT.objectApiName;
    @track detailApiName = PriceListStatementDetail__OBJECT.objectApiName;
    @track importSettings = '';
    fileData = {};
    fileDirectoryId;
    importedRecords = [];
    get hasGroupFields() {
        return this.displayedDynamicFields.length > 0 && this.displayedDynamicFields.filter(item => item.isFieldGroup).length > 0;
    }
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber >= Math.ceil(this.totalNumbOfRecords / pageSize));
    }
    get pagesBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
    }
    get colspan() {
        return this.displayedFields.length + 1;
    }
    get hasData() {
        return this.records.length > 0;
    }
    get emptyData() {
        return this.records.length == 0;
    }

    get isStatementValidated() {
        return this.mainData && this.mainData.currentPriceListStatement && this.mainData.currentPriceListStatement[API_NAMES.PriceListStatement__c.Status__c] == 'Validated';
    }

    get firstThTreeStyle() {
        return this.displayedTreeFields && this.displayedTreeFields.length > 0 ? this.displayedTreeFields[0].headerStyle : '';
    }

    get firstTdTreeStyle() {
        return this.displayedTreeFields && this.displayedTreeFields.length > 0 ? this.displayedTreeFields[0].cellStyle : '';
    }

    get firstThStyle() {
        return this.displayedFields && this.displayedFields.length > 0 ? this.displayedFields[0].headerStyle : '';
    }

    get firstTdStyle() {
        return this.displayedFields && this.displayedFields.length > 0 ? this.displayedFields[0].style : '';
    }

    get hasMaster() {
        return this.mainData.gridSettingsManager && this.mainData.gridSettingsManager.hasMaster;
    }

    firstLoad = true;
    @track wireIsDone = {
        ProductInfo: false,
        PriceListStatementInfo: false,
        PLSDPicklistValues: false,
        PriceListStatementDetailInfo: false,
    }
    checkIfWireIsDone() {
        if (this.wireIsDone.ProductInfo && this.wireIsDone.PriceListStatementInfo && this.wireIsDone.PriceListStatementDetailInfo && this.wireIsDone.PLSDPicklistValues && this.wireIsDone.PriceListStatementDetailInfo) {
            this.initData();
        }
    }
    // WIRES
    @wire(getObjectInfo, { objectApiName: Product2 }) objectInfoProduct({ error, data }) {
        if (data) {
            this.labels.ProductFields.GTIN__c = data.fields[GTIN__c.fieldApiName].label;
            this.labels.ProductFields.ProductCode = data.fields[ProductCode.fieldApiName].label;
            this.wireIsDone.ProductInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.log('ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: PriceListStatement__OBJECT }) objectInfoPriceListStatement({ error, data }) {
        if (data) {
            this.labels.PriceListStatementLabel = data.label;
            this.priceListStatementFields = data.fields;
            this.wireIsDone.PriceListStatementInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: PriceListStatementDetail__OBJECT }) objectInfoPriceListStatementDetail({ error, data }) {
        if (data) {
            this.priceListStatementDetailFields = data.fields;
            this.wireIsDone.PriceListStatementDetailInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: PriceListStatementDetail__OBJECT, recordTypeId: "012000000000000AAA" }) picklistValues({ error, data }) {
        if (data) {
            this.PLSDPicklistValues = data.picklistFieldValues;
            this.wireIsDone.PLSDPicklistValues = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: PriceListStatementDetail__OBJECT }) objectInfoPLSD({ error, data }) {
        if (data) {
            for (let field of Object.values(data.fields)) {
                if (field.updateable) {
                    this.PLSDFieldsType[field.apiName] = field.dataType;
                }
            }
            this.wireIsDone.PriceListStatementDetailInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }
    librariesLoaded = false;
    connectedCallback() {
        if (!this.librariesLoaded) {
            loadScript(this, xlsxLibJS + '/js-xlsx-master/dist/jszip.js')
                .then(async (data) => {
                    console.log("success------>>>", data);
                    Promise.all([
                        //loadStyle(this, negOptimGlobalCSS),
                        loadScript(this, xlsxLibJS + '/js-xlsx-master/dist/xlsx.js'),
                        loadScript(this, ExcelJSURL),
                        loadScript(this, formulonLibUrl + '/decimal.js')
                        //loadScript(this, xlsxLibJS + '/js-xlsx-master/dist/jszip.js'),
                    ]).then(() => {
                        loadScript(this, formulonLibUrl + '/formulon.min.js').then(() => {
                            this.librariesLoaded = true;
                        }).catch(error => {
                            console.log(error.message);
                        });
                    }).catch(error => {
                        console.log('error loading style, Script >> ' + error)
                    });
                })
                .catch(error => {
                    console.log("failure-------->>>>", error);
                });
        }
        // catch event of resizing
        window.addEventListener('resize', this.setTableDimension);
    }

    renderedCallback() {
        this.setnumberOfFixedColumns();
        let header = this.template.querySelector('.header');
        let body = this.template.querySelector('.main-panel');
        let footerDiv = this.template.querySelector('.footerDiv');
        if (/*!this.rendered &&*/ header && body && footerDiv) {
            this.setTableDimension();
            //this.rendered = true;
        }
    }

    @track tableStyleHeight;
    // setTableDimension
    setTableDimension() {
        let mainContainer = this.template.querySelector('.mainContainer');
        let master = this.template.querySelector('.masterStyle');
        let pageHeader = this.template.querySelector('.header');
        let pageBody = this.template.querySelector('.main-panel');
        let treeGrid = this.template.querySelector('.treeGrid');
        let pageFooter = this.template.querySelector('.footerDiv');
        if (
            mainContainer != null &&
            pageHeader != null &&
            pageBody != null &&
            pageFooter != null) {
            pageBody.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - (master ? master.offsetHeight : 0) - (treeGrid ? treeGrid.offsetHeight : 0) - pageFooter.offsetHeight - 10 + "px";
            this.tableStyleHeight = 'background-color: #FFFFFF !important; width: -webkit-fill-available; height:' + (pageBody.style.height) + 'px';
        }
    }
    objectFieldsType = null;
    objectFieldsCalculationMap = null;
    executionFormulaFieldOrder = [];
    formulasMetadata = null;
    PLDFullDataMap = {};
    initData() {
        this.loading = true;
        this.categoryBUClustersMap = {};
        this.categoryBUCpltMap = {};
        this.categoryBUClustersRefMap = {};
        this.categoryBUCpltRefMap = {};
        this.records = [];
        this.newPriceListStatementDetails = [];
        initData({ recordId: this.recordId, gridLayout: this.gridLayout }).then((result) => {
            this.mainData = JSON.parse(result);
            this.importSettings = this.mainData.importSettings || '';
            let formulaFieldsCalculationWrapper = JSON.parse(this.mainData.formulaFieldsCalculationWrapper)
            this.objectFieldsCalculationMap = formulaFieldsCalculationWrapper.objectFieldsCalculationMap;
            this.formulasMetadata = formulaFieldsCalculationWrapper.formulasMetadata;
            let calculatedFields = [];
            this.mainData.gridSettingsManager.GRID_FIELDS.forEach(field => {
                if (field.isCalculated) {
                    calculatedFields.push(field.fieldName)
                }
            });
            for (let formulaField of formulaFieldsCalculationWrapper.executionFormulaFieldOrder) {
                if (calculatedFields.includes(formulaField)) {
                    this.executionFormulaFieldOrder.push(formulaField);
                }
            }
            this.objectFieldsType = formulaFieldsCalculationWrapper.objectFieldsType;
            console.log('this.mainData >>> ' + JSON.stringify(this.mainData))
            this.priceListStatementName = this.mainData.currentPriceListStatement.Name;
            this.pageSize = parseInt(this.mainData.gridSettingsManager.Default_Page_Size);
            this.pageSizeOptions.forEach(element => element.isSelected = element.value == this.pageSize);
            this.dynamicTaxesFields = this.mainData.dynamicTaxesFields || [];
            this.displayedDynamicFields = this.mainData.displayedDynamicFields || [];
            this.populateFiltersMap(this.mainData.gridSettingsManager.FILTERS);
            if (this.displayedFields.length == 0) {
                let activeTaxFields = [];
                this.displayedDynamicFields = this.displayedDynamicFields.sort((a, b) => {
                    if (a.isFieldGroup || b.isFieldGroup) {
                        if (a.isFieldGroup && b.isFieldGroup) {
                            return a.displayOrder - b.displayOrder
                        } else {
                            return 1
                        }
                    } else {
                        return a.displayOrder - b.displayOrder;
                    }
                });
                this.displayedDynamicFields.forEach(item => {
                    item.subFieldsList.forEach(subField => {
                        subField.url = item.url;
                        activeTaxFields.push(subField);
                    });
                });
                for (let field of this.mainData.gridSettingsManager.GRID_FIELDS) {
                    this.fieldStyleMap[field.fieldName] = {
                        headerStyle: field.widthStyle + (field.headerStyle ? field.headerStyle.style : ''),
                        cellStyle: field.style,
                    };
                    if (!field.isHidden) {
                        let fieldWrapper = {
                            fieldName: field.fieldName,
                            fieldLabel: field.fieldLabel.toUpperCase(),
                            isNumberField: field.isNumberField,
                            isSortable: field.isSortable,
                            isReference: field.fieldType == 'REFERENCE',
                            headerStyle: field.widthStyle + (field.headerStyle ? field.headerStyle.style : ''),
                            style: field.style,
                            width: field.nonConditional && field.nonConditional.width ? field.nonConditional?.width.replace('px', '') / 4 : field.fieldLabel.toUpperCase().length * 2,
                            bgColor: field.bgColor.replace('#', '')
                        }
                        let isDynamicTaxField = this.dynamicTaxesFields.find(item => { return item === field.fieldName });
                        if (isDynamicTaxField) {
                            let activeTaxField = activeTaxFields ? activeTaxFields.filter(item => field.fieldName == item.fieldName) : [];
                            if (activeTaxField && activeTaxField.length/*activeTaxFields.includes(field.fieldName)*/) {
                                fieldWrapper.fieldLabel = activeTaxField[0].fieldLabel;
                                fieldWrapper.url = activeTaxField[0].url;
                                fieldWrapper.isLink = activeTaxField[0].url != null;
                                this.allDisplayedGridFields.push(field);
                                this.displayedFields.push(fieldWrapper);
                            }
                            continue;
                        }
                        this.displayedFields.push(fieldWrapper);
                        this.allDisplayedGridFields.push(field);
                    }
                }
            }
            if (this.isExportExcel) {
                this.exportExcel();
            } else {
                if (this.mainData.dataTreeRateCalculationWrapperSerialized && this.mainData.dataTreeRateCalculationWrapperSerialized != '') {
                    this.buildDisplayedTreeFields();
                }
                let bannerRecord = JSON.parse(this.mainData.bannerRecord);
                if (bannerRecord) {
                    this.buildBannerData(bannerRecord);
                }
                this.loadData();
            }
        }).catch(error => {
            console.error(error);
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
        });
    }
    @track bannerValues = [];
    buildBannerData(record) {
        this.bannerValues = [];
        try {
            for (let field of this.mainData.gridSettingsManager.BANNER_FIELDS) {
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
    treeList = [];
    dataTreeRateCalculationWrapper = {};
    buildDisplayedTreeFields() {
        this.displayedTreeFields = [];
        this.dataTreeRateCalculationWrapper = JSON.parse(this.mainData.dataTreeRateCalculationWrapperSerialized);
        let firstHierarchyNode = Object.values(this.dataTreeRateCalculationWrapper);
        console.log(' this.dataTreeRateCalculationWrapper >>>> ' + JSON.stringify(this.dataTreeRateCalculationWrapper))
        let keys = firstHierarchyNode[0].calculationValues;
        for (let field of keys) {
            const styleMeta = this.fieldStyleMap[field.fieldName] || {};
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldType: field.fieldType,
                scale: field.fieldScale,
                headerStyle: styleMeta.headerStyle,
                cellStyle: styleMeta.cellStyle
            }
            this.displayedTreeFields.push(fieldWrapper);
        }
        console.log(' this.displayedTreeFields >>>> ' + JSON.stringify(this.displayedTreeFields))
        this.buildTreeData();
    }
    buildTreeData() {
        this.treeList = [];
        for (let key in this.dataTreeRateCalculationWrapper) {
            this.treeDataPreperation(this.dataTreeRateCalculationWrapper[key], 1)
        }
        console.log('this.treeList: ' + JSON.stringify(this.treeList))
    }

    treeDataPreperation(row, level) {
        if (level == 1) {
            console.log('Object.values(row.calculationValues) >>> ' + JSON.stringify(row.calculationValues))
        }
        row.level = level;
        let val = [];
        for (let field of this.displayedTreeFields) {
            let value = row.calculationValues.filter(fieldCalc => fieldCalc.fieldName == field.fieldName)[0].value;
            val.push({
                Id: field.fieldName,
                style: field.cellStyle,
                scale: field.scale,
                isPercent: field.fieldType == 'PERCENT',
                value: field.fieldType == 'PERCENT' ? value / 100 : value
            });
        }
        if (level == 1) {
            console.log('val >>> ' + JSON.stringify(val))
        }
        row.values = val;
        // W-009027: Collapse totals tree on initial load (show only root level)
        row.show = (level === 1); // only root row visible
        row.expanded = (level === 1);
        row.ariaExpanded = false;
        let children = JSON.parse(JSON.stringify(row.children));
        row.children = [];
        row.historyLevel = level + 1;
        this.treeList.push(row);
        if (children != null && children.length > 0) {
            row.hasChildren = true;
            row.showChevronButton = row.hasChildren;
            level++;
            for (let item of children) {
                this.treeDataPreperation(item, level);
            }
        }
    }

    expandAndCollapse(event) {
        console.log('here')
        var rowKey = event.currentTarget.dataset.recordid;
        var dataModi = JSON.parse(JSON.stringify(this.treeList));
        let fn = obj => obj.key === rowKey;
        var indexClicked = dataModi.findIndex(fn);
        if (indexClicked != null) {
            dataModi[indexClicked].ariaExpanded = !dataModi[indexClicked].ariaExpanded;
            var currentLevel = parseInt(dataModi[indexClicked].level);
            for (var i = parseInt(indexClicked) + 1; i < dataModi.length; i++) {
                if (dataModi[i].level == currentLevel || dataModi[i].level < currentLevel) {
                    this.makeChanges(dataModi);
                    break;
                }
                var parent = dataModi.filter(obj => obj.key == dataModi[i].parentId)[0];
                if (dataModi[i].level == currentLevel + 1) {
                    dataModi[i].expanded = !dataModi[i].expanded;
                }
                if (!dataModi[i].expanded) {
                    dataModi[i].show = false;
                } else {
                    dataModi[i].show = parent.expanded ? !dataModi[i].show : false;
                }
            }
            this.makeChanges(dataModi);
        }
    }
    //to make the changes on the main array
    makeChanges(dataModi) {
        this.treeList = JSON.parse(JSON.stringify(dataModi));
    }

    populateFiltersMap(fields) {
        this.fieldsToFilterMap = {};
        for (let field of fields) {
            let fieldToFilter = {};
            if (SUPPORTED_TYPES.includes(field.stringFieldType)
                || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
                || field.hasOwnProperty('userFilterable')) {
                fieldToFilter.fieldLabel = field.fieldLabel;
                fieldToFilter.fieldName = field.fieldName;
                fieldToFilter.stringFieldType = field.stringFieldType;
                fieldToFilter.isMultiLevel = field.hasOwnProperty('isMultiLevel') ? field.isMultiLevel : false;
                if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
                if (field.stringFieldType === 'ID') {
                    if (field.values) fieldToFilter.displayVal = field.values.join(';');
                    fieldToFilter.isId = true;
                }
                fieldToFilter.isText = field.stringFieldType == 'STRING';
                fieldToFilter.isReference = field.stringFieldType == 'REFERENCE';
                fieldToFilter.isCheckboxGroup = field.stringFieldType == 'BOOLEAN' || ((field.stringFieldType === 'PICKLIST' || field.stringFieldType === 'MULTIPICKLIST' || field.stringFieldType === 'RECORDTYPE') && (field.pickListValues && field.pickListValues.length > 1));
                if (fieldToFilter.isCheckboxGroup) {
                    fieldToFilter.options = field.stringFieldType === 'BOOLEAN' ? [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }] : field.pickListValues;
                }
                fieldToFilter.isNumber = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
                if (fieldToFilter.isNumber) {
                    if (field.stringFieldType === 'DOUBLE') {
                        fieldToFilter.formatter = 'decimal';
                    }
                    if (field.stringFieldType === 'CURRENCY') {
                        fieldToFilter.formatter = 'currency';
                    }
                    if (field.stringFieldType === 'PERCENT') {
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
                    || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
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
                //list to display
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
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //get record type field
            var recordTypeField = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === false && filtersMap[fieldName].stringFieldType === 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //add record type fields always to the top
            if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
            this.multilevelFields = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === true)
                .map(fieldName => { return filtersMap[fieldName]; });
            this.fieldsToFilter.forEach(item => {
                if (item.isText || item.isReference) {
                    item.value = item.values.length != 0 ? item.values[0] : '';
                }
            })
        }
    }

    loadData() {
        this.loading = true;
        this.priceListStatementDetailsData = [];
        loadData({
            currentPriceListStatementJSON: JSON.stringify(this.mainData.currentPriceListStatement),
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
            filtersJSON: JSON.stringify(this.filters),
        }).then((result) => {
            try {
                let parsedresult = JSON.parse(result);
                console.log(' >>> ' + JSON.stringify(parsedresult))
                this.totalNumbOfRecords = parsedresult.totalSize;
                this.priceListStatementDetailsData = parsedresult.priceListStatementDetails;
                this.records = this.buildData(parsedresult.priceListStatementDetails);
                this.loading = false;
            } catch (error) {
                console.log('ERROR: ' + error?.body?.message || error?.message || error);
                showNotification(this, '', error.message, 'error');
            }
        }).catch(error => {
            console.error(error);
            console.log('ERROR: ' + error?.body?.message || error?.message || error);
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.loading = false;
        });
    }

    buildData(priceListStatementDetails) {
        this.PLDFullDataMap = {};
        let hierarchyWrapperMap = {};
        for (let item of priceListStatementDetails) {
            let hierarchyId = item[Hierarchy__c.fieldApiName];
            let hierarchyWrapper = {
                hierarchyId: hierarchyId,
                hierarchyName: item[Hierarchy__c.fieldApiName.replace('__c', '__r')].Name,
                link: '/' + hierarchyId,
                priceListStatementDetails: [],
                rowspan: 1,
            }
            if (!hierarchyWrapperMap.hasOwnProperty(hierarchyId)) {
                hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
            }
            hierarchyWrapper = hierarchyWrapperMap[hierarchyId];
            let priceListStatementDetailWrapper = this.buildRowData(item);
            hierarchyWrapper.priceListStatementDetails.push(priceListStatementDetailWrapper);
            hierarchyWrapper.rowspan += 1;
            hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
            this.PLDFullDataMap[item.Id] = item;
        }
        if (this.newpriceListStatementDetails && this.newpriceListStatementDetails.length) {
            for (let item of this.newpriceListStatementDetails) {
                let hierarchyId = item[Hierarchy__c.fieldApiName];
                let hierarchyWrapper = {
                    hierarchyId: hierarchyId,
                    hierarchyName: item.hierarchyName,
                    link: '/' + hierarchyId,
                    priceListStatementDetails: [],
                    rowspan: 1,
                }
                if (!hierarchyWrapperMap.hasOwnProperty(hierarchyId)) {
                    hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
                }
                hierarchyWrapper = hierarchyWrapperMap[hierarchyId];
                let priceListStatementDetailWrapper = this.buildRowData(item);
                hierarchyWrapper.priceListStatementDetails.push(priceListStatementDetailWrapper);
                hierarchyWrapper.rowspan += 1;
                hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
            }
        }
        return Object.values(hierarchyWrapperMap);
    }

    buildRowData(priceListStatementDetail) {
        let priceListStatementDetailWrapper = {
            Id: priceListStatementDetail.Id,
            url: "/" + priceListStatementDetail.Id,
            productId: priceListStatementDetail[Product__c.fieldApiName],
            values: [],
            isNew: false,
        }
        if (!priceListStatementDetail.Id) {
            priceListStatementDetailWrapper.newRowIndex = priceListStatementDetail.newRowIndex;
            priceListStatementDetailWrapper.isNew = true;
        }
        let index = 0;
        let snapshot = {};
        for (let field of this.allDisplayedGridFields) {
            if (field.isInputField && this.PLSDToUpdateMap.hasOwnProperty(priceListStatementDetail.Id)) {
                let obj = this.PLSDToUpdateMap[priceListStatementDetail.Id];
                if (obj.hasOwnProperty(field.fieldName)) {
                    priceListStatementDetail[field.fieldName] = obj[field.fieldName];
                }
            }
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                isInputField: field.isInputField && this.mainData.currentPriceListStatement[API_NAMES.PriceListStatement__c.Status__c] != 'Validated',
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: false,
                isDate: false,
                isPicklist: false,
                isBoolean: false,
                isText: false,
                isTextArea: false,
                isHTMLFormatted: field.isHTMLFormatted,
                style: field.style,
                bgColor: field.bgColor ? field.bgColor.replace('#', '') : 'FFFFFF',
                fieldValue: priceListStatementDetail[field.fieldName],
                picklistOptions: [],
                scale: field.scale,
                step: field.isInputField && field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                linkStyle: '',
                class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : ''),
                isProductField: priceListStatementDetail.Id && field.fieldName == Product__c.fieldApiName,
            }
            if (priceListStatementDetailWrapper.isNew) {
                fieldWrapper.style += ' background-color: rgb(250, 255, 189) !important;';
                fieldWrapper.class += ' slds-cell-edit slds-is-edited';
            }
            if (field.fieldName == Product__c.fieldApiName) {
                fieldWrapper.divClass = 'spaceBetween';
            }
            if (fieldWrapper.isHTMLFormatted) {
                fieldWrapper.class += ' slds-align--absolute-center';
            }
            switch (field.fieldType) {
                case "REFERENCE":
                    fieldWrapper.isReference = true;
                    fieldWrapper.link = "/" + fieldWrapper.fieldValue;
                    fieldWrapper.fieldValue = priceListStatementDetail[field.fieldName.replace('__c', '__r')]?.Name;
                    break;
                case "DATE":
                    fieldWrapper.isDate = true;
                    break;
                case "PICKLIST":
                    fieldWrapper.isPicklist = true;
                    for (let value of Object.keys(this.mainData.gridSettingsManager.picklistValuesMap[field.fieldName])) {
                        fieldWrapper.picklistOptions.unshift({
                            label: this.mainData.gridSettingsManager.picklistValuesMap[field.fieldName][value],
                            value: value,
                            isSelected: value == fieldWrapper.fieldValue,
                        })
                    }
                    fieldWrapper.fieldOutputValue = this.mainData.gridSettingsManager.picklistValuesMap[field.fieldName][fieldWrapper.fieldValue] != null ? this.mainData.gridSettingsManager.picklistValuesMap[fieldWrapper.fieldName][fieldWrapper.fieldValue] : fieldWrapper.fieldValue;
                    break;
                case "BOOLEAN":
                    fieldWrapper.isBoolean = true;
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    break;
                case "TEXTAREA":
                    fieldWrapper.isTextArea = true;
                    break;
                default:
                    fieldWrapper.isText = !fieldWrapper.isNumberField;
            }
            if (field.fieldName.includes('.')) {
                let values = field.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let item = index == 0 ? priceListStatementDetail : fieldWrapper.fieldValue;
                    if (index == values.length - 1 && field.stringFieldType == 'REFERENCE') {
                        fieldWrapper.fieldValue = item[values[index].replace('__c', '__r')].Name;
                        fieldWrapper.link = '/' + item[values[index]];
                    } else {
                        fieldWrapper.fieldValue = item[values[index]];
                    }
                }
            }
            fieldWrapper.class += fieldWrapper.isNumberField ? ' slds-text-align--right' : '';
            if (!field.widthStyle) {
                fieldWrapper.style += 'min-width: 100px; max-width: 100px; width: 100px;';
            }
            snapshot[fieldWrapper.fieldName] = fieldWrapper.fieldValue;
            priceListStatementDetailWrapper.values.push(fieldWrapper);
            index++;
        }
        if (!this.originalValuesById.hasOwnProperty(priceListStatementDetailWrapper.Id)) {
            this.originalValuesById[priceListStatementDetailWrapper.Id] = snapshot;
        }
        return priceListStatementDetailWrapper;
    }

    handleFieldEdits(event) {
        let Id = event.target.dataset.id;
        let fieldName = event.target.dataset.field;
        let isBoolean = event.target.dataset.isboolean;
        let value = event.target.value;
        let categIndex = event.target.dataset.categindex;
        let categoryId = this.records[categIndex].categoryId;
        let rowIndex = event.target.dataset.rowindex;
        let newRowIndex = event.target.dataset.newRowIndex;
        let fieldIndex = event.target.dataset.fieldindex;
        let item = this.records[categIndex].priceListStatementDetails[rowIndex];
        item.hasChanged = true;
        if (isBoolean == 'true') {
            value = event.target.checked;
        }
        const fieldMeta = this.records[categIndex].priceListStatementDetails[rowIndex].values[fieldIndex];
        const isNumberField = fieldMeta && fieldMeta.isNumberField === true;
        if (isNumberField) {
            value = (value === '' || value === null || typeof value === 'undefined') ? null : Number(value);
        }
        item[fieldName] = Array.isArray(value) ? value[0] : value;
        if (newRowIndex) {
            let newRecord = this.newpriceListStatementDetails.filter(item => item.newRowIndex == newRowIndex);
            if (newRecord && newRecord[0]) {
                newRecord[0][fieldName] = Array.isArray(value) ? value[0] : value;
            }
        } else {
            let obj;
            if (this.PLSDToUpdateMap.hasOwnProperty(Id)) {
                obj = this.PLSDToUpdateMap[Id];
            } else {
                obj = {
                    attributes: {
                        type: PriceListStatementDetail__OBJECT.objectApiName,
                    },
                    Id: Id
                };
            }
            const originalValue = this.originalValuesById[Id][fieldName];
            if (originalValue !== value) {
                obj[fieldName] = value;
            } else {
                if (obj.hasOwnProperty(fieldName)) {
                    delete obj[fieldName];
                }
                const hasAnyChange = Object.keys(obj).some(k => k !== 'attributes' && k !== 'Id');
                if (!hasAnyChange) {
                    delete this.PLSDToUpdateMap[Id];
                    return;
                }
            }
            this.PLSDToUpdateMap[Id] = obj;
        }
        let pldCopy = this.PLDFullDataMap[item.Id];
        pldCopy[fieldName] = value;
        this.recalculatePLDFormulaFields(pldCopy, item);
    }
    handleSave() {
        this.loading = true;
        let priceListStatementDetailsToSave = [];
        const hasNew = Array.isArray(this.newpriceListStatementDetails) && this.newpriceListStatementDetails.length > 0;
        const hasUpdates = this.PLSDToUpdateMap && Object.keys(this.PLSDToUpdateMap).length > 0;
        if (!hasNew && !hasUpdates) {
            this.loading = false;
            showNotification(this, this.labels.LBL_Warning, this.labels.MSG_No_Changes_To_Save, 'warning');
            return;
        }
        if (hasNew) {
            for (let item of this.newpriceListStatementDetails) {
                priceListStatementDetailsToSave.push(item);
            }
        }
        if (hasUpdates) {
            for (let priceListStatementDetailId in this.PLSDToUpdateMap) {
                let objPLSD = this.PLSDToUpdateMap[priceListStatementDetailId];
                priceListStatementDetailsToSave.push(objPLSD);
            }
        }
        save({
            // currentPriceListStatementJSON: JSON.stringify(this.mainData.currentPriceListStatement),
            dataToSave: JSON.stringify(priceListStatementDetailsToSave),//JSON.stringify(Object.values(this.PLSDToUpdateMap))
        }).then((result) => {
            if (result == '') {
                this.newpriceListStatementDetails = [];
                this.PLSDToUpdateMap = {};
                this.originalValuesById = {};
                this.initData();
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
            } else {
                showNotification(this, this.labels.LBL_Error, result, 'error', 'dismissible');
            }
        }).catch(error => {
            this.loading = false;
            showNotification(this, this.labels.LBL_Error, 'saving error', 'error', 'sticky');
            console.error(error);
        });
        this.loading = false;
    }

    handleCancel(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
            state: {
                //nooverride: '1'
            }
        });
    }
    handleChangeStatus(event) {
        this.loading = true;
        let status = 'Validated';
        changePriceListStatementStatus({
            currentPriceListStatementJSON: JSON.stringify(this.mainData.currentPriceListStatement)
        }).then(batchId => {
            checkCompletedBatches(this, batchId).then(result => {
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Validated, 'success', 'dismissible');
                this.records = [];
                this.initData();
            }).catch(error => {
                console.error(error);
            });
        }).catch(error => {
            this.loading = false;
            showNotification(this, this.labels.LBL_Error, error, 'error', 'dismissible');
            console.error(error);
        });
    }

    toggleFilter() {
        let filterSecion = this.template.querySelector('.filter-section');
        if (filterSecion) {
            filterSecion.classList.toggle('slds-hide');
        }
    }

    toggleImportPopup() {
        this.template.querySelector('.importSection').classList.toggle('slds-hide');
    }

    uploadExcel(event) {
        this.importedRecords = event.detail.value;
        this.fileData = event.detail.fileData;
    }

    getFileId(event) {
        this.fileDirectoryId = event.detail.fileDirectoryId;
    }

    confirmImportExcel() {
        try {
            this.loading = true;
            let recordsToUpsert = JSON.parse(this.importedRecords)
            importPLSD({
                recordId: this.recordId,
                recordsToUpsert: JSON.stringify(recordsToUpsert),
                fileName: this.fileData?.fileName,
                base64Data: this.fileData?.base64,
                fileType: this.fileData?.fileType,
                fileDirectoryId: this.fileDirectoryId,
            }).then(batchId => {
                if (batchId != null) {
                    checkCompletedBatches(this, batchId).then(result => {
                        this.loadData();
                        this.toggleImportPopup();
                    }).catch(error => {
                        console.error(error);
                    });
                } else {
                    this.loadData();
                    this.toggleImportPopup();
                }
            }).catch(error => {
                showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                console.log(error);
                this.loading = false;
            });
        } catch (error) {
            this.loading = false;
            showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
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
    setSearchValue(event) {
        this.filters.searchValue = event.detail.value;
    }

    confirmFilter() {
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
            this.filters.dynamicSearch = JSON.stringify(selection);
            this.loadData();
        } catch (error) {
            console.log(error);
        }
    }
    handleReset() {
        this.filters = {
            searchValue: '',
            dynamicSearch: '',
        };
        this.loadData();
    }

    handleChangePageSize(event) {
        this.pageSize = parseInt(event.target.value);
        for (let option of this.pageSizeOptions) {
            option.isSelected = option.value == this.pageSize;
        }
        this.pageNumber = 1;
        this.loadData();
    }

    handleChangePage(event) {
        this.loading = true;
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                let pageSize = parseInt(this.pageSize);
                this.pageNumber = Math.ceil(this.totalNumbOfRecords / pageSize);
            }
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    exportExcel() {
        this.showFileGenerationBar = true;
        this.allRecordsToExport = [];
        try {
            this.tableLoading = true;
            processRestForExcel({
                priceListStatementId: this.recordId,
                gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
                restURL: null
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    this.totalExportSize = parsedResult.totalSize;
                    this.rowCounter = 0;
                    if (parsedResult.error != null) {
                        showNotification(this, this.labels.LBL_Error, parsedResult.error, 'error');
                        return;
                    }
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.priceListStatementDetails) {
                            this.allRecordsToExport.push(...parsedResult.priceListStatementDetails);
                            this.rowCounter += parsedResult.priceListStatementDetails.length;
                            this.fileGenerationValue = (this.rowCounter / this.totalExportSize) * 100;
                        }
                        if (parsedResult.done) {
                            this.showFileGenerationBar = false;
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    showNotification(this, this.labels.LBL_Error, error.message, 'error');
                }
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                showNotification(this, this.labels.LBL_Error, error.message, 'error');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message, 'error');
        }
    }

    excelLoadMore(nextRecordsUrl) {
        processRestForExcel({
            priceListStatementId: this.recordId,
            gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
            restURL: nextRecordsUrl,
        }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result)
                try {
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.priceListStatementDetails) {
                            this.allRecordsToExport.push(...parsedResult.priceListStatementDetails);
                            this.rowCounter += parsedResult.priceListStatementDetails.length;
                            this.fileGenerationValue = (this.rowCounter / this.totalExportSize) * 100;
                        }
                        if (parsedResult.done) {
                            this.showFileGenerationBar = false;
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    showNotification(this, this.labels.LBL_Error, error.message, 'error');
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
            const worksheet = workbook.addWorksheet(this.priceListStatementName, { properties: { tabColor: { argb: 'worksheet' } } });
            let rowCounter = 1;
            const headerRow1 = worksheet.getRow(rowCounter);
            const header1Values = [];
            const colWidthStyle = [];
            const headerStyles = [];
            for (let field of this.displayedFields) {
                header1Values.push(field.fieldLabel);
                colWidthStyle.push(field.width);
                headerStyles.push(field.style);
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
                    fgColor: { argb: bgMatch ? bgMatch[1] : '0d807d' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: colorMatch ? colorMatch[1] : 'FFFFFF' },
                }
                cell.border = {
                    top: { style: 'thin', color: { argb: 'E6E6E6' } },
                    left: { style: 'thin', color: { argb: 'E6E6E6' } },
                    bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                    right: { style: 'thin', color: { argb: 'E6E6E6' } }
                };
                cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center', };
            });
            for (let record of dataToExport) {
                let rowLine;
                let rowValues = [];
                for (let priceListStatementDetail of record.priceListStatementDetails) {
                    rowLine = worksheet.getRow(rowCounter);
                    rowLine.height = 20;
                    rowValues = [];
                    let style = [];
                    let index = 1;
                    for (let field of priceListStatementDetail.values) {
                        let value = '';
                        if (field.isPicklist) {
                            value = field.fieldOutputValue ?? ' ';
                        } else if (field.isDate) {
                            value = new Date(field.fieldValue) ?? ' ';
                        } else {
                            value = field.fieldValue ?? ' ';
                        }
                        rowValues.push(value);
                        style.push({ fgColor: field.bgColor });
                        index++;
                    }
                    rowLine.values = rowValues;
                    rowLine.eachCell(function (cell, colNumber) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: style[colNumber - 1].fgColor },
                        };
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'E6E6E6' } },
                            left: { style: 'thin', color: { argb: 'E6E6E6' } },
                            bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                            right: { style: 'thin', color: { argb: 'E6E6E6' } }
                        };
                        cell.alignment = {
                            wrapText: true,
                            vertical: 'middle',
                            horizontal: style[colNumber - 1].horizAlign
                        };
                    });
                    rowCounter++;
                    this.fileGenerationValue = (rowCounter / this.totalExportSize) * 100;
                }
            }
            for (let index in colWidthStyle) {
                let colIndex = parseInt(index) + 1;
                worksheet.getColumn(colIndex).width = colWidthStyle[index];
            }
            worksheet._rows[0]._cells.forEach(cell => {
                cell.protection = { locked: true, lockText: false };
            });
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let base64Bin = result.toString('base64');
                if (this.isSendEmail) {
                    this.handleSend(base64Bin);
                } else {
                    const blob = new Blob([result], { type: 'application/octet-stream' });
                    const downloadElement = document.createElement('a');
                    downloadElement.style = 'display: none';
                    downloadElement.href = window.URL.createObjectURL(blob);
                    downloadElement.download = this.mainData.currentPriceListStatement.Name + '.xlsx';
                    document.body.appendChild(downloadElement);
                    downloadElement.click();
                    document.body.removeChild(downloadElement);
                    if (this.isExportExcel) {
                        window.close();
                    }
                    this.loadingtable = false;
                }
            });
        } catch (error) {
            this.loadingtable = false;
            console.log('error > ' + error)
        }
    }

    fieldsToBottomUp = [
        API_NAMES.PriceListStatementDetail__c.SellInTotalQtywGrossPriceP1__c,
        API_NAMES.PriceListStatementDetail__c.SellInTotalQtywGrossPricewNetTaxP1__c,
        API_NAMES.PriceListStatementDetail__c.SellInTotalQtywUnitGrossPriceP1__c,
        API_NAMES.PriceListStatementDetail__c.SellInTotalQtyTaxesP1__c,
        API_NAMES.PriceListStatementDetail__c.SellInTotalQtywUnitGrossPricewNetTaxP1__c,
    ]

    recalculatePLDFormulaFields(PLSD, item) {
        console.log('recalculatePLDFormulaFields >>> ' + JSON.stringify(this.priceListStatementDetailFields))
        this.executionFormulaFieldOrder.forEach(formulaField => {
            console.log('formulaField >>> ' + formulaField)
            if (this.formulasMetadata.hasOwnProperty(formulaField)) {
                let variablesMap = this.buildFormulonVariablesMap(PLSD);
                console.log('variablesMap >>> ' + JSON.stringify(variablesMap))
                const res = formulon.parse(this.formulasMetadata[formulaField], variablesMap);
                if (this.fieldsToBottomUp.includes(formulaField)) {
                    let oldValue = PLSD[formulaField] ? PLSD[formulaField] : 0;
                    this.recalculateParentValues(PLSD, formulaField, oldValue, res.value);
                }
                console.log('Pres.value >>> ' + res.value)
                let isPercent = this.priceListStatementDetailFields[formulaField]?.dataType?.toUpperCase() == 'PERCENT' || false
                PLSD[formulaField] = isPercent ? res.value * 100 : res.value;
                console.log('PLD[formulaField] >>> ' + PLSD[formulaField])
            }
        })
        this.executionFormulaFieldOrder.forEach(formulaField => {
            console.log('formulaField >>> ' + formulaField)
            if (this.formulasMetadata.hasOwnProperty(formulaField)) {
                let variablesMap = this.buildFormulonVariablesMap(PLSD);
                console.log('variablesMap >>> ' + JSON.stringify(variablesMap))
                const res = formulon.parse(this.formulasMetadata[formulaField], variablesMap);
                // if (this.fieldsToBottomUp.includes(formulaField)) {
                //     let oldValue = PLSD[formulaField] ? PLSD[formulaField] : 0;
                //     this.recalculateParentValues(PLSD, formulaField, oldValue, res.value);
                // }
                let isPercent = this.priceListStatementDetailFields[formulaField]?.dataType?.toUpperCase() == 'PERCENT' || false
                PLSD[formulaField] = isPercent ? res.value * 100 : res.value;
            }
        })
        item.values.forEach(field => {
            if (!field.fieldName.includes('.') && (field.isNumberField || field.isBoolean)) {
                field.fieldValue = PLSD[field.fieldName];
                console.log('field.fieldValue >>> ' + field.fieldValue)
            }
        })
    }

    recalculateParentValues(PLSD, fieldName, oldValue, newValue) {
        if (PLSD[API_NAMES.PriceListStatementDetail__c.PriceListStatement__r]) {
            PLSD[API_NAMES.PriceListStatementDetail__c.PriceListStatement__r][fieldName] = (PLSD[API_NAMES.PriceListStatementDetail__c.PriceListStatement__r][fieldName] ? PLSD[API_NAMES.PriceListStatementDetail__c.PriceListStatement__r][fieldName] : 0) - oldValue + newValue;
        }
    }

    buildFormulonVariablesMap(PLD) {
        try {
            let variablesMap = {};
            Object.keys(this.objectFieldsCalculationMap).forEach(referencedField => {
                if (!Object.keys(variablesMap).includes(referencedField)) {
                    const fieldType = this.objectFieldsType[referencedField] ? this.objectFieldsType[referencedField] : 'text';
                    // console.log(' >>>>> ' + referencedField + ' >>> ' + fieldType)
                    let fieldNameParts = referencedField.split('.');
                    let fieldValue = null;
                    for (let index = 0; index < fieldNameParts.length; index++) {
                        let item = index == 0 ? PLD : fieldValue;
                        fieldValue = item[fieldNameParts[index]] ? item[fieldNameParts[index]] : false;
                    }
                    let variable = {
                        type: 'literal',
                        value: fieldValue,
                        dataType: 'text',
                        options: { values: [], scale: this.priceListStatementDetailFields[referencedField]?.scale || 0 }
                    };
                    switch (fieldType) {
                        case 'BOOLEAN':
                            variable.dataType = 'checkbox';
                            variable.value = fieldValue ? 'true' : 'false';
                            break;
                        case 'DOUBLE':
                            variable.dataType = 'number';
                            variable.options.scale = 50;
                            // variable.options.scale = 3;
                            variable.value = fieldValue ? parseFloat(fieldValue) : 0;
                            break;
                        case 'INTEGER':
                            variable.dataType = 'number';
                            variable.options.scale = 0
                            variable.value = fieldValue ? parseFloat(fieldValue) : 0;
                            break;
                        case 'CURRENCY':
                            variable.dataType = 'number';
                            variable.options.scale = 50;
                            variable.value = fieldValue ? parseFloat(fieldValue) : 0;
                            break;
                        case 'PERCENT':
                            variable.dataType = 'number';
                            variable.options.scale = 50;
                            variable.value = fieldValue ? parseFloat(fieldValue) / 100 : 0;
                            break;
                        case 'DATE':
                            variable.dataType = 'date';
                            variable.value = fieldValue ? new Date(fieldValue).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]; // Format as 'YYYY-MM-DD'
                            break;
                        case 'DATETIME':
                            variable.dataType = 'datetime';
                            variable.value = fieldValue ? new Date(fieldValue).toISOString() : new Date().toISOString();
                            break;
                        case 'TIME':
                            variable.dataType = 'time';
                            variable.value = fieldValue ? fieldValue : new Date().getTime();
                            break;
                        case 'PICKLIST':
                            variable.dataType = 'picklist';
                            variable.value = fieldValue ? fieldValue : '';
                            break;
                        default:
                            variable.value = fieldValue ? String(fieldValue) : '';
                    }
                    variablesMap[referencedField] = variable;
                }
            });
            return variablesMap;
        }
        catch (error) {
            console.error(error.message);
        }
    }

    setnumberOfFixedColumns(event) {
        if (event) {
            this.nbOfFixedColumns = parseInt(event.detail.value);
        }
        let fixedColumn = this.nbOfFixedColumns;
        let tableTrs = this.template.querySelector('.main-table')?.rows;
        if (tableTrs) {
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                let left = 0;
                if (index != 0 && !tableTrs[index].classList?.contains('firsthierarchyRow') && !tableTrs[index].classList?.contains('subTotalRow')) {
                    fixedColumn = this.nbOfFixedColumns - 1;
                    left = tableTrs[1].children[0].offsetWidth;
                } else {
                    fixedColumn = this.nbOfFixedColumns;
                }
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 > fixedColumn) {
                        childrens[index2].style.position = '';
                        childrens[index2].style.left = '';
                        childrens[index2].style.zIndex = '';
                    } else if (index2 < fixedColumn) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = index == 0 ? 5 : 3;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                    }
                }
            }
        }
    }

}