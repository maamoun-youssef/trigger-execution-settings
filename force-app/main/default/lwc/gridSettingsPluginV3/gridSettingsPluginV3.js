import { LightningElement, api, track, wire } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi'; // EMP API (Platform Events / CDC)
import GridSettings from '@salesforce/resourceUrl/GridSettings'; // Static resource for custom CSS
import { toastWarning, toastError, toastSuccess, Labels, incrementFormat } from "c/gridSettingsHelper";
import userId from '@salesforce/user/Id';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import USER_LOCALE from '@salesforce/i18n/locale';
import { ShowToastEvent } from "lightning/platformShowToastEvent"; // For showing toast notifications
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

// Static resources for external libraries (required for Excel export/import)
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import xlsx from "@salesforce/resourceUrl/xlsxLib";

// Apex methods (server-side operations)
import initData from "@salesforce/apex/GridSettingsPluginCmpControllerV2.initData";
import loadData from "@salesforce/apex/GridSettingsPluginCmpControllerV2.loadData";
import importRecords from "@salesforce/apex/GridSettingsPluginCmpControllerV2.importRecords";
import deleteRecords from "@salesforce/apex/GridSettingsPluginCmpControllerV2.deleteRecords";
import saveRecords from "@salesforce/apex/GridSettingsPluginCmpControllerV2.saveRecords";
import getTotalAggregation from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getTotalAggregation";
import getApiName from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getApiName";
import actionsMap from "@salesforce/apex/GridSettingsPluginCmpControllerV2.actionsMap";
import getFieldDependencies from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getFieldDependencies";
import getPicklistValuesByRecordTypeId from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getPicklistValuesByRecordTypeId";
import getTemplates from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getTemplates";
import attachFileToRecords from "@salesforce/apex/GridSettingsPluginCmpControllerV2.attachFileToRecords";
import getMasterInfoData from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getMasterInfoData";
import getChildrenHierarchy from "@salesforce/apex/GridSettingsPluginCmpControllerV2.getChildrenHierarchy";

// =============================================================================
// Constants
// =============================================================================

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

/**
 * @description Modal plugin component used to configure grid settings.
 * Allows users to choose visible fields, define column order, and configure options
 * such as page size and sorting. Emits `save` and `close` events.
 */
export default class GridSettingsPluginV3 extends NavigationMixin(LightningElement) {

    // ====================================================================
    // 3. PRIVATE PROPERTIES (Internal)
    // ====================================================================
    @api templateName; // Required to fetch grid settings
    @api includeInListView; // Contextual setting, determines behavior in a list view
    @api displayListViewActions; // Controls visibility of quick actions/screen flows
    @api displayNewButton; // Enables the standard 'New' button
    @api displayNewInlineButton; // Enables the 'New Inline' button
    @api displayCloneButton; // Enables the 'Clone' button (for a record or selected records)
    @api allowDelete; // Enables delete functionality
    @api displayShowHideColumns; // Enables the column visibility selector
    @api allowImport; // Enables data import from Excel
    @api allowExport; // Enables data export to Excel
    @api allowFilter; // Enables filtering functionality
    @api allowOpenRecord; // Enables clicking to open the record page
    @api nameAsURL; // Renders Name field as a hyperlink
    @api showCurrency; // Displays currency field in a specific format
    @api showCurrencyAsSymbol; // Displays currency as symbol instead of ISO code
    @api useRecordIsoCurrency; // Uses the parent record's currency for currency fields
    @api showSubTotal; // Enables display of subtotal rows/calculations
    @api isReadOnly; // Alternative read-only flag (resolved in connectedCallback)
    @api enableMassUpdate; // Enables mass update/inline editing
    @api refreshViewAfterSave; // Refreshes the standard view after a save (likely via RefreshEvent)
    @api partialSave; // Allows saving of valid records even if others fail
    @api saveSuccessMessage; // Custom success message after save
    @api labelNewInlineButton; // Custom label for the 'New Inline' button
    @api numberFixedColumns; // The number of columns to be 'sticky' on the left
    @api cmpHeight; // Component height
    @api filterOnNoneDisplayedFields; // Allows filtering on fields not currently displayed
    @api injectedFiltersConfig; // Configuration for filter injection (from parent component)

    // NOT USED
    @api quickActions; // List of quick action names (string)

    // (DEPRECATED)
    @api readOnly; // Forces the grid to be read-only
    @api applyNewDesign;
    @api actions; // General actions flag (potentially redundant with displayListViewActions)
    @api objectApiName; // Not used as per comment

    @api recordId; // ID of the parent record (if used in a record page context)
    // @api pluginIcon; // Icon name for the component header (unused)

    // ====================================================================
    // 4. COMPUTED GETTERS (Derived UI State)
    // ====================================================================
    @track displayLastTd = false;
    @track showHideColumns = false; // Controls visibility of the show/hide columns panel
    @track numberOfFixedColumns = 0; // Resolved value from numberFixedColumns
    @track initDataWrapper = { // Data structure for initial settings from Apex
        prefix: '',
        errorMessages: [],
        gridSettingsManager: undefined // Contains object metadata
    }
    @track displayedFields = []; // The processed column definitions
    @track records = []; // The processed records to display in the table
    @track tableLoading = false; // Specific loading spinner for the data table
    @track selectedActions = []; // Quick actions retrieved from grid settings
    @track selectedListViews = false;
    @track listViewOptions = [];
    @track listViewTemplateValue;
    @track displaylistView = false; // Determines if the list view arrow is shown
    @track selectedFields = []; // API names of currently selected/visible columns
    @track sortDirection; // Current sort direction
    // @track actionFlows = []; // Screen flow actions displayed as dropdown actions
    // Editing state
    @track recordsToUpdateMap = {}; // Map of records modified via inline edit, keyed by Id
    @track newRecords = []; // Array of newly created records (inline new)
    @track hasChanges = false; // Tracks if the grid is in edit mode
    // UI state
    @track firstThStyle = ''; // Style for the first column header (for sticky columns)
    @track headerLabels = {
        objectLabel: '',
        layoutLabel: '',
        iconName: '',
        layoutSlogan: ''
    };
    @track tableStyle = ''; // Dynamic style for the table (height, width)
    // Sorting popup state
    @track sortingPopupOpen = false;
    @track sortingFields = [];
    @track availableSortFields = [];
    // Screen Flow state
    @track openFlow = false; // Controls visibility of the Flow modal
    @track currentFlow = { // Details of the currently running flow
        header: '',
        flowApiName: '',
        flowVariables: '',
    }
    @track picklistRelationshipMap = {}; // Map of controlling field API names to dependent field API names
    // Excel export state
    @track showFileGenerationBar = false; // Controls visibility of the file generation progress bar
    @track showFileDownloadBar = false; // Controls visibility of the file download progress bar
    @track fileGenerationValue = 0; // Progress value for generation
    @track totalExportSize = 0; // Total number of records to export
    @track fileDownloadValue = 0; // Progress value for download
    // Excel import state
    @track openImportPopup = false; // Controls visibility of the import modal
    @track fileName = ''; // Name of the selected file
    // Pagination state
    @track pageNumber = 1;
    @track pageSize = null;
    // Selection state
    @track selectedRecordIds = []; // Array of selected record IDs
    // Clone state
    @track fieldToClearOnClone = [];
    // Delete confirmation popup state
    @track popups = {
        deletePopup: {
            isOpen: false,
            idsToDelete: [],
            // Toggles the delete confirmation popup and prepares the target record Id(s).
            togglePopup(event) {
                this.popups.deletePopup.isOpen = !this.popups.deletePopup.isOpen;
                if (this.popups.deletePopup.isOpen) {
                    const type = event.target.dataset.type;
                    if (type == 'Single') {
                        const id = event.target.dataset.id;
                        this.popups.deletePopup.idsToDelete.push(id)
                    } else {
                        // If 'Mass Delete' or action on selected records
                        this.popups.deletePopup.idsToDelete = this.selectedRecordIds;
                    }
                } else {
                    this.popups.deletePopup.idsToDelete = []; // Clear array on close
                }
            },
        }
    }
    // Subtotals / aggregations state
    @track subTotals = {};
    @track aggregationFields = [];
    @track hasTotalFields = false;
    @track uploadedFileMap = {};
    @track selectedFile = '';
    @track uploadFilePopup = false;
    @track currentUploadfileRecord;
    @track currentUploadfileField = {};
    // Tree grid & grouping state
    @track treeList = [];
    @track isTreeGrid = false;
    @track expandedNodes = new Set();
    @track isReferenceField = '';
    @track groupedFieldTh = {
        label: '',
        headerStyle: '',
        bodyStyle: ''
    };

    @track loadDataWrapper = { // Data structure for fetched records from Apex
        relationshipName: '',
        records: [],
        total: 0,
        query: '',
        gsm: undefined
    }

    // ====================================================================
    // 2b. INTERNAL STATE (Non-reactive)
    // ====================================================================
    warningMessages = []; // Array of warning messages to display
    displayedFieldsMap = {}; // Map for quick lookup of field definitions by API name
    masterObjectInfo = {};
    appliedSortConfig; // Last applied multi-column sort configuration
    apexMethodPromises = [];
    msgRowCounter = 0; // Counter for rows processed during export
    allRecordsToExport = [];// Stores all records fetched for export
    file; // The File object from the file input
    importedJSONData = {}; // The parsed JSON data from the Excel file
    // csvDateFormat; // TODO: Date formatting for CSV/Excel import (currently unused)
    rejectedRecords = [];
    sortFieldApi; // Current field being sorted
    Labels = Labels; // Helper labels/messages
    userLocal = USER_LOCALE;
    timeZone = TIME_ZONE;
    pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];
    originalValuesById = {}; // Map to store original field values for inline edit comparison
    currentUploadfileRecordIndex;
    // File upload state
    baseUrl = window.location.origin;
    createdRecord = false;
    subscription = {};
    channelName;
    vfPageName;
    // Filters (global / search)
    filters = {
        dynamic: '',
        searchTerm: ''
    }
    // Column header filters
    fieldsToFilterMap = {};
    filtersFieldsMap;
    dependentPicklistMap = {}; // Map of dependent picklist values
    availablePicklistValues = {}; // Map of available picklist values for fields


    // ====================================================================
    // 3. LIFECYCLE & RESOURCE LOADING
    // ====================================================================
    /**
     * connectedCallback
     * Initializes public flags, prepares UI state, loads external resources, then calls `initData()`.
     */
    connectedCallback() {
        // Boolean property resolution: ensures string values like 'false' or null/undefined are treated as booleans.
        // If the property is not explicitly set to a string 'true', it defaults to false.
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
        //
        this.tableLoading = true;
        this.tableStyle = 'width: 100%;' + (this.cmpHeight ? 'height: ' + this.cmpHeight + '; min-height: ' + this.cmpHeight + ';' : 'height: ' + this.template.querySelector('.initial-table')?.offsetHeight + 'px; min-height: 300px;');
        this.enableMassUpdate = ((this.enableMassUpdate || this.allowDelete) && !this.isReadOnly) || (this.displayListViewActions && this.selectedActions?.length > 0);
        this.displayCloneButton = this.displayCloneButton && !this.isReadOnly;
        this.allowImport = this.allowImport && !this.isReadOnly;
        this.allowDelete = this.allowDelete && !this.isReadOnly;
        this.displayNewButton = this.displayNewButton && !this.isReadOnly;
        this.displayNewInlineButton = this.displayNewInlineButton && !this.isReadOnlyisReadOnly;
        this.numberOfFixedColumns = this.numberFixedColumns != null && this.numberFixedColumns >= 0 && this.numberFixedColumns < 7 ? this.numberFixedColumns : 0;
        this.displayLastTd = this.allowDelete || this.allowOpenRecord;

        // Event listener for window resize to handle sticky columns
        window.addEventListener('resize', this.handleResize);

        // Load external JavaScript libraries (ExcelJS and js-xlsx) from static resources
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

        // Load custom CSS
        Promise.all([
            loadStyle(this, GridSettings + '/customStyle.css'),
        ]).then(() => { }).catch(error => {
            console.log("Error " + error.body.message);
        });

        this.initData();
        this.sortingFields = [];
    }
    /**
     * renderedCallback
     * Registers streaming subscription (EMP API) and applies sticky-column layout.
     */
    renderedCallback() {
        this.handleSubscription();
        this.setSticky();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, response => {
            console.log('Unsubscribed Channel');
        });
        this.createdRecord = false;
        window.removeEventListener('resize', this.handleResize);
    }
    /**
     * Subscribes to the EMP API channel to receive real-time updates.
     */
    handleSubscription() {
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('New message received: ', JSON.stringify(response));
            if (this.createdRecord && response.data.payload.OwnerId == userId) {
                this.initData();
            }
            // Response contains the payload of the new message received
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
    // ====================================================================
    // 4. INITIALIZATION & DATA FETCHING
    // ====================================================================
    // Calls Apex initData to fetch initial configuration data (GridSettingsManager).
    initData() {
        if (!this.templateName) return;
        this.tableLoading = true;
        this.hasChanges = false;
        this.pageNumber = 1;
        initData({
            recordId: this.recordId,
            templateName: this.templateName
        }).then(result => {
            this.initDataWrapper = JSON.parse(result);
            console.log("🚀 ~ GridSettingsPluginV3 ~ initData ~ result:", JSON.stringify(this.initDataWrapper))

            this.objectApiName = this.initDataWrapper.gridSettingsManager.OBJECT_NAME ?? '';
            this.channelName = !this.initDataWrapper.gridSettingsManager.OBJECT_NAME.endsWith('__c') ? '/data/' + this.initDataWrapper.gridSettingsManager.OBJECT_NAME + 'ChangeEvent' : '/data/' + this.initDataWrapper.prefix + this.initDataWrapper.gridSettingsManager.OBJECT_NAME + '__ChangeEvent';
            // warnings
            this.warningMessages = this.initDataWrapper.gridSettingsManager.WARNINGS || [];
            if (this.initDataWrapper.errorMessages.length == 0 && this.warningMessages.length > 0) {
                this.warningMessages.forEach(item => toastWarning(this, item));
            }

            // handle error messages from server
            if (this.initDataWrapper.errorMessages != null && this.initDataWrapper.errorMessages != "") {
                let errorString = this.initDataWrapper.errorMessages.join('\n');
                toastError(this, errorString);
            }

            this.headerLabels.objectLabel = this.initDataWrapper.gridSettingsManager.objectLabel ?? '';
            this.headerLabels.layoutLabel = this.initDataWrapper.gridSettingsManager.layoutLabel ?? '';
            this.headerLabels.layoutSlogan = this.initDataWrapper.gridSettingsManager.layoutSlogan ?? '';
            this.headerLabels.iconName = this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.iconName && this.initDataWrapper.gridSettingsManager.iconSection
                ? this.initDataWrapper.gridSettingsManager.iconSection + ':' + this.initDataWrapper.gridSettingsManager.iconName
                : 'standard:orders';
            if (this.objectApiName != '' || this.objectApiName != 'None' || this.objectApiName != undefined) {
                getTemplates({ objectApiName: this.objectApiName })
                    .then(result => {
                        this.listViewOptions = JSON.parse(result);
                        this.listViewOptions.sort((a, b) => a.order - b.order);
                        if (this.listViewOptions.length > 0) {
                            this.selectedListViews = true;
                        } else {
                            this.selectedListViews = false;
                        }
                    }).catch(error => {
                        console.log("🚀 ~ GridSettingsPlugin ~ connectedCallback ~ getTemplates ~ error:", error)
                    })
            }
            this.isTreeGrid = this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.gridTypeValue == 'tree';
            this.selectedActions = this.initDataWrapper?.gridSettingsManager?.Quick_Actions;
            console.log("🚀 ~ GridSettingsPluginV3 ~ initData ~ this.selectedActions:", JSON.stringify(this.selectedActions))
            // this.actionFlows = (this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows ?? []).filter(f => f.value && f.displayType && f.displayType === 'Action');
            this.isShowFilterOnColumnHeader = this.initDataWrapper?.gridSettingsManager.isShowFilterOnColumnHeader;
            //default page size
            this.pageSize = '' + this.initDataWrapper.gridSettingsManager.Default_Page_Size;
            const gridLayout = this.initDataWrapper.gridSettingsManager.gridLayout.Grid_Configuration__c ? JSON.parse(this.initDataWrapper.gridSettingsManager.gridLayout.Grid_Configuration__c) : null;
            this.importSettingsTemplate = gridLayout?.importSettingsTemplate;

            this.displaylistView = this.includeInListView && this.objectApiName != 'None' && this.initDataWrapper.gridSettingsManager.templateType == 'Detail';
            // build displayed fields
            this.buildDisplayedFields(true);
        });

    }
    // Builds the grid column definitions (displayed fields) from Apex data.
    buildDisplayedFields(isFirstLoad) {
        return new Promise((resolve, reject) => {
            try {
                let fieldIndex = 0;
                const GRID_FIELDS = this.initDataWrapper.gridSettingsManager.GRID_FIELDS || [];
                this.apexMethodPromises = [];

                let masterFields = [];
                let allPicklistFields = [];
                for (let field of GRID_FIELDS) {
                    if (field.showInTotal && field.isNumberField) {
                        this.aggregationFields.push({ fieldName: field.fieldName, aggType: field.totaltype });
                    }
                    if (field.defaultType === 'master' && field.defaultValue) {
                        masterFields.push(field.defaultValue.split(".")[1]);
                    }
                    if (field.stringFieldType === 'PICKLIST') {
                        allPicklistFields.push(field.fieldName);
                    }
                    if (field.controllerName != null) {
                        this.picklistRelationshipMap[field.controllerName] = field.fieldName;
                        this.apexMethodPromises.push(this.getFieldDependencies(field.controllerName, field.fieldName));
                    }
                }

                this.apexMethodPromises.push(this.getPicklistValuesByRecordTypeId(allPicklistFields));
                if (masterFields.length) {
                    getMasterInfoData({ recordId: this.recordId, masterObjectApiName: this.initDataWrapper.gridSettingsManager.Master_OBJECT_NAME, fieldsName: masterFields }).then(result => {
                        this.masterObjectInfo = result;
                    });
                }
                this.hasTotalFields = this.showSubTotal && this.aggregationFields.length > 0;
                // get totals
                this.handelGetTotalAggregation().then((result) => {
                    this.displayedFields = [];
                    this.displayedFieldsMap = {};

                    let savedLocalGrid;
                    if (result && localStorage.getItem(this.templateName)) {
                    const cachedData = JSON.parse(localStorage.getItem(this.templateName));
                    savedLocalGrid = cachedData.map(field => field.fieldName);
                    }
                    const filterableFields = this.initDataWrapper.gridSettingsManager.FILTERS || [];

                    for (let field of GRID_FIELDS) {
                        if (!this.hiddenGridFields.includes(field.fieldName)) {
                            let fieldWrapper = {
                                fieldName: field.fieldName,
                                // fieldLabel: field.fieldLabel.toUpperCase(),
                                fieldType: field.fieldType,
                                isNumberField: field.isNumberField,
                                isId: field.stringFieldType == 'ID',
                                isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                                isDate: field.fieldType == 'DATE',
                                isDateTime: field.fieldType == 'DATETIME',
                                isPicklist: field.fieldType == 'PICKLIST',
                                isBoolean: field.fieldType == 'BOOLEAN',
                                isRichText: field.isRichText,
                                isTextArea: field.fieldType == 'TEXTAREA',
                                isText: field.stringFieldType == 'STRING',
                                isMultiPicklist: field.stringFieldType == 'MULTIPICKLIST',
                                isCurrency: field.stringFieldType == 'CURRENCY',
                                isPercent: field.stringFieldType == 'PERCENT',
                                isURL: field.stringFieldType == 'URL',
                                isNameField: field.fieldName.toLowerCase() == 'name',
                                link: '',
                                scale: field.scale,
                                step: '',
                                isInputField: field.isInputField,
                                style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                                headerStyle: field.headerStyle,
                                pickListValues: field.pickListValues,
                                picklistColorsMap: field.picklistColorsMap,
                                isSortable: field.isSortable,
                                isDefaultSortable: field.isDefaultSortable,
                                isFilterable: field.isFilterable,
                                isEncrypted: field.isEncrypted,
                                isMassUpdate: field.isMassUpdate && field.isInputField && this.enableMassUpdate,
                                filterValue: '',
                                nameAsURL: (this.nameAsURL && field.fieldName.toLowerCase() == "name"),
                                isHTMLFormatted: field.isHTMLFormatted,
                                isNotExportable: field.isNotExportable,
                                isPersonalised: field.isPersonalised,
                                total: field.showInTotal && this.aggregationFields.filter(obj => obj.fieldName == field.fieldName).length > '0'
                                    ? this.aggregationFields.filter(obj => obj.fieldName == field.fieldName)[0].totalVal == null ? 0 : this.aggregationFields.filter(obj => obj.fieldName == field.fieldName)[0].totalVal
                                    : '',
                                isFormula: field.isFormula,
                                sortedField: false,
                                referencedField: field.referencedField,
                                isReferenceField: field.isReferenceField,
                                equation: field.equation,
                                controlledByFields: field.controlledByFields,
                            }
                            // Formula fields state: set field type based on formula return type 
                            if (fieldWrapper.referencedField != null) {
                                fieldWrapper.isInputField = true;
                                fieldWrapper.isText = true;
                                if (fieldWrapper.pickListValues?.length > 0) {
                                    fieldWrapper.isPicklist = true;
                                    fieldWrapper.isText = false;
                                }
                            }
                            if (fieldWrapper.referencedField != null) {
                                fieldWrapper.pickListValues?.length > 0 ? fieldWrapper.isPicklist = true : fieldWrapper.isPicklist = false;
                                fieldWrapper.isInputField = true;
                            }
                            if (fieldWrapper.isPicklist) {
                                fieldWrapper.pickListValues.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                            }
                            if (fieldWrapper.isBoolean) {
                                let options = [{ label: this.Labels.LBL_True, value: 'true' }, { label: this.Labels.LBL_False, value: 'false' }];
                                fieldWrapper.pickListValues = options;
                            }
                            if (fieldWrapper.controllerName) {
                                fieldWrapper.controller = { controllerName: fieldWrapper.controllerName, value: undefined };
                            }
                            if (fieldWrapper.isNumberField) {
                                fieldWrapper.style += 'text-align:right;';
                            }
                            if (fieldWrapper.scale) {
                                const result = 1 / Math.pow(10, fieldWrapper.scale);
                                fieldWrapper.step = result.toFixed(fieldWrapper.scale);
                            }
                            if (this.initDataWrapper.gridSettingsManager?.GRID_FIELDS) {
                                this.availableSortFields = GRID_FIELDS.map(field => ({
                                    label: field.fieldLabel.charAt(0).toUpperCase() + field.fieldLabel.slice(1).toLowerCase(),
                                    value: field.fieldName
                                }));
                            }
                            // Clone state
                            if (field.clearOnClone) {
                                this.fieldToClearOnClone.push(fieldWrapper.fieldName);
                            }

                            if (savedLocalGrid == null || !savedLocalGrid.includes(fieldWrapper.fieldName)) {
                                fieldWrapper.sortedField = false;
                                fieldWrapper.sortedAscending = false;
                                fieldWrapper.sortedDescending = false;
                                fieldWrapper.isSearchableText = field.stringFieldType == 'STRING' || field.stringFieldType == 'TEXTAREA' || field.stringFieldType == 'REFERENCE';
                                fieldWrapper.isSearchableCheckboxes = field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'BOOLEAN';
                                fieldWrapper.isSearchableInput = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
                                fieldWrapper.isSearchableDateInput = field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME';
                                fieldWrapper.popUpStyle = field.isSearchableCheckboxes ? 'max-height:230px;min-height:230px;'
                                    : field.isSearchableDateInput || field.isSearchableInput ? 'min-width:260px' : '';
                                fieldWrapper.fieldLabel = (field.newLabel && field.newLabel != '' ? field.newLabel : field.fieldLabel).toUpperCase();
                                fieldWrapper.color = field.nonConditional?.textStyle?.color;
                                fieldWrapper.isRecordType = field.fieldName.toLowerCase() == 'recordtypeid';
                                fieldWrapper.isFilterable = filterableFields.filter(elt => elt.fieldName == field.fieldName && elt.hasOwnProperty('userFilterable') && elt.userFilterable).length > 0
                                    && this.isShowFilterOnColumnHeader;
                                fieldWrapper.options = filterableFields.filter(elt => elt.fieldName == field.fieldName).length > 0 && field.stringFieldType == 'PICKLIST'
                                    ? filterableFields.filter(elt => elt.fieldName == field.fieldName)[0].pickListValues
                                    : field.pickListValues;

                                fieldWrapper.iconStyle = '';
                                if (field.headerStyle && field.headerStyle.color != '') {
                                    fieldWrapper.iconStyle += '--slds-c-icon-color-foreground: ' + field.headerStyle.color + ' !important;--slds-c-icon-color-foreground-default: ' + field.headerStyle.color + ' !important;';
                                }
                                if (field.scale) {
                                    const result = 1 / Math.pow(10, field.scale);
                                    fieldWrapper.step = result.toFixed(field.scale);
                                }

                                fieldWrapper.headerStyle = field.headerStyle?.style + (field.nonConditional?.widthStyle ? field.nonConditional?.widthStyle : '');
                                if (!this.selectedFields.includes(field.fieldName)) {
                                    this.selectedFields.push(field.fieldName);
                                }
                                // dependent picklist handling
                                fieldWrapper.hasDependentPicklist = false;
                                if (fieldWrapper.controlledByFields && fieldWrapper.controlledByFields.length) {
                                    let controlledByFields = [];
                                    if (fieldWrapper.isPicklist && (Object.keys(this.picklistRelationshipMap).includes(fieldWrapper.fieldName)
                                        || Object.values(this.picklistRelationshipMap).includes(fieldWrapper.fieldName))) {
                                        fieldWrapper.hasDependentPicklist = true;
                                        let options = [...(fieldWrapper.options || [])];
                                        // options.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                                        controlledByFields.push({
                                            controlledByName: field.fieldName,
                                            controlledByLabel: field.fieldLabel,
                                            value: undefined,
                                            disabled: true,
                                            options: options
                                        });
                                        if (Object.keys(this.picklistRelationshipMap).includes(fieldWrapper.fieldName)) {
                                            let nextField = this.picklistRelationshipMap[fieldWrapper.fieldName];
                                            while (nextField) {
                                                let nextOptionField = this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(elt => elt.fieldName == nextField).length > 0
                                                    && field.stringFieldType == 'PICKLIST'
                                                    ? this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(elt => elt.fieldName == nextField)[0]
                                                    : {};
                                                let nextOptions = [...(nextOptionField.pickListValues || [])];
                                                // nextOptions.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                                                let nextOptionLabel = nextOptionField.fieldLabel;
                                                controlledByFields.push({
                                                    controlledByName: nextField,
                                                    controlledByLabel: nextOptionLabel,
                                                    value: undefined,
                                                    disabled: true,
                                                    options: nextOptions
                                                });
                                                nextField = this.picklistRelationshipMap[nextField];
                                            }
                                        }
                                        if (Object.values(this.picklistRelationshipMap).includes(fieldWrapper.fieldName)) {
                                            let indexField = Object.values(this.picklistRelationshipMap).indexOf(fieldWrapper.fieldName);
                                            let prevField = Object.keys(this.picklistRelationshipMap)[indexField];

                                            while (prevField) {
                                                let prevOptionField = this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(elt => elt.fieldName == prevField).length > 0
                                                    && field.stringFieldType == 'PICKLIST'
                                                    ? this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(elt => elt.fieldName == prevField)[0]
                                                    : {};
                                                let prevOptions = [...(prevOptionField.pickListValues || [])];
                                                // prevOptions.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                                                let prevOptionLabel = prevOptionField.fieldLabel;
                                                controlledByFields.unshift({
                                                    controlledByName: prevField,
                                                    controlledByLabel: prevOptionLabel,
                                                    value: undefined,
                                                    disabled: true,
                                                    options: prevOptions
                                                });
                                                indexField = Object.values(this.picklistRelationshipMap).indexOf(prevField);
                                                prevField = indexField != -1 ? Object.keys(this.picklistRelationshipMap)[indexField] : null;
                                            }
                                        }
                                        controlledByFields[0].disabled = false;
                                    }
                                    fieldWrapper.controlledByFields = controlledByFields;
                                }

                                this.displayedFields.push(fieldWrapper);
                                this.displayedFieldsMap[field.fieldName] = fieldWrapper;
                            }
                        }
                        field.fieldIndex = fieldIndex;
                        fieldIndex++;
                    }

                    this.firstThStyle = (this.displayedFields[0]?.headerStyle ? this.displayedFields[0].headerStyle : '') + 'text-align: center;';
                    if (isFirstLoad) {
                        Promise.all(this.apexMethodPromises).then(() => {
                            this.loadData();
                        }).catch(reject);
                    }
                    resolve(true);
                });
            } catch (error) {
                this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                console.log('buildDisplayedFields: %c' + error.message, 'color : red');
                console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
            }
        });
    }

    // Calls Apex loadData to fetch table rows.
    loadData(sortConfig = []) {
        try {
            this.records = [];
            this.tableLoading = true;
            console.log("🚀 ~ GridSettingsPluginV3 ~ loadData ~ sortConfig:", JSON.stringify(sortConfig))
            if (!sortConfig.length && this.appliedSortConfig) {
                sortConfig = this.appliedSortConfig;
            }
            if (!sortConfig.length) {
                this.appliedSortConfig = null;
            } else {
                this.appliedSortConfig = sortConfig;
            }

            loadData({
                gridSettingsManagerSerialized: JSON.stringify(this.initDataWrapper.gridSettingsManager),
                recordId: this.recordId,
                objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                pageSize: this.pageSize,
                pageNumber: this.pageNumber,
                filters: JSON.stringify(this.filters),
                sortedFieldName: this.sortFieldApi,
                defaultSortDirection: this.sortDirection,
                sortConfig: JSON.stringify(this.appliedSortConfig || [])
            }).then(result => {
                this.loadDataWrapper = JSON.parse(result);
                let p = Promise.resolve();
                if (this.recordId != null && this.initDataWrapper.gridSettingsManager.templateType != 'Detail') {
                    this.initDataWrapper.gridSettingsManager = this.loadDataWrapper.gsm;
                    p = this.buildDisplayedFields(false);
                }
                
                return p.then(() => {
                    if (this.appliedSortConfig == null || this.appliedSortConfig.length == 0) {
                        this.initializeSortingFields();
                    }
                    if (this.initDataWrapper.gridSettingsManager.gridTypeValue == 'tree') {
                        this.handleTreeLoad();
                    } else {
                        this.records = this.buildData(this.loadDataWrapper.records);
                    }
                    console.log("load data >>>>>>>>>>>>>>>>records, displayedFields ")
                    console.log(JSON.stringify(this.records))
                    console.log(JSON.stringify(this.displayedFields))
                    console.log(" >>>>>>>>>>>>>>>> ")
                    // to do ?
                    if (Object.keys(this.uploadedFileMap).length > 0) {
                        attachFileToRecords({ filesToRecordsSerialized: JSON.stringify(this.uploadedFileMap) }).then(() => {
                            this.uploadedFileMap = {};
                        });
                    }
                    this.tableLoading = false;
                });
            }).catch(error => {
                this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                console.log('loadData: %c' + error.message, 'color : red');
                console.log('loadData: %c' + error.body?.message, 'color : red');
                this.tableLoading = false;
            })
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
        }
    }

    /**
     * Aggregation logic: retrieves totals from the Apex controller.
     */
    handelGetTotalAggregation() {
        return new Promise((resolve, reject) => {
            if (this.aggregationFields.length > 0) {
                getTotalAggregation({
                    recordId: this.recordId, aggregationFields: JSON.stringify(this.aggregationFields),
                    objectApiName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                    masterObjectApiName: this.initDataWrapper.gridSettingsManager.relationName,
                    metadataDeveloperName: this.templateName
                }).then(result => {
                    this.aggregationFields = JSON.parse(result);
                    resolve(true);
                }).catch(error => {
                    console.log("Error " + error.body.message);
                });
            } else {
                resolve(true);
            }
        });
    }

    // Builds and formats the data rows for the grid display from the raw Apex result.
    buildData(data) {
        try {
            let groupedField = this.initDataWrapper.gridSettingsManager?.groupedField;
            if (groupedField) {
                const rowIndex = data.findIndex(record => record.hasOwnProperty(groupedField));
                this.isReferenceField = groupedField.endsWith('__c') && data?.length > 0 && rowIndex > 0 && data[rowIndex].hasOwnProperty(groupedField.replace('__c', '__r'));
                let GroupWrapperMap = {};
                for (let i = 0; i < data.length; i++) {
                    let item = data[i];
                    let GroupId = item[groupedField];
                    let GroupWrapper = {
                        GroupId: this.isReferenceField ? GroupId : '',
                        GroupName: this.isReferenceField ? (item[groupedField.replace('__c', '__r')] && item[groupedField.replace('__c', '__r')].Name) ? item[groupedField.replace('__c', '__r')].Name : '' : item[groupedField],
                        link: this.isReferenceField ? '/' + GroupId : '',
                        records: [],
                        rowspan: 1,
                    }
                    if (!GroupWrapperMap.hasOwnProperty(GroupId)) {
                        GroupWrapperMap[GroupId] = GroupWrapper;
                    }
                    GroupWrapper = GroupWrapperMap[GroupId];
                    let detailWrapper = this.buildRowData(item, i);
                    this.applyRowStyle(detailWrapper);
                    if (detailWrapper) {
                        GroupWrapper.records.push(detailWrapper);
                        GroupWrapper.rowspan += 1;
                        GroupWrapperMap[GroupId] = GroupWrapper;
                    }
                }
                return Object.values(GroupWrapperMap);
            }

            let allDetails = [];
            for (let i = 0; i < data.length; i++) {
                let item = data[i];
                let detail = this.buildRowData(item, i);
                this.applyRowStyle(detail);
                if (detail) allDetails.push(detail);
            }
            return allDetails ? [{ GroupId: '', GroupName: '', link: '', records: allDetails, rowspan: 1 }] : null;

        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
        }
    }
    // ====================================================================
    buildRowData(item, index) {
        try {
            let changeMap = { ...this.recordsToUpdateMap };
            let changedFieldValue = '';

            let buildDataWrapper = {
                index: index,
                Name: item.Name,
                Id: item.Id,
                isSelected: this.selectedRecordIds.includes(item.Id),
                link: '/' + item.Id,
                values: [],
                rowColor: '',
                firstTdStyle: '',
                lastTdStyle: '',
                nameURL: '/' + item.Id,
            }

            // If grouped field is enabled, remove it from displayedFields
            if (this.initDataWrapper.gridSettingsManager?.groupedField) {
                let groupedFieldData = this.initDataWrapper.gridSettingsManager.GRID_FIELDS.find((field) => field.fieldName == this.initDataWrapper.gridSettingsManager?.groupedField);
                this.groupedFieldTh.label = groupedFieldData.fieldLabel;
                this.groupedFieldTh.headerStyle = (groupedFieldData.headerStyle?.style || groupedFieldData.headerStyle || '') + (groupedFieldData.nonConditional?.widthStyle || '');;
                this.groupedFieldTh.bodyStyle = groupedFieldData.style;
                this.displayedFields = this.displayedFields.filter((field) => field.fieldName != this.initDataWrapper.gridSettingsManager?.groupedField);
            }

            if ((item.Id && this.rejectedRecords.includes(item.Id)) || (!item.Id && this.rejectedRecords.includes(index + ''))) {
                buildDataWrapper.hasError = true;
                console.log("🚀 ~ GridSettingsPluginV3 ~ buildRowData ~ uildDataWrapper.hasError:", buildDataWrapper.hasError)
            } else {
                buildDataWrapper.hasError = false;
            }
            
            for (let field of this.displayedFields) {
                if (field.isHidden) {
                    continue;
                }

                // Base wrapper for each field in the row
                let fieldWrapper = structuredClone(field);
                fieldWrapper.fieldValue = '';
                fieldWrapper.fieldOutputValue = '';
                fieldWrapper.nameAsURL = item.Id && field.nameAsURL;
                fieldWrapper.CurrencyExist = item['CurrencyIsoCode'] && this.useRecordIsoCurrency ? true : false;
                fieldWrapper.CurrencyIsoCode = item['CurrencyIsoCode'];
                fieldWrapper.controllerName = field.controllerName;
                fieldWrapper.controllerValue = item[fieldWrapper.controllerName] ? item[fieldWrapper.controllerName] : '';
                fieldWrapper.relatedField = field.fieldName.includes(".");

                // Filtering flags
                if (this.filtersFieldsMap && this.filtersFieldsMap[field.fieldName]) {
                    let filterData = this.filtersFieldsMap != undefined && this.filtersFieldsMap[field.fieldName]
                        ? this.filtersFieldsMap[field.fieldName]
                        : null;
                    field.filterValue = {
                        values: this.overrideFilter && filterData?.values && filterData.values !== '' ? filterData.values.join('') : '',
                        value1: this.overrideFilter && filterData?.value1 && filterData.value1 !== '' ? filterData.value1 : '',
                        value2: this.overrideFilter && filterData?.value2 && filterData.value2 !== '' ? filterData.value2 : ''
                    };
                    field.hasFilter = (field.filterValue.values != '' || field.filterValue.value1 != '' || field.filterValue.value2 != '')
                        && field.filterValue.userFilterable;
                }

                // Sorting flags
                if (this.appliedSortConfig && this.appliedSortConfig.length > 0) {
                    const sortConfigForField = this.appliedSortConfig.find(s => s.fieldName === field.fieldName);
                    if (sortConfigForField) {
                        fieldWrapper.sortedField = true;
                        fieldWrapper.sortedAscending = sortConfigForField.direction === 'ASC';
                        fieldWrapper.sortedDescending = sortConfigForField.direction === 'DESC';
                    }
                }

                if (fieldWrapper.relatedField) {
                    fieldWrapper.refObject = (this.initDataWrapper.gridSettingsManager.objectReferenceMap || {})[field.fieldName.toString().split(".")[0].replace(/__r/, '__c')];
                    fieldWrapper.refField = field.fieldName.toString().split(".")[1];
                    fieldWrapper.refId = item[fieldWrapper.refObject];
                }
                let fieldValue = '';
                if (field.isReference && !field.isInputField && item.Id == undefined && changeMap.hasOwnProperty(index) && changeMap[index].hasOwnProperty(field.fieldName)) {
                    fieldWrapper.class = 'slds-cell-edit slds-is-edited slds-border_left';
                    fieldValue = changeMap[index][field.fieldName];
                } else if (field.isReference && (!field.isInputField || this.isReadOnly)) {
                    fieldWrapper.link = '/' + (fieldValue || '');
                    fieldValue = item;
                    let relatedfields = field.fieldName.toString().split(".");
                    relatedfields?.forEach(fieldName => {
                        if (fieldValue && fieldValue.hasOwnProperty(fieldName)) {
                            fieldValue = fieldValue[fieldName];
                        } else {
                            fieldWrapper.fieldValue = null;
                            return;
                        }
                    });
                } else {
                    if (item.Id != undefined && changeMap.hasOwnProperty(item.Id) && changeMap[item.Id].hasOwnProperty(field.fieldName)) {
                        fieldWrapper.class = 'slds-cell-edit slds-is-edited slds-border_left';
                        fieldValue = changeMap[item.Id][field.fieldName];
                    } else if (item.Id == undefined && changeMap.hasOwnProperty(index) && changeMap[index].hasOwnProperty(field.fieldName)) {
                        fieldWrapper.class = 'slds-cell-edit slds-is-edited slds-border_left';
                        fieldValue = changeMap[index][field.fieldName];
                    } else {
                        fieldValue = item[field.fieldName];
                    }
                }
                fieldWrapper.fieldValue = fieldValue;
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
                if (field.isNumber) {
                    fieldWrapper.scale = field.scale;
                    fieldWrapper.increment = incrementFormat(field.scale);
                }
                if (field.isText) {
                    fieldWrapper.style += 'white-space: pre-wrap; word-break: break-word;'
                }
                fieldWrapper.class = (field.isReference ? '' : 'limited-cell') + ' slds-border_left slds-border_right slds-border_bottom' + (field.isBoolean ? ' slds-text-align_center' : '');
                fieldWrapper.pickListValueMap = {};
                console.log('🎐 ~ gridSettingsPluginV3.js:1505 -> item.pickListValues: ', JSON.stringify(field.pickListValues));
                field.pickListValues = field.pickListValues ? field.pickListValues.map(pick => {
                        fieldWrapper.pickListValueMap[pick.value] = pick.label;
                        return pick;
                    }) : [];

                if (fieldWrapper.isPicklist) {
                    fieldWrapper.picklistOptions = [];

                    if (fieldWrapper.controllerName != null && fieldWrapper.controllerValue != null && this.dependentPicklistMap[field.fieldName][fieldWrapper.controllerValue]) {
                        for (let option of this.dependentPicklistMap[field.fieldName][fieldWrapper.controllerValue]) {
                            if (!item.RecordTypeId || (item.RecordTypeId && this.availablePicklistValues[field.fieldName][item.RecordTypeId].includes(option.value))) {
                                fieldWrapper.picklistOptions.push({ label: option.label, value: option.value, isSelected: fieldWrapper.fieldValue == option.value })
                            }
                        }
                    } else {
                        for (let option of fieldWrapper.pickListValues) {
                            if (!item.RecordTypeId || (item.RecordTypeId && this.availablePicklistValues[field.fieldName][item.RecordTypeId].includes(option.value))) {
                                fieldWrapper.picklistOptions.push({ label: option.label, value: option.value, isSelected: fieldWrapper.fieldValue == option.value })
                            }
                        }
                    }
                    buildDataWrapper.rowColor += field.picklistColorsMap
                        && fieldWrapper.fieldValue !== ''
                        && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue)
                        && field.picklistColorsMap[fieldWrapper.fieldValue] !== ''
                        ? field.picklistColorsMap[fieldWrapper.fieldValue] : '';
                }
                let localeParts = this.userLocal.split('_');
                let locale = localeParts.length > 2 ? localeParts[0] + '_' + localeParts[0] : '';
                if (fieldWrapper.isDateTime) {
                    fieldWrapper.dateTimeValue = fieldWrapper.fieldValue;
                    try {
                        fieldWrapper.fieldValue = fieldWrapper.fieldValue != null && fieldWrapper.fieldValue != "" && !fieldWrapper.isInputField ? new Date(fieldWrapper.fieldValue).toLocaleDateString(locale.replace('_', '-')) + ' ' + new Date(fieldWrapper.fieldValue).toLocaleTimeString(locale.replace('_', '-')) : item.value;
                    } catch {
                        fieldWrapper.fieldValue = fieldWrapper.fieldValue != null && fieldWrapper.fieldValue != "" && !fieldWrapper.isInputField ? new Date(fieldWrapper.fieldValue).getTime() : item.value;
                    }
                }
                if (fieldWrapper.isDate) {
                    fieldWrapper.dateValue = fieldWrapper.fieldValue;
                }
                fieldWrapper.isInputField = !field.internallyCalculated && ((!this.isReadOnly && field.isInputField) || (item.Id == undefined && field.isCreateable && field.isUpdateable && !field.isCalculated && !field.fieldName.includes(".")));
                if (fieldWrapper.isMultiPicklist) {
                    if (fieldWrapper.isInputField) {
                        fieldWrapper.fieldValue = fieldValue ? fieldValue.split(';').map(val => val.trim()) : '';
                    } else {
                        fieldWrapper.fieldValue = fieldValue ? fieldValue.split(';').map(val => val.trim()).map(val => fieldWrapper.pickListValueMap[val]) : '';
                    }
                }
                fieldWrapper.SObjectName = field.SObjectName || '';
                changedFieldValue = fieldValue;
                if (fieldWrapper.isId) {
                    fieldWrapper.link = '/' + (fieldWrapper.fieldValue || '');
                }

                if (field.isFormula) {
                    fieldWrapper.isText = true;
                    let expr = field.equation;
                    if (!expr) return;
                    const keys = Object.keys(item);
                    keys.forEach(key => {
                        const re = new RegExp(`\\b${key}\\b`, 'g');
                        expr = expr.replace(re, item[key] ?? 0);
                    });
                    try {
                        fieldWrapper.fieldValue = eval(expr).toFixed(3);
                    } catch (e) {
                        fieldWrapper.fieldValue = null;
                    }
                }
                buildDataWrapper.values.push(fieldWrapper);
            }
            this.displayedFields.forEach(field => {
                if (field.isPicklist) {
                    let picklistField = field.fieldName;
                    let dependentValExist = this.picklistRelationshipMap.hasOwnProperty(picklistField);
                    let depVal = changedFieldValue;
                    while (dependentValExist) {
                        let fieldsWrapper = this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(depField => depField.fieldName == this.picklistRelationshipMap[picklistField]);
                        for (let fieldWrapper of fieldsWrapper) {
                            buildDataWrapper.values[fieldWrapper.fieldIndex].controllerValue = depVal;
                            // buildDataWrapper.values[fieldWrapper.fieldIndex].fieldValue = '';
                            buildDataWrapper.values[fieldWrapper.fieldIndex].picklistOptions = [];
                            if (this.dependentPicklistMap[fieldWrapper.fieldName] && this.dependentPicklistMap[fieldWrapper.fieldName][depVal]) {
                                for (let option of this.dependentPicklistMap[fieldWrapper.fieldName][depVal]) {
                                    if(option.value == '') continue;
                                    buildDataWrapper.values[fieldWrapper.fieldIndex].picklistOptions.push({ label: option.label, value: option.value, isSelected: fieldWrapper.fieldValue == option.value })
                                }
                            }
                            // buildDataWrapper.values[fieldWrapper.fieldIndex].picklistOptions.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                            dependentValExist = this.picklistRelationshipMap[fieldWrapper.fieldName] != null;
                            picklistField = fieldWrapper.fieldName;
                            depVal = '';
                        }
                    }
                }
            });
            if (Object.keys(this.uploadedFileMap).length > 0) {
            // if (this.uploadedFileMap != {}) {
                if (Object.values(this.uploadedFileMap).includes(buildDataWrapper.index.toString())) {
                    for (var key of Object.keys(this.uploadedFileMap)) {
                        if (this.uploadedFileMap[key] == buildDataWrapper.index.toString() && buildDataWrapper.Id != undefined) {
                            this.uploadedFileMap[key] = buildDataWrapper.Id;
                        }
                    }
                }
            }
            this.originalValuesById[buildDataWrapper.Id] = {};
            this.tableLoading = false;
            return buildDataWrapper;
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('buildRowData: %c' + error.message, 'color : red');
            console.log('buildRowData: %c' + error.body?.message, 'color : red');
        }
    }

    // ====================================================================
    // tree: 
    handleTreeLoad() {
        if (!this.loadDataWrapper.records || this.loadDataWrapper.length === 0) {
            this.tableLoading = false;
            return;
        }
        if (this.recordId) {
            let currentNode = this.loadDataWrapper.records[0];
            this.createRootNode(currentNode);
        } else {
            this.loadDataWrapper.records.forEach(record => {
                this.createRootNode(record);
            });
        }
        this.tableLoading = false;
    }
    // Creates the root node of the hierarchy tree and auto-expands it to show direct children
    createRootNode(currentNode) {
        const rootNode = {
            key: currentNode.Id,
            Id: currentNode.Id,
            values: [],
            level: 1,
            parentKey: null,
            showChevronButton: currentNode[this.loadDataWrapper.relationshipName] && currentNode[this.loadDataWrapper.relationshipName].length > 0,
            show: true,
            expanded: true,
            ariaExpanded: true,
            childrenLoaded: false,
        };
        for (let field of this.initDataWrapper.gridSettingsManager.GRID_FIELDS) {
            if (this.selectedFields.includes(field.fieldName) || field.isHidden) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isNumberField: field.isNumberField,
                    isReference: field.stringFieldType == "REFERENCE",
                    isNameField: field.fieldName == 'Name',
                    isDate: field.isDate,
                    isDateTime: field.isDateTime,
                    isPicklist: field.isPicklist,
                    isBoolean: field.isBoolean,
                    isTextArea: field.isTextArea,
                    isText: field.isText,
                    isHTMLFormatted: field.isHTMLFormatted,
                    scale: field.scale,
                    style: field.style + (field.fieldIndex == 0 ? 'display: table-cell;' : ''),
                    link: '',
                    value: currentNode[field.fieldName],
                    class: (field.class ? field.class : '') + (field.fieldIndex == 0 ? 'slds-tree__item' : ''),
                }
                let values = field.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let val = index == 0 ? currentNode : fieldWrapper.fieldValue;
                    if (val) {
                        if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                            fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                            fieldWrapper.link = '/' + val[values[index]];
                        } else {
                            fieldWrapper.fieldValue = val[values[index]];
                        }
                    }
                }
                if (fieldWrapper.fieldName == 'Name') {
                    fieldWrapper.link = '/' + rootNode.Id;
                }
                rootNode.values.push(fieldWrapper)
            }
        }

        this.treeList.push(rootNode);
        this.expandedNodes.add(rootNode.key);
        this.loadChildren(rootNode.key, rootNode.key, 2, 0);
    }
    // Processes children data from the Hierarchy Tree Apex Controller response and creates tree nodes
    processChildrenData(data, parentKey, level) {
        console.log("🚀 ~ GridSettingsPluginV3 ~ processChildrenData ~ data:", JSON.stringify(data))
        let newNodes = [];
        data.forEach(item => {
            let node = {
                key: item.Id,
                Id: item.Id,
                values: [],
                level: level,
                parentKey: parentKey,
                showChevronButton: Object.keys(item).some((fieldName) => {
                    const potentialChildRelation = item[fieldName];
                    const hasChildren =
                        potentialChildRelation &&
                        typeof potentialChildRelation === 'object' &&
                        (
                            (Array.isArray(potentialChildRelation.records) && potentialChildRelation.records.length > 0) ||
                            (typeof potentialChildRelation.size === 'number' && potentialChildRelation.size > 0) ||
                            (typeof potentialChildRelation.totalSize === 'number' && potentialChildRelation.totalSize > 0)
                        );
                    return hasChildren;
                }),
                show: level === 1 || (parentKey && this.expandedNodes.has(parentKey)),
                expanded: false,
                ariaExpanded: false,
                childrenLoaded: false,
            };
            for (let field of this.initDataWrapper.gridSettingsManager.GRID_FIELDS) {
                if (this.selectedFields.includes(field.fieldName) || field.isHidden) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        isNumberField: field.isNumberField,
                        isReference: field.stringFieldType == "REFERENCE",
                        isNameField: field.fieldName == 'Name',
                        isDate: field.isDate,
                        isDateTime: field.isDateTime,
                        isPicklist: field.isPicklist,
                        isBoolean: field.isBoolean,
                        isTextArea: field.isTextArea,
                        isText: field.isText,
                        isHTMLFormatted: field.isHTMLFormatted,
                        scale: field.scale,
                        style: field.style + 'display: table-cell;',
                        link: '',
                        fieldValue: item[field.fieldName],
                        class: (field.class ? field.class : '') + (field.fieldIndex == 0 ? 'slds-tree__item' : ''),
                    }
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let val = index == 0 ? item : fieldWrapper.fieldValue;
                        if (val) {
                            if (index == values.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                                fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                fieldWrapper.link = '/' + val[values[index]];
                            } else {
                                fieldWrapper.fieldValue = val[values[index]];
                            }
                        }
                    }
                    if (fieldWrapper.fieldName == 'Name') {
                        fieldWrapper.link = '/' + node.Id;
                    }
                    node.values.push(fieldWrapper)
                }
            }
            newNodes.push(node);
        });

        if (parentKey) {
            let parentIndex = this.treeList.findIndex(node => node.key === parentKey);
            if (parentIndex !== -1) {
                this.treeList.splice(parentIndex + 1, 0, ...newNodes);
                this.treeList[parentIndex].showChevronButton = newNodes.length > 0;
                this.treeList[parentIndex].childrenLoaded = true;
            }
        } else {
            this.treeList = [...newNodes];
        }
        this.treeList = [...this.treeList];
        this.tableLoading = false;
    }

    expandAndCollapse(event) {
        const nodeKey = event.currentTarget.dataset.recordid;
        const nodeIndex = this.treeList.findIndex(node => node.key === nodeKey);

        if (nodeIndex === -1) return;

        const node = this.treeList[nodeIndex];
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
        this.treeList = [...this.treeList];
    }

    loadChildren(hierarchyId, parentKey, level, parentIndex) {
        this.tableLoading = true;
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
                console.log('💻 ~ gridSettingsV3.js:543 -> data: ', JSON.stringify(data));
                if (Array.isArray(data) && data.length > 0) {
                    this.processChildrenData(data, parentKey, level);
                } else {
                    if (parentIndex !== undefined && this.treeList[parentIndex]) {
                        this.treeList[parentIndex].showChevronButton = false;
                        this.treeList[parentIndex].expanded = false;
                        this.treeList[parentIndex].ariaExpanded = false;
                        this.treeList[parentIndex].childrenLoaded = true;
                        this.expandedNodes.delete(parentKey);
                        this.treeList = [...this.treeList];
                    }
                    this.tableLoading = false;
                }
            }
        }).catch((error) => {
            console.error('Load children error:', error);
            toastError(this, error);
            this.tableLoading = false;
        });
    }

    showHideChildren(parentKey, show) {
        const parentLevel = this.treeList.find(node => node.key === parentKey)?.level || 0;
        for (const element of this.treeList) {
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
            current = this.treeList.find(n => n.key === current.parentKey);
            if (!current) break;
        }
        return false;
    }

    findDirectParent(node) {
        return this.treeList.find(n => n.key === node.parentKey);
    }

    // ====================================================================

    listViewChangeHandler(event) {
        this.tableLoading = true;
        this.resetValues();
        this.listViewTemplateValue = event.target.value;
        this.templateName = event.target.value;
        this.sortFieldApi = ''; // TODO:
        this.sortDirection = ''; // TODO:
        this.initData();
    }
    resetValues() {
        this.pageSize = null;
        this.displayedFields = [];
        this.displayedFieldsMap = {};
        this.selectedActions = [];
        this.selectedRecordIds = [];
        this.offset = 0;
        this.numberOfFixedColumns = 0;
        this.newRecords = [];
        this.recordsToUpdateMap = {};
        this.aggregationFields = [];
        this.records = this.records.forEach(group => {
            group.records.forEach(rec => {
                rec.isSelected = false;
            });
        });
        this.hasChanges = false;
    }
    // ====================================================================
    // 5. GETTERS
    // ====================================================================  
    // Flow Actions Getter 
    get flowActions() {
        return (this.initDataWrapper
            && this.initDataWrapper.gridSettingsManager
            && this.initDataWrapper.gridSettingsManager.actions
            && this.initDataWrapper.gridSettingsManager.actions.screenFlows) || [];
    }
    // Flows configured to display as actions in the main action menu
    get actionFlows() {
        return this.flowActions.filter(f => f.value && f.displayType && f.displayType === 'Action');
    }
    // Header Style Getters
    get lastThStyle() {
        return ((this.displayedFields || []).filter(f => !f.isHidden).slice(-1)[0]?.headerStyle) || '';
    }
    // Determines if all records are selected
    get isAllSelected() {
        return (Array.isArray(this.records) && this.records.length > 0 && this.records.flatMap(group => group.records).every(r => r.isSelected));
    }

    // Determines if the record selection checkbox column should be shown
    get showSelectRecords() {
        return this.enableMassUpdate || (this.records && this.records.length && this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.actions && this.initDataWrapper.gridSettingsManager.actions.screenFlows && this.initDataWrapper.gridSettingsManager.actions.screenFlows.filter(flow => flow.hasRecordIds).length > 0);
    };

    // Flow Getters
    get iconFlows() {
        // Flows configured to display as icons
        return this.flowActions?.filter(f => f.value && f.displayType && f.displayType === 'Icon');
    }
    get buttonFlows() {
        // Flows configured to display as buttons
        return this.flowActions?.filter(f => f.value && f.displayType && f.displayType === 'Button');
    }

    // Export Excel Getter
    @track fileGenerationLabel = '';// r2

    // Checks if any items should appear in the main action menu (delete, columns, export, import, actions)
    get hasMenu() {
        return (this.loadDataWrapper?.records?.length > 0 && (this.allowDelete || this.displayShowHideColumns || this.allowExport || this.allowImport || (this.displayListViewActions && this.selectedActions?.length > 0))) || (((this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows) || []).filter(f => f.value && f.displayType && f.displayType === 'Action')).length > 0;
    }

    // Controls visibility of the first divider in the action menu (separating grid options from list view actions)
    get showFirstDivider() {
        return (this.allowDelete || this.displayShowHideColumns) && this.displayListViewActions && this.selectedActions?.length > 0;
    }

    // Controls visibility of the second divider (separating export/import from list view actions)
    get showSecondDivider() {
        return (this.allowExport || this.allowImport) && this.displayListViewActions && this.selectedActions?.length > 0;
    }

    // Determines if the pagination controls should be shown
    get hasPagination() {
        return (this.initDataWrapper?.gridSettingsManager ? this.loadDataWrapper?.total > this.initDataWrapper?.gridSettingsManager?.Default_Page_Size : true) /* && !(this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'tree') */;
    }

    // Disables the 'Previous' page button
    get previousDisabled() {
        return this.pageNumber == 1;
    }

    // Disables the 'Next' page button (Salesforce limits query offset, often around 10k)
    get nextDisabled() {
        // Max records fetchable is 10k, so total pages is based on Math.min(total, 10000)
        let noOfRecords = this.loadDataWrapper.total > 10000 ? Math.ceil((10000 / this.pageSize)) : Math.ceil((this.loadDataWrapper.total / this.pageSize));
        return this.pageNumber >= noOfRecords;
    }

    // Generates the label for the pagination badge (e.g., "1-25 of 100")
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.loadDataWrapper.total ? this.pageNumber * pageSize + 1 - pageSize : this.loadDataWrapper.total - this.loadDataWrapper.records.length) + '-' + (this.pageNumber * pageSize > this.loadDataWrapper.total ? this.loadDataWrapper.total : this.pageNumber * pageSize) + ' ' + Labels.LBL_Of + ' ' + this.loadDataWrapper.total;
    }

    // get hasTotalFields() {// r2
    //     return this.showSubTotal && this.aggregationFields.length > 0;
    // }
    get enableMassPopup() {
        return this.showSubTotal && this.aggregationFields.length > 0 ? "left:100px;width: 255px;box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 190%; z-index:6;" : "left:100px;width: 255px;box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;";
    }
    get overrideFilter() {
        return this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.overrideFilter;
    };
    // --- Sorting Popup Data & Getters ---
    get directionOptions() {
        return [
            { label: 'Ascending', value: 'ASC' },
            { label: 'Descending', value: 'DESC' }
        ];
    }

    get disableAddButton() {
        return this.sortingFields.length >= 5;
    }

    // Returns the filter-field configuration as a JSON string.
    get filterSettingsFields() {
        let fieldsMap = this.filtersFieldsMap != undefined ? this.filtersFieldsMap : {};
        let includedFields = this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.FILTERS ? this.initDataWrapper.gridSettingsManager.FILTERS.map(item => item.fieldName).filter(item => !item.includes(".")) : [];
        if (this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.FILTERS) {
            fieldsMap = {};
            this.initDataWrapper.gridSettingsManager.FILTERS.forEach(item => {
                if (includedFields.includes(item.fieldName)) {
                    if (fieldsMap.hasOwnProperty(item.fieldName)) {
                        let olditem = fieldsMap[item.fieldName];
                        fieldsMap[item.fieldName] = Object.assign(JSON.parse(JSON.stringify(item)), olditem);
                    } else {
                        fieldsMap[item.fieldName] = item;
                    }
                }
            });
            if (fieldsMap) {
                let initialFiltersFieldsMap = {};
                Object.values(fieldsMap).forEach(item => {
                    let newItem = item;
                    newItem.value1 = '';
                    newItem.value2 = '';
                    newItem.values = '';
                    if (item.hasOwnProperty('userFilterable')) {
                        newItem.userFilterable = item.userFilterable;
                    }
                    initialFiltersFieldsMap[newItem.fieldName] = newItem;
                });
                this.filtersFieldsMap = initialFiltersFieldsMap;
            }
        }
        if (this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.FILTERS) {
            this.initDataWrapper.gridSettingsManager.FILTERS.forEach(item => {
                if (includedFields.includes(item.fieldName)) {
                    if (fieldsMap.hasOwnProperty(item.fieldName)) {
                        let olditem = fieldsMap[item.fieldName];
                        fieldsMap[item.fieldName] = Object.assign(JSON.parse(JSON.stringify(item)), olditem);
                    } else {
                        fieldsMap[item.fieldName] = JSON.parse(JSON.stringify(item));
                    }
                }
            });
        }
        //this.filtersFieldsMap = fieldsMap;
        return fieldsMap ? JSON.stringify(Object.values(fieldsMap).map(item => {
            let newItem = {
                fieldName: item.fieldName,
                fieldLabel: item.fieldLabel,
                stringFieldType: item.stringFieldType,
                pickListValues: item.pickListValues || [],
                isMultiLevel: item.fieldName && item.fieldName.includes("."),
            };
            if (item.hasOwnProperty('value1')) {
                newItem.value1 = item.value1
            }
            if (item.hasOwnProperty('value2')) {
                newItem.value2 = item.value2
            }
            if (item.hasOwnProperty('values')) {
                newItem.values = item.values
            }
            if (item.hasOwnProperty('userFilterable')) {
                newItem.userFilterable = item.userFilterable;
            }
            return newItem;
        }).sort((item1, item2) => item1.fieldName.includes('RecordTypeId') || item2.fieldName.includes('RecordTypeId') ? 1 : item2.fieldName.localeCompare(item2.fieldName))) : undefined;
    }
    get stringifiedFilters() {
        return this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.FILTERS ? JSON.stringify(this.initDataWrapper.gridSettingsManager.FILTERS) : '[]';
    }
    get hasFilterSettingsFields() {
        return this.allowFilter && (this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.gridLayout && this.initDataWrapper.gridSettingsManager.gridLayout.Filters__c && JSON.parse(this.initDataWrapper.gridSettingsManager.gridLayout.Filters__c).some(filter => filter.userFilterable === true));
    }
    // // SORT 
    // get isSortASC() {
    //     return this.sortDirection == 'ASC';
    // }
    get fieldOptions() {
        let options = [];
        for (let field of this.initDataWrapper.gridSettingsManager.GRID_FIELDS) {
            if (!field.isHidden) {
                options.push({ value: field.fieldName, label: field.fieldLabel });
            }
        }
        return options;
    }
    get getMassUpdateLines() {
        const count = this.records?.reduce((sum, group) => {
            return sum + group.records.filter(item =>
                this.selectedRecordIds.includes(item.Id)
            ).length;
        }, 0);

        return this.Labels.LBL_Selected_Lines.replace('{0}', count);
    }
    // ====================================================================
    // 6. INTERACTION & DML (ACTIONS UTILISATEUR ET DONNÉES)
    // --- Action Handlers: Save, Cancel, Delete, Refresh ---
    // ====================================================================

    /**
     * Saves pending changes (updates and inserts) via Apex.
     * - Updates are taken from `this.recordsToUpdateMap`.
     * - Inserts are taken from `this.newRecords`.
     *
     * When `partialSave` is enabled, valid records may be saved even if others fail.
     */
    normalizeRecord(item) {
        let normalizedItem = { ...item };
        for (let fieldName of Object.keys(normalizedItem)) {
            const field = this.displayedFieldsMap[fieldName];

            if (field?.isReferenceField && field.referencedField) {
                normalizedItem[field.referencedField] = normalizedItem[fieldName];
                delete normalizedItem[fieldName];
                continue;
            }
        }
        return normalizedItem;
    }
    handleSave() {
        try {
            this.tableLoading = true;
            const newRecordsArray = Object.values(this.newRecords);
            if (!this.newRecords.length && !Object.keys(this.recordsToUpdateMap || {}).length) {
                this.showNotification(this.Labels.LBL_Warning, this.Labels.MSG_No_Changes_To_Save, 'warning');
                this.tableLoading = false;
                return;
            }
            const recordsToInsert = newRecordsArray.map(record => {
                const recordForInsert = { ...record };
                delete recordForInsert.Id;
                return recordForInsert;
            });

            let recordsToInsertNormalized = recordsToInsert.map(item => this.normalizeRecord(item));
            let recordsToUpdateNormalized = Object.values(this.recordsToUpdateMap).map(item => this.normalizeRecord(item));
            this.rejectedRecords = [];
            saveRecords({
                recordsToUpdate: JSON.stringify(Object.values(recordsToUpdateNormalized)),
                recordsToInsert: JSON.stringify(recordsToInsertNormalized),
                partialSave: this.partialSave
            }).then(result => {
                if (result == 'SUCCESS') {
                    if (this.saveSuccessMessage) {
                        toastSuccess(this, this.saveSuccessMessage);
                    } else {
                        toastSuccess(this, this.Labels.MSG_Successfully_Saved);
                    }
                    // this.showNotification(this.Labels.LBL_Success, this.Labels.MSG_Successfully_Saved, 'success');
                    this.newRecords = [];
                    this.recordsToUpdateMap = {};
                    this.originalValuesById = {};
                    this.pageNumber = 1;
                    this.initData();
                    if (this.refreshViewAfterSave) {
                        this.dispatchEvent(new RefreshEvent());
                    }
                    this.hasChanges = false;

                    this.selectedActions = [];
                    this.selectedRecordIds = [];

                } else {
                    this.rejectedRecords = [];
                    Object.keys(result.errorMessages).map(key => {
                        toastError(this, saveResult.errorMessages[key]);
                        this.rejectedRecords.push(key);
                        return '' + key;
                    });
                    this.showNotification(this.Labels.LBL_Error, result, 'error');
                    this.tableLoading = false;
                }
            }).catch(error => {
                this.showNotification('Error', error?.body?.message || error?.message || 'Save failed', 'error');
                this.tableLoading = false;
            })
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.tableLoading = false;
        }
    }

    // Navigates back to the record page (or simply reloads/resets the grid).
    handleCancel() {
        this.tableLoading = true;
        this.hasChanges = false;
        this.recordsToUpdateMap = {};
        this.selectedRecordIds = [];
        this.rejectedRecords = [];
        this.loadData();
    }

    // --- Interaction Handlers: Selection, Edit, Pagination, Columns ---

    // Handles individual row checkbox changes.
    toggleSelectedRecords(event) {
        const recordIndex = event.currentTarget.dataset.index;
        const recId = event.currentTarget.dataset.id;
        // const fieldName = event.currentTarget.dataset.field;
        const groupIndex = event.currentTarget.dataset.groupIndex;
        // let item = this.records[recordIndex];
        let record;
        if (groupIndex != null && recordIndex != null) {
            record = this.records[groupIndex]?.records?.[recordIndex];
        }
        if (!record && recId) {
            for (const group of this.records) {
                record = group.records.find(r => r.Id === recId);
                if (record) break;
            }
        }
        record.isSelected = !record.isSelected;
        if (record.isSelected) {
            this.selectedRecordIds.push(record.Id);
        } else {
            this.selectedRecordIds.splice(recordIndex, 1);
        }
    }
    // Selects or deselects all checkboxes in the table.
    toggleAllSelected(event) {
        const checked = event.detail.checked;
        this.records.forEach(group => {
            group.records.forEach(record => {
                record.isSelected = checked;
                if (checked) {
                    this.selectedRecordIds.push(record.Id);
                } else {
                    this.selectedRecordIds = [];
                }
            });
        });
    }
    // Deletes selected rows using Apex and refreshes the grid.
    confirmDeleteRecords() {
        this.tableLoading = true;
        deleteRecords({ recordsIds: this.popups.deletePopup.idsToDelete || [] })
            .then((result) => {
                let deleteResult = JSON.parse(result);
                if (deleteResult.isSuccess) {
                    this.popups.deletePopup.isOpen = false;
                    this.selectedRecordIds = [];
                    this.popups.deletePopup.idsToDelete = [];
                    this.initData();
                } else {
                    this.showNotification(this.Labels.LBL_Error, result, 'error');
                    this.tableLoading = false;
                }
            }).catch(error => {
                this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.tableLoading = false;
            });
    }

    /**
     * Handles inline edits for a single field in the data table.
     * Updates the UI wrapper and prepares an update payload for the corresponding record
     * in `this.recordsToUpdateMap`.
     */
    handleFieldEdits(event) {
        console.log('🛠️ ~ gridSettingsPluginV3.js:1721 -> event: ',  JSON.stringify(event));
        const recordIndex = event.target.dataset.index;
        // const recId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const groupIndex = event.target.dataset.groupIndex;
        let newValue;
        if (event.target.tagName?.toLowerCase() === 'select') {
            newValue = event.target.value;
        } else {
            newValue = event.detail.hasOwnProperty('value')
                ? (event.detail.value ? (typeof event.detail.value === 'string' || typeof event.detail.value === 'number'
                ? event.detail.value : (event.detail.value.join ? event.detail.value.join(';') : event.detail.value))
                : '') : event.detail.hasOwnProperty('checked') ? event.detail.checked : null;
        }
        let record;
        if (groupIndex != null && recordIndex != null) {
            record = this.records[groupIndex]?.records?.[recordIndex];
            //record = this.records[groupIndex]?.records?.find(item => item.index == recordIndex );
            console.log('🛶 ~ gridSettingsPluginV3.js:1737 -> record: ', JSON.stringify(record));
        }
        // if (!record && recId) {
        //     for (const group of this.records) {
        //         record = group.records.find(r => r.Id === recId);
        //         if (record) break;
        //     }
        // }
        if (record) {
            const recordId = record.Id;
            const isNewRecord = typeof recordId === 'number';

            let fieldMeta = this.displayedFieldsMap[fieldName];
            if (fieldMeta && fieldMeta.picklistColorsMap && newValue !== '' && fieldMeta.picklistColorsMap.hasOwnProperty(newValue)) {
                record.rowColor = fieldMeta.picklistColorsMap[newValue];
            } else {
                record.rowColor = '';
            }
            this.displayedFields.forEach(field => {
                if (field.fieldName == fieldName && field.isPicklist) {
                    let picklistField = field.fieldName;
                    let dependentValExist = this.picklistRelationshipMap.hasOwnProperty(picklistField);
                    let depVal = newValue;
                    while (dependentValExist) {
                        let fieldsWrapper = this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(depField => depField.fieldName == this.picklistRelationshipMap[picklistField]);
                        for (let fieldWrapper of fieldsWrapper) {
                            record.values[fieldWrapper.fieldIndex].controllerValue = depVal;
                            // record.values[fieldWrapper.fieldIndex].fieldValue = '';
                            record.values[fieldWrapper.fieldIndex].picklistOptions = [];
                            if (this.dependentPicklistMap[fieldWrapper.fieldName] && this.dependentPicklistMap[fieldWrapper.fieldName][depVal]) {
                                for (let option of this.dependentPicklistMap[fieldWrapper.fieldName][depVal]) {
                                    record.values[fieldWrapper.fieldIndex].picklistOptions.push({ label: option.label, value: option.value, isSelected: fieldWrapper.fieldValue == option.value })
                                }
                            }
                            // record.values[fieldWrapper.fieldIndex].picklistOptions.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                            // console.log("🚀 ~ GridSettingsPluginV3 ~ buildRowData ~ buildDataWrapper.values[fieldWrapper.fieldIndex].picklistOptions:", JSON.stringify(buildDataWrapper.values[fieldWrapper.fieldIndex].picklistOptions))
                            dependentValExist = this.picklistRelationshipMap[fieldWrapper.fieldName] != null;
                            picklistField = fieldWrapper.fieldName;
                            depVal = '';
                        }
                    }
                }
            });

            this.applyRowStyle(record);
            if (isNewRecord) {
                // const newSObject = this.newRecords.find(obj => obj.Id === recordId);
                const newSObject = this.newRecords[recordId];
                if (newSObject) {
                    newSObject[fieldName] = newValue;
                }
                this.newRecords[recordId] = newSObject;
                this.hasChanges = true;
            } else {
                if (!this.originalValuesById[recordId]) {
                    return;
                }
                let updateObject;
                if (this.recordsToUpdateMap.hasOwnProperty(recordId)) {
                    updateObject = this.recordsToUpdateMap[recordId];
                } else {
                    updateObject = {
                        attributes: { type: this.initDataWrapper.gridSettingsManager.OBJECT_NAME },
                        Id: recordId
                    };
                }
                const originalValue = this.originalValuesById[recordId][fieldName];
                // const normalizedNewValue = (newValue === null || newValue === undefined) ? '' : String(newValue);
                // const normalizedOriginalValue = (originalValue === null || originalValue === undefined) ? '' : String(originalValue);

                /* if (normalizedOriginalValue !== normalizedNewValue) {
                    updateObject[fieldName] = newValue;
                } */
                if (originalValue !== newValue) {
                    updateObject[fieldName] = newValue;
                } else {
                    if (updateObject.hasOwnProperty(fieldName)) {
                        delete updateObject[fieldName];
                        return;
                    }
                }
                // const hasAnyChange = Object.keys(updateObject).some(key => key !== 'attributes' && key !== 'Id');
                // if (hasAnyChange) {
                this.recordsToUpdateMap[recordId] = updateObject;
                console.log('recordsToUpdateMap:', JSON.stringify(this.recordsToUpdateMap));
                // } else {
                //     delete this.recordsToUpdateMap[recordId];
                // }
                this.hasChanges = true;
            }
        }

    }

    // Applies row styling/color, primarily background color from conditional formatting.
    applyRowStyle(recordWrapper) {
        console.log("recordWrapper  : "+ JSON.stringify(recordWrapper))
        if (recordWrapper.values && recordWrapper.values.length > 0) {
            for (const fieldWrapper of recordWrapper.values) {
                if (this.originalValuesById.hasOwnProperty(recordWrapper.Id)) {
                    this.originalValuesById[recordWrapper.Id][fieldWrapper.fieldName] = fieldWrapper.fieldValue;
                }

                if (recordWrapper.rowColor !== '') {
                    fieldWrapper.style = /* fieldWrapper.style + */ this.setStyleProp(fieldWrapper.style, 'background-color', recordWrapper.rowColor)
                } else {
                    fieldWrapper.style = /* fieldWrapper.style + */ this.setStyleProp(fieldWrapper.style, 'background-color', '');
                }
            }
            recordWrapper.firstTdStyle = this.getStyleProp(recordWrapper.values[0].style, 'background-color');
            recordWrapper.lastTdStyle = this.getStyleProp(recordWrapper.values[recordWrapper.values.length - 1].style, 'background-color');
        }
    }

    // Utility: Sets a specific CSS property within a style string (handles existing values).
    setStyleProp(style, prop, value) {
        const regex = new RegExp(`${prop}\\s*:\\s*[^;]+`, 'i');
        if (regex.test(style)) {
            return style.replace(regex, `${prop}: ${value}`);
        }
        return style + `${prop}: ${value};`;
    }

    // Utility: Gets a specific CSS property from a style string.
    getStyleProp(style, prop) {
        const regex = new RegExp(`${prop}\\s*:\\s*([^;]+)`, 'i');
        const match = style.match(regex);
        return match ? (prop + ':' + match[1].trim() + ';') : null;
    }

    // Toggles visibility of the Show/Hide Columns modal.
    showHideColumns1() {
        this.showHideColumns = !this.showHideColumns;
    }

    // Handles change in the number of records per page (page size).
    handlePageSize(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.tableLoading = true;
        this.loadData();
    }

    // Handles navigation between pages (Previous, Next, First, Last).
    handleChangePage(event) {
        this.tableLoading = true;
        try {
            const type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.loadDataWrapper.total > 10000 ? Math.ceil((10000 / this.pageSize)) : Math.ceil((this.loadDataWrapper.total / this.pageSize));
            }
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }
    /**
     * Clones an existing record inline (client-side only; no Apex call).
     * The cloned wrapper is added to `this.records` (UI) and the SObject payload is added to
     * `this.newRecords` (save buffer).
     */
    cloneRecord(event) {
        this.tableLoading = true;
        const groupIndex = Number(event.target.dataset.groupIndex);
        const sourceId = event.target.dataset.id;

        try {
            const records = this.records[groupIndex]?.records || [];
            const source = records.find(r => r.Id === sourceId);
            if (!source) {
                this.showNotification(this.Labels.LBL_Error, 'Record not found locally for cloning.', 'error');
                return;
            }
            const newRowIndex = records.length;
            const rowIndex = Number(event.currentTarget.dataset.rowIndex);
            const relationName = this.initDataWrapper.gridSettingsManager.relationName;
            const clonedWrapper = JSON.parse(JSON.stringify(source));
            clonedWrapper.Id = newRowIndex;
            clonedWrapper.link = null;
            clonedWrapper.isSelected = false;
            clonedWrapper.isNew = true;
            const newRecord = {
                attributes: { type: this.initDataWrapper.gridSettingsManager.OBJECT_NAME }
            };
            this.originalValuesById[rowIndex] = {};
            for (const { fieldName, fieldValue } of clonedWrapper.values) {
                this.originalValuesById[rowIndex][fieldName] = fieldValue;

                if (!fieldName.includes('.') && fieldName !== 'Id') {
                    newRecord[fieldName] = fieldValue;
                }
            }
            if (relationName && this.recordId) {
                newRecord[relationName] = this.recordId;
            }
            this.newRecords[rowIndex + 1] = newRecord;
            records.splice(rowIndex+1, 0, clonedWrapper);
            this.hasChanges = true;
            this.showNotification(this.Labels.LBL_Success, this.Labels.MSG_Record_Cloned_Successfully, 'success'
            );
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, `Le clonage a échoué : ${error.message}`, 'error');
            console.error(error);
        } finally {
            this.tableLoading = false;
        }
    }


    /**
     * Creates a new inline record (client-side only; no Apex call).
     * Uses the current row index as a temporary client-side identifier until the record is saved.
     */
    newInlineRecord() {
        this.tableLoading = true;
        const groupIndex = 0;

        try {
            const { OBJECT_NAME, relationName } = this.initDataWrapper.gridSettingsManager;
            const rowIndex = this.records[groupIndex].records.length;
            const newRecord = { attributes: { type: OBJECT_NAME }, Id: rowIndex };

            if (relationName && this.recordId) {
                newRecord[relationName] = this.recordId;
            }

            for (const field of this.displayedFields) {
                let value;
                switch (field.defaultType) {
                    case 'master':
                        value = field.defaultValue ? this.masterObjectInfo?.[field.defaultValue.split('.')[1]] : null;
                        break;
                    case 'text':
                        value = field.defaultValue;
                        break;
                    case 'current': {
                        const ref = this.displayedFields.find(f => f.fieldName === field.defaultValue);
                        value = ref ? this.resolveFieldValue(ref, this.displayedFields) : null;
                        break;
                    }
                    case 'expression':
                        value = field.defaultExpression ? this.evaluateExpression(field, this.displayedFields) : null;
                        break;

                    default:
                        value = null;
                }
                if (value !== null && value !== undefined) {
                    newRecord[field.fieldName] = value;
                }
            }

            this.newRecords[rowIndex] = newRecord;
            this.loadDataWrapper.records.push(newRecord);
            this.records = this.buildData(this.loadDataWrapper.records);
            this.hasChanges = true;
            this.showNotification(this.Labels.LBL_Success, 'Nouvel enregistrement en ligne créé. Cliquez sur Enregistrer pour confirmer.', 'success');
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, `L'ajout d'un nouvel enregistrement a échoué : ${error.message}`, 'error'
            );
            console.error(error);
        } finally {
            this.tableLoading = false;
        }
    }

    resolveFieldValue(field, fields) {
        if (field.defaultType == 'expression') {
            return this.evaluateExpression(field, fields);
        }
        else if (field.defaultType == 'current') {
            const referencedField = fields.find(f => f.fieldName === field.defaultValue);
            if (referencedField) {
                return this.resolveFieldValue(referencedField, fields);
            }
        } else if (field.defaultType == 'master') {
            return this.masterObjectInfo[field.defaultValue.split(".")[1]] || '';
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

        const operators = [];
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

    newRecord() {
        let objectName = this.initDataWrapper && this.initDataWrapper.gridSettingsManager.OBJECT_NAME ? this.initDataWrapper.gridSettingsManager.OBJECT_NAME : undefined;
        if (objectName) {
            var defaultValues = "";
            if (this.recordId) {
                let relationName = this.initDataWrapper.gridSettingsManager.relationName;
                let defaultMasterLookupField = {};
                defaultMasterLookupField[relationName] = this.recordId;
                let fields = this.initDataWrapper.gridSettingsManager.GRID_FIELDS || [];
                for (let field of fields) {
                    if (field.defaultValue != null) {
                        if (field.defaultType == 'master') {
                            defaultMasterLookupField[field.fieldName] = this.masterObjectInfo[field.defaultValue.split(".")[1]];
                        } else if (field.defaultType == 'text') {
                            defaultMasterLookupField[field.fieldName] = field.defaultValue;
                        }
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
            toastError(this, 'can not create new record of type undefined');
        }
    }

    deleteNewInlineRecord(event) {
        const rowIndex = event.target.dataset.index;
        const groupIndex = event.target.dataset.groupIndex;
        const deletedIndex = rowIndex;
        this.records[groupIndex].records.splice(rowIndex, 1);
        for (let i = rowIndex; i < this.records[groupIndex].records.length; i++) {
            const record = this.records[groupIndex].records[i];
            if (record.index !== undefined && record.index > deletedIndex) {
                record.index = record.index - 1;
            }
        }

        if (this.recordsToUpdateMap[deletedIndex]) {
            delete this.recordsToUpdateMap[deletedIndex];
        }
        if (this.newRecords[deletedIndex]) {
            delete this.newRecords[deletedIndex];
        }
        const existingKeys = Object.keys(this.recordsToUpdateMap).map(key => parseInt(key, 10)).sort((a, b) => a - b);
        const keysToShift = existingKeys.filter(key => key > deletedIndex);
        for (const oldIndex of keysToShift) {
            const newIndex = oldIndex - 1;
            this.recordsToUpdateMap[newIndex] = this.recordsToUpdateMap[oldIndex];
            delete this.recordsToUpdateMap[oldIndex];
        }
        this.recordsToUpdateMap = { ...this.recordsToUpdateMap };
        this.records[groupIndex].records = [...this.records[groupIndex].records];
        this.hasChanges = true;

    }

    searchInputChangeHandler(event) {
        this.pageNumber = 1;
        this.filters.searchTerm = event.target.value; // TODO:
        this.tableLoading = true;
        this.loadData();
    }

    // ====================================================================
    // 7. EXPORT & IMPORT EXCEL
    // ====================================================================

    // Initiates the Excel export process.
    exportExcel() {
        this.showFileGenerationBar = true;
        this.msgRowCounter = 0;
        this.tableLoading = true;
        this.fileGenerationLabel = this.Labels.LBL_File_Generation;

        const helper = this.template.querySelector('c-data-loader-helper');
        if (!helper) {
            this.showNotification(this.Labels.LBL_Error, 'Data loader helper not found.', 'error');
            this.tableLoading = false;
            return;
        }

        helper.startExcelExport(null);
    }

    handleExcelSuccess(event) {
        try {
            const allSObjects = event.detail;
            this.allRecordsToExport = this.buildData(allSObjects);

            this.showFileGenerationBar = false;
            this.buildExcel();
        } catch (e) {
            this.showFileGenerationBar = false;
            this.tableLoading = false;
            this.showNotification(this.Labels.LBL_Error, e?.message || String(e), 'error');
        }

    }

    handleExcelError(event) {
        this.showFileGenerationBar = false;
        this.tableLoading = false;
        this.showNotification(this.Labels.LBL_Error, event.detail?.message || 'Export error', 'error');
    }

    // Generates the Excel file using the ExcelJS library and triggers download.
    buildExcel() {
        try {
            let sheetName = this.templateName;
            let fileName = this.templateName;
            let data = this.allRecordsToExport;
            let fields = this.displayedFields?.filter(field => !field.isNotExportable);
            const workbook = new ExcelJS.Workbook();
            workbook.properties.date1904 = true;
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet(sheetName, { properties: { tabColor: { argb: 'worksheet' } } });
            let columns = [];
            let column = {};
            let allFields = fields.map(field => field.fieldName);
            //fields Name
            if (!allFields.includes('Id') && this.allowImport) {
                column = { header: 'Id', width: 10, style: {}, hidden: true };
                columns.push(column);
            }
            fields?.forEach(field => {
                let newItem = {
                    header: field.fieldName, width: field?.fieldLabel?.length, style: {}
                };
                if (field.isNumber) {
                    newItem.style.numFmt = '0';
                    if (field.scale) {
                        newItem.style.numFmt += ".";
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
            worksheet.columns = columns;
            //fields Label
            let newRow = [];
            if (!allFields.includes('Id') && this.allowImport) {
                newRow.push('Id');
            }
            fields?.forEach(field => {
                newRow.push(field.fieldLabel);
            });
            worksheet.addRow(newRow);
            //data
            Object.values(data)?.forEach(rec => {
                rec.records?.forEach(item => {
                    this.msgRowCounter++;
                    let newRow1 = [];
                    if (!allFields.includes('Id') && this.allowImport) {
                        newRow1.push(item.Id);
                    }
                    item.values?.forEach(field => {
                        if (!field.isNotExportable) {
                            if (field.isBoolean) {
                                if (field.fieldValue) {
                                    newRow1.push('✓');
                                } else {
                                    newRow1.push('✗');
                                }
                            } else if (field.isPicklist) {
                                let picklistValue = field.fieldValue || '';
                                if (field.fieldValue && field.pickListValueMap && field.pickListValueMap.hasOwnProperty(field.fieldValue)) {
                                    picklistValue = field.pickListValueMap[field.fieldValue];
                                }
                                newRow1.push(picklistValue);
                            } else if (field.isMultiPicklist) {
                                let picklistValue = field.fieldValue || '';
                                if (field.fieldValue && field.fieldValue.length) {
                                    picklistValue = field.fieldValue.map(val => {
                                        val = val.trim();
                                        return field.pickListValueMap && field.pickListValueMap.hasOwnProperty(val) ? field.pickListValueMap[val] : val;
                                    }).join(';');
                                }
                                newRow1.push(picklistValue);
                            } else if (field.isText) {
                                if (field.fieldValue?.includes('<br>')) {
                                    newRow1.push(field.fieldValue.replaceAll('<br>', '\n'));
                                } else {
                                    newRow1.push(field.fieldValue);
                                }
                            } else if (field.isDate && field.fieldValue != null) {
                                newRow1.push(new Date(field.dateValue));
                            } else if (field.isDateTime && field.fieldValue != null) {
                                let formatter = new Intl.DateTimeFormat(this.userLocal);
                                let date = new Date(field.dateTimeValue);
                                let fullDate;
                                if (formatter) {
                                    const easternTime = date.toLocaleString(this.userLocal, { timeZone: this.timeZone });
                                    fullDate = easternTime;
                                }
                                newRow1.push(fullDate);
                            } else if (field.isReference && !this.allowImport) {
                                newRow1.push(field.refValue);
                            } else {
                                newRow1.push(field.fieldValue);
                            }
                        }
                    });
                    worksheet.addRow(newRow1);
                    this.fileGenerationValue = (this.msgRowCounter / this.totalExportSize) * 100;
                    this.fileGenerationLabel = this.Labels.LBL_File_Generation.replace('{0}', this.msgRowCounter).replace('{1}', this.totalExportSize);
                });
            });
            worksheet._rows?.forEach((row, rowIndex) => {
                if (rowIndex == 0) {
                    row.hidden = true;
                }
                row._cells?.forEach((cell, cellIndex) => {
                    cell.border = {
                        top: { style: 'thin', color: { argb: '000000' } },
                        left: { style: 'thin', color: { argb: '000000' } },
                        bottom: { style: 'thin', color: { argb: '000000' } },
                        right: { style: 'thin', color: { argb: '000000' } }
                    };
                    let field = fields[(this.allowImport ? cellIndex - 1 : cellIndex)];
                    if (field) {
                        if (rowIndex == 1) {
                            cell.font = {
                                color: { argb: '444444' },
                                bold: rowIndex == 0 ? true : false,
                            }
                            cell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: 'f3f3f3' },
                            }
                        } else {
                            cell.font = {
                                color: { argb: field.color?.replace('#', '') },
                                bold: rowIndex == 0 ? true : false,
                            }
                            cell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: field.bgColor?.replace('#', '') },
                            }
                        }
                        if (cell._value.model.value == '✓') {
                            cell.font = {
                                color: { argb: '00FF00' },
                                bold: true,
                            }
                        }
                        if (cell._value.model.value == '✗') {
                            cell.font = {
                                color: { argb: 'FF0000' },
                                bold: true,
                            }
                        }
                        if (!cell.numFmt && field.numFmt) {
                            cell.numFmt = field.numFmt;
                        }
                        if (field.isPicklist && field.picklistValuesMap) {
                            let formulae = `"` + Object.keys(field.picklistValuesMap)?.filter(keyField => keyField && field.picklistValuesMap[keyField]).map(keyField => field.picklistValuesMap[keyField]).join(',') + `"`;
                            cell.dataValidation = {
                                type: 'list',
                                allowBlank: true,
                                formulae: [formulae]
                            };
                        }
                        if (field.isBoolean) {
                            cell.dataValidation = {
                                type: 'boolean',
                                allowBlank: true,
                            };
                        }
                        if (!field.isCalculated && !field.isId && !field.fieldName.includes(".")) {
                            cell.protection = { locked: false, lockText: false };
                        } else {
                            cell.protection = { locked: true, lockText: true };
                        }
                    }
                });
            });
            worksheet._rows[0]._cells?.forEach(cell => {
                cell.protection = { locked: true, lockText: false };
            });
            window.wb = workbook;
            this.showFileDownloadBar = true;
            this.fileDownloadValue = 25;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement("a");
                document.body.appendChild(a);
                this.fileDownloadValue = 50;
                a.style = "display: none";
                let base64Bin = result.toString('base64');
                a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
                this.fileDownloadValue = 75;
                a.download = fileName + '.xlsx'; //File name Here
                a.click();
                this.fileDownloadValue = 100;
                this.tableLoading = false;
                this.showFileDownloadBar = false;
            });
            this.allRecordsToExport = [];
        } catch (error) {
            this.tableLoading = false;
            console.log('error >> ' + error)
        }
    }

    // --- Import Excel Logic ---    
    // Opens the import file selection popup.
    isAdvancedImport = false;
    handleOpenImport() {
        this.openImportPopup = true;
        if (this.importSettingsTemplate) {
            this.isAdvancedImport = true;
        } else {
            this.file = '';
            this.fileName = '';
        }
    }

    // advanced import settings handler
    fileDirectoryId;
    importedRecords = [];
    fileData = {};
    uploadExcel(event) {
        this.importedRecords = event.detail.value;
        this.fileData = JSON.stringify(event.detail.fileData);
        this.importedJSONData = JSON.stringify(JSON.parse(this.importedRecords));
        if (this.isAdvancedImport) {
            this.handleImportRecords();
        }
    }

    // Closes the import popup.
    handleCloseImportPopup() {
        this.fileName = '';
        this.openImportPopup = false;
    }

    // Stores the selected file object and name.
    handleFileSelect(event) {
        const files = event.target.files;
        this.file = files[0];
        this.fileName = this.file.name;
    }
    // Confirmation handler for file selection (starts the conversion).
    handleConfirmImport() {
        if (!this.isAdvancedImport) {
            if (this.file.name.endsWith('.xls') || this.file.name.endsWith('.xlsx')) {
                this.excelToJSON(this.file);
            }
        } else {
            this.prepareFile();
        }
    }
    // Prepares the file for advanced import settings.
    prepareFile() {
        const child = this.template.querySelector('c-import-settings');
        if (child) {
            child.prepareFile();
        }
    }
    // Converts the Excel file binary data into a JSON array of records.
    excelToJSON(file) {
        this.tableLoading = true;
        var reader = new FileReader();
        reader.onload = event => {
            const data = event.target.result;
            try {
                var workbook = XLSX.read(data, {
                    type: 'binary'
                });
                Object.keys(workbook.Sheets).forEach(sheetName => {
                    var XL_row_object = XLSX.utils.sheet_to_row_object_array(workbook.Sheets[sheetName]);
                    XL_row_object.forEach((rec, recIndex) => {
                        Object.keys(rec).forEach(key => {
                            if (this.displayedFieldsMap[key]) {
                                if (recIndex > 0 && rec[key] != undefined && rec[key] != '' && rec[key] != null) {
                                    if (this.displayedFieldsMap[key].isDate) {
                                        let currentVal = new Date(rec[key]);
                                        let ye = new Intl.DateTimeFormat('fr', { year: 'numeric' }).format(currentVal);
                                        let mo = new Intl.DateTimeFormat('fr', { month: '2-digit' }).format(currentVal);
                                        let da = new Intl.DateTimeFormat('fr', { day: '2-digit' }).format(currentVal);
                                        rec[key] = this.csvDateFormat ? this.csvDateFormat.toLowerCase().replace('dd', da).replace('mm', mo).replace('yyyy', ye) : da + '/' + mo + '/' + ye;
                                    } else if (this.displayedFieldsMap[key].isBoolean) {
                                        let currentVal = rec[key];
                                        if (currentVal == '✓' || currentVal.toLowerCase() == 'true' || currentVal == '1' || currentVal.toLowerCase() == 'yes' || currentVal.toLowerCase() == 'y') {
                                            rec[key] = 'true';
                                        } else if (currentVal == '✗' || currentVal.toLowerCase() == 'false' || currentVal == '0' || currentVal.toLowerCase() == 'no' || currentVal.toLowerCase() == 'n') {
                                            rec[key] = 'false';
                                        }
                                    } else if (this.displayedFieldsMap[key].isPicklist) {
                                        let currentVal = rec[key];
                                        for (let pickVal of this.displayedFieldsMap[key].pickListValues) {
                                            if (currentVal == pickVal.label) {
                                                rec[key] = pickVal.value;
                                            }
                                        }
                                    } else if (this.displayedFieldsMap[key].isMultiPicklist) {
                                        let currentVal = rec[key];
                                        let apiValues = [];
                                        for (let selectedVal of currentVal.split(';')) {
                                            for (let pickVal of this.displayedFieldsMap[key].pickListValues) {
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
                    var data = JSON.stringify(XL_row_object);
                    this.importedJSONData = data;
                    console.log("🚀 ~ GridSettingsPluginV3 ~ uploadExcel ~ this.importedJSONData:1", JSON.stringify(this.importedJSONData))
                    this.handleImportRecords();
                });
            } catch (err) {
                toastError(this, ' ' + (err && err.body && err.body.message ? err.body.message : err));
            }
            this.tableLoading = false;
        };
        reader.onerror = function (ex) {
            this.error = ex;
            toastError(this, this.Labels.LBL_Error_While_Reading_The_File + ex.message);
        };
        reader.readAsBinaryString(file);
    }

    // Calls Apex to insert/update the imported records.
    handleImportRecords() {
        this.openImportPopup = false;
        let fieldsToImport = this.displayedFields.filter(field => !field.isNotExportable && field.isInputField).map(item => item.fieldName);
        if (!fieldsToImport.includes('Id')) {
            fieldsToImport.unshift('Id');
        }
        this.tableLoading  = true;
        importRecords({
            objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
            xlsData: this.importedJSONData,
            fieldsToImport: fieldsToImport,
            parentId: this.recordId,
            lookupName: this.initDataWrapper.gridSettingsManager.relationName,
            isAdvancedImport: this.isAdvancedImport
        }).then(result => {
            toastSuccess(this, this.Labels.LBL_Import_Finish);
            this.initData();
        }).catch(error => {
            this.tableLoading = false;
            console.log('error >>> ' + JSON.stringify(error))
            toastError(this, ' ' + (error && error.body && error.body.message ? error.body.message : error));
        });
    }

    // ====================================================================
    // 8. SCREEN FLOW HANDLERS / ACTIONS & NAVIGATION
    // ====================================================================

    // Toggles the visibility of the Screen Flow modal and sets up flow variables.
    // toggleFlow(event) {
    //     const flowName = event.target.dataset.flowName;
    //     console.log('🏕️ ~ gridSettingsPluginV3.js:2587 -> flowName: ', flowName);
    //     const flowLabel = event.target.dataset.flowLabel;
    //     this.tableLoading = true;
    //     getFlowVariables({ flowApiName: flowName }).then((result) => {
    //         let flowVariables = JSON.parse(result);
    //         console.log('🎲 ~ gridSettingsPluginV3.js:2593 -> flowVariables: ', JSON.stringify(flowVariables));
    //         let variableExist = flowVariables.filter(variable => variable.isInput && variable.name == 'recordIds')
    //         this.currentFlow = {
    //             header: flowLabel,
    //             flowApiName: this.initDataWrapper.prefix + flowName
    //         }
    //         if (variableExist && variableExist.length > 0) {
    //             this.currentFlow.flowVariables = [{
    //                 name: 'recordIds',
    //                 type: 'String',
    //                 value: this.selectedRecordIds
    //             }];
    //         }
    //         this.openFlow = !this.openFlow;
    //         this.tableLoading = false;
    //     }).catch(err => {
    //         toastError(this, ' ' + (err && err.body && err.body.message ? err.body.message : err));
    //         this.tableLoading = false;
    //     })
    // }

    toggleFlow(event) {
        try {
            console.log('toggleFlow')
            let flowName = event.target.dataset.flowName;
            let flowLabel = event.target.dataset.flowLabel;
            this.tableLoading = true;
            this.currentFlow = {
                header: flowLabel,
                flowApiName: /*this.instance.resultWrapper.prefix + */flowName,
                flowVariables: []
            }
            console.log('1')
            if (this.initDataWrapper
                && this.initDataWrapper.gridSettingsManager
                && this.initDataWrapper?.gridSettingsManager?.actions
                && this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows) {
                console.log('2')
                let matchedFlow = this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows.filter(flow => flow.value == flowName);
                console.log('matchedFlow >>> ' + JSON.stringify(matchedFlow))
                if (matchedFlow && matchedFlow.length > 0) {
                    console.log('3')
                    if (this.recordId && matchedFlow[0].hasRecordId != null && matchedFlow[0].hasRecordId == true) {
                        console.log('hasRecordId')
                        this.currentFlow.flowVariables.push({
                            name: 'recordId',
                            type: 'String',
                            value: this.recordId
                        })
                    }
                    if (matchedFlow[0].hasRecordIds != null && matchedFlow[0].hasRecordIds == true) {
                        console.log('hasRecordIds')
                        this.currentFlow.flowVariables.push({
                            name: 'recordIds',
                            type: 'String',
                            value: this.instance.selectedRecordsIds
                        })
                    }
                }
            }
            this.openFlow = !this.openFlow;
            this.tableLoading = false;
        } catch (error) {
            console.log(JSON.stringify(error))
        }
    }

    // Closes the Flow modal.
    closeFlow() {
        this.openFlow = false;
    }

    // Handles the status change event from the lightning-flow component.
    handleFlowStatusChange(event) {
        console.log(event)
        // TODO: Store the output values (event.detail.outputVariables).
        if (event.detail.status === "FINISHED") {
            toastSuccess(this, event.detail.status);
            this.openFlow = !this.openFlow;
            this.currentFlow = {};
            this.tableLoading = true;
            this.loadData();
        }
        if (event.detail.status === "ERROR") {
            toastError(this, event.detail.status);
        }
    }

    /**
      * Handles a change in the list-view actions menu.
      *
      * Supports:
      * - Navigation to a Visualforce page by Id (resolved to an API name), or
      * - Navigation to a custom URL with dynamic variable resolution.
      *
      * @param {Event} event Click/change event (expects `data-id` or `data-url` on the target).
     */
    async handleActionsChange(event) {
        const actionId = event.target.dataset.id;
        const actionUrl = event.target.dataset.url;
        let pageName;
        let selectedFields = this.displayedFields.map(field => field.fieldName);

        if (actionId != null && actionUrl == null && this.objectApiName != 'None' && this.objectApiName != undefined) {
            await getApiName({ Id: actionId }).then(result => {
                this.vfPageName = JSON.parse(result);
                for (let item of this.vfPageName) {
                    pageName = item.Name;
                }
            });
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/apex/${pageName}?object=${this.objectApiName}&selectedFields=${selectedFields}&selectedIds=${this.selectedRecordIds}`,
                },
            });
        } else if (actionUrl != null) {
            let param = /{([^}]+)}/g;
            let matches = actionUrl.match(param);

            if (matches) {
                let values = matches.map(match => match.substring(1, match.length - 1)); // Removes "{" and "}"
                let variables = {
                    objectName: '',
                    action: '',
                };

                values.forEach(value => {
                    let parts = value.split(".");
                    variables.objectName = parts[0];
                    variables.action = parts[1];
                });

                await actionsMap({
                    objectName: variables.objectName,
                    parameters: variables.action
                }).then(result => {
                    if (variables.objectName == '!$Site') {
                        let actions = result;
                        actionUrl = actionUrl.replace(/{.*?\}/, actions);

                    } else if (variables.objectName == '!$User' || variables.objectName == '!$UserRole') {
                        let actions = result;
                        let value = [];
                        for (let action of actions) {
                            for (let i = 0; i < actions.length; i++) {
                                let param = Object.values(action)[i];
                                if (param.includes(' ')) {
                                    param = param.replaceAll(' ', '_');
                                }
                                value.push(param);
                            }
                        }
                        actionUrl = actionUrl.replace(/{.*?\}/, value);
                    }
                }).catch(error => {
                    console.log("🚀 ~ GridSettingsPlugin ~ handleActionsChange ~ error:", JSON.stringify(error))
                });
            }
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: actionUrl,
                }
            });
        }
    }
    // ====================================================================
    // 9. UI & UTILITY (AFFICHAGE ET UTILITAIRES)
    // ====================================================================

    // Handler for window resize event (calls setSticky).
    handleResize = () => this.setSticky();

    // Applies CSS 'sticky' positioning to column headers and data cells based on configuration.
    setSticky() {
        let fixedSticky = this.displayCloneButton && this.enableMassUpdate ? 2 : this.displayCloneButton || this.enableMassUpdate ? 1 : 0;
        if (this.numberOfFixedColumns != null && this.numberOfFixedColumns >= 0) {
            var headRows = this.template.querySelectorAll('.initial-table thead tr');
            let top = 0;
            for (let index = 0; headRows && index < headRows.length; index++) {
                let childrens = headRows[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < (this.numberOfFixedColumns + fixedSticky)) {
                        childrens[index2].style.zIndex = 6;
                        childrens[index2].style.left = left + 'px ';
                        left += childrens[index2].offsetWidth;

                    } else {
                        childrens[index2].style.zIndex = index == 0 ? 5 : 4;
                        childrens[index2].style.left = 'unset';
                    }
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.top = top + 'px';
                }
                top += headRows[index].offsetHeight;
            }
            var rows = this.template.querySelector('.initial-table') ? this.template.querySelector('.initial-table tbody').rows : [];
            for (let index = 0; rows && index < rows.length; index++) {
                let childrens = rows[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < (this.numberOfFixedColumns + fixedSticky)) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = 3;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].classList.add('stickyTD');
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.left = 'unset';
                        childrens[index2].style.zIndex = 0;
                        childrens[index2].classList.remove('stickyTD');
                    }
                }
            }
        }
    }

    // --- Utility Method ---

    // Shows a standard Lightning toast notification.
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }


    // ====================================================================
    // 10. 
    // ====================================================================

    getFieldDependencies(controllerField, fieldName) {
        return getFieldDependencies({
            objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
            controllingField: controllerField,
            dependentField: fieldName
        }).then((result) => {
            this.dependentPicklistMap[fieldName] = {};
            for (let key of Object.keys(result)) {
                this.dependentPicklistMap[fieldName][key] = result[key];
            }
        }).catch((apexError) => {
            console.error(apexError);
        });
    }
    getPicklistValuesByRecordTypeId(allPicklistFields) {
    return getPicklistValuesByRecordTypeId({
        objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
        allPicklistFields: allPicklistFields
    }).then((result) => {
        let results = JSON.parse(result);
        console.log("Parsed results:", JSON.stringify(results));
        this.availablePicklistValues = {};
        for (const recordTypeId in results) {
            const fields = results[recordTypeId];
            for (const fieldName in fields) {
                if (!this.availablePicklistValues[fieldName]) {
                    this.availablePicklistValues[fieldName] = {};
                }
                this.availablePicklistValues[fieldName][recordTypeId] = Object.values(fields[fieldName]);
            }
        }
        console.log("Structured availablePicklistValues (arrays):", JSON.stringify(this.availablePicklistValues));
    });
}

    isShowFilterOnColumnHeader = false;
    hiddenGridFields = [];
    handleChangeSelectedFields(event) {
        this.selectedFields = event.detail.value;
    }
    confirmSelectionFields() {
        this.hiddenGridFields = [];
        for (let field of this.displayedFields) {
            if (!this.selectedFields.includes(field.fieldName)) {
                field.isHidden = true;
                this.hiddenGridFields.push(field);
            } else {
                field.isHidden = false;
            }
        }
        localStorage.setItem(this.templateName, JSON.stringify(this.hiddenGridFields));
        this.showHideColumns = !this.showHideColumns;
        this.loadData();
    }

    // File upload
    handleFileUploadChange(event) {
        if (event.detail.files) {
            this.selectedFile = event.detail.files[0];
            let newFileUrl = this.baseUrl + '/sfc/servlet.shepherd/document/download/' + this.selectedFile.documentId;
            this.currentUploadfileField.fieldValue = newFileUrl;
            let recordKey;
            if (this.currentUploadfileRecord) {
                recordKey = this.currentUploadfileRecord;
            } else {
                recordKey = this.currentUploadfileRecordIndex;
                this.uploadedFileMap[this.selectedFile.documentId] = recordKey;
            }
        } else {
            this.currentUploadfileField.fieldValue = event.target.value;
        }
    }
    handleToggleInputFilePopup(event) {
        this.uploadFilePopup = !this.uploadFilePopup
        if (this.uploadFilePopup) {
            this.currentUploadfileRecord = event.target.dataset.id;
            if (!this.currentUploadfileRecord) {
                this.currentUploadfileRecordIndex = event.target.dataset.rowIndex;
            }
            this.currentUploadfileField.fieldName = event.target.dataset.field;
            this.currentUploadfileField.fieldValue = event.target.dataset.fieldValue;
        } else {
            this.currentUploadfileField = {};
            this.currentUploadfileRecordIndex = '';
            this.currentUploadfileRecord = '';
            this.selectedFile = {};
        }
    }
    handleSaveFileUpload() {
        let recordRow = this.currentUploadfileRecord ? this.currentUploadfileRecord : this.currentUploadfileRecordIndex;
        if (!this.recordsToUpdateMap.hasOwnProperty(recordRow) || this.recordsToUpdateMap[recordRow] == undefined) {
            this.recordsToUpdateMap[recordRow] = {};
        }

        this.recordsToUpdateMap[recordRow][this.currentUploadfileField.fieldName] = this.currentUploadfileField.fieldValue;
        this.records = this.records.forEach(group => {
            group.records.filter(rec => {
                if (rec.Id == recordRow || rec.index == recordRow) {
                    rec.fields = rec.fields.filter(f => {
                        if (f.key == this.currentUploadfileField.fieldName) {
                            f.value = this.currentUploadfileField.fieldValue;
                        }
                        return f;
                    })
                }
                return rec;
            });
        });
        this.hasChanges = true;

        this.handleToggleInputFilePopup();
    }
    handleDeleteInputFilePopup(event) {
        let currentUploadfileRecord = event.target.dataset.id;
        let currentUploadfileRecordIndex = event.target.dataset.rowIndex;
        let fieldName = event.target.dataset.field;
        let recordRow = currentUploadfileRecord ? currentUploadfileRecord : currentUploadfileRecordIndex;
        if (!this.recordsToUpdateMap.hasOwnProperty(recordRow) || this.recordsToUpdateMap[recordRow] == undefined) {
            this.recordsToUpdateMap[recordRow] = {};
        }
        this.recordsToUpdateMap[recordRow][fieldName] = '';
        this.records = this.records.forEach(group => {
            group.records.filter(rec => {
                if (rec.Id == recordRow || rec.index == recordRow) {
                    rec.fields = rec.fields.filter(f => {
                        if (f.key == fieldName) {
                            f.value = '';
                        }
                        return f;
                    })
                }
                return rec;
            });
        });
        this.hasChanges = true;

    }


    // Section : FILTER PANEL HANDLERS
    // Opens or closes the right-side filter panel.
    toggleFilter() {
        this.template.querySelector('.filterPanel').classList.toggle('slds-hide');
    }
    applyFilter(event) {
        this.filters.dynamic = event.detail.dynamicFilters;
        this.numberOfFixedColumns = Number(event.detail.numberOfFixedColumns);
        this.toggleFilter();
        this.loadData();
    }

    // section : MASS UPDATE HANDLERS
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
    massUpdateHandler(event) {
        try {
            let value = event.target.value;
            let index = event.target.dataset.index;
            let fieldName = event.target.dataset.field;
            let fieldDependancy = event.target.dataset.fieldDependancy;
            let fieldDependancyIndex = event.target.dataset.fieldDependancyIndex;

            if (index !== undefined && this.displayedFields[index]) {
                if (fieldDependancy == 'controller') {
                    this.displayedFields[index].controller.value = value;
                } else if (fieldDependancy == 'controlledBy') {
                    let picklistField = this.displayedFields[index];
                    fieldDependancyIndex = parseInt(fieldDependancyIndex);

                    for (let i = fieldDependancyIndex + 1; i < picklistField.controlledByFields.length; i++) {
                        let controlledField = picklistField.controlledByFields[i];
                        let dependPicklistField = this.displayedFields.find(item => item.fieldName == controlledField.controlledByName);

                        if (dependPicklistField && i == fieldDependancyIndex + 1 && value) {
                            controlledField.options = [];
                            controlledField.disabled = false;

                            let dependentOptions = this.dependentPicklistMap?.[controlledField.controlledByName]?.[value];
                            if (dependentOptions) {
                                for (let option of dependPicklistField.options) {
                                    let validOption = dependentOptions.find(item => item.value == option.value);
                                    if (validOption) {
                                        controlledField.options.push({ label: option.label, value: option.value, isSelected: false });
                                    }
                                }
                                // controlledField.options.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                            }
                        } else if (controlledField) {
                            controlledField.options = [];
                            controlledField.disabled = true;
                            dependPicklistField.hasChanged = false;
                        }
                    }
                    this.displayedFields[index].controlledByFields.forEach(item => {
                        if (item.controlledByName == fieldName) {
                            item.value = value;
                        }
                    });
                } else {
                    this.displayedFields[index].value = value;
                }
                this.displayedFields[index].hasChanged = true;
            }
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }
    handleApplyMassUpdate(event) {
        try {
            const fieldName = event.target.dataset.field;

            //let massRecordToUpdate = this.displayedFields.filter(item => item.hasChanged);
            let massRecordToUpdate = this.displayedFields.filter(item => item.fieldName == fieldName);
            let selectedList = this.selectedRecordIds;
            if (selectedList.length == 0) {
                toastWarning(this, Labels.MSG_No_Items_Selected);
                return;
            }

            let records = this.records.flatMap((group, groupIndex) =>
                group.records.filter(item => item.isSelected)
                    .map(item => ({
                        ...item,
                        groupIndex,
                        index: item.index
                    }))
            );
            records.forEach(item => {
                let field = massRecordToUpdate[0];
                let value = field.isPicklist ? (field.value || field.pickListValues[0].value) : field.value;
                if (!field.hasDependentPicklist) {
                    this.applyMassFieldUpdate(item, { fieldName: field.fieldName, value: value });

                } else {
                    if (field.controller) {
                        this.applyMassFieldUpdate(item, { fieldName: field.controller.controllerName, value: field.controller.value });
                    }
                    if (field.controlledByFields) {
                        field.controlledByFields.forEach(controlledField => {
                            this.applyMassFieldUpdate(item, { fieldName: controlledField.controlledByName, value: controlledField.value });
                        })
                    }
                }
            });

            // close the popup
            this.template.querySelectorAll('[data-updatefield]')?.forEach(element => {
                element.classList.add('slds-hide');

                /*  // reset UI values (inputs, textarea, select, etc.)
                 element.querySelectorAll('input, textarea, select, lightning-input, lightning-combobox')
                     .forEach(input => {
                         if (input.tagName === 'SELECT') {
                             input.selectedIndex = 0;
                         } else {
                             input.value = null;
                         }
                     }); */
            });

            /*  // reset JS model values
             massRecordToUpdate.forEach(field => {
                 field.fieldValue = null;
 
                 if (field.isPicklist && field.options) {
                     field.options = field.options.map(opt => ({
                         ...opt,
                         isSelected: false
                     }));
                 }
 
                 if (field.hasDependentPicklist && field.controlledByFields) {
                     field.controlledByFields = field.controlledByFields.map(cb => ({
                         ...cb,
                         value: null,
                         options: cb.options.map(o => ({
                             ...o,
                             isSelected: false
                         }))
                     }));
                 }
             }); */
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }
    applyMassFieldUpdate(record, field) {
        console.log('🛠️ ~ gridSettingsPluginV3.js:3133 -> field: ', JSON.stringify(field));
        console.log('🚢 ~ gridSettingsPluginV3.js:3133 -> record: ', JSON.stringify(record));
    
        let event = {
            target: {
                dataset: {
                    id: record.Id,
                    field: field.fieldName,
                    groupIndex: record.groupIndex,
                    index: record.index
                },
                closest() {
                    return {
                        dataset: {
                            rowIndex: record.index
                        }
                    };
                }
            },
            detail: {
                value: field.value
            }
        };

        console.log("🚀 applyMassFieldUpdate ~ field.Value:", field.value);
        this.handleFieldEdits(event);
        record?.values?.forEach(element => {
            if (element.fieldName !== field.fieldName) return;
            element.fieldValue = field.value;
            if (element.isPicklist) {
                const updateSelection = list =>
                    list.map(opt => ({
                        ...opt,
                        isSelected: opt.value === field.value
                    }));
                element.picklistOptions = updateSelection(element.picklistOptions || []);
                element.pickListValues = updateSelection(element.pickListValues || []);
            }
        });

        console.log("🚀 applyMassFieldUpdate ~ record:", JSON.stringify(record));
    }

    /**
     * Multi-column sorting popup handlers (ported and adapted from the legacy plugin).
     */
    // section : Sorting Popup Handlers
    // Toggles the visibility of the sorting configuration popup.
    toggleSortingPopup() {
        this.sortingPopupOpen = !this.sortingPopupOpen;
        if (this.sortingPopupOpen) {
            this.initializeSortingFields();
        }
    }
    // Initializes sorting fields based on previously applied configuration or defaults.
    initializeSortingFields() {
        const gridManager = this.initDataWrapper?.gridSettingsManager;
        const fields = gridManager?.GRID_FIELDS || [];

        // Build available fields list from GRID_FIELDS (not only displayed columns)
        this.availableSortFields = fields.map(field => ({
            label: field.fieldLabel,
            value: field.fieldName
        }));

        // Start from previously applied config or default config from metadata
        const sortingConfig = this.appliedSortConfig
            ? this.appliedSortConfig
            : (gridManager?.defaultSortFields || []);

        if (sortingConfig && sortingConfig.length > 0) {
            this.sortingFields = sortingConfig.map((sortItem, index) => ({
                id: Date.now() + index,
                fieldName: sortItem.fieldName,
                fieldLabel: sortItem.label || '',
                direction: sortItem.direction || 'ASC'
            }));
        } else if (this.sortingFields.length === 0) {
            this.sortingFields = [{
                id: Date.now(),
                fieldName: '',
                fieldLabel: '',
                direction: 'ASC'
            }];
        }

        this.appliedSortConfig = sortingConfig;
        console.log("🚀 ~ GridSettingsPluginV3 ~ initializeSortingFields ~ this.appliedSortConfig :", this.appliedSortConfig)
    }

    addSortColumn() {
        if (this.sortingFields.length < 5) {
            this.sortingFields.push({
                id: Date.now(),
                fieldName: '',
                direction: 'ASC'
            });
        } else {
            toastWarning(this, 'Maximum 5 sort columns allowed');
        }
    }

    removeSortColumn(event) {
        const sortId = parseInt(event.currentTarget.dataset.sortId, 10);
        const next = (this.sortingFields || []).filter(f => f.id !== sortId);
        this.sortingFields = next.length ? next : [{
            id: Date.now(),
            fieldName: '',
            direction: 'ASC'
        }];
    }

    handleSortFieldChange(event) {
        const sortId = parseInt(event.currentTarget.dataset.sortId, 10);
        const fieldName = event.detail.value;
        const selectedField = this.availableSortFields.find(f => f.value === fieldName);
        const fieldLabel = selectedField ? selectedField.label : '';

        this.sortingFields = this.sortingFields.map(field =>
            field.id === sortId ? { ...field, fieldName, fieldLabel } : field
        );
    }

    handleSortDirectionChange(event) {
        const sortId = parseInt(event.currentTarget.dataset.sortId, 10);
        const direction = event.detail.value;
        this.sortingFields = this.sortingFields.map(field =>
            field.id === sortId ? { ...field, direction } : field
        );
    }

    moveSortUp(event) {
        const sortId = parseInt(event.currentTarget.dataset.sortId, 10);
        const index = this.sortingFields.findIndex(f => f.id === sortId);
        if (index > 0) {
            const temp = [...this.sortingFields];
            [temp[index - 1], temp[index]] = [temp[index], temp[index - 1]];
            this.sortingFields = temp;
        }
    }

    moveSortDown(event) {
        const sortId = parseInt(event.currentTarget.dataset.sortId, 10);
        const index = this.sortingFields.findIndex(f => f.id === sortId);
        if (index < this.sortingFields.length - 1) {
            const temp = [...this.sortingFields];
            [temp[index], temp[index + 1]] = [temp[index + 1], temp[index]];
            this.sortingFields = temp;
        }
    }

    applySorting() {
        const invalidFields = this.sortingFields.filter(f => !f.fieldName);
        if (invalidFields.length > 0) {
            toastWarning(this, 'Please select a field for all sort columns');
            return;
        }

        const sortConfig = this.sortingFields.map(f => ({
            fieldName: f.fieldName,
            direction: f.direction
        }));

        this.appliedSortConfig = sortConfig;

        if (sortConfig.length > 0) {
            this.sortFieldApi = sortConfig[0].fieldName;
            this.sortDirection = sortConfig[0].direction;
        } else {
            this.sortFieldApi = '';
            this.sortDirection = '';
        }

        // Update header sort indicators on displayed fields
        this.displayedFields.forEach(f => {
            const sortConfigForField = sortConfig.find(s => s.fieldName === f.fieldName);
            if (sortConfigForField) {
                f.sortedField = true;
                f.sortedAscending = sortConfigForField.direction === 'ASC';
                f.sortedDescending = sortConfigForField.direction === 'DESC';
            } else {
                f.sortedField = false;
                f.sortedAscending = false;
                f.sortedDescending = false;
            }
        });

        this.sortingPopupOpen = false;
        this.tableLoading = true;
        this.loadData(sortConfig);
    }

    clearSorting() {
        this.sortingFields = [];
        this.sortFieldApi = '';
        this.sortDirection = '';
        this.appliedSortConfig = null;

        this.displayedFields.forEach(f => {
            f.sortedField = false;
            f.sortedAscending = false;
            f.sortedDescending = false;
        });

        this.sortingPopupOpen = false;
        this.tableLoading = true;
        this.loadData();
    }

    cancelSorting() {
        this.sortingPopupOpen = false;
    }

    changeSortDirection(event) {
        const fieldName = event.target.dataset.field;
        let newDirection;
        if (this.sortFieldApi?.startsWith(fieldName)) {
            if (this.sortDirection == 'ASC') {
                newDirection = 'DESC';
            } else {
                newDirection = 'ASC';
            }
        } else {
            newDirection = 'ASC';
        }
        this.sortFieldApi = fieldName;
        this.sortDirection = newDirection;
        const existingSortIndex = this.sortingFields.findIndex(f => f.fieldName === fieldName);
        if (existingSortIndex !== -1) {
            this.sortingFields[existingSortIndex].direction = newDirection;
        } else {
            this.sortingFields.unshift({
                id: Date.now(),
                fieldName: fieldName,
                direction: newDirection
            });
            if (this.sortingFields.length > 5) {
                this.sortingFields = this.sortingFields.slice(0, 5);
            }
        }
        this.appliedSortConfig = this.sortingFields.map(f => ({
            fieldName: f.fieldName,
            direction: f.direction
        }));
        this.displayedFields.forEach(f => {
            const sortConfigForField = this.appliedSortConfig.find(s => s.fieldName === f.fieldName);
            if (sortConfigForField) {
                f.sortedField = true;
                f.sortedAscending = sortConfigForField.direction === 'ASC';
                f.sortedDescending = sortConfigForField.direction === 'DESC';
            } else {
                f.sortedField = false;
                f.sortedAscending = false;
                f.sortedDescending = false;
            }
        });

        this.loadData(this.appliedSortConfig);
    }

    //section to open/close dropdown and populate fieldsToFilterMap
    openDropDownFilter(event) {
        const fieldName = event.target.dataset.field;
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        if (Object.entries(this.fieldsToFilterMap).length === 0) {
            this.populateFiltersMap();
        }
        this.displayedFields.forEach(field => {
            if (field.fieldName != fieldName && field.isFilterable) {
                let dropDpwnEltToHide = this.template.querySelector('[data-filter-field="' + field.fieldName + '"]');
                dropDpwnEltToHide.classList.add('slds-hide');
            }
        });
    }

    populateFiltersMap() {
        try {
            let fields = JSON.parse(this.filterSettingsFields);
            for (let field of fields) {
                let fieldToFilter = {};
                if (SUPPORTED_TYPES.includes(field.stringFieldType)
                    || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
                    || field.hasOwnProperty('userFilterable')) {
                    fieldToFilter.fieldLabel = field.fieldLabel;
                    fieldToFilter.fieldName = field.fieldName;
                    fieldToFilter.stringFieldType = field.stringFieldType;
                    fieldToFilter.isMultiLevel = field.isMultiLevel;
                    if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
                    if (field.stringFieldType === 'ID') {
                        if (field.values) fieldToFilter.displayVal = field.values.join(';');
                        fieldToFilter.isId = true;
                    }
                    if (field.stringFieldType === 'STRING') {
                        fieldToFilter.isText = true;
                    }
                    if (field.stringFieldType === 'REFERENCE') {
                        fieldToFilter.isReference = true;
                    }
                    if (field.stringFieldType === 'BOOLEAN') {
                        fieldToFilter.isCheckboxGroup = true;
                        let options = [{ label: this.Labels.LBL_True, value: 'true' }, { label: this.Labels.LBL_False, value: 'false' }];
                        fieldToFilter.options = options;
                    }
                    if (field.pickListValues
                        && (field.stringFieldType === 'PICKLIST'
                            || field.stringFieldType === 'MULTIPICKLIST'
                            || field.stringFieldType === 'COMBOBOX'
                            || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues.length > 1))) {
                        fieldToFilter.isCheckboxGroup = true;
                        let options = [];
                        options = field.pickListValues;
                        fieldToFilter.options = options;
                    }
                    if (field.stringFieldType === 'DOUBLE' || field.stringFieldType === 'INTEGER' || field.stringFieldType === 'LONG'
                        || field.stringFieldType === 'CURRENCY' || field.stringFieldType === 'PERCENT') {
                        fieldToFilter.isNumber = true;
                        fieldToFilter.formatter = '';
                        fieldToFilter.step = '';
                        if (field.stringFieldType === 'DOUBLE') {
                            fieldToFilter.formatter = 'decimal';
                            fieldToFilter.step = 0.01;
                        }
                        if (field.stringFieldType === 'CURRENCY') {
                            fieldToFilter.formatter = 'currency';
                            fieldToFilter.step = 0.01;
                        }
                        if (field.stringFieldType === 'PERCENT') {
                            fieldToFilter.formatter = 'percent-fixed';
                            fieldToFilter.step = 0.01;
                        }
                    }
                    if (field.stringFieldType === 'DATE' || field.stringFieldType === 'DATETIME') {
                        fieldToFilter.isDate = true;
                    }
                    if (field.stringFieldType === 'TIME') {
                        fieldToFilter.isTime = true;
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
                    if (Object.keys(fieldToFilter).length !== 0) {
                        this.fieldsToFilterMap[fieldToFilter.fieldName] = fieldToFilter;
                    }
                }
            }
        } catch (error) {
            console.error(error);
            console.error(error.body?.message);
        }

    }
    handleChangeFilter(event) {
        const value = event.detail.value;
        const fieldName = event.target.dataset.field;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field.values = [];
            field.values = (Array.isArray(value)) ? value : [value];
            this.fieldsToFilterMap[fieldName] = field;
        }
    }
    setSelectedRangeValue(event) {
        const value = event.detail.value;
        const fieldName = event.target.dataset.field;
        const rangeValue = event.target.dataset.range;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field[rangeValue] = value;
            this.fieldsToFilterMap[fieldName] = field;
        }
    }
    confirmFilter() {
        let selection = [];
        try {
            selection = Object.keys(this.fieldsToFilterMap)
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

            return selection;
        } catch (error) {
            console.log(error);
        }
    }
    handleApplyFilters() {
        try {
            let self = this;
            let fieldsMap = {};
            let fields = this.confirmFilter();
            fields.forEach(item => {
                let newItem = self.filtersFieldsMap[item.fieldName] || item;
                newItem.value1 = item.value1;
                newItem.value2 = item.value2;
                newItem.values = item.values;
                if (item.hasOwnProperty('userFilterable')) {
                    newItem.userFilterable = item.userFilterable;
                }
                fieldsMap[newItem.fieldName] = newItem;
            });
            this.filtersFieldsMap = fieldsMap;
            this.tableLoading = true;
            this.pageNumber = 1;
            this.loadData();
        } catch (error) {
            console.error(error);
        }
    }
    handleResetFilters(event) {
        const fieldName = event.target.dataset.field;
        if (this.filtersFieldsMap[fieldName]) {
            this.filtersFieldsMap[fieldName] = this.resetFilterValues(this.filtersFieldsMap[fieldName]);
        }

        if (this.fieldsToFilterMap[fieldName]) {
            this.fieldsToFilterMap[fieldName] = this.resetFilterValues(this.fieldsToFilterMap[fieldName]);
        }
        this.tableLoading = true;
        this.pageNumber = 1;
        this.loadData();
    }
    resetFilterValues(field) {
        if (field) {
            field.values = [];
            field.value1 = null;
            field.value2 = null;
        }
        return field;
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
}