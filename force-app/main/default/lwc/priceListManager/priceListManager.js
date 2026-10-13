import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import xlsxLibJS from '@salesforce/resourceUrl/xlsxLib';
// Services
import initData from '@salesforce/apex/PriceListManagerCmpController.initData';
import processRestForExcel from '@salesforce/apex/PriceListManagerCmpController.processRestForExcel';
import loadData from '@salesforce/apex/PriceListManagerCmpController.loadData';
import changePriceListStatus from '@salesforce/apex/PriceListManagerCmpController.changePriceListStatus';
import save from '@salesforce/apex/PriceListManagerCmpController.save';
import importPriceListDetails from "@salesforce/apex/PriceListManagerCmpController.importPriceListDetails";
//import uploadFile from "@salesforce/apex/PriceListManagerCmpController.uploadFile";
import { checkCompletedBatches } from 'c/appHelper';
import addNewPiceListDetail from '@salesforce/apex/PriceListManagerCmpController.addNewPiceListDetail';
// CUSTOM Objects
import PriceList__OBJECT from '@salesforce/schema/PriceList__c';
import PriceListDetail__OBJECT from '@salesforce/schema/PriceListDetail__c';
import Product2 from "@salesforce/schema/Product2";
import LOG__OBJECT from '@salesforce/schema/Log__c';
// PriceList CUSTOM FIELDS
import Year__c from '@salesforce/schema/PriceList__c.Year__c';
import BusinessUnitTarget__c from "@salesforce/schema/PriceList__c.BusinessUnitTarget__c";
import ExtId__c from "@salesforce/schema/PriceList__c.ExtId__c";
// PriceListDetail CUSTOM Fields
import Hierarchy__c from "@salesforce/schema/PriceListDetail__c.Hierarchy__c";
import Product__c from "@salesforce/schema/PriceListDetail__c.Product__c";
import Status__c from "@salesforce/schema/PriceListDetail__c.Status__c";
// Product2 CUSTOM FIELDS
import GTIN__c from "@salesforce/schema/Product2.GTIN__c";
import ProductCode from "@salesforce/schema/Product2.ProductCode";
// CUSTOM Labels
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Import_Excel from "@salesforce/label/c.LBL_Import_Excel";
import LBL_Export_Excel from "@salesforce/label/c.LBL_Export_Details";
import LBL_PL_No_Data from "@salesforce/label/c.LBL_PL_No_Data";
import LBL_PL_No_Data_Help from "@salesforce/label/c.LBL_PL_No_Data_Help";
import LBL_PL_Add_Products from "@salesforce/label/c.LBL_PL_Add_Products";
import LBL_PL_Import_Popup_Title from "@salesforce/label/c.LBL_PL_Import_Popup_Title";
import LBL_PL_Import_Popup_Reminder from "@salesforce/label/c.LBL_PL_Import_Popup_Reminder";
import LBL_Import_Field_Name from "@salesforce/label/c.LBL_Import_Field_Name";
import LBL_Import_Field_Label from "@salesforce/label/c.LBL_Import_Field_Label";
import LBL_Import_Field_Column_Number from "@salesforce/label/c.LBL_Import_Field_Column_Number";
import LBL_Import_First_Row_Number from "@salesforce/label/c.LBL_Import_First_Row_Number";
import LBL_PL_Validate_Prices from "@salesforce/label/c.LBL_PL_Validate_Prices";
import LBL_Product_Search from "@salesforce/label/c.LBL_Product_Search";
import LBL_PLD_No_Data_Found from "@salesforce/label/c.LBL_PLD_No_Data_Found";

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
export default class PriceListManager extends NavigationMixin(LightningElement) {
    //API Variables
    @api recordId;
    @api gridLayout;
    @api isExportExcel;

    // TRACK Variables
    @track labels = {
        MSG_No_Changes_To_Save,
        LBL_No_Item_To_Display,
        LBL_Cancel,
        LBL_Save,
        LBL_Success,
        LBL_Error,
        LBL_Search,
        LBL_Reset,
        LBL_Filter,
        LBL_Number_Of_Fixed_Columns,
        LBL_First,
        LBL_Previous,
        LBL_Next,
        LBL_Last,
        LBL_Of,
        MSG_Successfully_Saved,
        LBL_Import_Excel,
        LBL_Export_Excel,
        LBL_PL_No_Data,
        LBL_PL_No_Data_Help,
        LBL_PL_Add_Products,
        LBL_PL_Import_Popup_Title,
        LBL_PL_Import_Popup_Reminder,
        LBL_Import_Field_Name,
        LBL_Import_Field_Label,
        LBL_Import_Field_Column_Number,
        LBL_Import_First_Row_Number,
        LBL_PL_Validate_Prices,
        LBL_Product_Search,
        LBL_PLD_No_Data_Found,
        PriceListLabel: '',
        ProductFields: {
            GTIN__c: '',
            ProductCode: '',
        },
        LBL_PriceList_Modify_Status_to_Validate: '',
        LBL_Processing: 'Processing',

    }
    @track filters = {
        searchValue: '',
        dynamicSearch: '',
    }
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
    @track loading = false;
    @track pageSize = 25;
    @track pageNumber = 1;
    @track nbOfFixedColumns = 1;
    @track priceListName;
    @track availableImportFields = [];
    @track processing = false;
    @track processedItems = 0;
    @track processed = 0;
    @track acceptedFormats = ['.xls', '.xlsx'];
    @track file;
    @track off = 0;
    @track totalSize = 0;
    @track logs = [];
    @track startLineNumber = "2";
    @track records = [];
    @track displayedFields = [];
    @track allDisplayedGridFields = [];
    @track dynamicTaxesFields = [];
    @track dynamicUnitChargesFields = [];
    @track displayedUnitChargesFields = [];
    @track displayedDynamicFields = [];
    @track fieldsToFilter = [];
    @track PLDToUpdateMap = {};
    @track productPanelVisibility = false;
    @track PLDFieldsType = {};

    //EXCEL
    allRecordsToExport;
    rowCounter = 0;
    @track totalExportSize = 0;
    @track fileGenerationValue = 0;
    @track fileDownloadValue = 0;
    @track showFileGenerationBar = false;
    @track showFileDownloadBar = false;

    PLDPicklistValues = {};
    fieldsToFilterMap = {};
    totalNumbOfRecords = 0;
    validateDisabled = false;
    logData = {};
    XL_row_object = [];
    data = {};
    batchIndex = 0;
    processMethod;
    noDataToProcess = false;
    fileContent = '';
    processUplodingFile = false;
    rendered = false;
    @track priceListDetailsData = [];
    @track newPriceListDetails = [];
    @track PriceListDetailObject = PriceListDetail__OBJECT;
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
    firstLoad = true;
    @track hasDataOnFirstLoad = false;
    @track wireIsDone = {
        ProductInfo: false,
        PriceListInfo: false,
        PLDPicklistValues: false,
        PriceListDetailInfo: false,
        currentPageReference: false
    }
    checkIfWireIsDone() {
        if (this.wireIsDone.ProductInfo && this.wireIsDone.PriceListInfo && this.wireIsDone.PLDPicklistValues && this.wireIsDone.PriceListDetailInfo
            && this.wireIsDone.currentPageReference) {
            this.initData();
        }
    }
    // WIRES
    //Set PriceList Id
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
            this.wireIsDone.currentPageReference = true;
            this.checkIfWireIsDone();
        }
    }

    @wire(getObjectInfo, { objectApiName: Product2 }) objectInfoProduct({ error, data }) {
        if (data) {
            this.labels.ProductFields.GTIN__c = data.fields[GTIN__c.fieldApiName].label;
            this.labels.ProductFields.ProductCode = data.fields[ProductCode.fieldApiName].label;
            this.wireIsDone.ProductInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.log('ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: PriceList__OBJECT }) objectInfoPriceList({ error, data }) {
        if (data) {
            this.labels.PriceListLabel = data.label;
            this.wireIsDone.PriceListInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: PriceListDetail__OBJECT, recordTypeId: "012000000000000AAA" }) picklistValues({ error, data }) {
        if (data) {
            this.PLDPicklistValues = data.picklistFieldValues;
            this.wireIsDone.PLDPicklistValues = true;
            this.checkIfWireIsDone();
        } else if (error) {
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
            console.error(error);
        }
    }
    @wire(getObjectInfo, { objectApiName: PriceListDetail__OBJECT }) objectInfoPLD({ error, data }) {
        if (data) {
            for (let field of Object.values(data.fields)) {
                if (field.updateable) {
                    this.PLDFieldsType[field.apiName] = field.dataType;
                }
            }
            this.wireIsDone.PriceListDetailInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
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
                        //loadScript(this, xlsxLibJS + '/js-xlsx-master/dist/jszip.js'),
                    ]).then(() => {
                        this.librariesLoaded = true;
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

    handleChangeColumnNumber(event) {
        let value = event.target.value;
        let index = event.target.dataset.index;
        this.availableImportFields[index].columnNumber = value;
    }
    importExcel(event) {
        let productGTINField = this.availableImportFields.filter(item => item.fieldName == GTIN__c.fieldApiName);
        let productCodeField = this.availableImportFields.filter(item => item.fieldName == ProductCode.fieldApiName);
        let columns = this.availableImportFields.filter(item => item.columnNumber != null && item.columnNumber != '');
        if (productGTINField && productGTINField.columnNumber != null && productGTINField.columnNumber == '') {
            this.showNotification(LBL_Error, 'You should define GTIN column before performing your load', 'error', 'sticky');
            return;
        } else if (productCodeField && productCodeField.columnNumber != null && productCodeField.columnNumber == '') {
            this.showNotification(LBL_Error, 'You should define ProductCode column before performing your load', 'error', 'sticky');
            return;
        } else if (columns.length <= 2) {
            this.showNotification(LBL_Error, 'You have no data defining for download', 'error', 'sticky');
            return;
        }
        var files = event.target.files;
        this.file = files[0];
        this.noDataToProcess = !this.file;
        let self = this;
        let fileReader = new FileReader();
        fileReader.onload = () => {
            try {
                let workbook = XLSX.read(fileReader.result, { type: 'binary' });
                if (Object.keys(workbook.Sheets).length == 1) {
                    Object.keys(workbook.Sheets).forEach(sheetName => {
                        self.XL_row_object = XLSX.utils.sheet_to_row_object_array(workbook.Sheets[sheetName]);
                        self.totalSize = self.XL_row_object.length;
                        self.off = 0;
                        for (let index = self.XL_row_object.length; index > 0; index = index - 10000) {
                            self.off++;
                        }
                        self.XL_row_object.length < 10000;
                        self.processed = 0;
                        self.processedItems = 0;
                    });
                } else {
                    //self.showNotification('info', LBL_Information, MSG_Only_1_Sheet_Is_Allowed, '');
                }
                // this.fileContent = fileReader.result;
            } catch (error) {
                //self.showNotification('error', LBL_Error, MSG_Loading_Failed_Please_Refresh_Page, '');
                console.error(err);
                this.showNotification(LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            }
        };
        fileReader.readAsBinaryString(self.file);
    }
    handleUpload(priceListIds) {
        if (this.fileContent) {
            uploadFile({
                fileName: self.File.name,
                base64Data: this.fileContent,
                fileType: this.file.type,
                priceListIds: priceListIds,
                defaultRTnegOptimFile: this.mainData.defaultRTnegOptimFile,
            }).then(() => {
                this.showNotification(LBL_Success, 'File uploaded successfully', 'success', 'sticky');
            }).catch(error => {
                this.showNotification(LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        }
    }
    handleChangeStartLineNumber(event) {
        this.startLineNumber = event.target.value;
    }
    processUploading() {
        let priceListIds = [];
        let priceListExtIds = [];
        priceListIds.push(this.recordId);
        priceListExtIds.push(this.mainData.currentPriceList[ExtId__c.fieldApiName]);
        let columnsMap = {};
        this.availableImportFields.filter(item => item.columnNumber != null && item.columnNumber != '')?.forEach(item => {
            columnsMap[item.columnNumber] = item.fieldName;
        });
        let self = this;
        self.processing = true;
        self.processUplodingFile = true;
        let data = self.data;
        let rowNumber = 1;
        let XL_row_object = self.XL_row_object;
        if (XL_row_object && XL_row_object.length) {
            let row = XL_row_object.shift();
            if (self.startLineNumber < rowNumber) {
                rowNumber++;
                return;
            }
            rowNumber++;
            let fieldValues = [];
            let columnNumber = 1;
            let GTINValue = '', ProductCodeValue = '';
            Object.entries(row).forEach(([key, val]) => {
                if (columnsMap.hasOwnProperty(columnNumber)) {
                    let fieldName = columnsMap[columnNumber];
                    let fieldType = self.PLDFieldsType[fieldName];
                    if (fieldType) {
                        if (fieldType == 'Currency' || fieldType == 'Percent' || fieldType == 'Double' || fieldType == 'Integer' || fieldType == 'Long') {
                            val = self.extractNumber(val);
                        } else if (fieldType == 'Picklist') {
                            if (self.PLDPicklistValues && self.PLDPicklistValues[fieldName]) {
                                for (let pickVal of self.PLDPicklistValues[fieldName].values) {
                                    if (val == pickVal.label || val == pickVal.value) {
                                        val = pickVal.value;
                                    }
                                }
                            }
                        } else if (fieldType == 'Multipicklist') {
                            if (self.PLDPicklistValues && self.PLDPicklistValues[fieldName]) {
                                val = val.split(';').map(value => self.PLDPicklistValues[fieldName].find(pickVal => value == pickVal.label || value == pickVal.value) ? pickVal.value : value).join(';');
                            }
                        } else if (fieldType == 'Date') {
                            let currentVal = new Date(val);
                            let ye = new Intl.DateTimeFormat('fr', { year: 'numeric' }).format(currentVal);
                            let mo = new Intl.DateTimeFormat('fr', { month: '2-digit' }).format(currentVal);
                            let da = new Intl.DateTimeFormat('fr', { day: '2-digit' }).format(currentVal);
                            val = ye + '-' + mo + '-' + da;
                        }
                    }
                    fieldValues.push({ fieldName: fieldName, fieldValue: val });
                    if (fieldName == GTIN__c.fieldApiName) {
                        GTINValue = val;
                    }
                    if (fieldName == ProductCode.fieldApiName) {
                        ProductCodeValue = val;
                    }
                }
                columnNumber++;
            });
            let productKey = GTINValue + '|' + ProductCodeValue;
            data[productKey] = fieldValues;
            self.processedItems++;
            self.updateProcessed(self.processedItems * 100 / self.totalSize);
        }
        if (Object.keys(data).length >= 10000 || !XL_row_object.length) {
            //self.processing = XL_row_object.length != 0;
            if (data && Object.keys(data).length) {
                self.data = {};
                self.batchIndex++;
                let batchIndex = self.batchIndex + '/' + self.off;
                importPriceListDetails({ batchIndex: batchIndex, dataJson: JSON.stringify(data), priceListExtIdsJson: JSON.stringify(priceListExtIds) }).then(batchId => {
                    checkCompletedBatches(this, batchId).then(result => {
                        self.processing = false;
                        self.processUplodingFile = false;
                        self.loadData(true);
                        this.showNotification(LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                        self.popups.importPopup = false;
                    }).catch(error => {
                        console.log(`🚀 error`, error);
                        this.showNotification(LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                    });
                }).catch(error => {
                    console.log(`🚀 error`, error);
                    this.showNotification(LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                });
                if (XL_row_object && XL_row_object.length) {
                    self.processMethod = setTimeout(() => {
                        self.processUploading();
                    }, 1);
                }
            }
        } else {
            if (XL_row_object.length) {
                self.processMethod = setTimeout(() => {
                    self.processUploading();
                }, 1);
            }
        }
        if (!XL_row_object.length) {
            // self.checkLogs();
            var reader = new FileReader()
            reader.onload = () => {
                self.fileContent = reader.result.split(',')[1]
                //self.handleUpload(priceListIds);
            }
            reader.readAsDataURL(self.file)
        }
    }
    updateProcessed(processed) {
        this.processed = processed;
    }
    extractNumber = (val) => {
        return Number(val.replace(/[^0-9\.]+/g, ""));
    }
    @track tableStyleHeight;
    // setTableDimension
    setTableDimension() {
        let mainContainer = this.template.querySelector('.mainContainer');
        let pageHeader = this.template.querySelector('.header');
        let pageBody = this.template.querySelector('.main-panel');
        let pageFooter = this.template.querySelector('.footerDiv');
        if (
            mainContainer != null &&
            pageHeader != null &&
            pageBody != null &&
            pageFooter != null) {
            pageBody.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - pageFooter.offsetHeight - 10 + "px";
            this.tableStyleHeight = 'background-color: #FFFFFF !important; width: -webkit-fill-available; height:' + (pageBody.style.height) + 'px';
        }
    }
    initData() {
        this.loading = true;
        this.categoryBUClustersMap = {};
        this.categoryBUCpltMap = {};
        this.categoryBUClustersRefMap = {};
        this.categoryBUCpltRefMap = {};
        this.records = [];
        this.newPriceListDetails = [];
        initData({ recordId: this.recordId, gridLayout: this.gridLayout }).then((result) => {
            this.mainData = JSON.parse(result);
            this.priceListName = this.mainData.currentPriceList.CommercialName__c;
            this.pageSize = parseInt(this.mainData.gridSettingsManager.Default_Page_Size);
            this.pageSizeOptions.forEach(element => element.isSelected = element.value == this.pageSize);
            this.dynamicTaxesFields = this.mainData.dynamicTaxesFields || [];
            this.displayedDynamicFields = this.mainData.displayedDynamicFields || [];
            this.dynamicUnitChargesFields = this.mainData.dynamicUnitChargesFields || [];
            this.displayedUnitChargesFields = this.mainData.displayedUnitChargesFields || [];
            this.populateFiltersMap(this.mainData.gridSettingsManager.FILTERS);
            this.availableImportFields = [];
            if (this.mainData.availableImportFields && this.mainData.availableImportFields.length) {
                this.mainData.availableImportFields.forEach(item => {
                    this.availableImportFields.push({
                        fieldName: item.fieldName,
                        fieldLabel: item.fieldLabel,
                        columnNumber: item.fieldName == GTIN__c.fieldApiName ? '1' : (item.fieldName == ProductCode.fieldApiName ? '2' : ''),
                    });
                });
            }
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
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel.toUpperCase(),
                        isNumberField: field.isNumberField,
                        isSortable: field.isSortable,
                        isReference: field.fieldType == 'REFERENCE',
                        style: field.widthStyle + (field.headerStyle ? field.headerStyle.style : ''),
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
                    if (this.dynamicUnitChargesFields.includes(field.fieldName)) {
                        if (this.displayedUnitChargesFields.includes(field.fieldName)) {
                            this.allDisplayedGridFields.push(field);
                            this.displayedFields.push(fieldWrapper);
                        }
                        continue;
                    }
                    this.displayedFields.push(fieldWrapper);
                    this.allDisplayedGridFields.push(field);
                }
                /*this.displayedDynamicFields.forEach(item => {
                    item.isLink = item.url != null;
                    item.colSpan = item.subFieldsList.length;
                    this.displayedFields = this.displayedFields.concat(item.subFieldsList);
                });*/
            }
            if (this.isExportExcel) {
                this.exportExcel();
            } else {
                //this.populateFiltersMap(this.mainData.gridSettingsManager.FILTERS);
                this.loadData(false);
            }
        }).catch(error => {
            console.error(error);
            this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
        });
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
    loadData(addProduct) {
        this.loading = true;
        this.priceListDetailsData = [];
        loadData({
            currentPriceListJSON: JSON.stringify(this.mainData.currentPriceList),
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
            filtersJSON: JSON.stringify(this.filters),
        }).then((result) => {
            try {
                let parsedresult = JSON.parse(result);
                this.totalNumbOfRecords = parsedresult.totalSize;
                this.priceListDetailsData = parsedresult.priceListDetails;
                this.records = this.buildData(parsedresult.priceListDetails);
                this.loading = false;
                if (this.firstLoad || (addProduct && !this.hasDataOnFirstLoad)) {
                    this.firstLoad = false;
                    this.hasDataOnFirstLoad = this.records.length > 0;
                }
            } catch (error) {
                console.log('ERROR: ' + error?.body?.message || error?.message || error);
                this.showNotification('', error.message, 'error');
            }
        }).catch(error => {
            console.error(error);
            console.log('ERROR: ' + error?.body?.message || error?.message || error);
            this.showNotification(LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.loading = false;
        });
    }

    buildData(priceListDetails) {
        let hierarchyWrapperMap = {};
        for (let item of priceListDetails) {
            let hierarchyId = item[Hierarchy__c.fieldApiName];
            let hierarchyWrapper = {
                hierarchyId: hierarchyId,
                hierarchyName: item[Hierarchy__c.fieldApiName.replace('__c', '__r')].Name,
                link: '/' + hierarchyId,
                priceListDetails: [],
                rowspan: 1,
            }
            if (!hierarchyWrapperMap.hasOwnProperty(hierarchyId)) {
                hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
            }
            hierarchyWrapper = hierarchyWrapperMap[hierarchyId];
            let priceListDetailWrapper = this.buildRowData(item);
            hierarchyWrapper.priceListDetails.push(priceListDetailWrapper);
            hierarchyWrapper.rowspan += 1;
            hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
        }
        if (this.newPriceListDetails && this.newPriceListDetails.length) {
            for (let item of this.newPriceListDetails) {
                let hierarchyId = item[Hierarchy__c.fieldApiName];
                let hierarchyWrapper = {
                    hierarchyId: hierarchyId,
                    hierarchyName: item.hierarchyName,
                    link: '/' + hierarchyId,
                    priceListDetails: [],
                    rowspan: 1,
                }
                if (!hierarchyWrapperMap.hasOwnProperty(hierarchyId)) {
                    hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
                }
                hierarchyWrapper = hierarchyWrapperMap[hierarchyId];
                let priceListDetailWrapper = this.buildRowData(item);
                hierarchyWrapper.priceListDetails.push(priceListDetailWrapper);
                hierarchyWrapper.rowspan += 1;
                hierarchyWrapperMap[hierarchyId] = hierarchyWrapper;
            }
        }
        return Object.values(hierarchyWrapperMap);
    }

    buildRowData(priceListDetail) {
        let priceListDetailWrapper = {
            Id: priceListDetail.Id,
            url: "/" + priceListDetail.Id,
            productId: priceListDetail[Product__c.fieldApiName],
            isValid: priceListDetail[Status__c.fieldApiName] == 'Validated',
            values: [],
            isNew: false,
        }
        if (!priceListDetail.Id) {
            priceListDetailWrapper.newRowIndex = priceListDetail.newRowIndex;
            priceListDetailWrapper.isNew = true;
        }
        let index = 0;
        for (let field of this.allDisplayedGridFields) {
            if (field.isInputField && this.PLDToUpdateMap.hasOwnProperty(priceListDetail.Id)) {
                let obj = this.PLDToUpdateMap[priceListDetail.Id];
                if (obj.hasOwnProperty(field.fieldName)) {
                    priceListDetail[field.fieldName] = obj[field.fieldName];
                }
            }
            let fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                isInputField: (priceListDetailWrapper.isValid ? false : field.isInputField),
                fieldType: field.fieldType,
                isNumberField: field.isNumberField,
                isReference: false,
                isDate: false,
                isPicklist: false,
                isBoolean: false,
                isText: false,
                isHTMLFormatted: field.isHTMLFormatted,
                style: field.style,
                bgColor: field.bgColor ? field.bgColor.replace('#', '') : 'FFFFFF',
                fieldValue: priceListDetail[field.fieldName],
                picklistOptions: [],
                scale: field.scale,
                step: field.isInputField && field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                linkStyle: '',
                class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : ''),
                isProductField: priceListDetail.Id && field.fieldName == Product__c.fieldApiName,
            }
            if (priceListDetailWrapper.isNew) {
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
                    fieldWrapper.fieldValue = priceListDetail[field.fieldName.replace('__c', '__r')]?.Name;
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
                default:
                    fieldWrapper.isText = !fieldWrapper.isNumberField;
            }
            if (field.fieldName.includes('.')) {
                let values = field.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let item = index == 0 ? priceListDetail : fieldWrapper.fieldValue;
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
            priceListDetailWrapper.values.push(fieldWrapper);
            index++;
        }
        return priceListDetailWrapper;
    }
    handleAddPriceListDetail(event) {
        try {
            let Id = event.target.dataset.id;
            let rowIndex = event.target.dataset.rowindex;
            let categIndex = event.target.dataset.categindex;
            let currentPriceListDetail = this.records[categIndex].priceListDetails[rowIndex];
            let selectedPriceListDetail = this.priceListDetailsData.filter(item => item.Id == Id);
            if (selectedPriceListDetail) {
                addNewPiceListDetail({ priceListDetailJSON: JSON.stringify(selectedPriceListDetail[0]) }).then((result) => {
                    let newRecord = JSON.parse(result);
                    newRecord.hasChanged = true;
                    newRecord.isNew = true;
                    newRecord.newRowIndex = this.newPriceListDetails.length + 1;
                    newRecord.hierarchyName = this.records[categIndex].hierarchyName;
                    this.newPriceListDetails.push(newRecord);
                    let priceListDetailWrapper = this.buildRowData(newRecord);
                    this.records[categIndex].priceListDetails.push(priceListDetailWrapper);
                    this.records[categIndex].rowspan += 1;
                });
            }
        } catch (error) {
            console.error('error: ' + error);
        }
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
        let item = this.records[categIndex].priceListDetails[rowIndex];
        item.hasChanged = true;
        item[fieldName] = Array.isArray(value) ? value[0] : value;
        if (isBoolean == 'true') {
            value = event.target.checked;
        }
        if (newRowIndex) {
            let newRecord = this.newPriceListDetails.filter(item => item.newRowIndex == newRowIndex);
            if (newRecord) {
                newRecord[0][fieldName] = Array.isArray(value) ? value[0] : value;
            }
        } else {
            let obj;
            if (this.PLDToUpdateMap.hasOwnProperty(Id)) {
                obj = this.PLDToUpdateMap[Id];
            } else {
                obj = {
                    attributes: {
                        type: PriceListDetail__OBJECT.objectApiName,
                    },
                    Id: Id
                };
            }
            obj[fieldName] = value;
            this.PLDToUpdateMap[Id] = obj;
        }

    }
    handleSave() {
        this.loading = true;
        let priceListDetailsToSave = [];
        if (this.newPriceListDetails && this.newPriceListDetails.length > 0) {
            for (let item of this.newPriceListDetails) {
                priceListDetailsToSave.push(item);
            }
        }
        if (this.PLDToUpdateMap) {
            for (let priceListDetailId in this.PLDToUpdateMap) {
                let objPLD = this.PLDToUpdateMap[priceListDetailId];
                priceListDetailsToSave.push(objPLD);
            }
        }
        save({
            currentPriceListJSON: JSON.stringify(this.mainData.currentPriceList),
            dataToSave: JSON.stringify(priceListDetailsToSave),//JSON.stringify(Object.values(this.PLDToUpdateMap))
        }).then((result) => {
            if (result == '') {
                this.newPriceListDetails = [];
                this.PLDToUpdateMap = {};
                this.loadData(false);
                this.showNotification(LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
            } else {
                this.showNotification(LBL_Error, result, 'error', 'dismissible');
            }
        }).catch(error => {
            this.loading = false;
            this.showNotification(LBL_Error, 'saving error', 'error', 'sticky');
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
        changePriceListStatus({
            currentPriceListJSON: JSON.stringify(this.mainData.currentPriceList)
        }).then(batchId => {
            checkCompletedBatches(this, batchId).then(result => {
                this.showNotification(LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                this.records = [];
                this.loadData(false);
            }).catch(error => {
                console.error(error);
            });
        }).catch(error => {
            this.loading = false;
            this.showNotification(LBL_Error, error, 'error', 'dismissible');
            console.error(error);
        });
    }

    toggleFilter() {
        let filterSecion = this.template.querySelector('.filter-section');
        if (filterSecion) {
            filterSecion.classList.toggle('slds-hide');
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
            this.loadData(false);
        } catch (error) {
            console.log(error);
        }
    }
    handleReset() {
        this.filters = {
            searchValue: '',
            dynamicSearch: '',
        };
        this.loadData(false);
    }

    handleChangePageSize(event) {
        this.pageSize = parseInt(event.target.value);
        for (let option of this.pageSizeOptions) {
            option.isSelected = option.value == this.pageSize;
        }
        this.pageNumber = 1;
        this.loadData(false);
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
            this.loadData(false);
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
                priceListId: this.recordId,
                gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
                restURL: null
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    this.totalExportSize = parsedResult.totalSize;
                    this.rowCounter = 0;
                    if (parsedResult.error != null) {
                        this.showNotification(LBL_Error, parsedResult.error, 'error');
                        return;
                    }
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.priceListDetails) {
                            this.allRecordsToExport.push(...parsedResult.priceListDetails);
                            this.rowCounter += parsedResult.priceListDetails.length;
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
                    this.showNotification(LBL_Error, error.message, 'error');
                }
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.showNotification(LBL_Error, error.message, 'error');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification(LBL_Error, error.message, 'error');
        }
    }

    excelLoadMore(nextRecordsUrl) {
        processRestForExcel({
            priceListId: this.recordId,
            gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
            restURL: nextRecordsUrl,
        }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result)
                try {
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.priceListDetails) {
                            this.allRecordsToExport.push(...parsedResult.priceListDetails);
                            this.rowCounter += parsedResult.priceListDetails.length;
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
                    this.showNotification(LBL_Error, error.message, 'error');
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
            const worksheet = workbook.addWorksheet(this.priceListName, { properties: { tabColor: { argb: 'worksheet' } } });
            let rowCounter = 1;
            const headerRow1 = worksheet.getRow(rowCounter);
            const header1Values = [];
            const colWidthStyle = [];
            for (let field of this.displayedFields) {
                header1Values.push(field.fieldLabel);
                colWidthStyle.push(field.width);
            }
            headerRow1.values = header1Values;
            rowCounter++;
            headerRow1.eachCell(function (cell, colNumber) {
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: '0d807d' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: 'FFFFFF' },
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
                for (let priceListDetail of record.priceListDetails) {
                    rowLine = worksheet.getRow(rowCounter);
                    rowLine.height = 20;
                    rowValues = [];
                    let style = [];
                    let index = 1;
                    for (let field of priceListDetail.values) {
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
                    downloadElement.download = this.mainData.currentPriceList.Name + '.xlsx';
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

    // show notification 
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    toggleProductPanel() {
        this.productPanelVisibility = !this.productPanelVisibility;
        if (!this.productPanelVisibility) {
            this.records = [];
            this.initData();
            if (!this.hasDataOnFirstLoad) {
                this.hasDataOnFirstLoad = true;
            }
        }
    }

    @track popups = {
        importPopup: false,
        priceListProductSelection: {
            isOpen: false,
            title: '',
            openModal() {
                this.popups.priceListProductSelection.isOpen = true;
            },
            closeModal() {
                let self = this;
                self.popups.priceListProductSelection.isOpen = false;
                self.loadData(true);
                if (!this.hasDataOnFirstLoad) {
                    self.hasDataOnFirstLoad = self.records.length > 0
                }
            },
            submitDetails() {
                this.popups.priceListProductSelection.isOpen = false;
            }
        }
    }

    Events = {
        closePopup: 'closepopup'
    }

    togglePopups(event) {
        this.loading = true;
        this.popupLoading = true;
        let popup = event.target.dataset.popup;
        this.popups[popup] = !this.popups[popup];
        if (popup == 'importPopup' && this.processUplodingFile) {
            this.processUplodingFile = false;
            this.loadData(true);
        }
        this.loading = false;
    }
}