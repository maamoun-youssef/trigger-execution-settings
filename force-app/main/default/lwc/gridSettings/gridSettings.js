import { LightningElement, api, track } from 'lwc';
import { toastWarning, toastError, toastSuccess, Labels, incrementFormat } from "c/gridSettingsHelper";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import initData from "@salesforce/apex/GridSettingsController.initData";
import loadData from "@salesforce/apex/GridSettingsController.loadData";
import getChildrenHierarchy from "@salesforce/apex/GridSettingsController.getChildrenHierarchy";
import processRestForExcel from "@salesforce/apex/GridSettingsController.processRestForExcel";
import GridSetting from '@salesforce/resourceUrl/GridSettings';
import userLocal from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
// Static resources for external libraries (required for Excel export/import)
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";

export default class GridSettings extends LightningElement {
    //@API
    @api recordId;
    @api templateName;
    @api cmpHeight;
    ///////////////
    @track initDataWrapper = {};
    @track loadDataWrapper = {};
    @track displayedFields = [];
    @track allRecordsToExport = [];
    @track headerLabels = {
        objectLabel : '',
        layoutLabel : '',
        iconName : '',
        layoutSlogan : ''
    };
    @track currentFlow = {
        header: '',
        flowApiName: '',
        flowVariables: '',
    }
    @track firstThStyle;
    @track records = [];
    @track treeList = [];
    expandedNodes = new Set();
    @track isLoading = false;
    @track tableStyle = '';
    //pagination
    @track pageNumber = 1;
    @track pageSize = null;
    @track showHideColumns = false;
    @track isTreeGrid = false;
    @track openFlow = false;
    @track selectedFields = [];
    @track hiddenGridFields = [];
    @track picklistRelationshipMap = {};
    @track showHideFieldOptions = [];
    @track isGrouped = false;
    @track groupedFieldTh = { label: '', headerStyle: '', bodyStyle: '' };
    @track objectApiName;
    @track isRefresh = false;
    pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];
    //these are not used
    @track filters;
    @track sortFieldApi;
    @track sortDirection;
    Labels = Labels;

    get displayShowHideColumns() {
        return true;
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

       // Determines if the pagination controls should be shown
    get hasPagination() {
        return (this.initDataWrapper?.gridSettingsManager ? this.loadDataWrapper?.total > this.initDataWrapper?.gridSettingsManager?.Default_Page_Size : false) /* && !(this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'tree') */;
    }

    get allowExport() {
        return true;
    }

    get hasRecords() {
        return this.treeList.length > 0 || this.records.length > 0 
    }

    get visibleFields() {
        return (this.displayedFields || []).filter(f => !f.isHidden);
    }

    get tableColspan() {
        // +1 for the action column, +1 if grouped column is shown
        return this.visibleFields.length + 1 + (this.isGrouped ? 1 : 0);
    }

    get flowActions() {
        return (this.initDataWrapper?.gridSettingsManager?.actions?.screenFlows) || [];
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

    connectedCallback() {
        this.hiddenGridFields = localStorage.getItem(this.templateName)? JSON.parse(localStorage.getItem(this.templateName)) : [];
        loadScript(this, ExcelJSURL).then(() => {
            console.log('load exceljs success');
        }).catch(error => {
            console.log('load exceljs failedd');
            console.log(error);
        });
         // Load custom CSS
            Promise.all([
                loadStyle(this, GridSetting + '/customStyle.css'),
            ]).then(() => { }).catch(error => {
                console.log("Error " + error.body.message);
            });
        this.initData();
    }

    initData() {
        try {
            this.isLoading = true;
            this.pageNumber = 1;
            if (this.templateName) {
                initData({
                    recordId: this.recordId,
                    templateName: this.templateName
                }).then(result => {
                    this.initDataWrapper = JSON.parse(result);
                    console.log('🎺 ~ gridSettings.js:18 -> this.initDataWrapper: ', JSON.stringify(this.initDataWrapper));
                    this.headerLabels.objectLabel = this.initDataWrapper.gridSettingsManager.objectLabel ?? '';
                    this.headerLabels.layoutLabel = this.initDataWrapper.gridSettingsManager.layoutLabel ?? '';
                    this.headerLabels.layoutSlogan = this.initDataWrapper.gridSettingsManager.layoutSlogan ?? '';
                    this.headerLabels.iconName = this.initDataWrapper && this.initDataWrapper.gridSettingsManager && this.initDataWrapper.gridSettingsManager.iconName && this.initDataWrapper.gridSettingsManager.iconSection
                    ? this.initDataWrapper.gridSettingsManager.iconSection + ':' + this.initDataWrapper.gridSettingsManager.iconName 
                    : 'standard:orders'; 
                    this.pageSize = '' + this.initDataWrapper.gridSettingsManager.Default_Page_Size;
                    this.tableStyle = 'width: 100%;' + (this.cmpHeight ? 'height: ' + this.cmpHeight + '; min-height: ' + this.cmpHeight + ';' : 'height: ' + this.template.querySelector('.initial-table')?.offsetHeight + 'px;');
                    this.objectApiName = this.initDataWrapper.gridSettingsManager.OBJECT_NAME ?? '';
                    this.isTreeGrid = this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'tree';
                    this.sortFieldApi = this.initDataWrapper.gridSettingsManager?.groupedField ?? null;
                    console.log('🚣 ~ gridSettings.js:73 -> this.objectApiName: ', this.objectApiName);
                    if (this.isTreeGrid || this.initDataWrapper.gridSettingsManager.templateType != 'Detail') {
                        this.loadData();
                    } else {
                        this.buildDisplayedFields(true);
                    }
                    //console.log("TEST_TEST", JSON.stringify(this.selectedActions))
                });
            }
        } catch (error) {
        this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
        console.log('INITDATA:', error);
        this.isLoading = false;
        }
    }

    // Builds the grid column definitions
    buildDisplayedFields(isFirstLoad) {
        try {
            let fieldIndex = 0;
            this.displayedFields = [];
            this.showHideFieldOptions = []; 
            this.selectedFields = [];
            this.picklistRelationshipMap = {};
            let filterableFields = this.initDataWrapper.gridSettingsManager.FILTERS || [];
            const groupedField = this.initDataWrapper.gridSettingsManager?.groupedField;
            this.isGrouped = !!groupedField;
            for (let field of (this.initDataWrapper.gridSettingsManager.GRID_FIELDS || [])) {
                if(field.isHidden != true && field.fieldName != groupedField) {
                    this.showHideFieldOptions.push({
                        value: `${field.fieldName} ${field.isInputField == true ? 'In' : 'Out'}`,
                        label: `${field.fieldLabel} ${field.isInputField == true ? '(input)' : '(output)'}`
                    })
                }
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
                    isText: field.stringFieldType == 'STRING',
                    isMultiPicklist: field.stringFieldType == 'MULTIPICKLIST',
                    isCurrency: field.stringFieldType == 'CURRENCY',
                    isPercent: field.stringFieldType == 'PERCENT',
                    isURL: field.stringFieldType == 'URL',
                    isId : field.stringFieldType == 'ID',
                    isNameField: field.fieldName.toLowerCase() == 'name',
                    link: '',
                    scale: field.scale,
                    step: '',
                    isInputField: field.isInputField,
                    style: field.style,
                    headerStyle: field.stringHeaderStyle,
                    pickListValues: field.pickListValues,
                    isSortable: field.isSortable,
                    isDefaultSortable: field.isDefaultSortable,
                    isFilterable: field.isFilterable,
                    isEncrypted: field.isEncrypted,
                    isHidden: field.isHidden ?? false,
                    isNumber:  field.stringFieldType === 'DOUBLE' || field.stringFieldType === 'INTEGER' || field.stringFieldType === 'LONG' || field.stringFieldType === 'CURRENCY' || field.stringFieldType === 'PERCENT',
                    isOnlyNumber: field.isNumber && !field.isPercent && !field.isCurrency,
                    //isMassUpdate: field.isMassUpdate && field.isInputField && this.enableMassUpdate,
                    filterValue: '',
                    sortedField: false,
                    sortedAscending: false,
                    sortedDescending: false,
                    iconStyle: '',
                    color: field.nonConditional?.textStyle?.color,
                    popUpStyle: '',
                    total: false,
                    isRecordType: field.fieldName.toLowerCase() == 'recordtypeid',
                    value: '',
                    hasChanged: false,
                    isSearchableText: field.stringFieldType == 'STRING' || field.stringFieldType == 'TEXTAREA' || field.stringFieldType == 'REFERENCE',
                    isSearchableCheckboxes: field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'BOOLEAN',
                    isSearchableInput: field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT',
                    isSearchableDateInput: field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME',
                    hasFilter: false,
                    options: false, 
                    controller: {controllerName: field.controllerName, value: undefined}, 
                    hasDependentPicklist: false, 
                    controlledByFields: false,
                    replaceURLWith : field.replaceURLWith,
                    hasFileInput: field.hasFileInput,
                    picklistColorsMap: field.picklistColorsMap,
                    displayFullURL: field.displayFullURL,
                    isNotExportable: field.isNotExportable,
                    isPersonalised: field.isPersonalised,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isRichText: field.isRichText,
                    SObjectName: field.SObjectName || '',
                    nameAsURL: (this.nameAsURL && field.fieldName.toLowerCase() == "name"),
                }
                let localHiddenField = this.hiddenGridFields.find(item => item.fieldName == field.fieldName && item.isInputField == field.isInputField);
                if (localHiddenField) {
                    fieldWrapper.isHidden = true;
                } else {
                    this.selectedFields.push(`${field.fieldName} ${field.isInputField == true ? 'In' : 'Out'}`);
                }
                if (field.controllerName != null) {
                    this.picklistRelationshipMap[field.controllerName] = field.fieldName;
                    //const promise = this.getFieldDependencies(field.controllerName, field.fieldName);
                    //this.apexMethodPromises.push(promise); // Store the promise
                }
                fieldWrapper.popUpStyle =  fieldWrapper.isSearchableCheckboxes ? 'max-height:230px;min-height:230px;'
                                            : fieldWrapper.isSearchableDateInput || fieldWrapper.isSearchableInput ? 'min-width:260px' : ''
                if (fieldWrapper.isPicklist) {
                    fieldWrapper.pickListValues.unshift({ label: this.Labels.LBL_None_Picklist_Value, value: '', isSelected: true });
                }
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.scale) {
                    const result = 1 / Math.pow(10, fieldWrapper.scale);
                    fieldWrapper.step = result.toFixed(fieldWrapper.scale);
                }
                if (fieldWrapper.headerStyle && fieldWrapper.headerStyle.color != '') {
                    fieldWrapper.iconStyle += '--slds-c-icon-color-foreground: ' + fieldWrapper.headerStyle.color + ' !important;--slds-c-icon-color-foreground-default: ' + fieldWrapper.headerStyle.color + ' !important;';
                }
                if (fieldWrapper.isBoolean) {
                    let options = [{ label: this.Labels.LBL_True, value: 'true' }, { label: this.Labels.LBL_False, value: 'false' }];
                    fieldWrapper.pickListValues = options;
                }
                if (fieldWrapper.controlledByFields && field.controlledByFields.length) {
                    let controlledByFields = [];
                    if (fieldWrapper.isPicklist && (Object.keys(this.picklistRelationshipMap).includes(fieldWrapper.fieldName)
                        || Object.values(this.picklistRelationshipMap).includes(fieldWrapper.fieldName))) {
                        fieldWrapper.hasDependentPicklist = true;
                        let options = [...field.options];
                        options.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
                        controlledByFields.push({
                            controlledByName: fieldWrapper.fieldName,
                            controlledByLabel: fieldWrapper.fieldLabel,
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
                                let nextOptions = [];
                                if (nextOptionField.pickListValues != null) {
                                    nextOptions = [...nextOptionField.pickListValues];
                                }
                                nextOptions.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
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
                        if (Object.values(this.picklistRelationshipMap).includes(field.fieldName)) {
                            let indexField = Object.values(this.picklistRelationshipMap).indexOf(field.fieldName);
                            let prevField = Object.keys(this.picklistRelationshipMap)[indexField];

                            while (prevField) {
                                let prevOptionField = this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(elt => elt.fieldName == prevField).length > 0
                                    && field.stringFieldType == 'PICKLIST'
                                    ? this.initDataWrapper.gridSettingsManager.GRID_FIELDS.filter(elt => elt.fieldName == prevField)[0]
                                    : {};
                                let prevOptions = [];
                                if (prevOptionField.pickListValues != null) {
                                    prevOptions = [...prevOptionField.pickListValues];
                                }
                                prevOptions.unshift({ value: null, label: this.Labels.LBL_None_Picklist_Value, isSelected: true });
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
                fieldWrapper.options = filterableFields.filter(elt => elt.fieldName == field.fieldName).length > 0 && field.stringFieldType == 'PICKLIST';
                if(fieldWrapper.fieldName == groupedField && this.isGrouped) {
                    this.groupedFieldTh = {
                        label: (fieldWrapper?.fieldLabel || groupedField),
                        headerStyle: (fieldWrapper?.stringHeaderStyle || fieldWrapper?.headerStyle || ''),
                        bodyStyle: (fieldWrapper?.style || '')
                    };
                    continue;
                }
                this.displayedFields.push(fieldWrapper);
                field.fieldIndex = fieldIndex;
                fieldIndex++;
            }
                // remove it from displayed fields
                //this.displayedFields = this.displayedFields.filter(f => f.fieldName !== groupedField);
            this.firstThStyle = (this.displayedFields[0].headerStyle ? this.displayedFields[0].headerStyle : '') + 'text-align: center;';
            if (isFirstLoad) this.loadData();
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    // Calls Apex loadData to fetch table rows.
    loadData() {
        try {
            this.records = [];
            this.treeList = [];
            this.isLoading = true;
            if(!this.isRefresh){
                loadData({
                    gridSettingsManagerSerialized: JSON.stringify(this.initDataWrapper.gridSettingsManager),
                    recordId: this.recordId,
                    objectName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME,
                    pageSize: this.pageSize,
                    pageNumber: this.pageNumber,
                    filters: JSON.stringify(this.filters),
                    sortedFieldName: this.sortFieldApi,
                    defaultSortDirection: this.sortDirection
                }).then(result => {
                        this.loadDataWrapper = JSON.parse(result);
                        if (this.initDataWrapper.gridSettingsManager.templateType != 'Detail') {//this.recordId != null && 
                            this.initDataWrapper.gridSettingsManager = this.loadDataWrapper?.gsm ?? this.initDataWrapper.gridSettingsManager;
                            this.buildDisplayedFields(false);
                        }
                        if (this.isTreeGrid) {
                            this.handleTreeLoad();
                        } else {
                            this.records = this.buildData(this.loadDataWrapper.records);
                        }
                        console.log('🚲 ~ gridSettings.js:132 -> loadDataWrapper: ', JSON.stringify(this.loadDataWrapper));
                        console.log('🚲 ~ gridSettings.js:132 -> this.isTreeGrid: ', JSON.stringify(this.isTreeGrid));
                        console.log('🚲 ~ gridSettings.js:132 -> this.isTreeGrid: ', JSON.stringify(this.treeList));
                        console.log('🤖 ~ gridSettings.js:374 ->  this.records: ',  JSON.stringify(this.records));

                        // to do ?
                        this.isLoading = false;
                }).catch(error => {
                    this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                    console.log('loadData: %c' + error.message, 'color : red');
                    console.log('loadData: %c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                })
                return;
            }
            if (this.isTreeGrid) {
                this.handleTreeLoad();
            } else {
                this.records = this.buildData(this.loadDataWrapper?.records ?? []);
            }
            this.isLoading = false;

        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData:', error);
            this.isLoading = false;
        }
    }

    handleTreeLoad() {
        if (!this.loadDataWrapper.records || this.loadDataWrapper.length === 0) {
            this.isLoading = false;
            return;
        }
        if (this.recordId) {
            console.log('🌟 ~ gridSettings.js:351 -> recordId: ', this.recordId);
            let currentNode = this.loadDataWrapper.records[0];
            this.createRootNode(currentNode);
        } else {
            this.loadDataWrapper.records.forEach(record => {
                this.createRootNode(record);
            });
        }
        this.isLoading = false;
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
        this.initDataWrapper.gridSettingsManager.GRID_FIELDS.forEach((field, index) => {
            const isFirstTreeColumn = index === 0;
            let fieldWrapper = {
                ...field,
                isReference: field.stringFieldType == "REFERENCE",
                isNameField: field.fieldName == 'Name',
                style: field.style + (isFirstTreeColumn ? 'display: table-cell;' : ''),
                link: '',
                value: currentNode[field.fieldName],
                class: (field.class ? field.class : '') + (isFirstTreeColumn ? 'slds-tree__item' : ''),
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
        }) 
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
            this.initDataWrapper.gridSettingsManager.GRID_FIELDS.forEach((field, index) => {
                const isFirstTreeColumn = index === 0;
                let fieldWrapper = {
                    ...field,
                    isReference: field.stringFieldType == "REFERENCE",
                    isNameField: field.fieldName == 'Name',
                    style: field.style + 'display: table-cell;',
                    link: '',
                    fieldValue: item[field.fieldName],
                    class: (field.class ? field.class : '') + (isFirstTreeColumn ? 'slds-tree__item' : ''),
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
            });
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
        this.isLoading = false;
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
                console.log('💻 ~ gridSettings.js:543 -> data: ', JSON.stringify(data));
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
                    console.log('🛤️ ~ gridSettings.js:554 -> this.treeList: ', JSON.stringify(this.treeList));
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
        
    //from buildRowdata pluggin 1
    buildData(data) {
    try {
        const groupedField = this.initDataWrapper.gridSettingsManager?.groupedField;
        const doGroup = !!groupedField;
        const rowsData = data || [];
        const isReferenceGroup = doGroup && groupedField.endsWith('__c') && rowsData.some(r => r && r[groupedField.trim().replace(/__c$/, '__r')] && r[groupedField.trim().replace(/__c$/, '__r')].Name);
        const refName = isReferenceGroup ? groupedField.trim().replace(/__c$/, '__r') : null;
        const groupMap = new Map();
        for (let i = 0; i < rowsData.length; i++) {
            const item = rowsData[i];
            const row = this.buildRow(item, i);
            let key, groupId, groupName, link;
            if (doGroup) {
                const raw = item?.[groupedField];
                key = (raw === null || raw === undefined || raw === '') ? '__BLANK__' : String(raw);
                groupId = isReferenceGroup ? raw : '';
                const rawName = isReferenceGroup ? (item?.[refName]?.Name ?? '') : (raw ?? '---');
                groupName = (rawName === '' || rawName === null || rawName === undefined) ? '---' : String(rawName);
                link = (isReferenceGroup && groupId) ? `/${groupId}` : '';
            } else {
                key = '__NO_GROUP__';
                groupId = '';
                groupName = '';
                link = '';
            }
            let group = groupMap.get(key);
            if (!group) {
                group = {
                    key,
                    GroupId: groupId,
                    GroupName: groupName,
                    link,
                    records: [],
                    rowspan: 0
                };
                groupMap.set(key, group);
            }
            group.records.push(row);
        }
        // finalize rowspan + showGroupCell only when grouping is active
        for (const group of groupMap.values()) {
            if (doGroup) {
                group.rowspan = group.records.length;
                if (group.records.length > 0) {
                    group.records[0].showGroupCell = true;
                }
            } else {
                group.rowspan = 0;
            }
        }
        this.isLoading = false;

        return Array.from(groupMap.values());
    } catch (error) {
        this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
        console.log('buildData: %c' + error.message, 'color : red');
        console.log('buildData: %c' + error.body?.message, 'color : red');
    }
    }
    
    buildRow(item, rowIndex) {
        const rowKey = item.Id ?? `row-${rowIndex}`;
        let buildDataWrapper = {
            Name: item.Name,
            Id: item.Id,
            link: item.Id ? '/' + item.Id : '',
            values: [],
            rowColor: '',
            firstTdStyle: '',
            lastTdStyle: '',
            nameURL: item.Id ? '/' + item.Id : '',
            record: item,
            url: false,
            fields: false,
            hasError: false,
            index: rowIndex,
            rowKey,
            showGroupCell: false
        };
        for (let field of this.displayedFields) {
            let fieldWrapper = {
                ...field,
                Id: item.Id,
                fieldValue: '',
                fieldOutputValue: '',
                link: '',
                style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                filterValue: '',
                sortedField: false,
                CurrencyIsoCode: item['CurrencyIsoCode'],
                nameAsURL: item.Id && field.nameAsURL,
                class: false,
                nameURL: item.Id ? '/' + item.Id : '',
                key: field.fieldName,
                pickListValueMap: {},
                picklistOptions: false,
                pickListValues: [] 
            };
            let parts = fieldWrapper.fieldName.split('.');
            let val = item;
            for (let i = 0; i < parts.length; i++) {
                if (!val) break;
                const part = parts[i];
                if (i === parts.length - 1 && (fieldWrapper.isReference || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                    fieldWrapper.fieldOutputValue = val[part.trim().replace(/__c$/, '__r').replace('Id', '')]?.Name;
                    fieldWrapper.link = val[part] ? '/' + val[part] : '';
                    fieldWrapper.fieldValue = val[part];
                } else {
                    fieldWrapper.fieldOutputValue = val[part];
                    fieldWrapper.fieldValue = val[part];
                }
                val = val[part];
            }
            // picklist: build options + output label
            if (fieldWrapper.isPicklist) {
                const base = Array.isArray(field.pickListValues) ? field.pickListValues : [];
                const hasBlank = base.some(o => o && o.value === '');
                const options = hasBlank
                    ? base
                    : [{ label: this.Labels.LBL_None_Picklist_Value, value: '' }, ...base];
                fieldWrapper.pickListValues = options.map(o => ({
                    label: o.label,
                    value: o.value,
                    isSelected: fieldWrapper.fieldValue === o.value
                }));
                const match = options.find(o => o.value === fieldWrapper.fieldValue);
                if (match) fieldWrapper.fieldOutputValue = match.label;
                // row color
                buildDataWrapper.rowColor += field.picklistColorsMap
                    && fieldWrapper.fieldValue !== ''
                    && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue)
                    && field.picklistColorsMap[fieldWrapper.fieldValue] !== ''
                    ? field.picklistColorsMap[fieldWrapper.fieldValue]
                    : '';
            }
            // related field metadata (kept)
            fieldWrapper.relatedField = fieldWrapper.fieldName.includes(".");
            if (fieldWrapper.relatedField) {
                fieldWrapper.refObject =
                    (this.initDataWrapper.gridSettingsManager.objectReferenceMap || {})[
                        fieldWrapper.fieldName.toString().split(".")[0].trim().replace(/__c$/, '__r')
                    ];
                fieldWrapper.refField = field.fieldName.toString().split(".")[1];
                fieldWrapper.refId = item[fieldWrapper.refObject];
            }
            buildDataWrapper.values.push(fieldWrapper);
        }
        if (buildDataWrapper.rowColor !== '') {
            buildDataWrapper.values.forEach(fieldWrapper => {
                if (!fieldWrapper.style.includes('background-color')) {
                    fieldWrapper.style += `background-color:${buildDataWrapper.rowColor};`;
                }
            });
        }
        const lastStyle = buildDataWrapper.values[buildDataWrapper.values.length - 1]?.style || '';
        const match = lastStyle.match(/background-color\s*:\s*([^;]+)/i);
        buildDataWrapper.lastTdStyle = match ? `background-color:${match[1].trim()};` : null
        return buildDataWrapper;
    }

    refreshData() {
        this.isRefresh = true;
        this.isLoading = true;
        this.hiddenGridFields = localStorage.getItem(this.templateName)? JSON.parse(localStorage.getItem(this.templateName)) : [];
        this.buildDisplayedFields(true);
    }

    setShowHideColumns() {
        this.showHideColumns = !this.showHideColumns;
    }

    handleChangeSelectedFields(event) {
        this.selectedFields = event.detail.value;
        console.log('🎂 ~ gridSettings.js:420 -> this.selectedFields: ', JSON.stringify(this.selectedFields));
    }

    confirmSelectionFields() {
        this.hiddenGridFields = [];
        for (let item of this.displayedFields) {
            if(!this.selectedFields.includes(`${item.fieldName} ${item.isInputField ? 'In' : 'Out'}`)){
                console.log(item.fieldName);
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
        this.refreshData();
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
            if (this.recordId && this.initDataWrapper.gridSettingsManager.actions.screenFlows) {
                let matchedFlow = this.initDataWrapper.gridSettingsManager.actions.screenFlows.filter(flow => flow.value == flowName);
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

    handleFlowStatusChange(event) {
        if (event.detail.status === "FINISHED") {
            this.showNotification(this.labels.LBL_Success, event.detail.status, 'success');
            this.openFlow = !this.openFlow;
            this.currentFlow = {};
            this.loadData();
        }
        if (event.detail.status === "ERROR") {
            this.showNotification(this.labels.LBL_Error, event.detail.status, 'error');
        }
    }

    closeFlow() {
        this.openFlow = false;
    }

    // ====================================================================
    // 7. EXPORT EXCEL
    // ====================================================================

    // Initiates the Excel export process.
    handleExportExcel() {
        this.allRecordsToExport = [];
        try {
            this.isLoading = true;
            processRestForExcel({
                recordId: this.recordId,
                gridSettings: JSON.stringify(this.initDataWrapper.gridSettingsManager),
                restURL: null,
                objectApiName: this.initDataWrapper.gridSettingsManager.OBJECT_NAME
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.error != null) {
                    this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
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
                    this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                }
            }).catch((error) => {
                this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.isLoading = false;
            });
        } catch (error) {
            this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
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
                    this.showNotification(this.Labels.LBL_Error, error.body?.message, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                }
            }
        });
    }
    
    buildExcel() {
        this.isLoading = true;
        const dataToExport = this.buildData(this.allRecordsToExport) || [];
        try {
            const workbook = new ExcelJS.Workbook();
            workbook.properties.date1904 = true;
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
            const groupHeaderLabel = this.groupedFieldTh?.label || 'Group';
            const columns = [];
            if (isGrouped) {
                columns.push({
                    header: groupHeaderLabel,
                    key: '__group__',
                    width: 28,
                    style: { numFmt: '@' }
                });
            }
            fields.forEach(field => {
                headerStyles.push(field.headerStyle);
                let newItem = {
                    header: field.fieldLabel || field.fieldName,
                    key: field.fieldName || field.apiName,
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
            const headerRow = worksheet.getRow(1);
            headerRow.height = 28;
            headerRow.eachCell((cell, colNumber) => {
                const headerIndex = isGrouped ? colNumber - 2 : colNumber - 1;
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
            worksheet.views = [{ state: 'frozen', ySplit: 1 }];
            worksheet.autoFilter = {
                from: { row: 1, column: 1 },
                to: { row: 1, column: columns.length }
            };
            let currentRow = 2;
            for (const group of dataToExport) {
                const records = group.records || [];
                // If rowspan > records.length, blank rows are added so merge won't fail.
                const totalRows = isGrouped
                    ? Math.max(group.rowspan || 0, records.length, 1)
                    : Math.max(records.length, 1);
                const startRow = currentRow;
                for (let i = 0; i < totalRows; i++) {
                    const record = records[i] || {};
                    const rowValues = [];
                    const cellStyles = [];
                    if (isGrouped) {
                        rowValues.push( i === 0 ? group?.GroupName ?? '' : '');
                    }
                    for (let value of record.values) {
                        if(!value.isHidden && !value.isNotExportable) {
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
                    row.height = 24;
                    row.eachCell({ includeEmpty: true }, (cell, colNumber) => {
                        const cellIndex = isGrouped ? colNumber - 2 : colNumber - 1;
                        const style = cellStyles[cellIndex] || '';
                        // Color matches
                        const bgMatch = style.match(/(?:^|;)\s*background-color:\s*#([0-9a-fA-F]{6})/);
                        if(bgMatch) {
                            console.log('🙌 ~ gridSettings.js:1091 -> bgMatch: ', bgMatch);
                        }
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
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement('a');
                document.body.appendChild(a);
                a.style = 'display: none';
                let base64Bin = result.toString('base64');
                a.href = 'data:application/vnd.ms-excel;base64,' + base64Bin;
                a.download = this.templateName + '.xlsx';
                a.click();
                this.isLoading = false;
            });
        } catch (error) {
            console.error('Excel export failed:', error);
            this.isLoading = false;
        }
    }

     // ====================================================================
    // ====================================================================
    // Handles change in the number of records per page (page size).
    handlePageSize(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.isLoading = true;
        this.loadData();
    }

    handleChangePage(event) {
        this.isLoading = true;
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
     // Shows a standard Lightning toast notification.
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    @track selectedField = null;
    existingFieldPath = 'BusinessUnitSeller__r.AccountingCode__c';
    
    // Add these handlers:
    handleFieldSelect(event) {
        this.selectedField = event.detail;
        console.log(this.selectedField.apiPath);
        // event.detail = { apiPath, displayLabel, type, objectName }
    }
    
    handleFieldClear() {
        this.selectedField = null;
    }
}