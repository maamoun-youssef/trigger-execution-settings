import { LightningElement, api, track } from 'lwc';
import { toastWarning, toastError, toastSuccess, Labels, incrementFormat, processControllerFields } from "c/gridSettingsHelper";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
//import Static Resources
import xlsx from "@salesforce/resourceUrl/xlsxLib";
import GridSettings from '@salesforce/resourceUrl/GridSettings';
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import { showNotification } from 'c/appHelper';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { RefreshEvent } from 'lightning/refresh';
import userLocal from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
// APEX CLASS
import initData from "@salesforce/apex/GridSettingsPluginCmpController.initData";
import loadData from "@salesforce/apex/GridSettingsPluginCmpController.loadData";
import importRecords from "@salesforce/apex/GridSettingsPluginCmpController.importRecords";
import importRecordsAdvanced from "@salesforce/apex/GridSettingsPluginCmpController.importRecordsAdvanced";
import checkAndGetOutcome from "@salesforce/apex/GridSettingsPluginCmpController.checkAndGetOutcome";
import processRestForExcel from "@salesforce/apex/GridSettingsPluginCmpController.processRestForExcel";
import getChildrenHierarchy from "@salesforce/apex/GridSettingsPluginCmpController.getChildrenHierarchy";
import saveRecords from "@salesforce/apex/GridSettingsPluginCmpController.saveRecords";
import deleteRecords from "@salesforce/apex/GridSettingsPluginCmpController.deleteRecords";
import getFieldDependencies from "@salesforce/apex/GridSettingsPluginCmpController.getFieldDependencies";
import getApexPageName from '@salesforce/apex/GridSettingsPluginCmpController.getApexPageName';
import USER_ID from '@salesforce/user/Id';

export default class GridSettingsPlugin extends NavigationMixin(LightningElement) {
    Labels = Labels;

    //API
    @api templateName;
    @api recordId;
    @api displayNewButton;
    @api displayCloneButton;
    @api displayNewInlineButton;
    @api labelNewInlineButton;
    @api nameAsURL;
    @api allowExport;
    @api allowImport;
    @api includeInListView;
    @api displayListViewActions;
    @api quickActions;
    @api partialSave;
    @api cmpHeight;
    @api showCurrency;
    @api showCurrencyAsSymbol;
    @api useRecordIsoCurrency;
    @api displayShowHideColumns;
    @api refreshViewAfterSave;
    @api numberFixedColumns;
    @api filterOnNoneDisplayedFields;
    @api allowDelete;
    @api allowOpenRecord;
    @api allowFilter;
    @api isReadOnly;
    @api showSubTotal;
    @api enableMassUpdate;
    @api pluginIcon;
    @api saveSuccessMessage;

    //DEPRECATED API
    @api objectApiName;
    // Kept so existing Lightning pages that still store this property can be deployed; not used in the Sprint26 baseline
    @api displayRowActionIcons;
    @api applyNewDesign;
    @api actions;
    @api readOnly;

    //TRACK
    @track isLoading = false;
    @track allowSelectRecords = false;
    @track expandedNodes = new Set();

    //LIST VIEW ACTIONS
    @track selectedActions = [];
    apexPageNames = {}; // cache: ScontrolId -> page name
    // FILTERS
    filters = {
        dynamic: '[]',
        searchTerm: '',
    }
    @track isFilterOpen = false;
    @track filterStyle = '';

    Events = {
        confirmFilterSettings: 'confirmfiltersettings',
        cancelFilterSettings: 'cancelfiltersettings',
        fixedColumns: 'fixedcolumns',
    }
    // PAGINATION
    @track pageNumber = 1;
    @track pageSize = '25';
    @track totalSize = 0;
    @track totalPagesCount = 0;
    @track pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];

    // HEADER
    @track headerConfig = {
        title: '',
        subTitle: '',
        iconName: '',
    }
    // SCREEN FLOW
    @track flows = {
        icons: [],
        buttons: [],
        actions: [],
    }
    @track openFlow = false; // for popup
    @track currentFlow = {
        header: '',
        flowApiName: '',
        flowVariables: '',
    }
    // EXPORT EXCEL
    allRecordsToExport = [];
    exportExcelRowCounter = 0;
    @track totalExportSize = 0;
    @track fileGenerationValue = 0;
    @track fileDownloadValue = 0;
    @track showFileGenerationBar = false;
    @track showFileDownloadBar = false;
    // IMPORT
    @track advancedImportSettings = {};
    @track openImportPopup = false;
    fileInfos = {
        file: '',
        fileName: '',
    }
    advancedImportFileDirectoryId = '';
    // FIELDS
    @track displayedFields = [];
    @track showHideFieldOptions = [];
    @track selectedFields = [];
    initSelectedFields = [];
    @track hiddenGridFields = [];
    // DATA
    @track initDataWrapper = {};
    picklistRelationshipMap = {};
    selectedRecordIds = new Set();
    @track records = [];
    @track recordsToUpsertMap = {}
    dependentPicklistMap = {};
    // SORT
    sortConfig = {
        sortFieldApi: '',
        sortDirection: '',
    }

    // TEMPLATE TYPE
    @track isTreeGrid = false;
    @track isGrouped = false;
    @track groupedField = {};

    // ADD NEW RECORD
    createdRecord = false;
    subscription = {};
    channelName;

    // DELETE
    @track deletePopup = {
        show: false,
        deleteIds: [],
    }

    // SHOW/HIDE COLUMNS
    @track showHideColumns = false;

    // CLONE
    fieldsToClearOnClone = [];
    //LIST VIEW OPTION
    @track listViewLayoutOptions = [];

    //UPLOAD FILE 
    @track uploadFilePopup = false;
    @track uploadFileConfig = {
        record: '',
        index: '',
        field: {}
    }
    @track selectedFile = {};
    // DEFAULT VALUES
    bannerRecord = {}

    conditionalRulesMap = {};

    // GETTERS
    get lastThStyle() {
        const lastFieldStyle = ((this.displayedFields || []).filter(f => !f.isHidden).slice(-1)[0]?.headerStyle) || '';
        return this.stripWidthStyles(lastFieldStyle);
    }

    get hasChanges() {
        return this.recordsToUpsertMap && Object.keys(this.recordsToUpsertMap).length;
    }

    get firstThStyle() {
        const firstFieldStyle = ((this.displayedFields || []).filter(f => !f.isHidden)[0]?.headerStyle) || '';
        return this.stripWidthStyles(firstFieldStyle);
    }

    get filterableFieldsAll() {
        return this.isGrouped && this.groupedField?.fieldName ? [...this.displayedFields, this.groupedField] : this.displayedFields;
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.totalSize ? this.pageNumber * pageSize + 1 - pageSize : this.totalSize - this.records.length) + '-' + (this.pageNumber * pageSize > this.totalSize ? this.totalSize : this.pageNumber * pageSize) + ' ' + this.Labels.LBL_Of + ' ' + this.totalSize;
    }

    get filterSettingsFields() {
        return JSON.stringify((this.initDataWrapper.gridSettingsManager.FILTERS || []).map(item => {
            let newItem = {
                fieldName: item.fieldName,
                fieldLabel: item.fieldLabel,
                stringFieldType: item.stringFieldType,
                pickListValues: item.pickListValues || [],
                isMultiLevel: item.fieldName && item.fieldName.includes('.'),
                userFilterable: true
            };
            if (item.filterValue) {
                newItem.value1 = item.filterValue.value1;
                newItem.value2 = item.filterValue.value2;
                newItem.values = item.filterValue.values;
            }
            return newItem;
        }).sort((item1, item2) => item1.fieldName.includes('RecordTypeId') || item2.fieldName.includes('RecordTypeId') ? 1 : item1.fieldName.localeCompare(item2.fieldName)));
    }

    get hasMenu() {
        return (this.isTreeGrid ? (this.hasData && this.displayShowHideColumns) : (this.hasData && (this.allowDelete || this.displayShowHideColumns || (this.displayListViewActions && this.selectedActions.length > 0)))) || this.flows.actions.length > 0;
    }

    get hasImportExport() {
        return this.allowExport && this.allowImport;
    }

    get noRecordsSelected() {
        return this.selectedRecordIds && this.selectedRecordIds.size == 0;
    }

    get fileGenerationLabel() {
        return this.Labels.LBL_File_Generation.replace('{0}', this.exportExcelRowCounter).replace('{1}', this.totalExportSize);
    }

    get recordsLength() {
        return this.records.reduce((sum, group) => {
            return sum + (group.records ? group.records.length : 0);
        }, 0);
    }

    get hasTotalFields() {
        return this.showSubTotal && !this.isTreeGrid && this.loadDataWrapper?.totalResult != null;
    }

    get isAllRecordsSelected() {
        return this.recordsLength > 0 && this.records.every(group =>
            group.records.every(item => item?.isSelected === true)
        );
    }

    get displayLastTd() {
        return (this.allowDelete && !this.isTreeGrid) || this.allowOpenRecord;
    }

    get MassUpdatePopupStyle() {
        return this.showSubTotal ? "left:100px;width: 255px;box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 190%; z-index:6;" : "left:100px;width: 255px;box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;";
    }

    get getMassUpdateLines() {
        return /*this.Labels.LBL_Selected_Lines.replace('{0}', this.records.data.filter(item => this.selectedRecordIds.includes(item.Id)).length)*/'';
    }

    //check if there is data
    get hasData() {
        return this.records && this.records.length > 0;
    }

    get previousDisabled() {
        return (this.pageNumber <= 1);
    }

    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    get isSortASC() {
        return this.sortConfig.sortDirection == 'ASC';
    }

    //has Pagination
    get hasPagination() {
        return (this.totalSize > (this.initDataWrapper && this.initDataWrapper.gridSettingsManager ? this.initDataWrapper.gridSettingsManager.Default_Page_Size : 0)) && !this.isTreeGrid;
    }

    get showFirstDivider() {
        return (this.allowDelete || this.displayShowHideColumns) && this.displayListViewActions && this.selectedActions.length > 0;
    }

    get showSecondDivider() {
        return this.flows?.actions.length > 0 && this.displayListViewActions && this.selectedActions.length > 0;
    }

    //get data on component load
    connectedCallback() {
        //this.hiddenGridFields = localStorage.getItem(this.templateName) ? JSON.parse(localStorage.getItem(this.templateName)) : [];
        // handle if api is passed as string
        this.applyNewDesign = !this.applyNewDesign || this.applyNewDesign == 'false' ? false : true;
        this.includeInListView = !this.includeInListView || this.includeInListView == 'false' ? false : true;
        this.displayListViewActions = !this.displayListViewActions || this.displayListViewActions == 'false' ? false : true;
        this.displayNewButton = !this.displayNewButton || this.displayNewButton == 'false' ? false : true;
        this.displayNewInlineButton = !this.displayNewInlineButton || this.displayNewInlineButton == 'false' ? false : true;
        this.displayCloneButton = !this.displayCloneButton || this.displayCloneButton == 'false' ? false : true;
        this.allowDelete = !this.allowDelete || this.allowDelete == 'false' ? false : true;
        this.displayShowHideColumns = !this.displayShowHideColumns || this.displayShowHideColumns == 'false' ? false : true;
        this.allowImport = !this.allowImport || this.allowImport == 'false' ? false : true;
        this.allowExport = !this.allowExport || this.allowExport == 'false' ? false : true;
        this.allowFilter = !this.allowFilter || this.allowFilter == 'false' ? false : true;
        this.allowOpenRecord = !this.allowOpenRecord || this.allowOpenRecord == 'false' ? false : true;
        this.nameAsURL = !this.nameAsURL || this.nameAsURL == 'false' ? false : true;
        this.showCurrency = !this.showCurrency || this.showCurrency == 'false' ? false : true;
        this.showCurrencyAsSymbol = !this.showCurrencyAsSymbol || this.showCurrencyAsSymbol == 'false' ? false : true;
        this.useRecordIsoCurrency = !this.useRecordIsoCurrency || this.useRecordIsoCurrency == 'false' ? false : true;
        this.showSubTotal = !this.showSubTotal || this.showSubTotal == 'false' ? false : true;
        this.isReadOnly = !this.isReadOnly || this.isReadOnly == 'false' ? false : true;
        this.enableMassUpdate = !this.enableMassUpdate || this.enableMassUpdate == 'false' ? false : true;
        this.refreshViewAfterSave = !this.refreshViewAfterSave || this.refreshViewAfterSave == 'false' ? false : true;
        this.partialSave = !this.partialSave || this.partialSave == 'false' ? false : true;
        this.filterOnNoneDisplayedFields = !this.filterOnNoneDisplayedFields || this.filterOnNoneDisplayedFields == 'false' ? false : true;
        this.readOnly = !this.readOnly || this.readOnly == 'false' ? false : true;
        this.actions = !this.actions || this.actions == 'false' ? false : true;
        this.allowSelectRecords = ((this.enableMassUpdate || this.allowDelete) && !this.isReadOnly) || (this.displayListViewActions && this.selectedActions?.length > 0);
        this.displayCloneButton = this.displayCloneButton && !this.isReadOnly;
        this.allowImport = this.allowImport && !this.isReadOnly;
        this.allowDelete = this.allowDelete && !this.isReadOnly;
        this.displayNewButton = this.displayNewButton && !this.isReadOnly;
        this.displayNewInlineButton = this.displayNewInlineButton && !this.isReadOnly;
        this.numberFixedColumns = this.numberFixedColumns != null && this.numberFixedColumns >= 0 && this.numberFixedColumns < 7 ? this.numberFixedColumns : 2;
        // Load all static Resources
        this.loadStaticResources();
        window.addEventListener('resize', this.changeHeight);
        this.initData();
    }

    renderedCallback() {
        this.changeHeight();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, response => {
            console.log('Unsubscribed Channel');
        });
        this.createdRecord = false;
        window.removeEventListener('resize', this.handleResize);
    }

    loadStaticResources() {
        loadScript(this, ExcelJSURL).then(() => {
            console.log('load exceljs success');
        }).catch(error => {
            console.log('load exceljs failedd');
            console.log(error);
        });
        loadScript(this, xlsx + '/js-xlsx-master/dist/jszip.js').then(() => {
            loadScript(self, xlsx + '/js-xlsx-master/dist/xlsx.js').then(() => {
                console.log('jszip loaded');
            }).catch(error => {
                toastError(self, error)
                console.log('error: ' + error);
            });
        }).catch(error => {
            console.log('error: ' + error);
        });
        Promise.all([
            loadStyle(this, GridSettings + '/customStyle.css'),
        ]).then(() => { }).catch(error => {
            console.log("Error " + error.body.message);
        });
    }

    initData() {
        this.flows = {
            icons: [],
            buttons: [],
            actions: [],
        }
        this.recordsToUpsertMap = {};
        try {
            this.isLoading = true;
            this.pageNumber = 1;
            if (this.templateName) {
                initData({
                    recordId: this.recordId,
                    templateName: this.templateName,
                    saveMessage: this.saveSuccessMessage,
                    newInlineLabel: this.labelNewInlineButton,
                    filterOnNoneDisplayedFields: this.filterOnNoneDisplayedFields
                }).then(result => {
                    this.initDataWrapper = JSON.parse(result);
                    console.log('this.initDataWrapper >>> ' + JSON.stringify(this.initDataWrapper))
                    if (this.initDataWrapper.errorMessages && this.initDataWrapper.errorMessages.length > 0) {
                        showNotification(this, this.Labels.LBL_Error, this.initDataWrapper.errorMessages.join('\n'), 'error', 'dismissable');
                        return;
                    }
                    this.saveSuccessMessage = this.initDataWrapper.saveMessage && this.initDataWrapper.saveMessage.trim() ? this.initDataWrapper.saveMessage : this.Labels.MSG_Successfully_Saved;
                    this.labelNewInlineButton = this.initDataWrapper.newInlineLabel && this.initDataWrapper.newInlineLabel.trim() ? this.initDataWrapper.newInlineLabel : 'New inline row';
                    this.bannerRecord = this.initDataWrapper.bannerRecord;
                    this.listViewLayoutOptions = this.initDataWrapper.listViewLayoutOptions.sort((a, b) => a.order - b.order);
                    this.headerConfig = {
                        title: this.initDataWrapper.gridSettingsManager.layoutSlogan ?? this.initDataWrapper.gridSettingsManager.objectLabel ?? '',
                        subTitle: this.initDataWrapper.gridSettingsManager.layoutLabel ?? '',
                        iconName: this.initDataWrapper.gridSettingsManager.iconName && this.initDataWrapper.gridSettingsManager.iconSection ? this.initDataWrapper.gridSettingsManager.iconSection + ':' + this.initDataWrapper.gridSettingsManager.iconName : 'standard:orders'
                    }
                    this.selectedActions = this.initDataWrapper?.gridSettingsManager?.actions?.quickActions.length > 0 ? this.initDataWrapper.gridSettingsManager.actions.quickActions : [];
                    if (this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows?.length > 0) {
                        this.initDataWrapper.gridSettingsManager.actions.screenFlows.forEach(flow => {
                            if (flow.value) {
                                if (flow.displayType === 'Icon') {
                                    this.flows.icons.push(flow);
                                } else if (flow.displayType === 'Button') {
                                    this.flows.buttons.push(flow);
                                } else if (flow.displayType === 'Action') {
                                    this.flows.actions.push(flow);
                                }
                            }
                        })
                    }
                    if (this.displayNewButton) {
                        this.channelName = !this.initDataWrapper.gridSettingsManager.OBJECT_NAME.endsWith('__c') ? '/data/' + this.initDataWrapper.gridSettingsManager.OBJECT_NAME + 'ChangeEvent' : '/data/' + this.initDataWrapper.gridSettingsManager.OBJECT_NAME.replace(/__c$/, '') + '__ChangeEvent';
                        this.handleSubscription();
                    }
                    this.pageSize = '' + this.initDataWrapper.gridSettingsManager.Default_Page_Size;
                    this.advancedImportSettings = this.initDataWrapper.importSetting;
                    this.isTreeGrid = this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'tree';
                    this.isGrouped = this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'grouped' && this.initDataWrapper.gridSettingsManager.groupedField;
                    this.buildDisplayedFields();
                });
            }
        } catch (error) {
            showNotification(this, this.Labels.LBL_Error, error, 'error');
            console.log('initData:', error);
            this.isLoading = false;
        }
    }

    // Builds the grid column definitions
    buildDisplayedFields() {
        try {
            this.displayedFields = [];
            this.showHideFieldOptions = [];
            this.selectedFields = [];
            this.picklistRelationshipMap = {};
            this.dependentPicklistMap = {};
            this.conditionalRulesMap = {};
            const dependencyPromises = [];
            const gridFields = this.initDataWrapper.gridSettingsManager.GRID_FIELDS || [];
            this.hiddenGridFields = localStorage.getItem(this.templateName) ? JSON.parse(localStorage.getItem(this.templateName)) : [];
            let filterableFields = this.initDataWrapper.gridSettingsManager.FILTERS || [];
            const groupedField = this.initDataWrapper.gridSettingsManager?.groupedField;
            for (let field of gridFields) {
                if (!field.isHidden && field.fieldName != groupedField) {
                    this.showHideFieldOptions.push({
                        value: `${field.fieldName} ${field.isInputField == true ? 'In' : 'Out'}`,
                        label: `${field.fieldLabel} ${field.isInputField == true ? '(input)' : '(output)'}`
                    })
                }
                if (field.isDefaultSortable && !this.sortConfig.sortDirection) {
                    this.sortConfig.sortDirection = field.defaultSortDirection;
                    this.sortConfig.sortFieldApi = field.fieldName;
                }
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    stringFieldType: field.stringFieldType,
                    isNumberField: field.isNumberField,
                    isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    isText: field.stringFieldType == 'STRING',
                    isMultiPicklist: field.stringFieldType == 'MULTIPICKLIST',
                    isCurrency: field.stringFieldType == 'CURRENCY',
                    isPercent: field.stringFieldType == 'PERCENT',
                    isUrl: field.stringFieldType == 'URL',
                    isId: field.stringFieldType == 'ID',
                    isNameField: field.fieldName.toLowerCase() == 'name',
                    link: '',
                    scale: field.scale ?? 0,
                    step: '',
                    isInputField: field.isInputField && !this.isReadOnly,
                    hasConditionalFormating: field.hasConditionalFormating,
                    formattingRulesList: field.formattingRulesList,
                    style: (field.style ? field.style : '') + 'word-wrap: break-word; max-width:300px;',
                    class: 'limited-cell slds-border_left slds-border_right slds-border_bottom',
                    headerStyle: field.stringHeaderStyle + ' max-width: 300px;',
                    pickListValues: field.pickListValues,
                    isSortable: field.isSortable,
                    isDefaultSortable: field.isDefaultSortable,
                    isFilterable: filterableFields.filter(elt => elt.fieldName == field.fieldName && elt.hasOwnProperty('userFilterable') && elt.userFilterable).length > 0,
                    isEncrypted: field.isEncrypted,
                    isCalculated: field.isCalculated,
                    internallyCalculated: field.internallyCalculated,
                    isUpdateable: field.isUpdateable,
                    isCreateable: field.isCreateable,
                    isFormula: field.isFormula,
                    equation: field.equation,
                    isHidden: field.isHidden ?? false,
                    hasHelpText: field.hasHelpText,
                    helpText: field.helpText,
                    isOnlyNumber: field.isNumberField && !field.isPercent && !field.isCurrency,
                    isMassUpdate: field.isMassUpdate && field.isInputField && this.enableMassUpdate,
                    filterValue: { values: [], value1: '', value2: '', searchValue: '' },
                    initFilterValue: '',
                    sortedField: field.fieldName == this.sortConfig.sortFieldApi,
                    iconStyle: '',
                    color: field.nonConditional?.textStyle?.color,
                    headerFilterPopUpStyle: '',
                    total: false,
                    defaultValue: field.defaultValue,
                    defaultType: field.defaultType,
                    defaultExpression: field.defaultExpression,
                    isRecordType: field.fieldName.toLowerCase() == 'recordtypeid',
                    massUpdateValue: '',
                    isSearchableText: field.stringFieldType == 'STRING' || field.stringFieldType == 'TEXTAREA' || field.stringFieldType == 'REFERENCE',
                    isSearchableCheckboxes: field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'BOOLEAN',
                    isSearchableInput: field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT',
                    isSearchableDateInput: field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME',
                    hasFilter: false,
                    controllerPicklistField: { controllerName: field.controllerName, massUpdateValue: undefined },
                    hasDependentPicklist: false,
                    controlledByFields: field.controlledByFields,
                    replaceURLWith: field.replaceURLWith,
                    hasFileInput: field.hasFileInput,
                    picklistColorsMap: field.picklistColorsMap,
                    displayFullURL: field.displayFullURL,
                    isURLIcon: field.URLOption == 'IconReplace',
                    isNotExportable: field.isNotExportable,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isRichText: field.isRichText,
                    SObjectName: field.SObjectName || '',
                    nameAsURL: (this.nameAsURL && field.fieldName.toLowerCase() == "name"),
                    showInTotal: field.showInTotal,
                    conditionalRules: field.conditionalRules
                }
                if (field.clearOnClone) this.fieldsToClearOnClone.push(field.fieldName);
                let localHiddenField = this.hiddenGridFields.find(item => item.fieldName == field.fieldName && item.isInputField == field.isInputField);
                if (localHiddenField) {
                    fieldWrapper.isHidden = true;
                } else {
                    this.selectedFields.push(`${field.fieldName} ${field.isInputField == true ? 'In' : 'Out'}`);
                }
                fieldWrapper.headerFilterPopUpStyle = fieldWrapper.isSearchableCheckboxes ? 'max-height:230px;min-height:230px;'
                    : fieldWrapper.isSearchableDateInput || fieldWrapper.isSearchableInput ? 'min-width:260px' : ''
                if (fieldWrapper.isPicklist) {
                    // fieldWrapper.pickListValues.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                }
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.scale) {
                    const result = 1 / Math.pow(10, fieldWrapper.scale);
                    fieldWrapper.step = result.toFixed(fieldWrapper.scale);
                }
                const match = (fieldWrapper.headerStyle || '').match(/(?:^|;)\s*color\s*:\s*([^;]+)/i);
                if (match) {
                    const color = match[1].trim();
                    fieldWrapper.iconStyle += `--slds-c-icon-color-foreground: ${color} !important;--slds-c-icon-color-foreground-default: ${color} !important;`;
                }
                if (fieldWrapper.isBoolean) {
                    fieldWrapper.pickListValues = [{ label: this.Labels.LBL_True, value: 'true' }, { label: this.Labels.LBL_False, value: 'false' }];
                }
                // Handle Dependent Picklist
                if (field.controllerName != null) {
                    this.picklistRelationshipMap[field.controllerName] = field.fieldName;
                    // Load dependency data
                    dependencyPromises.push(
                        getFieldDependencies({
                            objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                            controllingField: field.controllerName,
                            dependentField: field.fieldName
                        }).then(result => {
                            this.dependentPicklistMap[field.fieldName] = JSON.parse(result);
                        }).catch(error => {
                            console.error(`Failed loading dependency ${field.controllerName} -> ${field.fieldName}`, error);
                            this.dependentPicklistMap[field.fieldName] = {};
                        })
                    );
                }
                fieldWrapper.hasDependentPicklist = fieldWrapper.isPicklist && (Object.keys(this.picklistRelationshipMap).includes(fieldWrapper.fieldName) || Object.values(this.picklistRelationshipMap).includes(fieldWrapper.fieldName));
                if (fieldWrapper.hasDependentPicklist) {
                    const controlledByFields = [];
                    // Find previous controllers
                    let previousField = Object.keys(this.picklistRelationshipMap).find(key => this.picklistRelationshipMap[key] === fieldWrapper.fieldName);
                    while (previousField) {
                        const previous = gridFields.find(f => f.fieldName === previousField);
                        controlledByFields.unshift({
                            controlledByName: previousField,
                            controlledByLabel: previous?.fieldLabel || previousField,
                            value: undefined,
                            disabled: controlledByFields.length > 0,
                            options: [...(previous?.pickListValues || [])]
                        });
                        previousField = Object.keys(this.picklistRelationshipMap).find(key => this.picklistRelationshipMap[key] === previousField);
                    }
                    // Find dependent children
                    let nextField = this.picklistRelationshipMap[fieldWrapper.fieldName];
                    while (nextField) {
                        const next = gridFields.find(f => f.fieldName === nextField);
                        controlledByFields.push({
                            controlledByName: nextField,
                            controlledByLabel: next?.fieldLabel || nextField,
                            value: undefined,
                            disabled: true,
                            options: [...(next?.pickListValues || [])]
                        });
                        nextField = this.picklistRelationshipMap[nextField];
                    }
                    fieldWrapper.controlledByFields = controlledByFields;
                }
                /// WHYYY
                // // fieldWrapper.options = filterableFields.filter(elt => elt.fieldName == field.fieldName).length > 0 && field.stringFieldType == 'PICKLIST';
                if (fieldWrapper.fieldName == groupedField && this.isGrouped) {
                    this.groupedField = fieldWrapper;
                    continue;
                }
                (field.conditionalRules || []).forEach(r => Object.values(r.criteria.rulesMap).forEach(rule =>
                    (this.conditionalRulesMap[rule.fieldName] ||= new Set()).add(field.fieldName)));
                this.displayedFields.push(fieldWrapper)
            }
            Promise.all(dependencyPromises).then(() => {
                this.loadData();
            });
        } catch (error) {
            showNotification(this, this.Labels.LBL_Error, error, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    // Calls Apex loadData to fetch table rows.
    loadData() {
        try {
            this.records = [];
            this.isLoading = true;
            loadData({
                gridSettingsManagerSerialized: JSON.stringify(this.initDataWrapper.gridSettingsManager),
                recordId: this.recordId,
                pageSize: this.pageSize,
                pageNumber: this.pageNumber,
                filters: JSON.stringify(this.filters),
                sortedFieldName: this.sortConfig.sortFieldApi,
                defaultSortDirection: this.sortConfig.sortDirection
            }).then(result => {
                this.loadDataWrapper = JSON.parse(result);
                console.log(' loadDataWrapper>>>> ' + JSON.stringify(this.loadDataWrapper))
                if (result) {
                    const totals = this.loadDataWrapper.totalResult || {};
                    this.displayedFields = this.displayedFields.map(field => ({
                        ...field,
                        total: field.showInTotal ? (totals[field.fieldName] ?? 0) : ''
                    }));
                    this.totalSize = this.loadDataWrapper.totalSize;
                    this.totalPagesCount = Math.ceil((this.totalSize / this.pageSize));
                    this.records = this.buildData(this.loadDataWrapper.records || [], false);
                    console.log('this.recordssss>>>> ' + JSON.stringify(this.records));
                }
            }).catch(error => {
                showNotification(this, this.Labels.LBL_Error, error, 'error');
                console.log('loadData: %c' + error.message, 'color : red');
                console.log('loadData: %c' + error.body?.message, 'color : red');
                this.isLoading = false;
            })
        } catch (error) {
            showNotification(this, this.Labels.LBL_Error, error, 'error');
            console.log('loadData:', error);
            this.isLoading = false;
        }
    }

    buildData(records, isExcelExport) {
        if (this.isTreeGrid) {
            this.handleTreeLoad();
            return this.records;
        } else {
            try {
                let recordMap = new Map();
                const groupedField = this.initDataWrapper.gridSettingsManager?.groupedField || '';
                for (let [id, value] of Object.entries(this.recordsToUpsertMap)) {
                    if (id.startsWith('TEMP-')) {
                        records.push(value);
                    }
                }
                for (let record of records) {
                    let groupId = record[groupedField];
                    let groupName = record[groupedField.trim().replace(/__c$/, '__r')] ? record[groupedField.trim().replace(/__c$/, '__r')].Name : groupId;
                    let key = !!groupedField ? groupId : '';
                    let group = recordMap.get(key);
                    if (!group) {
                        group = {
                            key: key,
                            groupId: groupId,
                            groupName: groupName,
                            link: groupName != groupId ? '/' + groupId : '',
                            records: [],
                        };
                        recordMap.set(key, group);
                    }
                    //we use this to minimize the load on the excelExport and we build the row inside the buildExcel function we do this for the progress bar
                    if (isExcelExport) {
                        group.records.push(record)
                    } else {
                        group.records.push(this.buildRow(record))
                    }
                }
                this.isLoading = false;
                return Array.from(recordMap.values())
            } catch (error) {
                showNotification(this, this.Labels.LBL_Error, error, 'error');
                console.log('buildData: %c' + error.message, 'color : red');
                console.log('buildData: %c' + error.body?.message, 'color : red');
            }
        }
    }

    buildRow(item) {
        try {
            let recordW = {
                Id: item.Id ?? `TEMP-${Date.now()}`,
                values: [],
                link: '/' + item.Id,
                rowColor: '',
                firstTdStyle: '',
                lastTdStyle: '',
                record: item,
                hasError: false,
                CurrencyIsoCode: item['CurrencyIsoCode'] && this.useRecordIsoCurrency ? item['CurrencyIsoCode'] : '',
                isSelected: this.selectedRecordIds.has(item.Id)
            };
            for (let field of this.displayedFields) {
                let fieldWrapper = {
                    ...field,
                    isInputField: !field.internallyCalculated && ((!this.isReadOnly && field.isInputField) || (item.Id == undefined && field.isCreateable && field.isUpdateable && !field.isCalculated && !field.fieldName.includes("."))),
                    key: item.Id + field.fieldName,
                    fieldValue: '',
                    fieldOutputValue: '',
                    link: field.nameAsURL || field.isId ? '/' + item.Id : (field.isReference ? '/' + item[field.fieldName] : ''),
                    CurrencyIsoCode: item['CurrencyIsoCode'],
                    pickListValues: [],
                    isDisabled: false
                };
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
                // Override with pending unsaved edit if one exists for this field.
                if (this.recordsToUpsertMap.hasOwnProperty(item.Id) && this.recordsToUpsertMap[item.Id].hasOwnProperty(field.fieldName)) {
                    fieldWrapper.fieldValue = this.recordsToUpsertMap[item.Id][field.fieldName];
                }
                // picklist: build options + output label
                if (fieldWrapper.isPicklist) {
                    let options = [...field.pickListValues];
                    const controllerField = Object.keys(this.picklistRelationshipMap).find(key => this.picklistRelationshipMap[key] === field.fieldName);
                    if (controllerField) {
                        const controllerValue = item[controllerField];
                        if (controllerValue) {
                            const allowedOptions = this.dependentPicklistMap?.[field.fieldName]?.[controllerValue] || [];
                            options = options.filter(option => allowedOptions.some(allowed => allowed.value === option.value));
                        } else {
                            options = [];
                        }
                    }
                    for (let pickVal of options) {
                        fieldWrapper.pickListValues.push({
                            label: pickVal.label,
                            value: pickVal.value,
                            isSelected: fieldWrapper.fieldValue == pickVal.value
                        });
                        if (fieldWrapper.fieldValue == pickVal.value) {
                            fieldWrapper.fieldOutputValue = pickVal.label;
                        }
                    }
                    recordW.rowColor += field.picklistColorsMap && fieldWrapper.fieldValue !== '' && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue) && field.picklistColorsMap[fieldWrapper.fieldValue] !== '' ? `background-color: ${field.picklistColorsMap[fieldWrapper.fieldValue]}` : '';
                }
                if (fieldWrapper.isMultiPicklist) {
                    fieldWrapper.pickListValues = [...field.pickListValues];
                    let values = fieldWrapper.fieldValue ? fieldWrapper.fieldValue.split(';') : [];
                    fieldWrapper.selectedValues = values;
                    let outputValues = [];
                    for (let val of values) {
                        for (let pickVal of field.pickListValues) {
                            if (val == pickVal.value) {
                                outputValues.push(pickVal.label);
                            }
                        }
                    }
                    fieldWrapper.fieldOutputValue = outputValues.join(';');
                }
                if (fieldWrapper.isFormula) {
                    let expr = fieldWrapper.equation;
                    if (expr) {
                        try {
                            Object.keys(item).forEach(key => {
                                const re = new RegExp(`\\b${key}\\b`, 'g');
                                expr = expr.replace(re, item[key]);
                            });
                            fieldWrapper.fieldValue = Number(eval(expr).toFixed(fieldWrapper.scale));
                        } catch (e) {
                            fieldWrapper.fieldValue = null;
                        }
                    }
                }
                // Conditional Formatting Style
                if (fieldWrapper.hasConditionalFormating) {
                    for (let condFormat of field.formattingRulesList) {
                        if (condFormat.operation == 'EQUALS') {
                            condFormat.value1 = field.isBoolean ? condFormat.value1 == 'true' : condFormat.value1;
                            if ((field.isText && fieldWrapper.fieldValue && fieldWrapper.fieldValue.toLowerCase() == condFormat.value1.toLowerCase()) || (!field.isText && fieldWrapper.fieldValue == condFormat.value1)) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'NOT_EQUALS') {
                            if ((field.isText && fieldWrapper.fieldValue && fieldWrapper.fieldValue.toLowerCase() != condFormat.value1.toLowerCase()) || (!field.isText && fieldWrapper.fieldValue != condFormat.value1)) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'ISNULL') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue == null) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'ISBLANK') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue == '') {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'CONTAINS') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue.toLowerCase().includes(condFormat.value1.toLowerCase())) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'NOT_CONTAINS') {
                            if (fieldWrapper.fieldValue && !fieldWrapper.fieldValue.toLowerCase().includes(condFormat.value1.toLowerCase())) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'GREATER') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue > condFormat.value1) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'GREATER_OR_EQUALS') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue >= condFormat.value1) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'LESS') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue < condFormat.value1) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'LESS_OR_EQUALS') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue <= condFormat.value1) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        } else if (condFormat.operation == 'BETWEEN') {
                            if (fieldWrapper.fieldValue && fieldWrapper.fieldValue >= condFormat.value1 && fieldWrapper.fieldValue <= condFormat.value2) {
                                fieldWrapper.style += condFormat.style.style;
                            }
                        }
                    }
                }

                if (field.conditionalRules) {
                    fieldWrapper.isDisabled = !!processControllerFields(this, item, field, false, null);
                }
                recordW.values.push(fieldWrapper);
            }
            recordW.firstTdStyle = this.stripWidthStyles(recordW.values[0].style);
            recordW.lastTdStyle = this.stripWidthStyles(recordW.values[recordW.values.length - 1].style);

            // handle Default Value
            if (recordW.Id.startsWith('TEMP-')) {
                this.displayedFields.filter(field => field.defaultType != null).forEach(field => {
                    if (!this.recordsToUpsertMap[recordW.Id] || !this.recordsToUpsertMap[recordW.Id][field.fieldName]) {
                        this.applyFieldUpdate(recordW, { fieldName: field.fieldName, value: this.resolveFieldValue(field, this.displayedFields) });
                    }
                })
            }
            return recordW;
        } catch (error) {
            showNotification(this, this.Labels.LBL_Error, error, 'error');
            console.log('buildRow: %c' + error.message, 'color : red');
            console.log('buildRow: %c' + error.body?.message, 'color : red');
        }
    }

    // DEFAULT VALUE FUNCTIONS
    resolveFieldValue(field, fields) {
        if (field.defaultType == 'expression') {
            return this.evaluateExpression(field, fields);
        } else if (field.defaultType == 'current') {
            const referencedField = fields.find(f => f.fieldName === field.defaultValue);
            if (referencedField) {
                return this.resolveFieldValue(referencedField, fields);
            }
        } else if (field.defaultType == 'master') {
            return this.bannerRecord[field.defaultValue.split(".")[1]] || '';
        } else if (field.defaultType == 'text') {
            return field.defaultValue;
        }
        return '';
    }

    evaluateExpression(field, fields) {
        const expressionFields = field.defaultExpression.split(/([+\-*/])/).map(expr => expr.trim().replace(/{!|}/g, ''));
        const resolveValue = (fieldName) => {
            const referencedField = fields.find(f => f.fieldName === fieldName);
            if (referencedField) {
                const fieldValue = this.resolveFieldValue(referencedField, fields);
                if (!isNaN(fieldValue)) {
                    return parseFloat(fieldValue);
                }
                return fieldValue || '';
            } else {
                if (!isNaN(fieldName)) {
                    return parseFloat(fieldName);
                }
            }
            return '';
        };

        const applyOperator = (operator, left, right, allFieldsAreNumbers) => {
            if (!allFieldsAreNumbers) {
                return left + right;
            }
            switch (operator) {
                case '+': return left + right;
                case '-': return left - right;
                case '*': return left * right;
                case '/':
                    if (right === 0) {
                        toastError(this, this.Labels.MSG_Division_By_Zero);
                        return 0;
                    }
                    return left / right;
            }
        };

        const priorityOperators = (priority) => {
            while (
                operators.length > 0 &&
                priority.includes(operators[operators.length - 1])
            ) {
                const operator = operators.pop();
                const right = values.pop();
                const left = values.pop();
                values.push(applyOperator(operator, left, right, allFieldsAreNumbers));
            }
        };

        const operators = [];
        const values = [];
        let allFieldsAreNumbers = true;
        expressionFields.forEach((exprFieldName) => {
            if (/[+\-*/]/.test(exprFieldName)) {
                priorityOperators(['*', '/']);
                operators.push(exprFieldName);
            } else {
                if (isNaN(resolveValue(exprFieldName))) {
                    allFieldsAreNumbers = false;
                }
                values.push(resolveValue(exprFieldName));
            }
        });

        priorityOperators(['*', '/']);
        while (operators.length > 0) {
            const operator = operators.shift();
            const left = values.shift();
            const right = values.shift();
            const result = applyOperator(operator, left, right, allFieldsAreNumbers);
            values.unshift(result);
        }

        return field.isText || field.isTextArea ? values.pop() + '' : values.pop();
    }

    
    handleTreeLoad() {
        const rows = this.loadDataWrapper?.records;
        if (!rows || rows.length === 0) {
            this.isLoading = false;
            return;
        }
        const roots = this.recordId ? [rows[0]] : rows;
        const autoExpand = this.recordId ? true : roots.length < 5;
        console.log('handleTreeLoad: roots', JSON.stringify(roots));
        roots.forEach((record, i) => this.createRootNode(record, autoExpand, i));
        this.isLoading = false;
    }
    // Creates the root node of the hierarchy tree and auto-expands it to show direct children
    createRootNode(currentNode, autoExpand, index) {
        const rootNode = this.buildRow(currentNode);
        rootNode.key = currentNode.Id;
        rootNode.level = 1;
        rootNode.parentKey = null;
        rootNode.showChevronButton = currentNode[this.loadDataWrapper.relationshipName]?.totalSize > 0;
        rootNode.show = true;
        rootNode.expanded = autoExpand;
        rootNode.ariaExpanded = autoExpand;
        rootNode.childrenLoaded = false;

        rootNode.values.forEach((fw, index) => {
            const isFirst = index === 0;
            fw.first = isFirst;
            fw.style = (fw.style || '') + (isFirst ? 'display: table-cell;' : '');
            fw.class = (fw.class || '') + (isFirst ? ' slds-tree__item' : '');
            if (fw.isNameField) fw.link = '/' + rootNode.Id;
        });

        this.records.push(rootNode);
        if (autoExpand) {
            this.expandedNodes.add(rootNode.key);
            this.loadChildren(rootNode.key, rootNode.key, 2, index);
        }
    }
    // Processes children data from the Hierarchy Tree Apex Controller response and creates tree nodes
    processChildrenData(data, parentKey, level) {
        let newNodes = [];
        data.forEach(item => {
            let node = this.buildRow(item);
            node.key = item.Id;
            node.level = level;
            node.parentKey = parentKey;
            node.showChevronButton = item[this.loadDataWrapper.relationshipName]?.totalSize > 0;
            node.show = level === 1 || (parentKey && this.expandedNodes.has(parentKey));
            node.expanded = false;
            node.ariaExpanded = false;
            node.childrenLoaded = false;
            node.values.forEach((fw, index) => {
                const isFirst = index === 0;
                fw.first = isFirst;
                fw.style = (fw.style || '') + (isFirst ? 'display: table-cell;' : '');
                fw.class = (fw.class || '') + (isFirst ? ' slds-tree__item' : '');
                if (fw.isNameField) fw.link = '/' + node.Id;
            });
            newNodes.push(node);
        });

        if (parentKey) {
            let parentIndex = this.records.findIndex(node => node.key === parentKey);
            if (parentIndex !== -1) {
                this.records.splice(parentIndex + 1, 0, ...newNodes);
                this.records[parentIndex].showChevronButton = newNodes.length > 0;
                this.records[parentIndex].childrenLoaded = true;
            }
        } else {
            this.records = [...newNodes];
        }
        this.records = [...this.records];
        this.isLoading = false;
    }

    expandAndCollapse(event) {
        const nodeKey = event.currentTarget.dataset.recordid;
        const nodeIndex = this.records.findIndex(node => node.key === nodeKey);

        if (nodeIndex === -1) return;

        const node = this.records[nodeIndex];
        const isExpanding = !node.expanded;

        if (isExpanding) {
            this.expandedNodes.add(nodeKey);
            node.expanded = true;
            node.ariaExpanded = true;
            if (!node.childrenLoaded) {
                this.loadChildren(nodeKey, nodeKey, node.level + 1, nodeIndex);
            } else {
                this.showHideChildren(nodeKey, true);
            }
        } else {
            this.expandedNodes.delete(nodeKey);
            node.expanded = false;
            node.ariaExpanded = false;
            this.showHideChildren(nodeKey, false);
        }
        this.records = [...this.records];
    }

    loadChildren(hierarchyId, parentKey, level, parentIndex) {
        this.isLoading = true;
        const levelIndex = Math.max(0, level - 2);

        getChildrenHierarchy({
            recordId: hierarchyId,
            hierarchyParentField: this.initDataWrapper.gridSettingsManager.hierarchyParentField,
            relationshipName: this.loadDataWrapper.relationshipName,
            objectApiName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
            allFields: this.initDataWrapper.gridSettingsManager.ALL_FIELDS,
            levelIndex: levelIndex
        }).then((result) => {
            if (result) {
                const data = typeof result === 'string' ? JSON.parse(result) : result;
                if (Array.isArray(data) && data.length > 0) {
                    this.processChildrenData(data, parentKey, level);
                } else {
                    if (parentIndex !== undefined && this.records[parentIndex]) {
                        this.records[parentIndex].showChevronButton = false;
                        this.records[parentIndex].expanded = false;
                        this.records[parentIndex].ariaExpanded = false;
                        this.records[parentIndex].childrenLoaded = true;
                        this.expandedNodes.delete(parentKey);
                        this.records = [...this.records];
                    }
                    this.isLoading = false;
                }
            }
        }).catch((error) => {
            console.error('Load children error:', error);
            toastError(this, error);
            this.isLoading = false;
        });
    }

    showHideChildren(parentKey, show) {
        const parentLevel = this.records.find(node => node.key === parentKey)?.level || 0;
        for (const element of this.records) {
            const node = element;

            if (this.isChildOf(node, parentKey, parentLevel)) {
                if (show) {
                    const directParent = this.findDirectParent(node);
                    node.show = directParent ? directParent.expanded : true;
                } else {
                    node.show = false;
                    node.expanded = false;
                    node.ariaExpanded = false;
                    this.expandedNodes.delete(node.key);
                }
            }
        }
    }

    isChildOf(node, parentKey, parentLevel) {
        return node.level > parentLevel && this.hasAncestor(node, parentKey);
    }

    hasAncestor(node, ancestorKey) {
        let current = node;
        while (current.parentKey) {
            if (current.parentKey === ancestorKey) {
                return true;
            }
            current = this.records.find(n => n.key === current.parentKey);
            if (!current) break;
        }
        return false;
    }

    findDirectParent(node) {
        return this.records.find(n => n.key === node.parentKey);
    }

    // HANDLERS
    toggleSelectAllRecords(event) {
        const checked = event.detail.checked;
        this.selectedRecordIds = new Set();
        this.records.forEach(group => {
            group.records.forEach(item => {
                item.isSelected = checked;
                if (checked) {
                    this.selectedRecordIds.add(item.Id);
                }
            })
        })
    }

    toggleSelectRecord(event) {
        const id = event.target.dataset.id;
        const isChecked = event.detail.checked;
        if (isChecked) {
            if (!this.selectedRecordIds.has(id)) {
                this.selectedRecordIds.add(id);
            }
        } else {
            this.selectedRecordIds.delete(id);
        }
        this.records.forEach(group => {
            group.records.forEach(item => {
                if (item.Id == id) {
                    item.isSelected = isChecked;
                }
            });
        });
    }

    // SAVE AND EDIT FUNCTIONS
    handleFieldEdit(event) {
        try {
            const fieldName = event.target.dataset.fieldName;
            const id = event.target.dataset.id;
            let value;
            if (event.target.tagName?.toLowerCase() === 'select') {
                value = event.target.value;
            } else if (event.detail && event.detail.hasOwnProperty('checked')) {
                value = event.target.checked;
            } else if (event.detail && event.detail.hasOwnProperty('value')) {
                const raw = event.detail.value;
                value = (raw === null || raw === undefined || raw === '') ? '' : (Array.isArray(raw) ? raw.join(';') : raw);
            } else {
                value = event.target.value ?? null;
            }
            // Find the record across groups
            let item;
            for (const group of this.records) {
                item = (group.records || []).find(record => record.Id == id);
                if (item) break;
            }
            if (!item) return;
            item.record[fieldName] = value;
            this.applyFieldUpdate(item, { fieldName: fieldName, value: value });
            this.updateDependentPicklists(item, fieldName);
            this.refreshConditionalRules(item, fieldName);
        } catch (error) {
            console.log('handleFieldEdit:', error.message);
            console.log('handleFieldEdit:', error.body?.message);
        }
    }

    refreshConditionalRules(item, fieldName, withMessages = true) {
        for (const name of this.conditionalRulesMap[fieldName] || []) {
            const fw = item.values.find(v => v.fieldName === name);
            if (fw) fw.isDisabled = !!processControllerFields(this, item.record, fw, withMessages, fieldName);
        }
    }

    updateDependentPicklists(item, changedFieldName) {
        const dependentFieldName = this.picklistRelationshipMap[changedFieldName];
        if (!dependentFieldName) {
            return;
        }
        const dependentField = item.values.find(field => field.fieldName === dependentFieldName);
        if (!dependentField) {
            return;
        }
        const controllerValue = item.record[changedFieldName];
        const allowedOptions = this.dependentPicklistMap?.[dependentFieldName]?.[controllerValue] || [];
        dependentField.pickListValues = [{ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true }, ...allowedOptions.map(option => ({ label: option.label, value: option.value, isSelected: false }))];
        dependentField.fieldValue = '';
        dependentField.fieldOutputValue = '';
        item.record[dependentFieldName] = '';
        this.applyFieldUpdate(item, { fieldName: dependentFieldName, value: '' });
        this.updateDependentPicklists(item, dependentFieldName);
    }

    handleSave() {
        this.isLoading = true;
        this.records.flatMap(group => group.records || []).forEach(record => { record.hasError = false; });
        saveRecords({
            recordsToUpsertJSON: JSON.stringify(Object.values(this.recordsToUpsertMap)),
            partialSave: this.partialSave
        }).then(result => {
            if (result == 'SUCCESS') {
                showNotification(this, this.Labels.LBL_Success, this.saveSuccessMessage, 'success');
                if (self.refreshViewAfterSave) {
                    this.dispatchEvent(new RefreshEvent());
                }
                this.records = [];
                this.recordsToUpsertMap = {};
                this.loadData();
            } else {
                let resultMap = JSON.parse(result);
                let errorMessages = [];
                Object.keys(resultMap).forEach(key => {
                    const errorMsg = resultMap[key];
                    const index = Number(key);
                    if (!isNaN(index)) {
                        const mapKeys = Object.keys(this.recordsToUpsertMap);
                        key = mapKeys[index];
                        errorMessages.push(`Record ${index + 1}: ${errorMsg}`);
                    } else {
                        errorMessages.push(`Record ${key}: ${errorMsg}`);
                    }
                    const item = this.records.flatMap(group => group.records || []).find(record => record.Id == key);
                    item.hasError = true;
                    item.errorMessage = errorMsg;
                });
                this.records = [...this.records];
                const combinedMessage = errorMessages.join('\n');
                showNotification(this, this.Labels.LBL_Error, combinedMessage, 'error');
                this.isLoading = false;
            }
        }).catch(error => {
            this.isLoading = false;
            showNotification(this, this.Labels.LBL_Error, error, 'error');
            console.error(error);
        });
    }

    // MASS UPDATE FUNCTIONS
    toggleMassUpdatePanel(event) {
        try {
            let field = event.target.dataset.field;
            this.template.querySelectorAll('[data-updatefield]').forEach(element => {
                if (element.dataset.updatefield == field) {
                    element.classList.toggle('slds-hide');
                } else {
                    element.classList.add('slds-hide');
                }
            });
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    // section : Sticky Header DropDown Handlers
    handleEnterHasDropDownElementSticky(event) {
        let closestTd = event.target.closest("td");
        for (var elem of this.template.querySelectorAll('.stickyTD')) {
            elem.style.zIndex = 3;
        }
        if (closestTd.style.position == 'sticky') {
            closestTd.style.zIndex = 5;
        }
    }

    massUpdateHandler(event) {
        try {
            const { value } = event.target;
            const { index, fieldName, fieldDependancy, fieldDependancyIndex } = event.target.dataset;
            const field = index !== undefined ? this.displayedFields[index] : null;
            if (!field) return;
            if (fieldDependancy == 'controlledBy') {
                const startIndex = parseInt(fieldDependancyIndex);
                for (let i = startIndex + 1; i < field.controlledByFields.length; i++) {
                    const controlledField = field.controlledByFields[i];
                    const dependPicklistField = this.displayedFields.find(item => item.fieldName == controlledField.controlledByName);
                    controlledField.options = [];

                    if (dependPicklistField && i == startIndex + 1 && value) {
                        controlledField.disabled = false;
                        const dependentOptions = this.dependentPicklistMap?.[controlledField.controlledByName]?.[value];
                        if (dependentOptions) {
                            controlledField.options = dependPicklistField.pickListValues.filter(option => dependentOptions.some(item => item.value === option.value)).map(option => ({ label: option.label, value: option.value, isSelected: false }));
                            controlledField.options.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                        }
                    } else if (controlledField) {
                        controlledField.disabled = true;
                    }
                }
                field.controlledByFields.forEach(item => {
                    if (item.controlledByName == fieldName) item.value = value;
                });
            } else {
                field.massUpdateValue = value;
            }
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    handleApplyMassUpdate(event) {
        try {
            let fieldName = event.target.dataset.fieldName;
            let field = this.displayedFields.find(item => item.fieldName == fieldName);
            if (this.selectedRecordIds.size == 0) {
                toastWarning(this, Labels.MSG_No_Items_Selected);
                return;
            }
            this.records.flatMap(group => group.records).filter(item => item.isSelected).forEach((item, index) => {
                let value = field.isPicklist ? (field.massUpdateValue || field.pickListValues[0].value) : field.massUpdateValue;
                if (!field.hasDependentPicklist) {
                    item.record[field.fieldName] = value;
                    this.applyFieldUpdate(item, { fieldName: field.fieldName, value: value });
                    this.refreshConditionalRules(item, field.fieldName, index === 0);
                } else {
                    if (field.controllerPicklistField?.controllerName) {
                        this.applyFieldUpdate(item, { fieldName: field.controllerPicklistField.controllerName, value: field.controllerPicklistField.massUpdateValue });
                    }
                    if (field.controlledByFields) {
                        field.controlledByFields.forEach(controlledField => {
                            this.applyFieldUpdate(item, { fieldName: controlledField.controlledByName, value: controlledField.value });
                        })
                    }
                }
            });
            this.template.querySelectorAll('[data-updatefield]').forEach(element => {
                element.classList.add('slds-hide');
            })
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    applyFieldUpdate(item, field) {
        let obj;
        if (this.recordsToUpsertMap.hasOwnProperty(item.Id)) {
            obj = this.recordsToUpsertMap[item.Id];
        } else {
            obj = {
                attributes: {
                    type: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                }
            };
            if (!item.Id.startsWith('TEMP-')) {
                obj.Id = item.Id;
            }
        }
        obj[field.fieldName] = field.value;
        this.recordsToUpsertMap[item.Id] = obj;
        const fieldEntry = item.values.find(v => v.fieldName == field.fieldName);
        if (fieldEntry) {
            if (fieldEntry.isMultiPicklist) {
                const joined = Array.isArray(field.value) ? field.value.join(';') : field.value;
                fieldEntry.fieldValue = joined;
                fieldEntry.selectedValues = joined ? joined.split(';') : [];
            } else {
                fieldEntry.fieldValue = field.value;
            }
        }
    }

    // HEADER FILTER FUNCTIONS
    toggleHeaderFilter(event) {
        try {
            let fieldName = event.target.dataset.field;
            let type = event.target.dataset.type;
            let dropDpwnElt = this.template.querySelector('[data-filter-field="' + fieldName + '"]');
            dropDpwnElt.classList.toggle('slds-hide');
            this.filterableFieldsAll.forEach(field => {
                if (field.fieldName != fieldName && field.isFilterable) {
                    let dropDpwnEltToHide = this.template.querySelector('[data-filter-field="' + field.fieldName + '"]');
                    dropDpwnEltToHide?.classList.add('slds-hide');
                    if (field.initFilterValue != '') {
                        field.filterValue = { ...field.initFilterValue };
                        field.initFilterValue = '';
                    }
                } else if (field.fieldName == fieldName) {
                    if (field.initFilterValue == '') {
                        field.initFilterValue = { ...field.filterValue };
                    } else {
                        if (type != 'apply') {
                            field.filterValue = { ...field.initFilterValue };
                        }
                        field.initFilterValue = '';
                    }
                    if (type == 'reset') {
                        field.filterValue = { values: [], value1: '', value2: '', searchValue: '' };
                        field.initFilterValue = '';
                        field.hasFilter = false;
                    }
                }
            });
            if (type) {
                this.filters.dynamic = JSON.stringify(this.buildDynamicFilter());
                this.pageNumber = 1;
                this.loadData();
            }
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }
    // builds the dynamic filter
    buildDynamicFilter() {
        return this.initDataWrapper?.gridSettingsManager?.FILTERS
            .map(field => this.filterableFieldsAll.find(headerField => headerField.fieldName === field.fieldName && headerField.hasFilter) || field)
            .filter(field => field.hasFilter)
            .map(field => {
                const item = { fieldName: field.fieldName };
                const values = (field.filterValue.values || []).filter(v => v !== '' && v !== null && v !== undefined);
                if (values.length > 0) {
                    item.values = values;
                }
                if (field.filterValue.value1) {
                    item.value1 = field.filterValue.value1;
                }
                if (field.filterValue.value2) {
                    item.value2 = field.filterValue.value2;
                }
                return item;
            })
            .filter(item => item.hasOwnProperty('values') || item.hasOwnProperty('value1') || item.hasOwnProperty('value2'));
    }

    handleChangeFilter(event) {
        const value = event.detail.value;
        const fieldName = event.target.dataset.field;
        const field = this.filterableFieldsAll.find(f => f.fieldName === fieldName);
        const rangeKey = event.target.dataset.range;
        if (!field) return;
        if (!rangeKey) {
            field.filterValue.values = Array.isArray(value) ? value : [value];
            field.filterValue.searchValue = Array.isArray(value) ? value.join(';') : value;
        } else {
            field.filterValue[rangeKey] = value;
        }
        field.hasFilter = true;
    }

    //RIGHT HAND FILTER
    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }

    confirmFilterSettings(event) {
        try {
            const fields = JSON.parse(event.detail.value);
            fields.forEach(item => {
                const field = this.initDataWrapper?.gridSettingsManager?.FILTERS.find(f => f.fieldName === item.fieldName);
                if (!field) return;
                field.filterValue = {
                    value1: item.value1 || '',
                    value2: item.value2 || '',
                    values: item.values || []
                };
                field.hasFilter = !!(item.value1 || item.value2 || (item.values && item.values.length > 0));
            });
            this.displayedFields = [...this.displayedFields];
            this.isFilterOpen = false;
            this.filters.dynamic = JSON.stringify(this.buildDynamicFilter());
            this.pageNumber = 1;
            this.loadData();
        } catch (error) {
            console.log('confirmFilterSettings:', error.message);
            console.log('confirmFilterSettings:', error.body?.message);
        }
    }

    fixedColumnsChanged(event) {
        this.numberFixedColumns = Number(event.detail.value);
        this.setSticky();
    }

    // SORTING FUNCTIONS
    changeSortDirection(event) {
        try {
            let fieldName = event.target.dataset.field;
            if (this.sortConfig.sortFieldApi?.startsWith(fieldName)) {
                this.sortConfig.sortDirection = this.sortConfig.sortDirection == 'ASC' ? 'DESC' : 'ASC';
            } else {
                this.sortConfig.sortDirection = 'ASC';
            }
            this.sortConfig.sortFieldApi = fieldName;
            this.displayedFields.forEach(f => {
                f.sortedField = f.fieldName == this.sortConfig.sortFieldApi;
            });
            if (this.groupedField) {
                this.groupedField = { ...this.groupedField, sortedField: this.groupedField.fieldName == this.sortConfig.sortFieldApi };
            }
            this.loadData();
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    // FLOW FUNCTIONS
    toggleFlow(event) {
        try {
            if (!this.openFlow) {
                let flowName = event.target.dataset.flowName;
                let flowLabel = event.target.dataset.flowLabel;
                this.isLoading = true;
                this.currentFlow = {
                    header: flowLabel,
                    flowApiName: flowName,
                    flowVariables: []
                }
                if (this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows) {
                    let matchedFlow = this.initDataWrapper.gridSettingsManager.actions.screenFlows.filter(flow => flow.value == flowName);
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
                                value: [...this.selectedRecordIds]
                            })
                        }
                    }
                }
            }
            this.openFlow = !this.openFlow;
            this.isLoading = false;
        } catch (error) {
            console.log(JSON.stringify(error))
        }
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === "FINISHED") {
            toastSuccess(this, event.detail.status);
            this.openFlow = !this.openFlow;
            this.currentFlow = {};
            this.loadData();
        }
        if (event.detail.status === "ERROR") {
            toastError(this, event.detail.status);
        }
    }

    // EXPORT FUNCTIONS

    // EXPORT EXCEL
    // Initiates the Excel export process.
    handleExportExcel() {
        this.allRecordsToExport = [];
        this.exportExcelRowCounter = 0;
        this.totalExportSize = 0;
        try {
            this.isLoading = true;
            this.exportExcel(null);
        } catch (error) {
            showNotification(this, this.Labels.LBL_Error, error, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    exportExcel(nextRecordsUrl) {
        processRestForExcel({
            recordId: this.recordId,
            gridSettings: JSON.stringify(this.initDataWrapper.gridSettingsManager),
            restURL: nextRecordsUrl,
        }).then((result) => {
            try {
                let parsedResult = JSON.parse(result);
                if (parsedResult.error != null) {
                    showNotification(this, this.Labels.LBL_Error, error.body?.message, 'error');
                    return;
                }
                if (parsedResult.hasOwnProperty('done')) {
                    if (parsedResult.totalSize != null) {
                        this.totalExportSize = parsedResult.totalSize;
                    }
                    if (parsedResult.records) {
                        this.allRecordsToExport.push(...parsedResult.records);
                    }
                    if (parsedResult.done) {
                        this.buildExcel();
                    } else {
                        this.exportExcel(parsedResult.nextRecordsUrl);
                    }
                }
            } catch (error) {
                showNotification(this, this.Labels.LBL_Error, error.body?.message, 'error');
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.isLoading = false;
            }
        }).catch((error) => {
            showNotification(this, this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        });
    }

    async buildExcel() {
        this.isLoading = true;
        this.showFileGenerationBar = true;
        const dataToExport = this.buildData(this.allRecordsToExport, true) || [];
        const yieldEvery = Math.max(1, Math.floor((this.totalExportSize || 1) / 100));
        try {
            const workbook = new ExcelJS.Workbook();
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet(this.templateName || 'Export');
            const isGrouped = this.isGrouped;
            const headerStyles = [];
            // Normalize displayed fields
            const fields = (this.displayedFields.filter(field => !field.isNotExportable && !field.isHidden) || []);
            const border = {
                top: { style: 'thin', color: { argb: 'FFE6E6E6' } },
                left: { style: 'thin', color: { argb: 'FFE6E6E6' } },
                bottom: { style: 'thin', color: { argb: 'FFE6E6E6' } },
                right: { style: 'thin', color: { argb: 'FFE6E6E6' } }
            };
            const groupHeaderLabel = this.initDataWrapper.gridSettingsManager.groupedField || 'Group';
            let allFields = fields.map(field => field.fieldName);
            const hasIdCol = !allFields.includes('Id') && this.allowImport;
            const columns = [];
            if (isGrouped) {
                columns.push({
                    header: groupHeaderLabel,
                    key: '__group__',
                    width: 28,
                    style: { numFmt: '@' }
                });
                headerStyles.push(this.groupedField.headerStyle);
            }
            //fields Name
            if (!allFields.includes('Id') && this.allowImport) {
                columns.push({ header: 'Id', key: 'Id', width: 10, style: {}, hidden: true });
                headerStyles.push('');
            }
            fields.forEach(field => {
                headerStyles.push(field.headerStyle);
                let newItem = {
                    header: field.fieldName,
                    key: field.fieldName,
                    width: Math.max((field.fieldLabel || field.fieldName || '').length, 12),
                    style: {}
                };
                if (field.isNumber) {
                    newItem.style.numFmt = '0';
                    if (field.scale) {
                        newItem.style.numFmt += '.';
                        for (let index = 0; index < field.scale; index++) {
                            newItem.style.numFmt += '0';
                        }
                    }
                    if (field.isPercent) {
                        newItem.style.numFmt += '"%"';
                    }
                } else if (field.isBoolean || field.isDate || field.isDateTime) {
                    newItem.style.numFmt = undefined;
                } else {
                    newItem.style.numFmt = '@';
                }
                field.numFmt = newItem.style.numFmt;
                columns.push(newItem);
            });
            worksheet.columns = columns
            let newRow = [];
            if (isGrouped) {
                newRow.push(this.groupedField?.fieldLabel || 'Group');
            }
            if (!allFields.includes('Id') && this.allowImport) {
                newRow.push('Id');
            }
            fields.forEach(field => {
                newRow.push(field.fieldLabel);
            });
            worksheet.addRow(newRow);
            worksheet.getRow(1).hidden = true;
            const headerRow = worksheet.getRow(2);
            headerRow.height = 28;
            headerRow.eachCell((cell, colNumber) => {
                const headerIndex = colNumber - 1;
                const style = headerStyles[headerIndex] || '';
                const bgMatch = style.match(/(?:^|;)\s*background-color:\s*#([0-9a-fA-F]{6})/);
                const colorMatch = style.match(/(?:^|;)\s*color:\s*#([0-9a-fA-F]{6})/);
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: bgMatch ? bgMatch[1] : 'FFE6E6E6' },
                };
                cell.font = {
                    bold: true,
                    color: { argb: colorMatch ? colorMatch[1] : 'FF000000' },
                    size: 11
                };
                cell.border = border;
                cell.alignment = {
                    vertical: 'middle',
                    horizontal: 'center',
                    wrapText: true
                };
            });
            worksheet.views = [{ state: 'frozen', ySplit: 2 }];
            worksheet.autoFilter = {
                from: { row: 2, column: 1 },
                to: { row: 2, column: columns.length }
            };
            let currentRow = isGrouped ? 3 : 2;
            for (const group of dataToExport) {
                const records = group.records || [];
                // If rowspan > records.length, blank rows are added so merge won't fail.
                const totalRows = Math.max(records.length, 1);
                const startRow = currentRow;
                for (let i = 0; i < totalRows; i++) {
                    this.exportExcelRowCounter++;
                    const record = records[i] ? this.buildRow(records[i]) : {};;
                    const rowValues = [];
                    const cellStyles = [];
                    if (isGrouped) {
                        rowValues.push(i === 0 ? group?.groupName ?? '' : '');
                    }
                    if (!allFields.includes('Id') && this.allowImport) {
                        rowValues.push(record.Id ?? '');
                    }
                    for (let value of record.values) {
                        if (!value.isHidden && !value.isNotExportable) {
                            if (value.isBoolean) {
                                value.fieldValue == true ? rowValues.push('✓') : rowValues.push('✗')
                            }
                            else if (value.isDate && value.fieldValue != null) {
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
                            cellStyles.push(value.style || '');
                        }
                    }
                    const row = worksheet.addRow(rowValues);
                    if (this.exportExcelRowCounter % yieldEvery === 0 || this.exportExcelRowCounter == this.totalExportSize) {
                        this.fileGenerationValue = (this.exportExcelRowCounter / this.totalExportSize) * 100;
                        await new Promise(resolve => setTimeout(resolve, 0));
                    }
                    row.height = 24;
                    row.eachCell({ includeEmpty: true }, (cell, colNumber) => {
                        const cellIndex = colNumber - 1 - (hasIdCol ? 1 : 0) - (isGrouped ? 1 : 0);
                        const style = cellStyles[cellIndex] || '';
                        // Color matches
                        const bgMatch = style.match(/(?:^|;)\s*background-color:\s*#([0-9a-fA-F]{6})/);
                        const colorMatch = style.match(/(?:^|;)\s*color:\s*#([0-9a-fA-F]{6})/);
                        // Font matches
                        const fontWeightMatch = style.match(/(?:^|;)\s*font-weight:\s*(\w+)/i);
                        const fontSizeMatch = style.match(/(?:^|;)\s*font-size:\s*(\d+)px/i);
                        const fontStyleMatch = style.match(/(?:^|;)\s*font-style:\s*(\w+)/i);
                        const textDecorationMatch = style.match(/(?:^|;)\s*text-decoration:\s*([^;]+)/i);
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
                        cell.border = border;
                        cell.alignment = {
                            vertical: 'middle',
                            horizontal: isGrouped && colNumber === 1 ? 'center' : 'left',
                            wrapText: true
                        };
                        if (cell.value instanceof Date) {
                            cell.numFmt = 'yyyy-mm-dd hh:mm';
                        }
                    });
                    currentRow++;
                }
                if (isGrouped) {
                    const endRow = startRow + totalRows - 1;
                    if (endRow > startRow) {
                        worksheet.mergeCells(startRow, 1, endRow, 1);
                    }
                    const mergedCell = worksheet.getCell(startRow, 1);
                    mergedCell.alignment = {
                        vertical: 'middle',
                        horizontal: 'center',
                        wrapText: true
                    };
                    mergedCell.font = {
                        bold: true,
                        size: 11,
                        color: { argb: 'FF000000' }
                    };
                    mergedCell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: 'FFF7F7F7' }
                    };
                    mergedCell.border = border;
                }
            }
            // Set column widths
            const widths = [
                ...(isGrouped ? [28] : []),
                ...fields.map(() => 20)
            ];
            widths.forEach((width, index) => {
                worksheet.getColumn(index + 1).width = width;
            });
            this.showFileGenerationBar = false;
            this.showFileDownloadBar = true;
            window.wb = workbook;
            this.fileDownloadValue = 75;
            workbook.xlsx.writeBuffer().then(result => {
                // Replace the long restricted type with octet-stream
                const blob = new Blob([result], { type: 'application/octet-stream' });
                const downloadElement = document.createElement('a');
                downloadElement.style = 'display: none';
                downloadElement.href = window.URL.createObjectURL(blob);
                downloadElement.download = this.templateName + '.xlsx'; // The extension forces Excel to read it
                this.fileDownloadValue = 100;
                document.body.appendChild(downloadElement);
                downloadElement.click();
                document.body.removeChild(downloadElement);
                this.isLoading = false;
                this.fileGenerationValue = 0;
                this.exportExcelRowCounter = 0;
                this.fileDownloadValue = 0;
                this.showFileDownloadBar = false;
            });
        } catch (error) {
            console.error('Excel export failed:', error);
            this.isLoading = false;
            this.fileGenerationValue = 0;
            this.exportExcelRowCounter = 0;
            this.fileDownloadValue = 0;
            this.showFileDownloadBar = false;
            this.showFileGenerationBar = false;
        }
    }

    // IMPORT FUNCTIONS
    toggleImportPopup() {
        this.fileInfos = {
            file: '',
            fileName: '',
        };
        this.openImportPopup = !this.openImportPopup;
    }

    // NORMAL IMPORT FUNCTIONS
    handleFileSelect(event) {
        var files = event.target.files;
        this.fileInfos = {
            file: files[0],
            fileName: files[0].name,
        }
    }

    handleConfirmImport(event) {
        if (this.advancedImportSettings) {
            this.prepareAdvancedImportFile()
        } else {
            this.isLoading = true;
            let fieldsMap = {};
            this.displayedFields.forEach(f => fieldsMap[f.fieldName] = f);
            var reader = new FileReader();
            reader.onload = event => {
                var data = event.target.result;
                try {
                    var workbook = XLSX.read(data, {
                        type: 'binary'
                    });
                    Object.keys(workbook.Sheets).forEach(sheetName => {
                        var XL_row_object = XLSX.utils.sheet_to_row_object_array(workbook.Sheets[sheetName], {
                            raw: true
                        });
                        XL_row_object.forEach((rec, recIndex) => {
                            Object.keys(rec).forEach(key => {
                                if (fieldsMap[key]) {
                                    if (recIndex > 0 && rec[key] != undefined && rec[key] != '' && rec[key] != null) {
                                        if (fieldsMap[key].isDate) {
                                            let currentDate = this.excelDateToJSDate(rec[key]);
                                            rec[key] = currentDate.getFullYear() + '-' + (currentDate.getMonth() + 1) + '-' + currentDate.getDate();
                                        } else if (fieldsMap[key].isBoolean) {
                                            let currentVal = rec[key];
                                            if (currentVal == '✓' || currentVal.toLowerCase() == 'true' || currentVal == '1' || currentVal.toLowerCase() == 'yes' || currentVal.toLowerCase() == 'y') {
                                                rec[key] = 'true';
                                            } else if (currentVal == '✗' || currentVal.toLowerCase() == 'false' || currentVal == '0' || currentVal.toLowerCase() == 'no' || currentVal.toLowerCase() == 'n') {
                                                rec[key] = 'false';
                                            }
                                        } else if (fieldsMap[key].isPicklist) {
                                            let currentVal = rec[key];
                                            for (let pickVal of fieldsMap[key].pickListValues) {
                                                if (currentVal == pickVal.label) {
                                                    rec[key] = pickVal.value;
                                                }
                                            }
                                        } else if (fieldsMap[key].isMultiPicklist) {
                                            let currentVal = rec[key];
                                            let apiValues = [];
                                            for (let selectedVal of currentVal.split(';')) {
                                                for (let pickVal of fieldsMap[key].pickListValues) {
                                                    if (selectedVal == pickVal.label) {
                                                        apiValues.push(pickVal.value);
                                                    }
                                                }
                                            }
                                            rec[key] = apiValues.join(';');
                                        }
                                    }
                                }
                            })
                        })
                        let data = JSON.stringify(XL_row_object);
                        this.importedJSONData = data;
                        this.handleImportRecords();
                    });
                } catch (err) {
                    toastError(this, ' ' + (err && err.body && err.body.message ? err.body.message : err));
                }
                this.isLoading = false;
            };
            reader.onerror = (ex) => {
                toastError(this, this.Labels.LBL_Error_While_Reading_The_File + ex.message);
            };
            reader.readAsBinaryString(this.fileInfos.file);
        }
    }

    excelDateToJSDate(excelDate) {
        const baseDate = new Date(Date.UTC(1899, 11, 30)); // Excel base date
        return new Date(baseDate.getTime() + excelDate * 24 * 60 * 60 * 1000);
    }

    handleImportRecords() {
        this.openImportPopup = false;
        let fieldsToImport = this.displayedFields.filter(field => !field.isNotExportable).map(item => item.fieldName);
        if (!fieldsToImport.includes('Id')) {
            fieldsToImport.unshift('Id');
        }
        this.isLoading = true;
        importRecords({
            objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
            xlsData: this.importedJSONData,
            fieldsToImport: fieldsToImport,
            parentId: this.recordId,
            lookupName: this.initDataWrapper.gridSettingsManager.relationName
        }).then(result => {
            toastSuccess(this, this.Labels.LBL_Import_Finish);
            this.loadData();
        }).catch(error => {
            this.isLoading = false;
            console.log('error >>> ' + JSON.stringify(error))
            toastError(this, ' ' + (error && error.body && error.body.message ? error.body.message : error));
        });
    }

    // ADVANCED IMPORT FUNCTIONS
    // Called by the modal's Import button; triggers c-import-settings to read the selected file
    prepareAdvancedImportFile() {
        const child = this.template.querySelector('c-import-settings');
        if (child) {
            child.prepareFile();
        }
    }

    // Called when c-import-settings dispatches 'getfileid' (after the file is uploaded as a ContentVersion)
    handleAdvancedGetFileId(event) {
        this.advancedImportFileDirectoryId = event.detail.fileDirectoryId;
    }

    confirmAdvancedImportExcel(event) {
        try {
            this.isLoading = true;
            let advancedImportedRecords = JSON.parse(event.detail.value);
            let advancedImportFileData = event.detail.fileData;
            importRecordsAdvanced({
                objectName: this.advancedImportSettings.objectName,
                recordsToUpsert: JSON.stringify(advancedImportedRecords),
                fileName: advancedImportFileData?.fileName,
                fileDirectoryId: this.advancedImportFileDirectoryId,
                recordId: this.recordId || null,
                externalIdField: this.advancedImportSettings.externalIdField
            }).then(batchId => {
                if (batchId != null) {
                    let nIntervId = setInterval(() => {
                        checkAndGetOutcome({ batchJobId: batchId }).then(outcome => {
                            if (outcome == null) return;
                            clearInterval(nIntervId);
                            if (outcome.hasOwnProperty('hasError') && outcome.hasError) {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: this.Labels.LBL_Import_Failed,
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
                                this.openImportPopup = false;
                            } else {
                                showNotification(this, this.Labels.LBL_Success, this.Labels.LBL_Import_Finish, 'success');
                                this.openImportPopup = false;
                                this.loadData();
                            }
                        });
                        this.isLoading = false;
                    }, 3000);
                }
            }).catch(error => {
                showNotification(this, this.Labels.LBL_Error, error?.body?.message, 'error');
                console.error('Import error:', error);
            });
        } catch (error) {
            console.error('Unexpected error:', error);
            showNotification(this, this.Labels.LBL_Error, error?.body?.message || error?.message, 'error');
        }
    }

    //PAGINATION
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

    // PROPERTIES
    stripWidthStyles(styleString) {
        if (!styleString) return '';
        return styleString.split(';').map(s => s.trim()).filter(s => !/^(min-width|max-width|width)\s*:/i.test(s)).filter(s => s.length > 0).map(s => s + ';').join(' ');
    }

    //GLOBAL SEARCH FUNCTIONS
    handleSearch(event) {
        this.pageNumber = 1;
        if (event.type == 'keypress' && this.filters.searchTerm && (event.which == 13 || event.keyCode == 13)) {
            this.loadData();
            event.target.blur();
        } else if (event.type == 'commit') {
            this.filters.searchTerm = event.target.value;
            this.loadData();
        }
    }

    // ADD NEW RECORD FUNCTIONS
    handleAddNewRecord() {
        let objectName = this.initDataWrapper?.gridSettingsManager?.OBJECT_NAME || undefined;
        if (objectName) {
            var defaultValues = "";
            if (this.recordId) {
                let masterRelationName = this.initDataWrapper?.gridSettingsManager.relationName;
                let defaultMasterLookupField = {};
                defaultMasterLookupField[masterRelationName] = this.recordId;
                let fields = this.initDataWrapper?.gridSettingsManager?.GRID_FIELDS || [];
                for (let field of fields) {
                    if (field.defaultType != null) {
                        defaultMasterLookupField[field.fieldName] = this.resolveFieldValue(field, this.displayedFields)
                    }
                }
                try {
                    defaultValues = encodeDefaultFieldValues(defaultMasterLookupField);
                } catch (error) {
                    console.error('error ' + error);
                }
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: objectName,
                    actionName: 'new',
                },
                state: {
                    useRecordTypeCheck: 1,
                    navigationLocation: 'RELATED_LIST',
                    defaultFieldValues: defaultValues
                }
            });
            this.createdRecord = true;
        } else {
            showNotification(this, this.Labels.LBL_Error, 'can not create new record of type undefined', 'error');
        }
    }

    // INLINE NEW RECORD FUNCTIONS
    handleAddNewInlineRecord() {
        try {
            const gridSettings = this.initDataWrapper.gridSettingsManager;
            const newRecord = { attributes: { type: gridSettings.OBJECT_NAME } };
            if (this.recordId) {
                newRecord[gridSettings.relationName] = this.recordId;
            }
            let newItem = this.buildRow(newRecord);
            let group = {
                key: Date.now(),
                groupId: '',
                groupName: '',
                groupAsInput: true,
                records: [newItem],
            };
            this.records.push(group);
        } catch (error) {
            console.log('ERROR:', error?.message || error);
            showNotification(this, this.Labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
        }
    }

    // CLONE FUNCTIONS
    cloneRecord(event) {
        try {
            let groupIndex = Number(event.target.dataset.groupIndex);
            let recordIndex = Number(event.target.dataset.recordIndex);
            let item = this.records[groupIndex].records[recordIndex];
            if (!item) return;
            let dbRecord = { ...item.record, Id: null };
            if (dbRecord) {
                this.fieldsToClearOnClone.forEach(fieldName => {
                    dbRecord[fieldName] = null;
                });
            }
            let clonedItem = this.buildRow(dbRecord);
            this.records[groupIndex].records.splice(recordIndex + 1, 0, clonedItem);
            for (let fieldName of Object.keys(dbRecord)) {
                if (!this.fieldsToClearOnClone.includes(fieldName)) {
                    this.applyFieldUpdate(clonedItem, { fieldName: fieldName, value: dbRecord[fieldName] });
                }
            }
        } catch (error) {
            console.log('ERROR:: ' + error.message);
        }
    }

    handleSubscription() {
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('New message received: ', JSON.stringify(response));
            if (this.createdRecord/* && response.data.payload.OwnerId == userId*/) {
                this.loadData();
            }
        };
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback.bind(this)).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
        onError(error => {
            console.error('Server Error--->' + JSON.stringify(error));
        });
    }

    // DELETE FUNCTIONS
    toggleDeletePopUp(event) {
        let type = event.target.dataset.type;
        this.deletePopup.show = !this.deletePopup.show;
        if (this.deletePopup.show) {
            if (type == 'mass') {
                this.deletePopup.deleteIds = Array.from(this.selectedRecordIds);
            } else {
                let id = event.target.dataset.id;
                this.deletePopup.deleteIds = [id];
            }
        } else {
            this.deletePopup.deleteIds = []
        }
    }

    confirmDelete() {
        this.isLoading = true;
        if (this.deletePopup.deleteIds) {
            for (let itemId of this.deletePopup.deleteIds) {
                if (this.recordsToUpsertMap.hasOwnProperty(itemId)) {
                    delete this.recordsToUpsertMap[itemId];
                }
                if (this.selectedRecordIds.has(itemId)) {
                    this.selectedRecordIds.delete(itemId);
                }
            }
            this.deletePopup.deleteIds = this.deletePopup.deleteIds.filter(itemId => !itemId.startsWith('TEMP-'));
            deleteRecords({ recordsIds: this.deletePopup.deleteIds }).then(result => {
                let deleteResult = JSON.parse(result);
                if (deleteResult.isSuccess) {
                    toastSuccess(this, "Delete success");
                } else {
                    let errorKeys = Object.keys(deleteResult.errorMessages);
                    ids = ids.filter(id => !errorKeys.includes(id));
                    errorKeys.forEach(key => {
                        toastError(this, deleteResult.errorMessages[key]);
                    });
                }
                this.deletePopup.show = false;
                this.loadData();
            }).catch(error => {
                toastError(this, error);
            });
        }
    }

    // CANCEL
    cancelChangesHandler() {
        this.recordsToUpsertMap = {};
        this.selectedRecordIds = new Set();
        this.loadData();
    }

    // SHOW/HIDE COLUMNS FUNCTIONS
    toggleShowHideColumns() {
        this.showHideColumns = !this.showHideColumns;
        if (!this.showHideColumns) {
            this.selectedFields = [...this.initSelectedFields];
            this.initSelectedFields = [];
        } else {
            this.initSelectedFields = [...this.selectedFields];
        }
    }

    handleChangeSelectedFields(event) {
        this.selectedFields = event.detail.value;
    }

    confirmSelectionFields() {
        this.hiddenGridFields = [];
        for (let item of this.displayedFields) {
            if (!this.selectedFields.includes(`${item.fieldName} ${item.isInputField ? 'In' : 'Out'}`)) {
                const value = item.fieldName;
                const isInput = item.isInputField;
                this.hiddenGridFields.push({
                    fieldName: value,
                    isInputField: isInput
                });
            }
        }
        localStorage.setItem(this.templateName, JSON.stringify(this.hiddenGridFields));
        this.showHideColumns = !this.showHideColumns;
        this.buildDisplayedFields();
    }

    // STIKCY/RESIZING FUNCTIONS
    setSticky() {
        const table = this.template.querySelector('.initial-table');
        if (!table || this.numberFixedColumns == null || this.numberFixedColumns < 0) return;
        const groupedLeading = this.isGrouped ? 1 : 0;
        let utilityLeading = 0;
        if (this.allowSelectRecords) utilityLeading += 1;
        if (this.displayCloneButton) utilityLeading += 1;
        const fixedColumn = groupedLeading + utilityLeading + this.numberFixedColumns;
        // HEADER — also capture the grouped column's width (header cell 0 when grouped).
        const headRows = table.querySelectorAll('thead tr');
        let groupedColWidth = 0;
        let top = 0;
        for (let r = 0; headRows && r < headRows.length; r++) {
            const cells = headRows[r].children;
            let left = 0;
            for (let c = 0; cells && c < cells.length; c++) {
                const cell = cells[c];
                if (r === 0 && c === 0 && this.isGrouped) {
                    groupedColWidth = cell.offsetWidth; // width of the grouped column
                }
                if (c < fixedColumn) {
                    cell.style.position = 'sticky';
                    cell.style.left = left + 'px';
                    cell.style.zIndex = r === 0 ? 6 : 5;
                    left += cell.offsetWidth;
                } else {
                    cell.style.position = 'sticky';
                    cell.style.left = '';
                    cell.style.zIndex = r === 0 ? 5 : 4;
                }
                cell.style.top = top + 'px';
                if (r === 1 && this.hasTotalFields == true) {
                    cell.classList.add('slds-color__background_gray-4');
                    cell.classList.add('limited-cell');
                }
            }
            top += headRows[r].offsetHeight;
        }
        // BODY
        const tbody = table.querySelector('tbody');
        const rows = tbody ? tbody.rows : [];
        for (let r = 0; rows && r < rows.length; r++) {
            const cells = rows[r].children;
            const first = cells[0];
            const rowHasGroupedCell = this.isGrouped && !!(first && first.classList && first.classList.contains('grouped-cell'));
            const rowFixed = (this.isGrouped && !rowHasGroupedCell) ? fixedColumn - 1 : fixedColumn;
            let left = (this.isGrouped && !rowHasGroupedCell) ? groupedColWidth : 0;
            for (let c = 0; cells && c < cells.length; c++) {
                const cell = cells[c];
                if (c < rowFixed) {
                    cell.style.position = 'sticky';
                    cell.style.left = left + 'px';
                    cell.style.zIndex = 3;
                    left += cell.offsetWidth;
                    cell.classList.add('stickyTD');
                    if (!(cell.classList && cell.classList.contains('grouped-cell'))) {
                        cell.style.backgroundColor = rows[r].style.backgroundColor || cell.style.backgroundColor || '#FFFFFF';
                    } else {
                        if (!this.groupedField.style.includes('background-color')) {
                            cell.style.backgroundColor = '#FFFFFF';
                        }
                    }
                } else {
                    cell.style.position = '';
                    cell.style.left = '';
                    cell.style.zIndex = '';
                    cell.classList.remove('stickyTD');
                }
            }
        }
    }

    changeHeight = () => {
        try {
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBody = this.template.querySelector(".pageBody");
            if (pageHeader && pageBody) {
                if (this.cmpHeight) {
                    pageBody.style.height = this.cmpHeight;
                } else {
                    pageBody.style.height = (this.recordId ? (window.innerHeight - pageHeader.offsetHeight - 10) / 2 : window.innerHeight - pageHeader.offsetHeight - 10) + "px";
                }
                pageBody.style.width = "100%";
            }
            this.filterStyle = (this.cmpHeight ? 'height: ' + this.cmpHeight + '; min-height: ' + this.cmpHeight + ';' : 'height: ' + pageBody?.offsetHeight + 'px; min-height: 300px;') + ' width: 100%;';
            this.setSticky();
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            console.error(error.message)
            showNotification(this, this.Labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    };

    // UPLOAD FILE FUNCTIONS
    handleToggleInputFilePopup(event) {
        this.uploadFilePopup = !this.uploadFilePopup
        if (this.uploadFilePopup) {
            this.uploadFileConfig.record = event.target.dataset.id;
            if (!this.uploadFileConfig.record) {
                this.uploadFileConfig.index = Number(event.target.dataset.rowIndex);
            }
            this.uploadFileConfig.field.fieldName = event.target.dataset.fieldName;
            this.uploadFileConfig.field.fieldValue = event.target.dataset.fieldValue;
        } else {
            this.uploadFileConfig.field = {};
            this.uploadFileConfig.index = '';
            this.uploadFileConfig.record = '';
            this.selectedFile = {};
        }
    }

    handleFileUploadChange(event) {
        if (event.detail.files) {
            this.selectedFile = event.detail.files[0];
            let newFileUrl = this.initDataWrapper.baseUrl + '/sfc/servlet.shepherd/document/download/' + this.selectedFile.documentId;
            this.uploadFileConfig.field.fieldValue = newFileUrl;
            let recordKey;
            if (this.uploadFileConfig.record) {
                recordKey = this.uploadFileConfig.record;
            } else {
                recordKey = this.uploadFileConfig.index;
                this.uploadedFileMap[this.selectedFile.documentId] = recordKey;
            }
        } else {
            this.uploadFileConfig.field.fieldValue = event.target.value;
        }
    }

    handleSaveFileUpload() {
        let recordRow = this.uploadFileConfig.record ? this.uploadFileConfig.record : this.uploadFileConfig.index;
        const item = this.records.flatMap(group => group.records || []).find(record => record.Id === recordRow);
        this.applyFieldUpdate(item, { fieldName: this.uploadFileConfig.field.fieldName, value: this.uploadFileConfig.field.fieldValue });
        console.log('this.recordsToUpsertMap>>>>>> ' + JSON.stringify(this.recordsToUpsertMap));
        this.handleToggleInputFilePopup();
    }

    handleDeleteInputFilePopup(event) {
        let recordRow = event.target.dataset.id;
        let fieldName = event.target.dataset.fieldName
        const item = this.records.flatMap(group => group.records || []).find(record => record.Id === recordRow);
        this.applyFieldUpdate(item, { fieldName: fieldName, value: '' });
    }

    // LIST VIEW FUNCTIONS
    listViewChangeHandler(event) {
        this.templateName = event.target.value;
        this.initData();
    }

    // LIST VIEW ACTIONS FUNCTIONS
    async handleActionsChange(event) {
        if (this.selectedRecordIds.size === 0) {
            showNotification(this, this.Labels.LBL_Error, 'Choose at least one record', 'error');
            return;
        }
        let { url, linkType, label, pageId } = event.currentTarget.dataset;
        if (linkType === 'javascript' || (url || '').trim().toLowerCase().startsWith('javascript:')) {
            showNotification(this, this.Labels.LBL_Error, `${label}: JavaScript buttons are not supported`, 'error');
            return;
        }
        let finalUrl;
        if (!url && pageId) {
            try {
                const name = this.apexPageNames[pageId] ?? (this.apexPageNames[pageId] = await getApexPageName({ pageId }));
                if (!name) throw new Error('Apex page name not found for pageId: ' + pageId);
                const fields = this.filterableFieldsAll.filter(f => !f.isHidden).map(f => f.fieldName);
                finalUrl = `/apex/${name}?object=${this.initDataWrapper.gridSettingsManager.OBJECT_NAME}&selectedFields=${fields.join(',')}&selectedIds=${[...this.selectedRecordIds]}`;
            } catch (error) {
                showNotification(this, this.Labels.LBL_Error, error?.body?.message || error?.message, 'error');
                return;
            }
        } else {
            finalUrl = this.resolveMergeFields(url);
            const ids = Array.from(this.selectedRecordIds).filter(id => !id.startsWith('TEMP-'));
            if (ids.length) {
                const idsQueryParam = ids.map(id => `ids=${encodeURIComponent(id)}`).join('&');
                finalUrl += (finalUrl.includes('?') ? '&' : '?') + idsQueryParam;
            }
        }
        if (!finalUrl) return;
        const a = document.createElement('a');
        a.href = this.initDataWrapper.baseUrl + finalUrl;
        a.target = '_blank';
        a.rel = 'noopener';
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }
    // Replaces {!Source.Field}: {!$User.Id}, {!$Site.BaseUrl}, {!BusinessUnit__c.Id}, {!Supplier__r.Name}...
    resolveMergeFields(url) {
        return url.replace(/\{!\s*([\w$]+)\.([\w.]+)\s*\}/g, (token, source, path) => {
            let value;
            if (source === '$User') {
                value = path === 'Id' ? USER_ID : null;
            } else if (source === '$Site' || source === '$Api') {
                value = this.initDataWrapper?.baseUrl;
            } else if (path === 'Id') {
                value = this.recordId ?? this.bannerRecord?.Id ?? Array.from(this.selectedRecordIds).find(id => !id.startsWith('TEMP-'));
            } else {
                value = path.split('.').reduce((obj, key) => obj?.[key], this.bannerRecord);
            }
            return value == null ? '' : encodeURIComponent(value);
        });
    }
}