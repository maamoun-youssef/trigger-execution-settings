import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import ExcelJSURL from '@salesforce/resourceUrl/ExcelJS';
import xlsxLib from '@salesforce/resourceUrl/xlsxLib';
import initData from '@salesforce/apex/AssortmentMatrixCtrl.initData';
import processRestForExcel from '@salesforce/apex/AssortmentMatrixCtrl.processRestForExcel';
import loadData from '@salesforce/apex/AssortmentMatrixCtrl.loadData';
import changeAssortmentStatus from '@salesforce/apex/AssortmentMatrixCtrl.changeAssortmentStatus';
import save from '@salesforce/apex/AssortmentMatrixCtrl.save';
import saveData from '@salesforce/apex/AssortmentMatrixCtrl.saveData';
import getHLPProducts from '@salesforce/apex/AssortmentMatrixCtrl.getHLPProducts';
import getSwitchProducts from '@salesforce/apex/AssortmentMatrixCtrl.getSwitchProducts';
import sendEmail from '@salesforce/apex/AssortmentDirectAccessPluginCtrl.sendEmail';
import importAssortmentDetails from '@salesforce/apex/AssortmentMatrixCtrl.importAssortmentDetails';
import uploadFile from '@salesforce/apex/AssortmentMatrixCtrl.uploadFile';
// HELPER
import { checkCompletedBatches, showNotification } from 'c/appHelper';

import ASD__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Product2 from '@salesforce/schema/Product2';
import AS__OBJECT from '@salesforce/schema/Assortment__c';
import AssortmentDetail__c from '@salesforce/schema/AssortmentDetail__c.Name';

import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import formulonLibUrl from '@salesforce/resourceUrl/formulonLib';
import { ASD_API_NAMES, BU_API_NAMES, PROD_API_NAMES, AS_API_NAMES, labels, fieldsToColor, fixedColumnsOptions, pageSizeOptions, loadOptions, fieldsToFakesave, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES } from './properties.js';
import { updateAsdOnClusterChange, recalculateTotalFormulaFields, recalculateSubTotalFormulaFields } from './services.js';

export default class AssortmentMatrix extends NavigationMixin(LightningElement) {

    //API VARIABLES
    @api recordId;
    @api gridLayout;
    @api isExportExcel;
    @api isSendEmail;

    //SERVICES VARIABLES
    ASD_API_NAMES = ASD_API_NAMES;
    BU_API_NAMES = BU_API_NAMES;
    PROD_API_NAMES = PROD_API_NAMES;
    AS_API_NAMES = AS_API_NAMES;
    @track labels = labels;
    fieldsToColor = fieldsToColor;
    fixedColumnsOptions = fixedColumnsOptions;
    pageSizeOptions = pageSizeOptions;
    loadOptions = loadOptions;

    //TRACK VARIABLES
    @track flows = {
        createSimulationFromTarget: false, validateTargetAndGenSimul: false, validateTargetAndGenNego: false, createSimulationFromNego: false, createSimulationFromSimulation: false, validateSimulAndGenNego: false, synchroRelatedAssortments: false,
    }
    @track popups = {
        switchRenoPopup: false,
        HLPPopup: false,
        stopPopup: false,
        importPopup: false,
        synchroASRegion: false,
        productPanelVisibility: false,
        LinkToContractVisibility: false,
    }
    @track filters = {
        searchValue: '',
        dynamicSearch: '',
        productLifeStatus: [],
        productTypes: [],
        hideBlankStatus: false,
        showIntroProducts: false,
        onlyShowIntroProducts: false,
        isShowHistory: false,
        includeNbOfStores: false,
        includeAllStatuses: false,
    }
    @track sortField = '';
    @track sortDirection = 'DESC';
    @track isSortASC = false;
    @track loading = false;
    @track pageSize = 25;
    @track pageNumber = 1;
    @track assortmentLongName = '';
    @track productLifeStatusValues = [];
    @track AssortmentDetailObject = AssortmentDetail__c;
    @track globalSearchPlaceholder = '';
    asdFieldsType = null;
    asdFieldsCalculationMap = null;
    executionFormulaFieldOrder = [];
    formulasMetadata = null;
    asdFullDataMap = null;
    categoryBUClustersMap = {};
    categoryBUCpltMap = {};
    @track ASDFields = [];
    @track ASDFieldsType = {};
    @track nbOfFixedColumns = 2;
    @track availableImportFields = [];
    @track processing = false;
    @track processedItems = 0;
    @track processed = 0;
    @track off = 0;
    @track totalSize = 0;
    @track logs = [];
    @track startLineNumber = '2';
    @track selectedLoadOption = '1';
    @track showAllRelatedAssortments = false;
    @track showSimulations = false;
    @track relatedAssortments = [];
    @track relatedSimulations = [];
    @track acceptedFormats = ['.xls', '.xlsx'];
    @track file;
    @track records = [];
    @track displayedFields = [];
    @track fieldOptions = [];
    @track selectedFields = [];
    @track fieldsToFilter = [];
    @track ASDToUpdateMap = {};
    @track isAlertModalOpen = false;
    @track switchProductsList = [];
    @track totalExportSize = 0;
    @track fileGenerationValue = 0;
    @track fileDownloadValue = 0;
    @track showFileGenerationBar = false;
    @track showFileDownloadBar = false;
    @track selectedPopup = '';
    @track openFlow = false;
    @track currentFlow = {
        header: '',
        flowApiName: '',
        flowVariables: '',
    }
    ASDCalculatedValuesMap = {};
    totalPagesCount = 0;
    totalRecords = 0;
    fieldsToFakesave = fieldsToFakesave;
    HLPProducts = [];
    ASDScaleMap = {};
    ValidateDisabled = false;
    isASTarget;
    isGenerateASRegional;
    isASNego;
    isASSimulation;
    logData = {};
    XL_row_object = [];
    data = {};
    batchIndex = 0;
    processMethod;
    noDataToProcess = true;
    fileContent = '';
    processUplodingFile = false;
    rendered = false;
    mainData;
    nbOfStoresField;
    categoryBUClustersMap = {};
    categoryBUCpltMap = {};
    categoryBUClustersRefMap = {};
    categoryBUCpltRefMap = {};
    subTotalsMap = {};
    totalsMap = {};
    totalsList = [];
    picklistColorsMap = {};
    clusterTotalIndexes = [];
    cpltTotalIndexes = [];
    clusterRefTotalIndexes = [];
    cpltRefTotalIndexes = [];
    selectedProducts = [];
    popupLoading = false;
    fieldsToFilterMap = {};
    initialHLPProducts = [];
    detailList = [];
    excelDetailList = [];
    sortFieldApi = '';
    prefix;
    //EXCEL
    allRecordsToExport;
    rowCounter = 0;
    createSimulationFromTargetVariables;
    validateTargetAndGenSimulVariables;
    validateTargetAndGenNegoVariables;
    createSimulationFromNegoVariables;
    createSimulationN1FromNegoVariables;
    createSimulationFromSimulationVariables;
    validateSimulAndGenNegoVariables;
    synchroRelatedAssortmentsVariables;
    API_SCREEN_Assortment_Create_Simulation_from_target_Simulation;
    API_SCREEN_Assortment_Validate_my_Target;
    API_SCREEN_Assortment_Validate_Simulation_and_Generate_Nego_N_1_Validated;
    API_Synchro_Related_Assortments;
    //EMAIL Variables
    isEmailPopup = false;
    targetAddress = '';
    cc = '';
    bcc = '';
    subject = '';
    name = '';
    body = '';
    // WIRES
    @wire(getObjectInfo, { objectApiName: Product2.objectApiName }) objectInfoProduct({ error, data }) {
        if (data) {
            this.globalSearchPlaceholder = data.fields['Name'].label + ', ' + data.fields[this.PROD_API_NAMES.ProductCode].label + ', ' + data.fields[this.PROD_API_NAMES.GTIN__c].label + ', ' + data.fields[this.PROD_API_NAMES.VIP__c].label + ', ' + data.fields[this.PROD_API_NAMES.Hierarchy__c].label;
            this.labels.ProductFields.Name = data.fields['Name'].label;
            this.labels.ProductFields.ProductCode = data.fields[this.PROD_API_NAMES.ProductCode].label;
            this.labels.ProductFields.ProductGTIN = data.fields[this.PROD_API_NAMES.GTIN__c].label;
            this.labels.ProductFields.isMasterHLP = data.fields[this.PROD_API_NAMES.IsMaster_Higher_Level_Packaging__c].label;
            this.labels.ProductFields.PCB = data.fields[this.PROD_API_NAMES.PCB__c].label;
            this.labels.ProductFields.PCBElementNb = data.fields[this.PROD_API_NAMES.PCBElementNb__c].label;
        } else if (error) {
            console.log('ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: AS__OBJECT.objectApiName }) objectInfoAS({ error, data }) {
        if (data) {
            this.labels.AssortmentLabel = data.label;
        } else if (error) {
            console.log('ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: ASD__OBJECT }) objectInfoASD({ error, data }) {
        if (data) {
            for (let field of Object.values(data.fields)) {
                this.ASDScaleMap[field.apiName] = field.scale;
                if (field.updateable) {
                    this.ASDFieldsType[field.apiName] = field.dataType;
                }
            }
        } else if (error) {
            console.error(error);
        }
    }
    yearToNbOfStoresFieldMap = {
        '0': this.BU_API_NAMES.SiteOfSalesNumber__c,
        '1': this.BU_API_NAMES.SiteOfSalesNumberN1__c,
        '-1': this.BU_API_NAMES.SiteOfSalesNumberP1__c,
        '-2': this.BU_API_NAMES.SiteOfSalesNumberP2__c,
    }
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }
    get colspan() {
        return this.displayedFields.length + 1;
    }
    get fileGenerationLabel() {
        return this.labels.LBL_File_Generation.replace('{0}', this.msgRowCounter).replace('{1}', this.totalExportSize);
    }
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.totalRecords ? this.pageNumber * pageSize + 1 - pageSize : this.totalRecords - this.records.length) + '-' + (this.pageNumber * pageSize > this.totalRecords ? this.totalRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalRecords;
    }
    get flowActions() {
        return (this.mainData
            && this.mainData.gridSettingsManager
            && this.mainData.gridSettingsManager.actions
            && this.mainData.gridSettingsManager.actions.screenFlows) || [];
    }

    get iconFlows() {
        return this.flowActions.filter(f => f.value && f.displayType && f.displayType === 'Icon');
    }

    get buttonFlows() {
        return this.flowActions.filter(f => f.value && f.displayType && f.displayType === 'Button');
    }

    get actionFlows() {
        return this.flowActions.filter(f => f.value && f.displayType && f.displayType === 'Action');
    }

    get showSynchroRelatedAssortments() {
        return this.isASNego && this.mainData && this.mainData.hasLinkedAssortments;
    }

    connectedCallback() {
        loadScript(this, xlsxLib + '/js-xlsx-master/dist/jszip.js').then(() => {
            loadScript(this, xlsxLib + '/js-xlsx-master/dist/xlsx.js').then(() => {
                console.log('loaded')
            }).catch(error => {
                console.log(error.message);
                console.log(error.body?.message);
            });
        }).catch(error => {
            console.log(error.message);
            console.log(error.body?.message);
        });
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
            loadScript(this, ExcelJSURL),
            loadScript(this, formulonLibUrl + '/decimal.js')
        ]).then(() => {
            loadScript(this, formulonLibUrl + '/formulon.min.js').then(() => {
                this.createSimulationFromTargetVariables = [{ name: 'recordId', type: 'String', value: this.recordId }];
                this.validateTargetAndGenSimulVariables = [{ name: 'recordId', type: 'String', value: this.recordId }, { name: 'ValidateTargetWithSimul', type: 'Boolean', value: true }];
                this.validateTargetAndGenNegoVariables = [{ name: 'recordId', type: 'String', value: this.recordId }, { name: 'ValidateTargetWithValidateNego', type: 'Boolean', value: true }];
                this.createSimulationFromNegoVariables = [{ name: 'recordId', type: 'String', value: this.recordId }, { name: 'validateCurrentAss', type: 'Boolean', value: true }];
                this.createSimulationN1FromNegoVariables = [{ name: 'recordId', type: 'String', value: this.recordId }, { name: 'validateCurrentAss', type: 'Boolean', value: true }, { name: 'isCreateSimulationN1', type: 'Boolean', value: true }];
                this.createSimulationFromSimulationVariables = [{ name: 'recordId', type: 'String', value: this.recordId }];
                this.validateSimulAndGenNegoVariables = [{ name: 'recordId', type: 'String', value: this.recordId }];
                this.synchroRelatedAssortmentsVariables = [{ name: 'recordId', type: 'String', value: this.recordId }];
                this.initData();
            }).catch(error => {
                console.log(error.message);
            });
        }).catch(error => {
            console.log('error loading style, Script >> ' + error)
        });

        window.addEventListener('resize', this.changeHeight);
        let self = this;
        window.addEventListener('closelinkcontractpopup', function (event) {
            self.toggleAttachContract();
        });
        window.addEventListener('closeSynchroASRegionpopup', function (event) {
            self.popups.synchroASRegion = !self.popups.synchroASRegion
        });
    }
    renderedCallback() {
        this.setnumberOfFixedColumns();
        let header = this.template.querySelector('.header');
        let body = this.template.querySelector('.main-panel');
        let footerDiv = this.template.querySelector('.footerDiv');
        if (!this.rendered && header && body && footerDiv) {
            this.setTableDimension();
            this.rendered = true;
        }
    }
    handleChangeColumnNumber(event) {
        let value = event.target.value;
        let index = event.target.dataset.index;
        this.availableImportFields[index].columnNumber = value;
    }
    handleChangeLoadOption(event) {
        let value = event.target.value;
        this.selectedLoadOption = value;
        this.showSimulations = this.selectedLoadOption == '2';
        this.showAllRelatedAssortments = this.selectedLoadOption == '3';
    }
    importExcel(event) {
        let eanField = this.availableImportFields.filter(item => item.fieldName == this.ASD_API_NAMES.ProductGTIN__c);
        let columns = this.availableImportFields.filter(item => item.columnNumber != null && item.columnNumber != '');
        if (eanField && (/*!eanField.columnNumber || */eanField.columnNumber == '')) {
            showNotification(this, this.labels.LBL_Error, this.labels.MSG_Define_GTIN_before_Load, 'error', 'sticky');
            return;
        } else if (columns.length <= 1) {
            showNotification(this, this.labels.LBL_Error, 'You have no data defining for download', 'error', 'sticky');
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
                if (Object.keys(workbook.Sheets).length > 0) {
                    let sheetName = Object.keys(workbook.Sheets)[0];
                    self.XL_row_object = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], {
                        header: 1,
                        defval: '',
                        raw: true
                    });
                    let skip = parseInt(self.startLineNumber, 10) - 1;
                    if (skip > 0) {
                        self.XL_row_object = self.XL_row_object.slice(skip);
                    }
                    self.totalSize = self.XL_row_object.length;
                    self.off = Math.ceil(self.totalSize / 10000) || 1;
                    self.processed = 0;
                    self.processedItems = 0;
                }
            } catch (err) {
                console.error(err);
            }
        };
        fileReader.readAsBinaryString(self.file);
    }
    handleUpload(assortmentIds) {
        if (this.fileContent) {
            uploadFile({
                fileName: this.file.name,
                base64Data: this.fileContent,
                fileType: this.file.type,
                assortmentIds: assortmentIds,
            }).then(() => {
                showNotification(this, this.labels.LBL_Success, 'File uploaded successfully', 'success', 'sticky')
                this.resetImportFile();
            }).catch(error => {
                showNotification(this, this.labels.LBL_Error, error.body.message, 'error', 'sticky')
            });
        }
    }

    resetImportFile() {
        this.file = null;
        this.fileContent = '';
        this.XL_row_object = [];
        this.noDataToProcess = true;
        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) {
            fileInput.value = null;
        }
    }

    handleChangeStartLineNumber(event) {
        this.startLineNumber = event.target.value;
    }
    processUploading() {
        let assortmentIds = [];
        let assortmentExtIds = [];
        assortmentIds.push(this.recordId);
        assortmentExtIds.push(this.mainData.currentAssortment[this.AS_API_NAMES.ExtId__c]);
        if (this.showSimulations && this.relatedSimulations && this.relatedSimulations.length) {
            this.relatedSimulations.forEach(item => {
                assortmentExtIds.push(item[this.AS_API_NAMES.ExtId__c]);
                assortmentIds.push(item.Id);
            });
        } else if (this.showAllRelatedAssortments && this.relatedAssortments && this.relatedAssortments.length) {
            this.relatedAssortments.forEach(item => {
                assortmentExtIds.push(item[this.AS_API_NAMES.ExtId__c]);
                assortmentIds.push(item.Id);
            });
        }
        let columnsMap = {};
        this.availableImportFields.filter(item => item.columnNumber != null && item.columnNumber != '')?.forEach(item => {
            columnsMap[item.columnNumber] = item.fieldName;
        });
        let self = this;
        self.processing = true;
        self.processUplodingFile = true;
        let data = self.data;
        let XL_row_object = self.XL_row_object;
        console.log('XL_row_object >>> ' + JSON.stringify(XL_row_object))
        if (XL_row_object && XL_row_object.length) {
            let row = XL_row_object.shift();
            let fieldValues = [];
            let eanKey;
            for (let columnNumber of Object.keys(columnsMap)) {
                let fieldName = columnsMap[columnNumber];
                let val = row[Number(columnNumber) - 1] ?? null;
        console.log('val11 >>> ' + val)
                if (typeof val === 'string') val = val.trim();
                if (val === '' || val === null || val === undefined) {
                    fieldValues.push({ fieldName, fieldValue: null });
                    continue;
                }
                //raw:true can make it a number
                if (fieldName == this.ASD_API_NAMES.ProductGTIN__c) {
                    val = String(val).trim();
                    eanKey = val;
                    fieldValues.push({ fieldName, fieldValue: val });
                    continue;
                }
                let fieldType = this.ASDFieldsType[fieldName];
                if (fieldType && val != null) {
                    if (fieldType == 'Currency' || fieldType == 'Percent' || fieldType == 'Double' || fieldType == 'Integer' || fieldType == 'Long') {
                        val = self.extractNumber(String(val));
                    } else if (fieldType == 'Picklist') {
                        let picklistMap = this.mainData.gridSettingsManager.picklistValuesMap?.[fieldName] || {};
                        for (let value of Object.keys(picklistMap)) {
                            if (val == picklistMap[value] || val == value) { val = value; break; }
                        }
                    } else if (fieldType == 'Multipicklist') {
                        let picklistMap = this.mainData.gridSettingsManager.picklistValuesMap?.[fieldName] || {};
                        val = String(val).split(';').map(item => {
                            item = item.trim();
                            for (let value of Object.keys(picklistMap)) {
                                if (item == picklistMap[value] || item == value) return value;
                            }
                            return item;
                        }).join(';');
                    } else if (fieldType == 'Date') {
                        let currentDate = this.excelDateToJSDate(val);
                        val = currentDate.getFullYear() + '-' + (currentDate.getMonth() + 1) + '-' + currentDate.getDate();
                        console.log('val>>> ' + val);
                    }
                }
                fieldValues.push({ fieldName, fieldValue: val });
            }
            data[eanKey] = fieldValues;
            self.processedItems++;
            self.updateProcessed(self.processedItems * 100 / self.totalSize);
        }
        if (Object.keys(data).length >= 10000 || !XL_row_object.length) {
            if (data && Object.keys(data).length) {
                this.data = {};
                this.batchIndex++;
                let batchIndex = this.batchIndex + '/' + this.off;
                importAssortmentDetails({ batchIndex: batchIndex, dataJson: JSON.stringify(data), assortmentExtIdsJson: JSON.stringify(assortmentExtIds) }).then(batchId => {
                    if (batchId != null) {
                        checkCompletedBatches(this, batchId, false).then(result => {
                            this.processing = false;
                        }).catch(error => {
                            console.error(error);
                        });
                    } else {
                        this.processing = false;
                    }
                }).catch(error => {
                    console.log(`🚀 error`, error);
                    console.log(`🚀 error`, error);
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
            var reader = new FileReader();
            reader.onload = () => {
                self.fileContent = reader.result.split(',')[1];
                self.handleUpload(assortmentIds);
            };
            reader.readAsDataURL(self.file);
        }
    }
    updateProcessed(processed) {
        this.processed = processed;
    }
    extractNumber = (val) => {
        return Number(val.replace(/[^0-9\.]+/g, ''));
    }
    excelDateToJSDate(excelDate) {
        const baseDate = new Date(Date.UTC(1899, 11, 30)); // Excel base date
        return new Date(baseDate.getTime() + excelDate * 24 * 60 * 60 * 1000);
    }
    changeHeight = () => this.setTableDimension();
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
            pageBody.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - pageFooter.offsetHeight - 10 + 'px';
        }
    }
    initData() {
        this.loading = true;
        this.categoryBUClustersMap = {};
        this.categoryBUCpltMap = {};
        this.categoryBUClustersRefMap = {};
        this.categoryBUCpltRefMap = {};
        this.fieldOptions = [];
        this.selectedFields = [];
        this.totalsList = [];
        this.displayedFields = [];
        this.clusterTotalIndexes = [];
        this.cpltTotalIndexes = [];
        this.clusterRefTotalIndexes = [];
        this.cpltRefTotalIndexes = [];
        this.availableImportFields = [];
        this.relatedAssortments = [];
        this.relatedSimulations = [];
        initData({ assortmentId: this.recordId, gridLayout: this.gridLayout }).then((result) => {
            this.mainData = JSON.parse(result);
            this.prefix = this.mainData.prefix || '';
            this.API_SCREEN_Assortment_Create_Simulation_from_target_Simulation = this.prefix + 'SCREEN_Assortment_Create_Simulation_from_target_Simulation';
            this.API_SCREEN_Assortment_Validate_my_Target = this.prefix + 'SCREEN_Assortment_Validate_my_Target';
            this.API_SCREEN_Assortment_Validate_Simulation_and_Generate_Nego_N_1_Validated = this.prefix + 'SCREEN_Assortment_Validate_Simulation_and_Generate_Nego_N_1_Validated';
            this.API_Synchro_Related_Assortments = this.prefix + 'Synchro_Related_Assortments';
            // check the local Storage
            let selectedFields;
            if (localStorage.getItem('AssortmentMatrix' + this.mainData.currentAssortment.RecordType.DeveloperName) != null) {
                selectedFields = JSON.parse(localStorage.getItem('AssortmentMatrix' + this.mainData.currentAssortment.RecordType.DeveloperName));
            }
            this.hypothesisReportMap = this.mainData.hypothesisReportMap;
            this.asdFieldsCalculationMap = this.mainData.calculationWrapper.asdFieldsCalculationMap;
            this.formulasMetadata = this.mainData.calculationWrapper.formulasMetadata;
            let calculatedFields = [];
            this.mainData.gridSettingsManager.GRID_FIELDS.forEach(field => {
                //PUT ALL THE FIELDS RETURNED AS OPTIONS FOR SHOW/HIDE POPUP
                this.fieldOptions.push({ label: field.fieldLabel, value: field.fieldName });
                field.isShown = !selectedFields || (selectedFields && selectedFields.includes(field.fieldName));
                if (field.isShown) {
                    this.selectedFields.push(field.fieldName);
                }
                if (field.isCalculated) {
                    calculatedFields.push(field.fieldName)
                }
            });
            // for (let formulaField of this.mainData.calculationWrapper.executionFormulaFieldOrder) {
            //     if (calculatedFields.includes(formulaField)) {
            //         this.executionFormulaFieldOrder.push(formulaField);
            //     }
            // }
            this.executionFormulaFieldOrder = this.mainData.calculationWrapper.executionFormulaFieldOrder;
            this.asdFieldsType = this.mainData.calculationWrapper.asdFieldsType;
            for (let category of Object.keys(this.mainData.categoryBUClustersMap)) {
                for (let strat of this.mainData.categoryBUClustersMap[category]) {
                    let key = category + strat.clientCategory;
                    if (!this.categoryBUClustersMap.hasOwnProperty(key)) {
                        this.categoryBUClustersMap[key] = [];
                    }
                    this.categoryBUClustersMap[key].push(strat);
                }
            }
            for (let category of Object.keys(this.mainData.categoryBUCpltMap)) {
                for (let cplt of this.mainData.categoryBUCpltMap[category]) {
                    let key = category + cplt.clientCategory;
                    if (!this.categoryBUCpltMap.hasOwnProperty(key)) {
                        this.categoryBUCpltMap[key] = [];
                    }
                    this.categoryBUCpltMap[key].push(cplt);
                }
            }
            for (let category of Object.keys(this.mainData.categoryBUClustersRefMap)) {
                for (let refStrat of this.mainData.categoryBUClustersRefMap[category]) {
                    let key = category + refStrat.clientCategory;
                    if (!this.categoryBUClustersRefMap.hasOwnProperty(key)) {
                        this.categoryBUClustersRefMap[key] = [];
                    }
                    this.categoryBUClustersRefMap[key].push(refStrat);
                }
            }
            for (let category of Object.keys(this.mainData.categoryBUCpltRefMap)) {
                for (let refCplt of this.mainData.categoryBUCpltRefMap[category]) {
                    let key = category + refCplt.clientCategory;
                    if (!this.categoryBUCpltRefMap.hasOwnProperty(key)) {
                        this.categoryBUCpltRefMap[key] = [];
                    }
                    this.categoryBUCpltRefMap[key].push(refCplt);
                }
            }
            if (this.mainData && this.mainData.currentAssortment) {
                this.isASSimulation = this.mainData.currentAssortment.RecordType.DeveloperName == 'Simulation';
                this.isASNego = this.mainData.currentAssortment.RecordType.DeveloperName == 'Negotiation';
                this.isASTarget = this.mainData.currentAssortment.RecordType.DeveloperName == 'Target';
                this.isGenerateASRegional = (this.mainData.currentAssortment.RecordType.DeveloperName == 'Negotiation' || this.mainData.currentAssortment.RecordType.DeveloperName == 'Simulation') && this.mainData.currentAssortment[this.AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][this.BU_API_NAMES.SetASRegionSynchro__c];
            }
            this.buildSubtotalMap(this.mainData.subTotalWrapper.details);
            let yearDifference = this.mainData.currentAssortment[this.AS_API_NAMES.Year__c] - new Date().getFullYear();
            this.nbOfStoresField = this.yearToNbOfStoresFieldMap[yearDifference] ?? this.BU_API_NAMES.SiteOfSalesNumber__c;
            this.assortmentLongName = this.mainData.currentAssortment[this.AS_API_NAMES.LongName__c];
            this.pageSize = parseInt(this.mainData.gridSettingsManager.Default_Page_Size);
            this.pageSizeOptions.forEach(element => element.isSelected = element.value == this.pageSize);
            //this.populateFiltersMap(this.mainData.gridSettingsManager.FILTERS);
            if (this.isSendEmail) {
                this.toggleEmailModal();
            } else if (this.isExportExcel) {
                this.exportExcel();
            } else {
                this.populateFiltersMap(this.mainData.gridSettingsManager.FILTERS);
                this.loadData();
            }
            if (this.mainData.availableImportFields && this.mainData.availableImportFields.length) {
                this.mainData.availableImportFields.forEach(item => {
                    if ((item.isAdmin && this.mainData.isAdmin) || (item.isUser && !this.mainData.isAdmin)) {
                        this.availableImportFields.push({
                            fieldName: item.fieldName,
                            fieldLabel: item.fieldLabel,
                            columnNumber: item.fieldName == this.ASD_API_NAMES.ProductGTIN__c ? '1' : '',
                        });
                    }
                });
            }
            if (this.mainData.relatedAssortments) {
                this.mainData.relatedAssortments.forEach(item => {
                    this.relatedAssortments.push({
                        Id: item.Id,
                        Name: item.Name,
                        LongName__c: item[this.AS_API_NAMES.LongName__c],
                        ExtId__c: item[this.AS_API_NAMES.ExtId__c],
                    });
                });
            }
            if (this.mainData.relatedSimulations) {
                this.mainData.relatedSimulations.forEach(item => {
                    this.relatedSimulations.push({
                        Id: item.Id,
                        Name: item.Name,
                        LongName__c: item[this.AS_API_NAMES.LongName__c],
                        ExtId__c: item[this.AS_API_NAMES.ExtId__c],
                    });
                });
            }
        }).catch(error => {
            console.error(error);
            showNotification(this, 'error', error?.body?.message || error?.message || error, 'error', 'sticky');
        });
    }
    totalRecalculateFormulaFields = [];
    buildSubtotalMap(details) {
        let fieldsToSum = this.mainData.gridSettingsManager.GRID_FIELDS.filter(field => field.isNumberField || field.fieldType == 'BOOLEAN');
        var clientStatusToExclude = ['Opportunity', '', 'ProbablyDeleted'];
        let hierarchyCount = {};
        this.subTotalsMap = {}
        this.totalsMap = {}
        this.initTotalsMap = {}
        for (let detail of details) {
            let key = detail[this.ASD_API_NAMES.ClientCategory__c] || detail[this.ASD_API_NAMES.Hierarchy__c];
            if (!this.subTotalsMap.hasOwnProperty(key)) {
                this.subTotalsMap[key] = {};
                hierarchyCount[key] = 0;
            }
            hierarchyCount[key]++;
            for (let field of this.mainData.gridSettingsManager.GRID_FIELDS) {
                if (!field.showInTotal) {
                    if (!this.subTotalsMap[key].hasOwnProperty(field.fieldName)) {
                        this.subTotalsMap[key][field.fieldName] = {
                            value: null,
                            valueofAllStatus: null,
                            scale: 0,
                            class: 'categoryTd'
                        };
                    }
                    if (!this.totalsMap.hasOwnProperty(field.fieldName)) {
                        this.totalsMap[field.fieldName] = {
                            key: 'Total' + field.fieldName,
                            fieldName: field.fieldName,
                            value: null,
                            valueofAllStatus: null,
                            scale: 0,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: field.isShown,
                            class: 'categoryTd'
                        };
                    }
                } else {
                    let value;
                    if (field.fieldName.includes('.')) {
                        let values = field.fieldName.split('.');
                        for (let index = 0; index < values.length; index++) {
                            let item = index == 0 ? detail : value;
                            if (item) {
                                value = item[values[index]];
                            }
                        }
                    } else {
                        value = detail[field.fieldName] ? detail[field.fieldName] : 0;
                    }
                    if (field.fieldType == 'BOOLEAN') {
                        value = value ? 1 : 0;
                    }
                    if (!this.subTotalsMap[key].hasOwnProperty(field.fieldName)) {
                        this.subTotalsMap[key][field.fieldName] = {
                            value: 0,
                            valueofAllStatus: 0,
                            scale: field.isNumberField ? field.scale : 0,
                            class: 'categoryTd' + (field.fieldType == 'BOOLEAN' ? ' slds-text-align_center' : ' slds-text-align_right')
                        };
                    }

                    this.subTotalsMap[key][field.fieldName].valueofAllStatus += value

                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.subTotalsMap[key][field.fieldName].value += value;
                    }
                    if (!this.totalsMap.hasOwnProperty(field.fieldName)) {
                        this.totalsMap[field.fieldName] = {
                            key: 'Total' + field.fieldName,
                            fieldName: field.fieldName,
                            value: 0,
                            valueofAllStatus: 0,
                            scale: field.isNumberField ? field.scale : 0,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: field.isShown,
                            class: 'categoryTd' + (field.fieldType == 'BOOLEAN' ? ' slds-text-align_center' : ' slds-text-align_right')
                        };
                    }
                    this.totalsMap[field.fieldName].valueofAllStatus += value;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.totalsMap[field.fieldName].value += value;
                    }
                }
            }
            if (detail[this.ASD_API_NAMES.ProductCluster__c] != null) {
                let selectedStratValues = detail[this.ASD_API_NAMES.ProductCluster__c] ? JSON.parse(detail[this.ASD_API_NAMES.ProductCluster__c]).Strat?.filter(item => item.value).map(item => item.index) : [];
                let selectedCpltValues = detail[this.ASD_API_NAMES.ProductCluster__c] ? JSON.parse(detail[this.ASD_API_NAMES.ProductCluster__c]).Cplt?.filter(item => item.value).map(item => item.index) : [];
                if (!this.subTotalsMap.hasOwnProperty(key)) {
                    this.subTotalsMap[key] = {}
                }

                for (let index of selectedStratValues) {
                    let field = 'Strat' + index;
                    if (!this.subTotalsMap[key].hasOwnProperty(field)) {
                        this.subTotalsMap[key][field] = {
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            class: 'categoryTd slds-text-align_center'
                        };
                    }

                    this.subTotalsMap[key][field].valueofAllStatus++;

                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.subTotalsMap[key][field].value++;
                    }
                    if (!this.totalsMap.hasOwnProperty(field)) {
                        this.totalsMap[field] = {
                            key: 'Total' + field.fieldName,
                            fieldName: field.fieldName,
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: this.selectedFields && this.selectedFields.includes(this.ASD_API_NAMES.ProductCluster__c),
                            class: 'categoryTd slds-text-align_center'
                        };
                    }
                    this.totalsMap[field].valueofAllStatus++;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.totalsMap[field].value++;
                    }

                }
                for (let index of selectedCpltValues) {
                    let field = 'Cplt' + index;
                    if (!this.subTotalsMap[key].hasOwnProperty(field)) {
                        this.subTotalsMap[key][field] = {
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            class: 'categoryTd slds-text-align_center'
                        };
                    }
                    this.subTotalsMap[key][field].valueofAllStatus++;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.subTotalsMap[key][field].value++;
                    }
                    if (!this.totalsMap.hasOwnProperty(field)) {
                        this.totalsMap[field] = {
                            key: 'Total' + field.fieldName,
                            fieldName: field.fieldName,
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: this.selectedFields && this.selectedFields.includes(this.ASD_API_NAMES.ProductCluster__c),
                            class: 'categoryTd slds-text-align_center'
                        };
                    }
                    this.totalsMap[field].valueofAllStatus++;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.totalsMap[field].value++;
                    }
                }
            }
            if (detail[this.ASD_API_NAMES.ProductClusterASDNego__c] != null) {
                let selectedRefStratValues = detail[this.ASD_API_NAMES.ProductClusterASDNego__c] ? JSON.parse(detail[this.ASD_API_NAMES.ProductClusterASDNego__c]).Strat?.filter(item => item.value).map(item => item.index) : [];
                let selectedRefCpltValues = detail[this.ASD_API_NAMES.ProductClusterASDNego__c] ? JSON.parse(detail[this.ASD_API_NAMES.ProductClusterASDNego__c]).Cplt?.filter(item => item.value).map(item => item.index) : [];
                if (!this.subTotalsMap.hasOwnProperty(key)) {
                    this.subTotalsMap[key] = {}
                }

                for (let index of selectedRefStratValues) {
                    let field = 'RefStrat' + index;
                    if (!this.subTotalsMap[key].hasOwnProperty(field)) {
                        this.subTotalsMap[key][field] = {
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            class: 'categoryTd slds-text-align_center'
                        };
                    }

                    this.subTotalsMap[key][field].valueofAllStatus++;

                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.subTotalsMap[key][field].value++;
                    }
                    if (!this.totalsMap.hasOwnProperty(field)) {
                        this.totalsMap[field] = {
                            key: 'Total' + field.fieldName,
                            fieldName: field.fieldName,
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: this.selectedFields && this.selectedFields.includes(this.ASD_API_NAMES.ProductClusterASDNego__c),
                            class: 'categoryTd slds-text-align_center'
                        };
                    }
                    this.totalsMap[field].valueofAllStatus++;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.totalsMap[field].value++;
                    }

                }
                for (let index of selectedRefCpltValues) {
                    let field = 'RefCplt' + index;
                    if (!this.subTotalsMap[key].hasOwnProperty(field)) {
                        this.subTotalsMap[key][field] = {
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            class: 'categoryTd slds-text-align_center'
                        };
                    }
                    this.subTotalsMap[key][field].valueofAllStatus++;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.subTotalsMap[key][field].value++;
                    }
                    if (!this.totalsMap.hasOwnProperty(field)) {
                        this.totalsMap[field] = {
                            key: 'Total' + field.fieldName,
                            fieldName: field.fieldName,
                            value: 0,
                            valueofAllStatus: 0,
                            scale: 0,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: this.selectedFields && this.selectedFields.includes(this.ASD_API_NAMES.ProductClusterASDNego__c),
                            class: 'categoryTd slds-text-align_center'
                        };
                    }
                    this.totalsMap[field].valueofAllStatus++;
                    if (!clientStatusToExclude.includes(detail[this.ASD_API_NAMES.ProductLifeStatusAss__c])) {
                        this.totalsMap[field].value++;
                    }
                }
            }
        }
        for (let field of this.mainData.gridSettingsManager.GRID_FIELDS) {
            if (field.showInTotal && field.totalType == 'AVG') {
                if (!field.isCalculated) {
                    Object.keys(this.subTotalsMap).forEach(hierarchy => {
                        this.subTotalsMap[hierarchy][field.fieldName].value = this.subTotalsMap[hierarchy][field.fieldName].value / hierarchyCount[hierarchy];
                        this.subTotalsMap[hierarchy][field.fieldName].valueofAllStatus = this.subTotalsMap[hierarchy][field.fieldName].valueofAllStatus / hierarchyCount[hierarchy];
                    })
                    this.totalsMap[field.fieldName].value = this.totalsMap[field.fieldName].value / Object.values(hierarchyCount).reduce((a, b) => a + b, 0);
                    this.totalsMap[field.fieldName].valueofAllStatus = this.totalsMap[field.fieldName].valueofAllStatus / Object.values(hierarchyCount).reduce((a, b) => a + b, 0);
                }
                if (field.isCalculated) {
                    this.totalRecalculateFormulaFields.push(field.fieldName);
                }
            }
        }
        this.mainData.subTotalWrapper.details = [];
        recalculateTotalFormulaFields(this.totalsMap, this, false);
        recalculateTotalFormulaFields(this.totalsMap, this, false);
        this.initTotalsMap = JSON.parse(JSON.stringify(this.totalsMap))
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
    loadData() {
        this.loading = true;
        loadData({
            currentAssortmentJSON: JSON.stringify(this.mainData.currentAssortment),
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
            filtersJSON: JSON.stringify(this.filters),
            sortField: this.sortField,
            includeAllStatuses: this.filters.includeAllStatuses
        }).then((result) => {
            try {
                let parsedresult = JSON.parse(result);
                this.totalRecords = parsedresult.totalSize;
                this.totalPagesCount = Math.ceil((parsedresult.totalSize / this.pageSize));
                this.records = this.buildData(parsedresult.assortmentDetails);
                for (let categIndex = 0; categIndex < this.records.length; categIndex++) {
                    recalculateSubTotalFormulaFields(this.subTotalsMap, this, true, categIndex);
                    recalculateSubTotalFormulaFields(this.subTotalsMap, this, false, categIndex);
                }
                this.loading = false;
            } catch (error) {
                console.log('%c' + error.message, 'color : red');
                showNotification(this, '', error.message, 'error');
            }
        }).catch(error => {
            console.log('error: ' + error?.body?.message || error?.message || error)
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.loading = false;
        });
    }
    buildData(asdList) {
        console.log("TEST_TEST buildData", JSON.stringify(asdList))
        let asdMap = {};
        let categoryWMap = {};
        let productLifeStatusField = this.mainData.gridSettingsManager.GRID_FIELDS.filter(item => item.fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c);
        if (productLifeStatusField.length > 0) {
            this.picklistColorsMap = productLifeStatusField[0].picklistColorsMap;
            if (this.productLifeStatusValues.length == 0) {
                for (let item of productLifeStatusField[0].pickListValues) {
                    this.productLifeStatusValues.push({ value: item.value, label: item.label, bgColor: (this.picklistColorsMap ? this.picklistColorsMap[item.value] : 'white;'), style: 'background-color:' + (this.picklistColorsMap ? this.picklistColorsMap[item.value] : 'white') + ';' })
                }
                this.productLifeStatusValues.unshift({ value: 'BLANK', label: this.labels.Blank, bgColor: 'white', style: 'background-color:white;' })
            }
        }
        let categoryIndex = 0;
        for (let item of asdList) {
            if (this.ASDCalculatedValuesMap.hasOwnProperty(item.detail.Id)) {
                Object.assign(item.detail, this.ASDCalculatedValuesMap[item.detail.Id]);
            }
            let key = item.detail[this.ASD_API_NAMES.ClientCategory__c] || item.detail[this.ASD_API_NAMES.Hierarchy__c];
            let categW = {
                hierarchyId: item.detail[this.ASD_API_NAMES.Hierarchy__c],
                categoryId: key,
                categoryIndex: categoryIndex,
                key: key + '' + categoryIndex,
                categoryName: item.detail[this.ASD_API_NAMES.ClientCategory__c] || item.detail[this.ASD_API_NAMES.Hierarchy__c.replace('__c', '__r')].Name,
                link: item.detail[this.ASD_API_NAMES.ClientCategory__c] ? '' : '/' + item.detail[this.ASD_API_NAMES.Hierarchy__c],
                asdList: [],
                rowspan: 1,
                subTotalList: []
            }
            if (!categoryWMap.hasOwnProperty(key)) {
                //BUILD DISPLAYED FIELDS
                // exist in boucle for of asdList => In Case that a new product is added to the assortment that didn't previously have an ASD, the Strat header should be rebuilt accordingly.
                if (this.displayedFields.length == 0) {
                    for (let field of this.mainData.gridSettingsManager.GRID_FIELDS) {
                        let emptyTotal = {
                            key: 'Total' + field.fieldName,
                            value: 0,
                            valueofAllStatus: null,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: field.isShown,
                            class: 'categoryTd' + ((field.fieldType == 'BOOLEAN' || field.fieldName == this.ASD_API_NAMES.ProductCluster__c || field.fieldName == this.ASD_API_NAMES.ProductClusterASDNego__c) ? ' slds-text-align_center' : ' slds-text-align_right')
                        };
                        if (field.fieldName != this.ASD_API_NAMES.ProductCluster__c && field.fieldName != this.ASD_API_NAMES.ProductClusterASDNego__c) {
                            this.displayedFields.push({
                                fieldName: field.fieldName,
                                fieldLabel: field.fieldLabel.toUpperCase(),
                                helpText: field.helpText,
                                hasHelpText: field.hasHelpText,
                                isShown: field.isShown,
                                isNumberField: field.isNumberField,
                                isSortable: field.isSortable,
                                isReference: field.fieldType == 'REFERENCE',
                                isBoolean: field.fieldType == 'BOOLEAN',
                                sortedField: false,
                                scale: field.scale,
                                style: field.widthStyle + (field.headerStyle ? field.headerStyle.style : ''),
                                width: field.nonConditional && field.nonConditional.width ? field.nonConditional?.width.replace('px', '') / 4 : field.fieldLabel.toUpperCase().length * 2,
                                bgColor: field.bgColor.replace('#', '')
                            })
                            this.totalsList.push(this.totalsMap.hasOwnProperty(field.fieldName) ? this.totalsMap[field.fieldName] : emptyTotal);
                        } else if (field.fieldName == this.ASD_API_NAMES.ProductCluster__c) {
                            for (let key of Object.keys(this.mainData.categoryBUClustersMap)) {
                                for (let strat of this.mainData.categoryBUClustersMap[key]) {
                                    if (this.displayedFields.filter(field => field.fieldName == 'Strat' + strat.index)?.length == 0) {
                                        this.clusterTotalIndexes.push(strat.index);
                                        this.displayedFields.push({
                                            isStrat: true,
                                            isShown: field.isShown,
                                            fieldName: 'Strat' + strat.index,
                                            fieldLabel: strat.cluster.Name.toUpperCase(),
                                            isNumberField: field.isNumberField,
                                            style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''),
                                            width: '15', bgColor: field.bgColor.replace('#', '')
                                        })

                                        if (!this.totalsMap.hasOwnProperty('Strat' + strat.index)) {
                                            this.totalsMap['Strat' + strat.index] = emptyTotal;
                                            this.initTotalsMap['Strat' + strat.index] = { value: 0, valueofAllStatus: 0, scale: 0 };
                                        }
                                        this.totalsList.push(this.totalsMap.hasOwnProperty('Strat' + strat.index) ? this.totalsMap['Strat' + strat.index] : emptyTotal);
                                    }
                                }
                            }
                            for (let key of Object.keys(this.mainData.categoryBUCpltMap)) {
                                for (let cplt of this.mainData.categoryBUCpltMap[key]) {
                                    if (this.displayedFields.filter(field => field.fieldName == 'Cplt' + cplt.index)?.length == 0) {
                                        this.cpltTotalIndexes.push(cplt.index);
                                        this.displayedFields.push({
                                            isShown: field.isShown, isCplt: true, fieldName: 'Cplt' + cplt.index, fieldLabel: cplt.cluster.Name.toUpperCase(), isNumberField: field.isNumberField, style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''), width: '15', bgColor: field.bgColor.replace('#', '')
                                        })

                                        if (!this.totalsMap.hasOwnProperty('Cplt' + cplt.index)) {
                                            this.totalsMap['Cplt' + cplt.index] = emptyTotal;
                                            this.initTotalsMap['Cplt' + cplt.index] = { value: 0, valueofAllStatus: 0, scale: 0 };
                                        }
                                        this.totalsList.push(this.totalsMap.hasOwnProperty('Cplt' + cplt.index) ? this.totalsMap['Cplt' + cplt.index] : emptyTotal);
                                    }
                                }
                            }
                        } else if (field.fieldName == this.ASD_API_NAMES.ProductClusterASDNego__c && this.mainData.currentAssortment[this.AS_API_NAMES.AssortmentNegotiationRef__c] != null) {
                            for (let key of Object.keys(this.mainData.categoryBUClustersRefMap)) {
                                for (let strat of this.mainData.categoryBUClustersRefMap[key]) {
                                    if (this.displayedFields.filter(field => field.fieldName == 'RefStrat' + strat.index)?.length == 0) {
                                        this.clusterRefTotalIndexes.push(strat.index);
                                        this.displayedFields.push({
                                            isStrat: true,
                                            fieldName: 'RefStrat' + strat.index,
                                            fieldLabel: strat.cluster.Name.toUpperCase(),
                                            isShown: field.isShown,
                                            isNumberField: field.isNumberField,
                                            style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''),
                                            width: '15', bgColor: field.bgColor.replace('#', '')
                                        })
                                        this.totalsList.push(this.totalsMap.hasOwnProperty('RefStrat' + strat.index) ? this.totalsMap['RefStrat' + strat.index] : emptyTotal);
                                    }
                                }
                            }
                            for (let key of Object.keys(this.mainData.categoryBUCpltRefMap)) {
                                for (let cplt of this.mainData.categoryBUCpltRefMap[key]) {
                                    if (this.displayedFields.filter(field => field.fieldName == 'RefCplt' + cplt.index)?.length == 0) {
                                        this.cpltRefTotalIndexes.push(cplt.index);
                                        this.displayedFields.push({
                                            isCplt: true,
                                            fieldName: 'RefCplt' + cplt.index,
                                            fieldLabel: cplt.cluster.Name.toUpperCase(),
                                            isNumberField: field.isNumberField,
                                            isShown: field.isShown,
                                            style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''),
                                            width: '15',
                                            bgColor: field.bgColor.replace('#', '')
                                        })
                                        this.totalsList.push(this.totalsMap.hasOwnProperty('RefCplt' + cplt.index) ? this.totalsMap['RefCplt' + cplt.index] : emptyTotal);
                                    }
                                }
                            }
                        }
                    }
                }
                categW.subTotalList = this.getSubTotalList(item.detail[this.ASD_API_NAMES.Hierarchy__c], key);
                categoryWMap[key] = categW;
                categoryIndex++;
            }
            categW = categoryWMap[key];
            categW.asdList.push(this.buildRowData(item.detail, productLifeStatusField[0], item.historyList));
            categW.rowspan += 1;
            if (this.filters.isShowHistory) {
                categW.rowspan += item.historyList.length;
            }
            categoryWMap[key] = categW;
            asdMap[item.detail.Id] = item.detail;
        }
        this.asdFullDataMap = asdMap;
        console.log("TEST_TEST categoryWMap", JSON.stringify(categoryWMap))
        return Object.values(categoryWMap);
    }
    isDisabled(option, initialValue, currentValue, hasLastHistory, isValidDetail) {
        initialValue = initialValue == undefined || initialValue == null ? '' : initialValue;
        currentValue = currentValue == undefined || currentValue == null ? '' : currentValue;
        if (initialValue != currentValue) {
            if (option == initialValue || option == currentValue)
                return false;
            return true;
        }
        if (currentValue == option) {
            return false;
        }
        switch (initialValue) {
            case '':
                if (option == 'Opportunity') {
                    return false;
                }
                break;
            case 'Increase':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Decrease':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'New':
                if (option == 'Opportunity' || (option == '' && !hasLastHistory && !isValidDetail)) {
                    return false;
                }
                break;
            case 'Keep':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Delist':
                if (option == 'New') {
                    return false;
                }
                break;
            case 'Opportunity':
                if (option == 'Keep' || option == 'ProbablyDeleted' || option == 'Delist' || ((!hasLastHistory || isValidDetail) && option == 'New')) {
                    return false;
                }
                break;
            case 'ProbablyDeleted':
                if (option == 'Keep' || option == 'Delist') {
                    return false;
                }
                break;
        }
        return true;
    }
    getSubTotalList(categoryId, key) {
        try {
            //GET NB OF STORES FOR EACH CLUSTER
            let clusterToStores = {};
            if (this.filters.includeNbOfStores) {
                if (this.mainData.categoryBUClustersMap && this.mainData.categoryBUClustersMap.hasOwnProperty(categoryId)) {
                    for (let strat of this.mainData.categoryBUClustersMap[categoryId]) {
                        if (categoryId == key || strat.clientCategory == key) {
                            clusterToStores['Strat' + strat.index] = strat.cluster[this.nbOfStoresField];
                        }
                    }
                }
                if (this.mainData.categoryBUCpltMap && this.mainData.categoryBUCpltMap.hasOwnProperty(categoryId)) {
                    for (let cplt of this.mainData.categoryBUCpltMap[categoryId]) {
                        if (categoryId == key || cplt.clientCategory == key) {
                            clusterToStores['Cplt' + cplt.index] = cplt.cluster[this.nbOfStoresField];
                        }
                    }
                }
                if (this.mainData.categoryBUClustersRefMap && this.mainData.categoryBUClustersRefMap.hasOwnProperty(categoryId)) {
                    for (let strat of this.mainData.categoryBUClustersRefMap[categoryId]) {
                        if (categoryId == key || cplt.clientCategory == key) {
                            clusterToStores['RefStrat' + strat.index] = strat.cluster[this.nbOfStoresField];
                        }
                    }
                }
                if (this.mainData.categoryBUCpltRefMap && this.mainData.categoryBUCpltRefMap.hasOwnProperty(categoryId)) {
                    for (let cplt of this.mainData.categoryBUCpltRefMap[categoryId]) {
                        if (categoryId == key || cplt.clientCategory == key) {
                            clusterToStores['RefCplt' + cplt.index] = cplt.cluster[this.nbOfStoresField];
                        }
                    }
                }
                console.log('clusterToStores >>> ' + JSON.stringify(clusterToStores))
            }
            let subTotalList = [];
            let categoryTotals = this.subTotalsMap[key];
            for (let field of this.displayedFields) {
                if (field.isStrat || field.isCplt) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        key: 'SubTotal ' + key + '' + field.fieldName,
                        isShown: field.isShown,
                        scale: 0,
                        value: 0,
                        class: 'categoryTd slds-text-align_center'
                    }
                    if (this.subTotalsMap && this.subTotalsMap.hasOwnProperty(key) && categoryTotals.hasOwnProperty(field.fieldName)) {
                        fieldWrapper.value = (this.filters.includeAllStatuses ? categoryTotals[field.fieldName].valueofAllStatus : categoryTotals[field.fieldName].value);
                        if (this.filters.includeNbOfStores && clusterToStores.hasOwnProperty(field.fieldName)) {
                            fieldWrapper.value *= clusterToStores[field.fieldName];
                        }
                    } else {
                        fieldWrapper.value = 0
                    }
                    subTotalList.push(fieldWrapper)
                } else {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        key: 'SubTotal ' + key + '' + field.fieldName,
                        scale: field.scale,
                        isShown: field.isShown,
                        value: null,
                        class: categoryTotals && categoryTotals.hasOwnProperty(field.fieldName) ? categoryTotals[field.fieldName].class : 'categoryTd'
                    }
                    if (this.subTotalsMap.hasOwnProperty(key) && categoryTotals.hasOwnProperty(field.fieldName)) {
                        fieldWrapper.value = this.filters.includeAllStatuses ? categoryTotals[field.fieldName].valueofAllStatus : categoryTotals[field.fieldName].value;
                    } else if (field.isNumberField || field.isBoolean) {
                        fieldWrapper.value = 0
                    }
                    subTotalList.push(fieldWrapper)
                }
            }
            return subTotalList;
        } catch (error) {
            console.log('getSubTotalList')
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    buildRowData(asd, productLifeStatusField, historyList) {
        let asdW = {
            Id: asd.Id,
            productId: asd[this.ASD_API_NAMES.Product__c],
            startDate: asd[this.ASD_API_NAMES.StartDate__c],
            lastValidProductLifeStatus: '',
            isNegoN1: !asd[this.ASD_API_NAMES.AssortmentDetailLHistory__c] && asd[this.ASD_API_NAMES.AssortmentDetailNegotiationRef__c],
            lastValidStratIndex: '',
            lastValidStratCount: 0,
            hasHistory: asd[this.ASD_API_NAMES.AssortmentDetailLHistory__c] != null || asd[this.ASD_API_NAMES.AssortmentDetailNegotiationRef__c] != null,
            isValid: asd[this.ASD_API_NAMES.Status__c] == 'Validate',
            initialClientStatus: asd[this.ASD_API_NAMES.ProductLifeStatusAss__c],
            initialClusters: asd[this.ASD_API_NAMES.ProductCluster__c],
            values: [],
            historyList: [],
        }
        if (asd[this.ASD_API_NAMES.Status__c] == 'Validate') {
            asdW.lastValidProductLifeStatus = asd[this.ASD_API_NAMES.ProductLifeStatusAss__c];
            asdW.lastValidStratIndex = asd[this.ASD_API_NAMES.BusinessUnitCluster__c] ? parseInt(asd[this.ASD_API_NAMES.BusinessUnitCluster__c.replace('__c', '__r')][this.BU_API_NAMES.AssortmentStrat__c].replace('Strat', '').replace('Cplt', '')) : null;
        } else {
            let lastHistory = asd[this.ASD_API_NAMES.AssortmentDetailLHistory__c] ? asd[this.ASD_API_NAMES.AssortmentDetailLHistory__c.replace('__c', '__r')] : asd[this.ASD_API_NAMES.AssortmentDetailNegotiationRef__c.replace('__c', '__r')]
            asdW.lastValidProductLifeStatus = lastHistory ? lastHistory[this.ASD_API_NAMES.ProductLifeStatusAss__c] : null;
            asdW.lastValidStratIndex = lastHistory && lastHistory[this.ASD_API_NAMES.BusinessUnitCluster__c] ? parseInt(lastHistory[this.ASD_API_NAMES.BusinessUnitCluster__c.replace('__c', '__r')][this.BU_API_NAMES.AssortmentStrat__c]?.replace('Strat', '')?.replace('Cplt', '')) : null;
        }
        let index = 0;
        for (let field of this.mainData.gridSettingsManager.GRID_FIELDS) {
            if (field.isInputField && this.ASDToUpdateMap.hasOwnProperty(asd.Id)) {
                let obj = this.ASDToUpdateMap[asd.Id];
                if (obj.hasOwnProperty(field.fieldName)) {
                    asd[field.fieldName] = obj[field.fieldName];
                }
            }
            if (field.fieldName != this.ASD_API_NAMES.ProductCluster__c && field.fieldName != this.ASD_API_NAMES.ProductClusterASDNego__c) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    key: asd.Id + '' + field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isInputField: field.isInputField,
                    fieldType: field.fieldType,
                    isNumberField: field.isNumberField,
                    isReference: false,
                    isDate: false,
                    isPicklist: false,
                    isBoolean: false,
                    isText: false,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isShown: field.isShown,
                    style: field.style,
                    bgColor: field.bgColor ? field.bgColor.replace('#', '') : 'FFFFFF',
                    fieldValue: asd[field.fieldName],
                    picklistOptions: [],
                    scale: field.scale,
                    step: field.isInputField && field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                    linkStyle: '',
                    showInTotal: field.showInTotal,
                    isSwitch: false,
                    isStop: false,
                    isHLP: false,
                    class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[this.ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                }
                if (field.fieldName == this.ASD_API_NAMES.Product__c) {
                    fieldWrapper.divClass = 'spaceBetween';
                    if (this.mainData.productsHavingASDHLP.includes(asd[this.ASD_API_NAMES.Product__c])) {
                        fieldWrapper.HLPClass = 'HLPSelected';
                    }
                }
                if (fieldWrapper.isHTMLFormatted) {
                    fieldWrapper.class += ' slds-align--absolute-center';
                }
                if (field.fieldName.includes('.')) {
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let item = index == 0 ? asd : fieldWrapper.fieldValue;
                        if (index == values.length - 1 && field.stringFieldType == 'REFERENCE') {
                            fieldWrapper.fieldValue = item[values[index].replace('__c', '__r')].Name;
                            fieldWrapper.link = '/' + item[values[index]];
                        } else {
                            fieldWrapper.fieldValue = item[values[index]];
                        }
                    }
                }
                switch (field.fieldType) {
                    case 'REFERENCE':
                        fieldWrapper.isReference = true;
                        fieldWrapper.link = '/' + fieldWrapper.fieldValue;
                        fieldWrapper.fieldValue = asd[field.fieldName.replace('__c', '__r')]?.Name;
                        break;
                    case 'DATE':
                        fieldWrapper.isDate = true;
                        break;
                    case 'PICKLIST':
                        fieldWrapper.isPicklist = true;
                        let picklistMap = this.mainData.gridSettingsManager.picklistValuesMap?.[field.fieldName] || {};
                        for (let pickVal of Object.keys(picklistMap).map(value => ({ value: value, label: picklistMap[value] }))) {
                            if (field.fieldName != this.ASD_API_NAMES.Status__c || (field.fieldName == this.ASD_API_NAMES.Status__c && pickVal.value != 'PreviouslyValidate')) {
                                fieldWrapper.picklistOptions.push({
                                    label: pickVal.label,
                                    value: pickVal.value,
                                    key: asd.Id + '' + pickVal.value,
                                    isSelected: pickVal.value == fieldWrapper.fieldValue,
                                    isDisabled: field.fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c && this.isDisabled(pickVal.value, asd[this.ASD_API_NAMES.ProductLifeStatusAss__c], asd[this.ASD_API_NAMES.ProductLifeStatusAss__c], asdW.hasHistory, asdW.isValid)
                                })
                            }
                        }
                        fieldWrapper.picklistOptions.unshift({
                            label: this.labels.LBL_None_Picklist_Value,
                            value: '',
                            key: asd.Id + 'NULL',
                            isSelected: asd[field.fieldName] == '',
                            isDisabled: field.fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c && this.isDisabled('', asd[this.ASD_API_NAMES.ProductLifeStatusAss__c], asd[this.ASD_API_NAMES.ProductLifeStatusAss__c], asdW.hasHistory, asdW.isValid)
                        })
                        fieldWrapper.fieldOutputValue = this.mainData.gridSettingsManager.picklistValuesMap[field.fieldName][fieldWrapper.fieldValue] != null ? this.mainData.gridSettingsManager.picklistValuesMap[fieldWrapper.fieldName][fieldWrapper.fieldValue] : fieldWrapper.fieldValue;
                        break;
                    case 'BOOLEAN':
                        fieldWrapper.isBoolean = true;
                        fieldWrapper.divClass = 'slds-p-left--x-small';
                        break;
                    default:
                        fieldWrapper.isText = !fieldWrapper.isNumberField;
                }

                if (this.fieldsToColor.includes(field.fieldName)) {
                    fieldWrapper.style += 'background-color:' + (this.picklistColorsMap ? this.picklistColorsMap[asd[this.ASD_API_NAMES.ProductLifeStatusAss__c]] : 'white') + ';';
                    fieldWrapper.bgColor = (this.picklistColorsMap ? this.picklistColorsMap[asd[this.ASD_API_NAMES.ProductLifeStatusAss__c]] : '#ffffff')?.replace('#', '');
                }
                fieldWrapper.class += fieldWrapper.isNumberField ? ' slds-text-align--right' : '';
                if (!field.widthStyle) {
                    fieldWrapper.style += 'min-width: 100px; max-width: 100px; width: 100px;';
                }
                let product = asd[this.ASD_API_NAMES.Product__c.replace('__c', '__r')];
                if (product.RecordType?.DeveloperName == 'Competitor' && !this.fieldsToColor.includes(field.fieldName)) {
                    fieldWrapper.style += 'background: #FFF7E8;';
                }
                if (field.fieldName == this.ASD_API_NAMES.Product__c) {
                    if (product[this.PROD_API_NAMES.Market_Introduction_Date__c]) {
                        if ((product[this.PROD_API_NAMES.IsInnovation__c] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[this.PROD_API_NAMES.Market_Introduction_Date__c]).getFullYear()) < this.mainData.currentAssortment[this.AS_API_NAMES.Year__c])) {
                            fieldWrapper.linkStyle = 'color:' + this.mainData.INNO_INTRO_DATE_LESS_N + ';';
                        }
                        if ((product[this.PROD_API_NAMES.IsInnovation__c] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[this.PROD_API_NAMES.Market_Introduction_Date__c]).getFullYear()) >= this.mainData.currentAssortment[this.AS_API_NAMES.Year__c])) {
                            fieldWrapper.linkStyle = 'color:' + this.mainData.INNO_INTRO_DATE_GREATER_N + ';';
                        }
                    }
                    if (product[this.PROD_API_NAMES.Market_End_of_Life_Date__c]) {
                        if ((new Date(product[this.PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) < this.mainData.currentAssortment[this.AS_API_NAMES.Year__c]) {
                            fieldWrapper.linkStyle = 'color:' + this.mainData.STOP_DATE_LESS_N + ';';
                        }
                        if ((new Date(product[this.PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) >= this.mainData.currentAssortment[this.AS_API_NAMES.Year__c]) {
                            fieldWrapper.linkStyle = 'color:' + this.mainData.STOP_DATE_GREATER_N + ';';
                        }
                    }
                    if (product[this.PROD_API_NAMES.Product_Reference_Type__c] == 'Switch'
                        && (!product[this.PROD_API_NAMES.Market_End_of_Life_Date__c] || (new Date(product[this.PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) > this.mainData.currentAssortment[this.AS_API_NAMES.Year__c])
                        && !asd[this.ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isSwitch = true;
                    }
                    if ((product[this.PROD_API_NAMES.Market_End_of_Life_Date__c] && (new Date(product[this.PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) <= this.mainData.currentAssortment[this.AS_API_NAMES.Year__c])
                        && !asd[this.ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isStop = true;
                    }
                    if (product[this.PROD_API_NAMES.Product_Reference_Type__c] == 'Reno'
                        && (!product[this.PROD_API_NAMES.Market_End_of_Life_Date__c] || (new Date(product[this.PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) > this.mainData.currentAssortment[this.AS_API_NAMES.Year__c])
                        && !asd[this.ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isReno = true;
                    }
                    if (asd.RecordType.DeveloperName == 'Regular'
                        && this.mainData.productsHavingHLP.includes(asd[this.ASD_API_NAMES.Product__c])
                        && !asd[this.ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isHLP = true;
                    }

                }
                asdW.values.push(fieldWrapper);
            } else if (field.fieldName == this.ASD_API_NAMES.ProductCluster__c) {
                let selectedStratValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Strat?.filter(item => item.value).map(item => item.index) : [];
                let selectedCpltValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Cplt?.filter(item => item.value).map(item => item.index) : [];
                let key = asd[this.ASD_API_NAMES.Hierarchy__c] + asd[this.ASD_API_NAMES.ClientCategory__c];
                let key2 = asd[this.ASD_API_NAMES.Hierarchy__c] + null;
                let stratList = this.categoryBUClustersMap.hasOwnProperty(key) ? this.categoryBUClustersMap[key] : [];
                if (stratList.length == 0) {
                    stratList = this.categoryBUClustersMap.hasOwnProperty(key2) ? this.categoryBUClustersMap[key2] : [];
                }
                let stratIndexList = stratList.map(strat => strat.index);
                for (let index of this.clusterTotalIndexes) {
                    let strat = stratIndexList.includes(index) ? stratList[stratIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'Strat' + strat.index,
                        key: asd.Id + 'Strat' + strat.index,
                        clusterId: strat?.cluster?.Id,
                        stratIndex: strat.index,
                        stratId: strat?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedStratValues.includes(strat.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[this.ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !stratIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    fieldWrapper.style = 'background-color:' + (this.picklistColorsMap ? this.picklistColorsMap[asd[this.ASD_API_NAMES.ProductLifeStatusAss__c]] : 'white') + ';';
                    fieldWrapper.bgColor = (this.picklistColorsMap ? this.picklistColorsMap[asd[this.ASD_API_NAMES.ProductLifeStatusAss__c]] : '#ffffff')?.replace('#', '');
                    asdW.values.push(fieldWrapper);
                }
                let cpltList = this.categoryBUCpltMap.hasOwnProperty(key) ? this.categoryBUCpltMap[key] : [];
                if (cpltList.length == 0) {
                    cpltList = this.categoryBUCpltMap.hasOwnProperty(key2) ? this.categoryBUCpltMap[key2] : [];
                }
                let cpltIndexList = cpltList.map(cplt => cplt.index);
                for (let index of this.cpltTotalIndexes) {
                    let cplt = cpltIndexList.includes(index) ? cpltList[cpltIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'Cplt' + cplt.index,
                        key: asd.Id + 'Cplt' + cplt.index,
                        clusterId: cplt?.cluster?.Id,
                        stratIndex: cplt.index,
                        stratId: cplt?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedCpltValues.includes(cplt.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[this.ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !cpltIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    fieldWrapper.style = 'background-color:' + (this.picklistColorsMap ? this.picklistColorsMap[asd[this.ASD_API_NAMES.ProductLifeStatusAss__c]] : 'white') + ';';
                    fieldWrapper.bgColor = (this.picklistColorsMap ? this.picklistColorsMap[asd[this.ASD_API_NAMES.ProductLifeStatusAss__c]] : '#ffffff')?.replace('#', '');
                    asdW.values.push(fieldWrapper);
                }
                // calculate lastValidStratCount
                if (asd[this.ASD_API_NAMES.Status__c] == 'Validate') {
                    asdW.lastValidStratCount += selectedStratValues.length;
                } else {
                    let lastHistory = asd[this.ASD_API_NAMES.AssortmentDetailLHistory__c] ? asd[this.ASD_API_NAMES.AssortmentDetailLHistory__c.replace('__c', '__r')] : asd[this.ASD_API_NAMES.AssortmentDetailNegotiationRef__c.replace('__c', '__r')]
                    let selectedStratHistoValues = lastHistory && lastHistory[field.fieldName] ? JSON.parse(lastHistory[field.fieldName]).Strat?.filter(item => item.value).map(item => item.index) : [];
                    asdW.lastValidStratCount += selectedStratHistoValues.length;
                }
            } else if (field.fieldName == this.ASD_API_NAMES.ProductClusterASDNego__c && this.mainData.currentAssortment[this.AS_API_NAMES.AssortmentNegotiationRef__c] != null) {
                let selectedRefStratValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Strat?.filter(item => item.value).map(item => item.index) : [];
                let selectedRefCpltValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Cplt?.filter(item => item.value).map(item => item.index) : [];

                let key = asd[this.ASD_API_NAMES.Hierarchy__c] + asd[this.ASD_API_NAMES.ClientCategory__c];
                let key2 = asd[this.ASD_API_NAMES.Hierarchy__c] + null;
                let stratList = this.categoryBUClustersRefMap.hasOwnProperty(key) ? this.categoryBUClustersRefMap[key] : [];
                if (stratList.length == 0) {
                    stratList = this.categoryBUClustersRefMap.hasOwnProperty(key2) ? this.categoryBUClustersRefMap[key2] : [];
                }
                let stratIndexList = stratList.map(strat => strat.index);
                for (let index of this.clusterRefTotalIndexes) {
                    let strat = stratIndexList.includes(index) ? stratList[stratIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'RefStrat' + strat.index,
                        key: asd.Id + 'RefStrat' + strat.index,
                        stratIndex: strat.index,
                        stratId: strat?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedRefStratValues.includes(strat.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[this.ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !stratIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    asdW.values.push(fieldWrapper);
                }
                let cpltList = this.categoryBUCpltRefMap.hasOwnProperty(key) ? this.categoryBUCpltRefMap[key] : [];
                if (cpltList.length == 0) {
                    cpltList = this.categoryBUCpltRefMap.hasOwnProperty(key2) ? this.categoryBUCpltRefMap[key2] : [];
                }
                let cpltIndexList = cpltList.map(cplt => cplt.index);
                for (let index of this.cpltRefTotalIndexes) {
                    let cplt = cpltIndexList.includes(index) ? cpltList[cpltIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'RefCplt' + cplt.index,
                        key: asd.Id + 'RefCplt' + cplt.index,
                        stratIndex: cplt.index,
                        stratId: cplt?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedRefCpltValues.includes(cplt.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[this.ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !cpltIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    asdW.values.push(fieldWrapper);
                }
            }
            index++;
        }
        for (let history of historyList) {
            asdW.historyList.push(this.buildRowData(history, productLifeStatusField, []));
        }
        return asdW;
    }
    handleFieldEdits(event) {
        let Id = event.target.dataset.id;
        let fieldName = event.target.dataset.field;
        let categIndex = event.target.dataset.categindex;
        let rowIndex = event.target.dataset.rowindex;
        if (this.fieldsToFakesave.includes(fieldName) || Object.keys(this.asdFieldsCalculationMap).includes(fieldName)) {
            let productRow = this.template.querySelector('[data-row="' + rowIndex + '"][data-category="' + categIndex + '"]');
            productRow.classList.toggle('newLoading');
        }
        var clientStatusToExclude = ['Opportunity', 'Delist', 'ProbablyDeleted'];
        let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        value = (Array.isArray(value) ? value[0] : value) || null;
        let item = this.records[categIndex].asdList[rowIndex];
        let lastValidProductLifeStatus = item.lastValidProductLifeStatus;
        let lastValidStratIndex = item.lastValidStratIndex;
        let initialClientStatus = item.initialClientStatus;
        let initialClusters = item.initialClusters;
        let productLifeStatusField = item.values.filter(field => field.fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c);
        let currentClientStatus = productLifeStatusField ? productLifeStatusField[0].fieldValue : '';
        let timeout = this.fieldsToFakesave.includes(fieldName) ? 50 : 10;
        setTimeout(() => {
            item.values.forEach(field => {
                if (field.fieldName == fieldName) {
                    if (!this.fieldsToFakesave.includes(fieldName) && !Object.keys(this.asdFieldsCalculationMap).includes(fieldName)) {
                        field.fieldValue = value;
                    }
                    if (field.isPicklist) {
                        field.picklistOptions.forEach(pickVal => {
                            if (pickVal.value == value) {
                                pickVal.isSelected = true;
                            } else {
                                pickVal.isSelected = false;
                            }
                        })
                    }
                }
            })
            let obj;
            if (this.ASDToUpdateMap.hasOwnProperty(Id)) {
                obj = this.ASDToUpdateMap[Id];
            } else {
                obj = {
                    attributes: {
                        type: ASD__OBJECT.objectApiName,
                    },
                    Id: Id
                };
            }
            if (fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c) {
                if (this.picklistColorsMap) {
                    this.colorCells(item, value);
                }
                if (value == 'Complement') {
                    let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                    stratvalues.forEach(strat => {
                        strat.fieldValue = false;
                    })
                } else {
                    let cpltvalues = item.values.filter(field => field.fieldName.startsWith('Cplt'));
                    cpltvalues.forEach(cplt => {
                        cplt.fieldValue = false;
                    })
                    if (value == '') {
                        let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                        stratvalues.forEach(strat => {
                            strat.fieldValue = false;
                        })
                    } else if (initialClientStatus != null
                        && initialClientStatus != ''
                        && initialClientStatus != 'Blank'
                        && initialClientStatus != 'New'
                        && value == 'New'
                        && clientStatusToExclude.includes(currentClientStatus)) {
                        productLifeStatusField[0].fieldValue = initialClientStatus;
                        value = initialClientStatus;
                        alert(labels.MSG_Cannot_Select_Intro_for_Product_Referenced_in_Assortment);
                    } else if (value == 'Delist') {
                        let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                        stratvalues.forEach(strat => {
                            strat.fieldValue = false;
                        })
                    } else if (value == lastValidProductLifeStatus && lastValidProductLifeStatus != 'Delist') {
                        let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                        stratvalues.forEach(strat => {
                            strat.fieldValue = strat.stratIndex > lastValidStratIndex;
                        })
                    } else if (value == initialClientStatus && initialClientStatus != 'Delist') {
                        let selectedStratValues = initialClusters ? JSON.parse(initialClusters).Strat?.filter(item => item.value).map(item => item.index) : [];
                        let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                        stratvalues.forEach(strat => {
                            if (selectedStratValues.includes(strat.stratIndex)) {
                                strat.fieldValue = true;
                            } else {
                                strat.fieldValue = false;
                            }
                        })
                    } else if (value != 'Delist' && initialClientStatus == 'Delist') {
                        let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                        let index = 0;
                        stratvalues.forEach(strat => {
                            strat.fieldValue = index == stratvalues.length - 1;
                            index++;
                        })
                    }
                }
                let selectedStrat = {};
                let clusters = [];
                let stratValues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                stratValues.forEach(strat => {
                    clusters.push({ 'index': strat.stratIndex, 'value': strat.fieldValue, 'Id': strat.clusterId });
                })
                selectedStrat['Strat'] = clusters;
                clusters = [];
                let cpltValues = item.values.filter(field => field.fieldName.startsWith('Cplt'));
                cpltValues.forEach(cplt => {
                    clusters.push({ 'index': cplt.stratIndex, 'value': cplt.fieldValue, 'Id': cplt.clusterId });
                })
                selectedStrat['Cplt'] = clusters;
                obj[this.ASD_API_NAMES.ProductCluster__c] = JSON.stringify(selectedStrat);
                console.log('obj >>> ' + JSON.stringify(obj))
                item.values.forEach(fieldWrapper => {
                    if (fieldWrapper.fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c) {
                        fieldWrapper.picklistOptions?.forEach(option => {
                            option.isDisabled = this.isDisabled(option.value, fieldWrapper.fieldValue, value, item.hasHistory, item.isValid);
                        });
                    }
                });
            }
            obj[fieldName] = value;
            this.ASDToUpdateMap[Id] = obj;
            if (this.fieldsToFakesave.includes(fieldName) || Object.keys(this.asdFieldsCalculationMap).includes(fieldName)) {
                // let productRow = this.template.querySelector('[data-row="' + rowIndex + '"][data-category="' + categIndex + '"]');
                // productRow.classList.toggle('newLoading');
                let assortmentDetailCopy = this.asdFullDataMap[item.Id];
                assortmentDetailCopy[fieldName] = value;
                updateAsdOnClusterChange(assortmentDetailCopy, item, categIndex, rowIndex, fieldName, currentClientStatus, productLifeStatusField ? productLifeStatusField[0].fieldValue : '', this);
                this.ASDCalculatedValuesMap[item.Id] = JSON.parse(JSON.stringify(assortmentDetailCopy));
                // setTimeout(() => {
                //     productRow.classList.toggle('newLoading');
                // }, 200);
            }
        }, timeout);
    }
    colorCells(item, value) {
        let cellsToColor = item.values.filter(field => this.fieldsToColor.includes(field.fieldName) || field.fieldName.startsWith('Strat') || field.fieldName.startsWith('Cplt'))
        let style = '';
        let bgColor = '';
        if (this.picklistColorsMap && this.picklistColorsMap.hasOwnProperty(value) && this.picklistColorsMap[value] != '') {
            style += 'background-color:' + this.picklistColorsMap[value] + ';';
            bgColor = this.picklistColorsMap[value]?.replace('#', '');
        } else {
            style += 'background-color: white;';
        }
        cellsToColor.forEach(field => {
            field.style = style;
            field.bgColor = bgColor;
        })
    }
    toggleCheckboxes(event) {
        try {
            let categIndex = event.target.dataset.categindex;
            let rowIndex = event.target.dataset.rowindex;
            let productRow = this.template.querySelector('[data-row="' + rowIndex + '"][data-category="' + categIndex + '"]');
            productRow.classList.toggle('newLoading');
            let clientStatusToExclude = ['Opportunity', 'Delist', 'ProbablyDeleted'];
            let Id = event.target.dataset.id;
            let fieldName = event.target.dataset.field;
            let value = event.detail.checked;
            let item = this.records[categIndex].asdList[rowIndex];
            let lastValidProductLifeStatus = item.lastValidProductLifeStatus;
            let lastValidStratIndex = item.lastValidStratIndex;
            let lastValidStratCount = item.lastValidStratCount;
            let initialClientStatus = item.initialClientStatus;
            let productLifeStatusField = item.values.filter(field => field.fieldName == this.ASD_API_NAMES.ProductLifeStatusAss__c);
            let currentClientStatus = productLifeStatusField ? (productLifeStatusField[0].fieldValue ?? '') : '';
            let stratIndex = parseInt(fieldName.replace('Strat', '').replace('Cplt', ''));
            let currentStratIndex = value ? stratIndex : stratIndex + 1;
            let categoryId = this.records[categIndex].categoryId;
            setTimeout(() => {
                if (fieldName.startsWith('Strat')) {
                    item.values.filter(field => field.fieldName.startsWith('Strat')).forEach((field, fieldIndex) => {
                        fieldIndex = item.values.findLastIndex(value => value.stratId === field.stratId);
                        this.recalculateSubtotals(categIndex, categoryId, fieldIndex, field.fieldName, field.fieldValue, currentClientStatus, '-', 0);
                        let index = parseInt(field.fieldName.replace('Strat', ''));
                        if (value) {
                            if (index >= stratIndex) {
                                field.fieldValue = true;
                            }
                        } else {
                            if (index <= stratIndex) {
                                field.fieldValue = false;
                            }
                        }
                    })
                }
                if (fieldName.startsWith('Cplt')) {
                    item.values.filter(field => field.fieldName.startsWith('Cplt')).forEach((field, fieldIndex) => {
                        fieldIndex = item.values.findLastIndex(value => value.stratId === field.stratId);
                        this.recalculateSubtotals(categIndex, categoryId, fieldIndex, field.fieldName, field.fieldValue, currentClientStatus, '-', 0);
                        let index = parseInt(field.fieldName.replace('Cplt', ''));
                        if (index == stratIndex) {
                            field.fieldValue = value;
                        } else if (!this.mainData.multipleComplementary) {
                            field.fieldValue = false;
                        }
                    })
                }
                let currentStratCount = item.values.filter(field => field.fieldName.startsWith('Strat') && field.fieldValue).length;
                let currentCpltCount = item.values.filter(field => field.fieldName.startsWith('Cplt') && field.fieldValue).length;
                console.log('initialClientStatus >>> ' + initialClientStatus);
                console.log('currentClientStatus >>> ' + currentClientStatus);
                console.log('lastValidProductLifeStatus >>> ' + lastValidProductLifeStatus);
                console.log('currentStratCount >>> ' + currentStratCount);
                console.log('currentCpltCount >>> ' + currentCpltCount);
                console.log('lastValidStratCount >>> ' + lastValidStratCount);
                if (productLifeStatusField && productLifeStatusField.length != 0) {
                    if ((/*initialClientStatus == 'Delist' || */lastValidProductLifeStatus == 'Delist') && currentStratCount > 0) {
                        console.log('1');
                        productLifeStatusField[0].fieldValue = 'New';
                    } else if (lastValidProductLifeStatus == null) {
                        console.log('2');
                        if (currentStratCount == 0) {
                            if (currentCpltCount > 0) {
                                productLifeStatusField[0].fieldValue = 'Complement';
                            } else {
                                productLifeStatusField[0].fieldValue = '';
                            }
                        } else if (currentClientStatus == '' || currentClientStatus == 'Complement') {
                            productLifeStatusField[0].fieldValue = 'New';
                        }
                    } else {
                        console.log('3');
                        if (currentStratCount == 0) {
                            if (currentCpltCount > 0) {
                                productLifeStatusField[0].fieldValue = 'Complement';
                            } else {
                                productLifeStatusField[0].fieldValue = 'Delist';
                            }
                        } else if (!clientStatusToExclude.includes(currentClientStatus) && !clientStatusToExclude.includes(lastValidProductLifeStatus)) {
                            console.log('4');
                            if (currentStratCount > lastValidStratCount) {
                                productLifeStatusField[0].fieldValue = 'Increase';
                            } else if (currentStratCount < lastValidStratCount) {
                                productLifeStatusField[0].fieldValue = 'Decrease';
                            } else {
                                if (item.isNegoN1) {
                                    productLifeStatusField[0].fieldValue = 'Keep';
                                } else {
                                    productLifeStatusField[0].fieldValue = lastValidProductLifeStatus;
                                }
                            }
                        } else if (currentClientStatus != 'Opportunity') {
                            if (!item.hasHistory) {
                                productLifeStatusField[0].fieldValue = 'New';
                            } else {
                                if (currentStratCount > lastValidStratCount) {
                                    productLifeStatusField[0].fieldValue = 'Increase';
                                } else if (currentStratCount < lastValidStratCount) {
                                    productLifeStatusField[0].fieldValue = 'Decrease';
                                } else {
                                    productLifeStatusField[0].fieldValue = item.isNegoN1 ? 'Keep' : lastValidProductLifeStatus;
                                }
                            }
                        }
                    }
                    productLifeStatusField[0].fieldOutputValue = this.mainData?.gridSettingsManager?.picklistValuesMap?.[this.ASD_API_NAMES.ProductLifeStatusAss__c][productLifeStatusField[0].fieldValue] ?? productLifeStatusField[0].fieldValue
                    /*if (fieldName.startsWith('Strat')) {
                        if (lastValidProductLifeStatus == null) {
                            if (currentStratCount == 0) {
                                productLifeStatusField[0].fieldValue = '';
                            } else if ((initialClientStatus == null || initialClientStatus == '' || initialClientStatus == 'New' || initialClientStatus == 'Complement' || initialClientStatus == 'Opportunity')
                                && (currentClientStatus == null || currentClientStatus == '' || currentClientStatus == 'Complement')) {
                                productLifeStatusField[0].fieldValue = 'New';
                            }
                        } else {
                            if (currentStratCount == 0) {
                                let cpltExist = false;
                                let cpltvalues = item.values.filter(field => field.fieldName.startsWith('Cplt'));
                                cpltvalues.forEach(cplt => {
                                    if (cplt.fieldValue && !cpltExist) {
                                        cpltExist = true;
                                    }
                                })
                                productLifeStatusField[0].fieldValue = cpltExist ? 'Complement' : 'Delist';
                            } else if (!clientStatusToExclude.includes(currentClientStatus) && !clientStatusToExclude.includes(lastValidProductLifeStatus)) {
                                if (lastValidStratIndex >= 0) {
                                    if (currentStratIndex < lastValidStratIndex) {
                                        productLifeStatusField[0].fieldValue = 'Increase';
                                    } else if (currentStratIndex > lastValidStratIndex) {
                                        productLifeStatusField[0].fieldValue = 'Decrease';
                                    } else {
                                        if (item.isNegoN1) {
                                            productLifeStatusField[0].fieldValue = 'Keep';
                                        } else {
                                            productLifeStatusField[0].fieldValue = lastValidProductLifeStatus;
                                        }
                                    }
                                } else {
                                    productLifeStatusField[0].fieldValue = 'Increase';
                                }
                            } else if (currentClientStatus != 'Opportunity') {
                                productLifeStatusField[0].fieldValue = 'New';
                            }
                        }
                    } else if (fieldName.startsWith('Cplt')) {
                        let stratExist = false;
                        let stratvalues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                        stratvalues.forEach(strat => {
                            if (strat.fieldValue && !stratExist) {
                                stratExist = true;
                            }
                        })
                        productLifeStatusField[0].fieldValue = stratExist ? productLifeStatusField[0].fieldValue : 'Complement';
                        if (currentCpltCount == 0) {
                            if (lastValidProductLifeStatus == null) {
                                if (productLifeStatusField && productLifeStatusField.length != 0) {
                                    productLifeStatusField[0].fieldValue = '';
                                }
                            } else {
                                if (productLifeStatusField && productLifeStatusField.length != 0) {
                                    productLifeStatusField[0].fieldValue = 'Delist';
                                }
                            }
                        }
                    }*/
                    let recauclateSubtotalFields = fieldName.startsWith('Cplt') ? 'Cplt' : 'Strat';
                    item.values.forEach((field, fieldIndex) => {
                        if (field.fieldName.startsWith(recauclateSubtotalFields)) {
                            this.recalculateSubtotals(categIndex, categoryId, fieldIndex, field.fieldName, field.fieldValue, productLifeStatusField ? productLifeStatusField[0].fieldValue : '', '+', 0);
                        }
                    })
                    productLifeStatusField[0].picklistOptions.forEach(pickVal => {
                        if (pickVal.value == productLifeStatusField[0].fieldValue) {
                            pickVal.isSelected = true;
                        } else {
                            pickVal.isSelected = false;
                        }
                    })
                }
                let selectedStrat = {};
                let clusters = [];
                let stratValues = item.values.filter(field => field.fieldName.startsWith('Strat'));
                stratValues.forEach(strat => {
                    clusters.push({ 'index': strat.stratIndex, 'value': strat.fieldValue, 'Id': strat.clusterId });
                })
                selectedStrat['Strat'] = clusters;
                clusters = [];
                let cpltValues = item.values.filter(field => field.fieldName.startsWith('Cplt'));
                cpltValues.forEach(cplt => {
                    clusters.push({ 'index': cplt.stratIndex, 'value': cplt.fieldValue, 'Id': cplt.clusterId });
                })
                selectedStrat['Cplt'] = clusters;
                let obj;
                if (this.ASDToUpdateMap.hasOwnProperty(Id)) {
                    obj = this.ASDToUpdateMap[Id];
                } else {
                    obj = {
                        attributes: {
                            type: ASD__OBJECT.objectApiName,
                        },
                        Id: Id
                    };
                }
                obj[this.ASD_API_NAMES.ProductCluster__c] = JSON.stringify(selectedStrat);
                obj[this.ASD_API_NAMES.ProductLifeStatusAss__c] = productLifeStatusField[0].fieldValue;
                this.ASDToUpdateMap[Id] = obj;
                if (this.picklistColorsMap) {
                    this.colorCells(item, productLifeStatusField[0].fieldValue);
                }
                let assortmentDetailCopy = this.asdFullDataMap[item.Id];
                assortmentDetailCopy[this.ASD_API_NAMES.ProductCluster__c] = JSON.stringify(selectedStrat);
                assortmentDetailCopy[this.ASD_API_NAMES.ProductLifeStatusAss__c] = productLifeStatusField[0].fieldValue;
                updateAsdOnClusterChange(assortmentDetailCopy, item, categIndex, rowIndex, null, currentClientStatus, productLifeStatusField ? productLifeStatusField[0].fieldValue : '', this);
                this.ASDCalculatedValuesMap[item.Id] = JSON.parse(JSON.stringify(assortmentDetailCopy));
                /*setTimeout(() => {
                    productRow.classList.toggle('newLoading');
                }, 200);*/
            }, 50);
        } catch (error) {
            console.log('toggleCheckboxes')
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    recalculateSubtotals(categIndex, categoryId, fieldIndex, fieldName, fieldValue, productLifeStatus, operator, fieldScale) {
        try {
            fieldValue = typeof fieldValue != "boolean" ? parseFloat(fieldValue) : (fieldValue ? 1 : 0);
            var clientStatusToExclude = ['Opportunity', '', 'ProbablyDeleted'];
            // if (!this.totalsMap.hasOwnProperty(fieldName)) {
            //     this.totalsMap[fieldName] = {
            //         key: 'Total' + fieldName,
            //         value: null,
            //         valueofAllStatus: null,
            //         isValueUp: false,
            //         isValueDown: false,
            //         isValueofAllStatusUp: false,
            //         isValueofAllStatusDown: false,
            //         isShown: this.selectedFields && this.selectedFields.includes(fieldName)
            //     };
            //     this.initTotalsMap[fieldName] = { value: 0, valueofAllStatus: 0, scale: fieldScale };
            // }
            // if (!this.subTotalsMap[categoryId].hasOwnProperty(fieldName)) {
            //     this.subTotalsMap[categoryId][fieldName] = { value: 0, valueofAllStatus: 0, scale: fieldScale };
            // }
            if (operator == '-' && fieldValue) {
                this.subTotalsMap[categoryId][fieldName].valueofAllStatus -= fieldValue;
                this.totalsMap[fieldName].valueofAllStatus -= fieldValue;
                if (!clientStatusToExclude.includes(productLifeStatus)) {
                    this.subTotalsMap[categoryId][fieldName].value -= fieldValue;
                    this.totalsMap[fieldName].value -= fieldValue;
                }
                if (this.filters.includeAllStatuses || !clientStatusToExclude.includes(productLifeStatus)) {
                    this.records[categIndex].subTotalList[fieldIndex].value -= fieldValue;
                }
            } else if (operator == '+' && fieldValue) {
                if (!this.subTotalsMap[categoryId].hasOwnProperty(fieldName)) {
                    this.subTotalsMap[categoryId][fieldName] = {
                        value: 0,
                        valueofAllStatus: 0,
                        scale: 0,
                        class: 'categoryTd slds-text-align_center'
                    };
                }
                if (!this.totalsMap.hasOwnProperty(fieldName)) {
                    this.totalsMap[fieldName] = {
                        key: 'Total' + fieldName,
                        fieldName: fieldName,
                        value: 0,
                        valueofAllStatus: 0,
                        scale: 0,
                        isValueUp: false,
                        isValueDown: false,
                        isValueofAllStatusUp: false,
                        isValueofAllStatusDown: false,
                        isShown: this.selectedFields && this.selectedFields.includes(this.ASD_API_NAMES.ProductCluster__c),
                        class: 'categoryTd slds-text-align_center'
                    };
                }
                this.subTotalsMap[categoryId][fieldName].valueofAllStatus += fieldValue;
                this.totalsMap[fieldName].valueofAllStatus += fieldValue;
                if (!clientStatusToExclude.includes(productLifeStatus)) {
                    this.subTotalsMap[categoryId][fieldName].value += fieldValue;
                    this.totalsMap[fieldName].value += fieldValue;
                }
                if (this.filters.includeAllStatuses || !clientStatusToExclude.includes(productLifeStatus)) {
                    this.records[categIndex].subTotalList[fieldIndex].value += fieldValue;
                }
            }
            this.handleUpDownTotals(fieldName, fieldIndex);
        } catch (error) {
            console.log('recalculateSubtotals')
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }

    }
    handleUpDownTotals(fieldName, fieldIndex) {
        try {
            if (this.initTotalsMap.hasOwnProperty(fieldName)) {
                this.totalsList[fieldIndex].isValueDown = this.initTotalsMap[fieldName].value > this.totalsMap[fieldName].value;
                this.totalsList[fieldIndex].isValueUp = this.initTotalsMap[fieldName].value < this.totalsMap[fieldName].value;
                this.totalsList[fieldIndex].isValueofAllStatusDown = this.initTotalsMap[fieldName].valueofAllStatus > this.totalsMap[fieldName].valueofAllStatus;
                this.totalsList[fieldIndex].isValueofAllStatusUp = this.initTotalsMap[fieldName].valueofAllStatus < this.totalsMap[fieldName].valueofAllStatus;
            }
        } catch (error) {
            console.log('handleUpDownTotals')
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    toggleNbOfStores() {
        this.filters.includeNbOfStores = !this.filters.includeNbOfStores
        this.records.forEach(categ => {
            categ.subTotalList = this.getSubTotalList(categ.hierarchyId, categ.categoryId)
        })
    }
    handleSave() {
        this.loading = true;
        save({ dataToSave: JSON.stringify(Object.values(this.ASDToUpdateMap)) }).then((result) => {
            if (result == '') {
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                this.records = [];
                this.ASDToUpdateMap = {};
                this.ASDCalculatedValuesMap = {};
                this.loadData();
            } else {
                showNotification(this, this.labels.LBL_Error, result, 'error', 'dismissible');
            }
        }).catch(error => {
            this.loading = false;
            showNotification(this, this.labels.LBL_Error, 'saving error', 'error', 'sticky');
            console.error(error);
        });
    }

    confirmAlertModal() {
        this.isAlertModalOpen = false;
        this.handleSave();
        // this.ASDToUpdateMap = {};
        console.log('this.selectedPopup  >>>> ' + this.selectedPopup);
        if (this.selectedPopup != '') {
            this.popups[this.selectedPopup] = !this.popups[this.selectedPopup];
            this.selectedPopup = '';
        }
        // this.productPanelVisibility = !this.productPanelVisibility;
    }


    closeAlertModal() {
        this.isAlertModalOpen = false;
    }

    toggleAttachContract() {
        this.popups.LinkToContractVisibility = !this.popups.LinkToContractVisibility;
        if (!this.popups.LinkToContractVisibility) {
            this.records = [];
            this.loadData();
        }
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

    handleChangeStatus(event) {
        this.loading = true;
        let status = 'Validate';
        changeAssortmentStatus({ assortmentId: this.recordId, status: status }).then((res) => {
            if (res == '') {
                showNotification(this, this.labels.LBL_Success, this.labels.LBL_Assortment_Validated, 'success', 'dismissible');
                this.records = [];
                this.initData();
            } else {
                showNotification(this, this.labels.LBL_Error, res, 'error', 'dismissible');
            }
        }).catch(error => {
            this.loading = false;
            showNotification(this, this.labels.LBL_Error, error, 'error', 'dismissible');
            console.error(error);
        });
    }

    handleChangeFlow(event) {
        let flow = event.target.dataset.flow;
        this.flows[flow] = !this.flows[flow];
    }
    handleExitFlow(event) {
        let flow = event.target.dataset.flow;
        if (event.detail.status == 'FINISHED') {
            this.flows[flow] = !this.flows[flow];
            if (event.detail.outputVariables) {
                for (let outputVar of event.detail.outputVariables) {
                    if (outputVar.name == 'createdAsId') {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + outputVar.value
                            },
                        });
                    }
                }
            }
        }
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
            if (modeValue == 'multiple') {
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
    setStaticFilters(event) {
        let filter = event.target.dataset.filter;
        let status = event.target.dataset.status;
        let productType = event.target.dataset.productType;
        if (status) {
            let value = this.productLifeStatusValues.filter(item => item.value == status);
            if (status == 'BLANK') {
                status = null;
            }
            if (!this.filters.productLifeStatus.includes(status)) {
                this.filters.productLifeStatus.push(status);
                value[0].style = 'background-color:' + value[0].bgColor + ';border: 1px solid red;';
            } else {
                this.filters.productLifeStatus.splice(this.filters.productLifeStatus.indexOf(status), 1);
                value[0].style = 'background-color:' + value[0].bgColor + ';border: 1px solid black;';
            }
            this.loadData();
        } else if (productType) {
            let icon = this.template.querySelector('.' + productType.toLowerCase() + 'Icon');
            if (!this.filters.productTypes.includes(productType)) {
                this.filters.productTypes.push(productType);
                if (icon) {
                    icon.style.border = '1px solid red';
                }
            } else {
                this.filters.productTypes.splice(this.filters.productTypes.indexOf(productType), 1);
                if (icon) {
                    icon.style.border = '';
                }
            }
            this.loadData();
        } else {
            this.filters[filter] = event.target.checked;
            if (filter == 'includeAllStatuses') {
                this.records.forEach(categ => {
                    categ.subTotalList = this.getSubTotalList(categ.hierarchyId, categ.categoryId);
                })
            }
            if (!this.filters.hideBlankStatus) {
                this.filters.showIntroProducts = false;
            }
        }
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
            productLifeStatus: [],
            productTypes: [],
            hideBlankStatus: false,
            showIntroProducts: false,
            onlyShowIntroProducts: false,
            isShowHistory: false,
            includeNbOfStores: false,
            includeAllStatuses: false,
        };
        this.loadData();
    }
    togglePopups(event) {
        let popup = event.target.dataset.popup;
        if (!this.popups[popup] && Object.keys(this.ASDToUpdateMap).length != 0) {
            this.selectedPopup = popup;
            this.isAlertModalOpen = true;
            return;
        }
        this.popups[popup] = !this.popups[popup];
        this.popupLoading = true;
        let asdId = event.target.dataset.asdid;
        let startDate = event.target.dataset.startdate;
        let productId = event.target.dataset.productid;
        if (popup == 'importPopup' && !this.popups[popup]) {
            this.resetImportFile();
        }
        if (popup == 'productPanelVisibility') {
            if (!this[popup]) {
                this.records = [];
                this.initData();
            }
        }
        if (popup == 'LinkToContractVisibility') {
            if (!this[popup]) {
                this.records = [];
                this.loadData();
            }
        }
        if (popup == 'switchRenoPopup') {
            getSwitchProducts({
                productId: productId
            }).then((result) => {
                this.switchProductsList = [];
                let parsedResult = JSON.parse(result);
                for (let prod of parsedResult) {
                    this.switchProductsList.push({
                        asdId: asdId,
                        productId: prod.currentProduct.Id,
                        productName: prod.currentProduct.Name,
                        newProductId: prod.newProduct.Id,
                        newProductName: prod.newProduct.Name,
                        startDate: startDate,
                        isSelected: false,
                    })
                }
                this.popupLoading = false;
            }).catch(error => {
                console.error(error);
                showNotification(this, this.labels.LBL_Error, error, 'error', 'dismissible');
            });
        }
        if (popup == 'HLPPopup') {
            this.selectedProducts = [];
            getHLPProducts({
                assortmentId: this.recordId,
                productId: productId
            }).then((result) => {
                let parsedResult = JSON.parse(result);
                this.HLPProducts = parsedResult;
                if (this.HLPProducts.length > 0) {
                    this.HLPProducts.forEach(productHLP => {
                        productHLP.IsMaster_Higher_Level_Packaging__c = productHLP[this.PROD_API_NAMES.IsMaster_Higher_Level_Packaging__c];
                        productHLP.GTIN__c = productHLP[this.PROD_API_NAMES.GTIN__c];
                        productHLP.Name = productHLP.Name;
                        productHLP.PCB__c = productHLP[this.PROD_API_NAMES.PCB__c];
                        productHLP.PCBElementNb__c = productHLP[this.PROD_API_NAMES.PCBElementNb__c];
                    });
                }
                this.initialHLPProducts = JSON.parse(JSON.stringify(this.HLPProducts));
                this.popupLoading = false;
            }).catch(error => {
                console.error(error);
                showNotification(this, this.labels.LBL_Error, error, 'error', 'dismissible');
            });
        }
        if (popup == 'importPopup' && this.processUplodingFile) {
            this.processUplodingFile = false;
            this.loadData();
        }
    }

    handleToggleHLP(event) {
        let index = event.target.dataset.index;
        this.HLPProducts[index].isSelected = !this.HLPProducts[index].isSelected;
    }

    handleSaveHLP() {
        try {
            let detailsToAdd = [];
            let detailsToDelete = [];

            for (let index = 0; index < this.HLPProducts.length; index++) {
                if (!this.initialHLPProducts[index].isSelected && this.HLPProducts[index].isSelected) {
                    let detail = {
                        attributes: {
                            type: ASD__OBJECT.objectApiName,
                        },
                    }
                    detail[this.ASD_API_NAMES.Assortment__c] = this.recordId;
                    detail[this.ASD_API_NAMES.Product__c] = this.HLPProducts[index].productHLP.Id;
                    detail.RecordTypeId = this.mainData.HLPRecordType;
                    detail[this.ASD_API_NAMES.StartDate__c] = this.mainData.currentAssortment[this.AS_API_NAMES.BDate__c];
                    detailsToAdd.push(detail);
                }
                if (this.initialHLPProducts[index].isSelected && !this.HLPProducts[index].isSelected) {
                    detailsToDelete.push(this.HLPProducts[index].asdHLP)
                }
            }
            if ((!detailsToAdd || detailsToAdd.length == 0)
                && (!detailsToDelete || detailsToDelete.length == 0)
            ) {
                showNotification(this, this.labels.MSG_No_Changes_To_Save, '', 'info');
                return;
            }
            this.popupLoading = true;
            saveData({
                recordsToUpsertJSON: JSON.stringify(detailsToAdd),
                recordsToDeleteJSON: JSON.stringify(detailsToDelete)
            }).then((result) => {
                if (result == 'SUCCESS') {
                    showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                } else {
                    showNotification(this, this.labels.LBL_Error, result, 'error');
                }
                this.popupLoading = false;
            }).catch(error => {
                showNotification(this, this.labels.LBL_Error, error.body?.message, 'error');
                console.log('%c' + error.message, 'color : red');

                this.popupLoading = false;
            })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleSwitchProduct(event) {
        this.loading = true;
        let index = event.target.dataset.index;
        let newProductId = this.switchProductsList[index].newProductId;
        let startDate = this.switchProductsList[index].startDate;
        let asdId = this.switchProductsList[index].asdId;
        obj = {
            attributes: {
                type: ASD__OBJECT.objectApiName,
            },
            Id: asdId
        };
        obj[this.ASD_API_NAMES.Product__c] = newProductId;
        obj[this.ASD_API_NAMES.StartDate__c] = startDate;
        save({ dataToSave: JSON.stringify([...obj]) }).then((result) => {
            if (result == '') {
                showNotification(this, this.labels.LBL_Success, 'Switched Success', 'success', 'dismissible');
                this.records = [];
                this.loadData();
                this.popups.switchRenoPopup = false;
            } else {
                showNotification(this, this.labels.LBL_Error, result, 'error', 'dismissible');
            }
            this.loading = false;
        }).catch(error => {
            this.loading = false;
            console.log('error save Data >> ' + error.message);
            showNotification(this, this.labels.LBL_Error, 'Switched Error', 'error', 'sticky');
            console.error(error);
        });
    }

    handleSelectSwitchProduct(event) {
        let index = event.target.dataset.index;
        this.switchProductsList[index].isSelected = event.target.checked;
    }

    handleChangeStartDate(event) {
        let index = event.target.dataset.index;
        this.switchProductsList[index].startDate = event.target.value;
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
                this.pageNumber = this.totalPagesCount;
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
                assortmentId: this.recordId,
                gridsettingsJSON: JSON.stringify(this.mainData.gridSettingsManager),
                restURL: null
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    this.totalExportSize = parsedResult.totalSize;
                    this.rowCounter = 0;
                    if (parsedResult.error != null) {
                        showNotification(this, this.labels.LBL_Error, parsedResult.error, 'error');
                        this.tableLoading = false;
                        return;
                    }
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                            this.rowCounter += parsedResult.records.length;
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
                    showNotification(this, this.labels.LBL_Error, error.message, 'error');
                }
            }).catch((error) => {
                showNotification(this, this.labels.LBL_Error, error.message, 'error');
            });
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error.message, 'error');
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
                            this.rowCounter += parsedResult.records.length;
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
            const worksheet = workbook.addWorksheet(this.assortmentLongName, { properties: { tabColor: { argb: 'worksheet' } } });
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
                let rowLine = worksheet.getRow(rowCounter);
                let rowValues = [];
                for (let index = 0; index < record.subTotalList.length; index++) {
                    if (index === 0) {
                        rowValues.push(record.categoryName ?? ' ');
                    } else {
                        let value = record.subTotalList[index].value ?? ' ';
                        rowValues.push(value);
                    }
                }
                rowLine.height = 20;
                rowLine.values = rowValues;
                rowLine.eachCell(function (cell, colNumber) {
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: '595959' },
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
                });
                rowCounter++;
                for (let asd of record.asdList) {
                    rowLine = worksheet.getRow(rowCounter);
                    rowLine.height = 20;
                    rowValues = [];
                    let style = [];
                    let index = 1;
                    for (let field of asd.values) {
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
            // workbook.xlsx.writeBuffer().then(result => {
            //     let a = document.createElement('a');
            //     document.body.appendChild(a);
            //     a.style = 'display: none';
            //     let base64Bin = result.toString('base64');
            //     if (this.isSendEmail) {
            //         this.handleSend(base64Bin);
            //     } else {
            //         a.href = 'data:application/vnd.ms-excel;base64,' + base64Bin;
            //         a.download = this.mainData.currentAssortment.Name + '.xlsx'; //File name Here
            //         a.click();
            //         if (this.isExportExcel) {
            //             window.close()
            //         }
            //         this.loadingtable = false;
            //     }
            // });
            workbook.xlsx.writeBuffer().then(result => {
                let base64Bin = result.toString('base64');
                if (this.isSendEmail) {
                    this.handleSend(base64Bin);
                } else {
                    const blob = new Blob(
                        [result],
                        { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
                    );
                    const blobUrl = URL.createObjectURL(blob);
                    const anchorTag = document.createElement('a');
                    anchorTag.setAttribute('href', blobUrl);
                    anchorTag.setAttribute('download', this.mainData.currentAssortment.Name + '.xlsx');
                    anchorTag.click();
                    URL.revokeObjectURL(blobUrl);
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
    handleChangeSortField(event) {
        this.loading = true;
        let fieldName = event.target.dataset.field;
        if (this.sortFieldApi.startsWith(fieldName)) {
            if (this.sortDirection == 'ASC') {
                this.sortDirection = 'DESC';
            } else {
                this.sortDirection = 'ASC';
            }
        } else {
            this.sortDirection = 'ASC';
        }
        this.isSortASC = this.sortDirection == 'ASC'
        this.sortField = fieldName + ' ' + this.sortDirection + ' NULLS ' + (this.isSortASC ? 'FIRST' : 'LAST');
        this.sortFieldApi = fieldName;
        this.displayedFields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.sortedField = true;
                if (field.isReference && field.fieldName.endsWith('__c')) {
                    this.sortField = fieldName.replace('__c', '__r.Name') + ' ' + this.sortDirection + ' NULLS ' + (this.isSortASC ? 'FIRST' : 'LAST');
                }
            } else {
                field.sortedField = false;
            }
        })
        this.loadData();
    }

    setnumberOfFixedColumns(event) {
        if (event) {
            this.nbOfFixedColumns = parseInt(event.detail.value);
        }
        let fixedColumn = this.nbOfFixedColumns;
        let tableTrs = this.template.querySelector('.main-table')?.rows;
        if (tableTrs) {
            let titleHeight = 0;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                if (index == 0) {
                    titleHeight = tableTrs[index].offsetHeight;
                }
                let childrens = tableTrs[index].children;
                let left = 0;
                if (index != 0 && !tableTrs[index].classList?.contains('firstCategoryRow') && !tableTrs[index].classList?.contains('subTotalRow')) {
                    fixedColumn = this.nbOfFixedColumns;
                    left = 0;
                } else {
                    fixedColumn = this.nbOfFixedColumns;
                }
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    let isHistory = childrens[index2].dataset.isHistory;
                    if (index2 < fixedColumn) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = index == 0 ? 5 : 3;
                        left += childrens[index2].offsetWidth;
                    } else {
                        childrens[index2].style.position = '';
                        childrens[index2].style.left = '';
                        childrens[index2].style.zIndex = '';
                    }
                    let bg = childrens[index2].style.backgroundColor;
                    if (bg && isHistory === 'true') {
                        if (bg.startsWith('rgb(')) {
                            // convert rgb to rgba
                            bg = bg.replace('rgb(', 'rgba(').replace(')', ', 0.5)');
                        } else if (bg.startsWith('#') && bg.length === 7) {
                            // add hex alpha
                            bg = bg + '80';
                        }
                    }
                    childrens[index2].style.backgroundColor = bg ? bg : '#FFFFFF';
                }
            }
            let subTotalRows = this.template.querySelectorAll('tr.subTotalRow');
            if (subTotalRows && subTotalRows.length) {
                let globalHeight = subTotalRows[0].offsetHeight || 0;
                subTotalRows.forEach((row, idx) => {
                    row.style.position = 'sticky';
                    row.style.zIndex = 4;
                    if (idx === 0) {
                        row.style.top = titleHeight + 'px';
                    }
                    else {
                        row.style.top = (titleHeight + globalHeight) + 'px';
                    }
                });
            }
        }
    }

    toggleFlow(event) {
        try {
            let flowName = event.target.dataset.flowName;
            let flowLabel = event.target.dataset.flowLabel;
            this.currentFlow = {
                header: flowLabel,
                flowApiName: flowName,
                flowVariables: []
            }
            if (this.recordId
                && this.mainData
                && this.mainData.gridSettingsManager
                && this.mainData.gridSettingsManager.actions
                && this.mainData.gridSettingsManager.actions.screenFlows) {
                let matchedFlow = this.mainData.gridSettingsManager.actions.screenFlows.filter(flow => flow.value == flowName);
                if (matchedFlow && matchedFlow.length > 0) {
                    this.currentFlow.flowVariables.push({
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    })
                }
            }
            this.openFlow = !this.openFlow;
        } catch (error) {
            console.log(JSON.stringify(error))
        }
    }

    closeFlow() {
        this.openFlow = false;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === "FINISHED") {
            showNotification(this, this.labels.LBL_Success, event.detail.status, 'success');
            this.openFlow = !this.openFlow;
            this.currentFlow = {};
            this.loadData();
        }
        if (event.detail.status === "ERROR") {
            showNotification(this, this.labels.LBL_Error, event.detail.status, 'error');
        }
    }

    handleShowTotal() {
        let screenLink = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrixTreeGrid';
        screenLink += '&c__recordId=' + this.mainData.currentAssortment.Id;
        window.open(screenLink, '_blank');
    }

    toggleEmailModal() {
        this.isEmailPopup = !this.isEmailPopup;
    }

    closeScreen() {
        window.close()
    }

    handleChangeEmail(event) {
        let field = event.target.dataset.field;
        let value = event.target.value;
        this[field] = value;
    }

    handleSend(excelBlob) {
        if (this.selectedId != '') {
            sendEmail({
                emailTo: this.targetAddress,
                Name: this.mainData.currentAssortment.Name,
                emailCc: this.cc,
                emailBcc: this.bcc,
                emailSubject: this.subject,
                emailBody: this.body,
                excelBlob: excelBlob,
                recordId: this.recordId,
                assortmentName: 'assortmentTest'
            }).then(result => {
                this.loadingtable = false;
                window.close()
            }).catch(error => {
                console.error(error); // Handle error
            });
        }
    }
    handleDisplayedFieldsChange(event) {
        let value = event.target.value;
        this.selectedFields = this.sortSelectedByOptions(value, this.fieldOptions);
        // this.selectedFields = value;
        localStorage.setItem('AssortmentMatrix' + this.mainData.currentAssortment.RecordType.DeveloperName, JSON.stringify(value));
    }
    sortSelectedByOptions(selectedValues, options) {
        // Create a map of option values and their index in the options array
        const optionIndexMap = new Map();
        options.forEach((option, index) => {
            optionIndexMap.set(option.value, index);
        });

        // Sort the selected values based on the order in options
        return selectedValues.sort((a, b) => optionIndexMap.get(a) - optionIndexMap.get(b));
    }
    applyFieldManager() {
        try {
            this.popups.fieldManagerPopup = false;
            this.mainData.gridSettingsManager.GRID_FIELDS.forEach((field, index) => {
                field.isShown = this.selectedFields && this.selectedFields.includes(field.fieldName);
            });
            this.displayedFields.forEach((field, index) => {
                if (field.isStrat || field.isCplt) {
                    field.isShown = this.selectedFields.includes(this.ASD_API_NAMES.ProductCluster__c);
                } else {
                    field.isShown = this.selectedFields.includes(field.fieldName);
                }
                this.totalsList[index].isShown = field.isShown
            });
            this.records.forEach(record => {
                record.asdList.forEach(((asd, asdIndex) => {
                    asd.values.forEach((field, fieldIndex) => {
                        if (field.isStrat || field.isCplt) {
                            field.isShown = this.selectedFields.includes(this.ASD_API_NAMES.ProductCluster__c);
                        } else {
                            field.isShown = this.selectedFields.includes(field.fieldName);
                        }
                        if (asdIndex == 0) {
                            record.subTotalList[fieldIndex].isShown = field.isShown;
                        }
                        if (asd.hasHistory) {
                            asd.historyList?.forEach(((asd) => {
                                asd.values?.forEach((field) => {
                                    if (field.isStrat || field.isCplt) {
                                        field.isShown = this.selectedFields.includes(this.ASD_API_NAMES.ProductCluster__c);
                                    } else {
                                        field.isShown = this.selectedFields.includes(field.fieldName);
                                    }
                                });
                            }))
                        }
                    });
                }))
            })
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
}