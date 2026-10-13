import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
// import { loadScript } from 'lightning/platformResourceLoader'; 
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from "lightning/navigation";
import save from "@salesforce/apex/GridSettingsCmpController.save";
import compile from "@salesforce/apex/GridSettingsCmpController.compile";
// import deployZip from "@salesforce/apex/GridSettingsCmpController.deployZip";
import getObjects from "@salesforce/apex/GridSettingsCmpController.getObjects";
import getObjectDetail from "@salesforce/apex/GridSettingsCmpController.getObjectDetail";
import getAllFields from "@salesforce/apex/GridSettingsCmpController.getAllFields";
import getGridLayouts from "@salesforce/apex/GridSettingsCmpController.getGridLayouts";
import getTimeLineFields from "@salesforce/apex/GridSettingsCmpController.getTimeLineFields";
// import deleteMetadata from "@salesforce/apex/GridSettingsCmpController.deleteMetadata";
// import getLastApiVersion from "@salesforce/apex/GridSettingsCmpController.getLastApiVersion";
// import getPreviewTableUrl from "@salesforce/apex/GridSettingsCmpController.getPreviewTableUrl";
import getIconsNamePicklist from "@salesforce/apex/GridSettingsCmpController.getIconsNamePicklist";
import checkDeploymentStatus from "@salesforce/apex/GridSettingsCmpController.checkDeploymentStatus";
import getAllReferenceFields from "@salesforce/apex/GridSettingsCmpController.getAllReferenceFields";
import getGridSettingsFieldsLabel from "@salesforce/apex/GridSettingsCmpController.getGridSettingsFieldsLabel";
import getGridSettingsTypes from "@salesforce/apex/GridSettingsCmpController.getGridSettingsTypes";
import getListViewActions from "@salesforce/apex/GridSettingsCmpController.getListViewActions";
import getActiveScreenFlows from "@salesforce/apex/GridSettingsCmpController.getActiveScreenFlows";
import getImportSettingsOptions from "@salesforce/apex/GridSettingsCmpController.getImportSettingsOptions";
import uploadImage from '@salesforce/apex/GridSettingsCmpController.uploadImage';
import initData from '@salesforce/apex/GridSettingsCmpController.initData';
// static resources
import GridSettings from '@salesforce/resourceUrl/GridSettings';
import { showNotification } from 'c/appHelper';
// import jsziplib from '@salesforce/resourceUrl/jszip'
// import Columns__c from '@salesforce/schema/Grid_Settings__mdt.Columns__c';
// import Custom_JS__c from '@salesforce/schema/Grid_Settings__mdt.Custom_JS__c';
// import Object_Name__c from '@salesforce/schema/Grid_Settings__mdt.Object_Name__c';
// import Master_Object_Name__c from '@salesforce/schema/Grid_Settings__mdt.Master_Object_Name__c';
// import Master_Object_Columns__c from '@salesforce/schema/Grid_Settings__mdt.Master_Object_Columns__c';
// import Icon__c from '@salesforce/schema/Grid_Settings__mdt.Icon__c';
//labels
import { Labels, toastInfo, toastError, toastSuccess, array_move_one_item, addToArrayIfDoesntExist, trimDeveloperName, trimRegex } from "c/gridSettingsHelper"
export default class GridSettingsManager extends NavigationMixin(LightningElement) {
    Label = Labels;
    userFiltersList = [];
    @track hasAdminFilter = false;
    @track searchTermTemplate = '';
    @track filteredFieldsList = [];
    @track filteredMasterObjFieldsList = [];
    @track queryTermDetail = '';
    @track queryTermMaster = '';
    @track queryTermRef = '';
    @track queryTermFilterField = '';
    @track defaultUserFilter = [];
    @track filterableFieldsList = [];
    @track filterableFilteredFieldsList = [];
    @track filteredRefFieldsList = [];
    @track layouts = [];
    @track objectFields = [];
    @track dateObjectFields = [];
    @track picklistObjectFields = [];
    @track referenceObjectFields = [];
    @track masterObjectFields = [];
    @track objectRefFields = [];
    @track adminFiltersCount = 0;
    @track instance = {
        get showButtons() {
            return this.currentTemplate.value != '' && this.currentTemplate.value != 'Custom_Template';
        },
        get isEnableTemplateSave() {
            return !this.currentTemplate.namespacePrefix && this.showButtons;
        },
        get isDisableTemplateSave() {
            return this.currentTemplate.namespacePrefix && this.showButtons;
        },
        types: [],
        limit: { detail: 500, banner: 10 },
        iconNamesList: [],
        defaultNewTemplate: { label: this.Label.LBL_New_Template, value: "Custom_Template" },
        deployPopUp: {
            display: false,
        },
        changeTypePopUp: {
            display: false,
            type: '',
        },
        currentTemplate: {
            name: '',
            label: '',
            value: '',
            slogan: '',
            icon: 'standard:orders',
            type: 'Detail',
            // customJS: '',
            readOnlyCriteria: '{}',
            GeneratedJSON: '[]',
            calendarSettings: '{}',
            GeneratedMasterJSON: '[]',
            filters: '[]',
            fields: [],
            Default_Page_Size: '50',
            displayAsTree: false,
            displayAsGroupable: false,
            hierarchyParentField: [],
            groupedField: '',
            gridTypeValue: 'normal',
            actions: {
                screenFlows: [],
                quickActions: this.selectedActions,
            },
            importSettingsOptions: '',
            showUserFilter: false,
            isShowFilterOnColumnHeader: false,
            overrideFilter: false,
            //Is default sorting
            sortableFields: [],
            currentDefaultSortableField: '',
            currentdefaultSortDirection: '',
            namespacePrefix: '',
            isdefaultSortDirectionAsc: false,
            isdefaultSortDirectionDesc: false,
            get fieldslength() { return this.fields.filter(item => !item.key.includes('--- Separator(')).length; },
            masterfields: [],
            get masterfieldslength() { return this.masterfields.length; },
            get displayDetail() {
                return this.isDetail || this.isMasterDetail || this.isNoneMasterDetail || this.isMasterDetailLookup;
            },
            get displayMaster() {
                return this.isMaster || this.isMasterDetail || this.isNoneMasterDetail || this.isMasterDetailLookup;
            },
            get isMaster() {
                return this.type == 'Master';
            },
            get isDetail() {
                return this.type == 'Detail';
            },
            get isMasterDetail() {
                return this.type == 'Master-Detail';
            },
            get isNoneMasterDetail() {
                return this.type == 'None-Master-Detail';
            },
            get isMasterDetailLookup() {
                return this.type == 'Master-Detail-Lookup';
            },
            get isRelationalTemplate() {
                return this.isMasterDetail || this.isMasterDetailLookup;
            },
        },
        get displayGrid() {
            return this.currentTemplate.value && this.currentTemplate.value != this.defaultNewTemplate.value;
        },
        currentObject: { value: '', status: false, objectFields: [], fieldsMap: {}, },
        currentMasterObject: { value: '', status: false, objectFields: [], fieldsMap: {}, relationName: '' },
        calendarSettingsData: { startDate: '', endDate: '', pickListValue: '', showCalendarSettings: false },
        timeLineSettings: { levelControl: 1, masterLookup: '', masterLookupParent: '', isTimeLineSettings: false },
        selection: { selectedObjectFields: [], selectedMasterObjectFields: [] },
        __objects: [],
        get objects() {
            if (this.currentTemplate.isMasterDetail) {
                return this.__objects.filter(item => item && item.mastersList && item.mastersList.length > 0);
            } else {
                return this.__objects;
            }
        },
        __objectsMap: {},
        get objectsMap() {
            if (!this.__objectsMap || Object.keys(this.__objectsMap).length == 0) {
                this.__objectsMap = {};
                this.__objects.forEach(item => {
                    this.__objectsMap[item.value] = item;
                });
            }
            return this.__objectsMap;
        },
        get parentFields() {
            let objectsMap = this.objectsMap;
            let options = this.currentObject && this.currentObject.value && objectsMap && objectsMap.hasOwnProperty(this.currentObject.value) && objectsMap[this.currentObject.value] && objectsMap[this.currentObject.value].hasOwnProperty('lookupList') && objectsMap[this.currentObject.value].lookupList ?
                objectsMap[this.currentObject.value].lookupList.filter(item => item.masterName == this.currentObject.value).map(item => {
                    item.label = item.relationLabel + ' - ' + item.relationName;
                    item.value = item.relationName;
                    return item;
                }) : [];
            return options
        },
        get masterObjects() {
            let objectsMap = this.objectsMap;
            if (this.currentTemplate.isMasterDetail) {
                return this.currentObject && this.currentObject.value && objectsMap && objectsMap.hasOwnProperty(this.currentObject.value) && objectsMap[this.currentObject.value] && objectsMap[this.currentObject.value].hasOwnProperty('mastersList') && objectsMap[this.currentObject.value].mastersList ?
                    objectsMap[this.currentObject.value].mastersList.map(item => {
                        if (objectsMap.hasOwnProperty(item.masterName)) {
                            let newItem = JSON.parse(JSON.stringify(objectsMap[item.masterName]));
                            newItem.label = newItem.objectLabel + ' (' + item.relationLabel + ' - ' + item.relationName + ')';
                            newItem.key = newItem.value;
                            newItem.value = item.relationName + '-' + item.masterName;
                            return newItem;
                        }
                    }).filter(item => item) : [];
            } else if (this.currentTemplate.isMasterDetailLookup) {
                return this.currentObject && this.currentObject.value && objectsMap && objectsMap.hasOwnProperty(this.currentObject.value) && objectsMap[this.currentObject.value] && objectsMap[this.currentObject.value].hasOwnProperty('lookupList') && objectsMap[this.currentObject.value].lookupList ?
                    objectsMap[this.currentObject.value].lookupList.map(item => {
                        if (objectsMap.hasOwnProperty(item.masterName)) {
                            let newItem = JSON.parse(JSON.stringify(objectsMap[item.masterName]));
                            newItem.label = newItem.objectLabel + ' (' + item.relationLabel + ' - ' + item.relationName + ')';
                            newItem.key = newItem.value;
                            newItem.value = item.relationName + '-' + item.masterName;
                            return newItem;
                        }
                    }).filter(item => item) : [];
            } else if (this.currentTemplate.isDetail) {
                return [];
            } else if (this.currentTemplate.isMaster || this.currentTemplate.isNoneMasterDetail) {
                return this.__objects.map(item => {
                    let newItem = JSON.parse(JSON.stringify(item));
                    newItem.key = newItem.value;
                    return item;
                });
            } else {
                return [];
            }
        },
        get masterRelation() {
            let relationApiName = '';
            let objectsMap = this.objectsMap;
            let masterName = this.currentMasterObject.value;
            if (this.currentTemplate.isMasterDetail) {
                if (masterName && objectsMap && objectsMap.hasOwnProperty(this.currentObject.value) && objectsMap[this.currentObject.value] && objectsMap[this.currentObject.value].hasOwnProperty('mastersList') && objectsMap[this.currentObject.value].mastersList && objectsMap[this.currentObject.value].mastersList.length) {
                    objectsMap[this.currentObject.value].mastersList.forEach(item => {
                        if (item.masterName == masterName) {
                            relationApiName = item.relationName;
                        }
                    });
                }
            } else if (this.currentTemplate.isMasterDetailLookup) {
                if (masterName && objectsMap && objectsMap.hasOwnProperty(this.currentObject.value) && objectsMap[this.currentObject.value] && objectsMap[this.currentObject.value].hasOwnProperty('lookupList') && objectsMap[this.currentObject.value].lookupList && objectsMap[this.currentObject.value].lookupList.length) {
                    objectsMap[this.currentObject.value].lookupList.forEach(item => {
                        if (item.masterName == masterName) {
                            relationApiName = item.relationName;
                        }
                    });
                }
            }
            return relationApiName;
        },
        get displayMaster() {
            let masterObjects = this.masterObjects;
            return masterObjects && masterObjects.length > 0
        },
        gridLayouts: [],
        Templates: [],
        previewLink: { url: '', has: false },
        pageLink: { url: '', has: false },
        saveAsTemplateName: '',
        fieldSettings: { show: false },
        templateSettings: { show: false },
        filterSettings: { show: false, fields: [] },
        addrelatedFields: { fieldStack: [], originafieldLabel: '', relatedFieldsLabel: '' },
        // personalisedField: {
        //   name: '', type: '', action: '', rerender: '', options: [
        //     { label: this.Label.LBL_Button, value: 'Button' },
        //     { label: this.Label.LBL_Link, value: 'Link' },
        //   ]
        // },
        newTemplatePopUp: {
            display: false,
            showInstructions: false,
        }
    };

    get filterIconClass() {
        return this.hasAdminFilter ? 'filter-brand' : 'apple-green-icon';
    }

    get filterIconVariant() {
        return this.hasAdminFilter ? 'brand' : 'border';
    }

    toggleNewTemplateInstructions() {
        this.instance.newTemplatePopUp.showInstructions = !this.instance.newTemplatePopUp.showInstructions;
    }

    @track guidanceSections = [
        {
            title: this.Label.LBL_New_Template_Name,
            text: this.Label.LBL_GridSettingsManager_NewTemplateNameDescription,
        },
        {
            title: this.Label.LBL_Template_Type,
            text: this.Label.LBL_GridSettingsManager_NewTemplateTypeDescription
        },
        {
            title: this.Label.LBL_Grid_Description_Slogan,
            text: this.Label.LBL_GridSettingsManager_NewTemplateSloganDescription
        },
        {
            title: this.Label.LBL_Select_Object,
            text: this.Label.LBL_GridSettingsManager_NewTemplateObjectDescription
        },
        {
            title: this.Label.LBL_Select_Master_Object,
            text: this.Label.LBL_GridSettingsManager_NewTemplateMasterObjectDescription,
        }
    ];

    updateHierarchyLevels() {
        let hierarchyArray = [...this.instance.currentTemplate.hierarchyParentField];
        if (!hierarchyArray[0]) {
            let value = (this.instance.parentFields.find(option => option.value === this.instance?.currentMasterObject?.relationName) || this.instance?.parentFields[0])?.value;
            hierarchyArray[0] = value ? value : '';
        }
        this.hierarchyLevels = hierarchyArray.map((fieldValue, fieldIndex) => ({
            value: fieldValue,
            index: fieldIndex,
            levelNumber: fieldIndex + 1,
            isFirst: fieldIndex === 0,
            showRemove: fieldIndex > 0
        }));
    }

    addHierarchyLevel() {
        let hierarchyArray = [...this.instance.currentTemplate.hierarchyParentField];
        hierarchyArray.push('');
        this.instance.currentTemplate.hierarchyParentField = hierarchyArray;
        this.updateHierarchyLevels();
    }

    removeHierarchyLevel(event) {
        let hierarchyArray = [...this.instance.currentTemplate.hierarchyParentField];
        hierarchyArray.splice(parseInt(event.currentTarget.dataset.index, 10), 1);
        this.instance.currentTemplate.hierarchyParentField = hierarchyArray.length ? hierarchyArray : [];
        this.updateHierarchyLevels();
    }

    handleHierarchyLevelChange(event) {
        let hierarchyArray = [...this.instance.currentTemplate.hierarchyParentField];
        hierarchyArray[parseInt(event.currentTarget.dataset.index, 10)] = event.detail.value;
        this.instance.currentTemplate.hierarchyParentField = hierarchyArray;
        this.updateHierarchyLevels();
    }

    handleGroupedFieldChange(event) {
        this.instance.currentTemplate.groupedField = event.detail.value;
    }

    @track currentMasterObjectValue;
    @track currentObjectValue;
    @track normalizedApiName = {
        Columns__c: 'Columns__c',
        Type__c: 'Type__c',
        Filters__c: 'Filters__c',
        ReadOnly_Criteria__c: 'ReadOnly_Criteria__c',
        Object_Name__c: 'Object_Name__c',
        Master_Object_Name__c: 'Master_Object_Name__c',
        Master_Object_Columns__c: 'Master_Object_Columns__c',
        Relationship_Name__c: 'Relationship_Name__c',
        Icon__c: 'Icon__c',
        Grid_Configuration__c: 'Grid_Configuration__c',
        Calendar_Setting__c: 'Calendar_Setting__c',
        Time_Line_Settings__c: 'Time_Line_Settings__c',
        NamespacePrefix: 'NamespacePrefix',
        Grid_Slogan__c: 'Grid_Slogan__c',
        Grid_Settings__mdt: 'Grid_Settings__mdt',
        MasterLabel: 'MasterLabel'
    };
    @track generatedZipCode = '';
    generatedBase64Zip = '';
    @track Loading = true;
    readOnlyCriteriaHasError = false;
    @track currentObjectValue;
    @track wantedFields = [];
    selectedObjectRefField = '';
    @track selectedObjectRefFieldLabel = '';
    selectedObjectRefFieldFields = [];
    selectedWantedFields = [];
    @track readOnlyCriteriasJSON = '';
    @track selectedWantedFieldspickListValuesJSON = '';
    @track selectedWantedFieldsJSON;
    @track ObjectRelatedFieldsFields = [];
    @track ObjectRelatedFieldsFieldsShowStatus;
    @track ObjectRelatedFieldsFieldsDisableStatus;
    @track isInputField = false;
    @track InOutValue = 'output';
    @track currentFieldsSettingsLabel = '';
    @track previewCount = [1, 2, 3, 4];
    @track previewTable = [];
    @track showAddrelatedPopup = false;
    @track showPersonalizedAddForm = false;
    @track showPreview = false;
    @track showPreviewValue = false;
    @track showSaveAsMenu = false;
    @track showDeleteConfirm = false;
    @track showConfirmOverwrite = false;
    @track showAlreadyExistPOPUP = false;
    @track hasLayouts = true;
    @track templateApiName;
    @track actionDescribe;
    @track allActions = [];
    @track selectedActions = [];
    // import Settings
    @track importSettingsOptions = [];
    @track importSettingsTemplate = '';
    // Grid Type Options
    @track gridTypeOptions = [{ label: this.Label.LBL_GridSettingsManager_Normal, value: 'normal' },
                              { label: this.Label.LBL_GridSettingsManager_Tree, value: 'tree' },
                              { label: this.Label.LBL_GridSettingsManager_Grouped, value: 'grouped' }];
    // Tree Settings
    @track hierarchyLevels = [];
    @track groupableFieldsOptions = [];

    @track helpTextLabels = {
        Grid_Settings__mdt: {
            MasterLabel: '',
            Grid_Slogan__c: '',
            Type__c: '',
            Master_Object_Name__c: '',
            Object_Name__c: '',
            Icon__c: ''
        }
    };

    @wire(CurrentPageReference)
    currentPageReference;
    apiVersion = '51.0';
    likenessMap = {};
    separatorIndex = 0;
    previewTableUrl;
    Events = {
        confirmEdit: 'confirmedit',
        cancelEdit: 'canceledit',
        confirmFilterSettings: 'confirmfiltersettings',
        cancelFilterSettings: 'cancelfiltersettings',
        confirmReadOnlyExpressionEditor: 'confirmreadonlyexpressioneditor',
        cancelReadOnlyExpressionEditor: 'cancelreadonlyexpressioneditor',
        saveTemplatesOrder: 'savetemplatesorder',
        cancelTemplatesOrder: 'canceltemplatesorder',
    }
    levelControlOptions = [
        {
            label: '1',
            value: '1'
        },
        {
            label: '2',
            value: '2'
        },
        {
            label: '3',
            value: '3'
        },
    ];
    displayTypeOptions = [
        { label: 'Button', value: 'Button' },
        { label: 'Icon', value: 'Icon' },
        { label: 'Action', value: 'Action' }
    ];

    handleGridTypeChange(event) {
        this.instance.currentTemplate.gridTypeValue = event.detail.value;
        switch (this.instance.currentTemplate.gridTypeValue) {
            case 'normal':
                this.instance.currentTemplate.displayAsTree = false;
                this.instance.currentTemplate.displayAsGroupable = false;
                break;
            case 'tree':
                this.instance.currentTemplate.displayAsGroupable = false;
                this.instance.currentTemplate.displayAsTree = true;
                if (this.instance.currentTemplate.hierarchyParentField.length == 0) {
                    const defaultField = this.instance.parentFields.find(opt => opt.value === this.instance?.currentMasterObject?.relationName)
                        || this.instance?.parentFields[0];
                    this.instance.currentTemplate.hierarchyParentField[0] = defaultField?.value;
                    this.updateHierarchyLevels();
                }
                break;
            case 'grouped':
                this.instance.currentTemplate.displayAsTree = false;
                this.instance.currentTemplate.displayAsGroupable = true;
                this.instance.currentTemplate.groupedField = this.instance.currentTemplate.groupedField == '' ? this.groupableFieldsOptions[0]?.value : this.instance.currentTemplate.groupedField
                break;
        }
    }
    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        let self = this;
        this.Loading = true;
        this.initData();
        Promise.all([
            // loadScript(this, jsziplib),
            loadStyle(this, GridSettings + '/customStyle.css'),
        ]).then(() => {
            //self.Loading = false;
        }).catch(error => {
            self.Loading = false;
        });
    }
    initData() {
        try {
            let self = this;
            initData().then((result) => {
                let parsedResult = JSON.parse(result);
                self.normalizedApiName = {
                    Columns__c: parsedResult.prefix + 'Columns__c',
                    Type__c: parsedResult.prefix + 'Type__c',
                    Filters__c: parsedResult.prefix + 'Filters__c',
                    ReadOnly_Criteria__c: parsedResult.prefix + 'ReadOnly_Criteria__c',
                    Object_Name__c: parsedResult.prefix + 'Object_Name__c',
                    Master_Object_Name__c: parsedResult.prefix + 'Master_Object_Name__c',
                    Master_Object_Columns__c: parsedResult.prefix + 'Master_Object_Columns__c',
                    Relationship_Name__c: parsedResult.prefix + 'Relationship_Name__c',
                    Icon__c: parsedResult.prefix + 'Icon__c',
                    Grid_Configuration__c: parsedResult.prefix + 'Grid_Configuration__c',
                    Time_Line_Settings__c: parsedResult.prefix + 'Time_Line_Settings__c',
                    Calendar_Setting__c: parsedResult.prefix + 'Calendar_Setting__c',
                    NamespacePrefix: 'NamespacePrefix',
                    Grid_Slogan__c: parsedResult.prefix + 'Grid_Slogan__c',
                    Grid_Settings__mdt: parsedResult.prefix + 'Grid_Settings__mdt',
                    MasterLabel: parsedResult.prefix + 'MasterLabel'
                };
                this.setLabels(parsedResult.fieldsMap);
                self.LoadGridLayouts();
                self.loadScreenFlows();
            })

        } catch (error) {
            this.Loading = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            showNotification(this, this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }
    setLabels(fieldsMap) {
        const objectApiName = this.normalizedApiName.Grid_Settings__mdt;
        const names = this.normalizedApiName;
        this.helpTextLabels.Grid_Settings__mdt.MasterLabel = (fieldsMap[objectApiName] && fieldsMap[objectApiName][names.MasterLabel]?.inlineHelpText) || '';
        this.helpTextLabels.Grid_Settings__mdt.Grid_Slogan__c = (fieldsMap[objectApiName] && fieldsMap[objectApiName][names.Grid_Slogan__c]?.inlineHelpText) || '';
        this.helpTextLabels.Grid_Settings__mdt.Type__c = (fieldsMap[objectApiName] && fieldsMap[objectApiName][names.Type__c]?.inlineHelpText) || '';
        this.helpTextLabels.Grid_Settings__mdt.Master_Object_Name__c = (fieldsMap[objectApiName] && fieldsMap[objectApiName][names.Master_Object_Name__c]?.inlineHelpText) || '';
        this.helpTextLabels.Grid_Settings__mdt.Object_Name__c = (fieldsMap[objectApiName] && fieldsMap[objectApiName][names.Object_Name__c]?.inlineHelpText) || '';
        this.helpTextLabels.Grid_Settings__mdt.Icon__c = (fieldsMap[objectApiName] && fieldsMap[objectApiName][names.Icon__c]?.inlineHelpText) || '';
    }
    @track actions = {
        screenFlows: [],
        quickActions: [],
    };
    @track flowsOptions = [];
    loadScreenFlows() {
        getActiveScreenFlows().then(result => {
            if (result) {
                let options = [];
                let parsedResult = JSON.parse(result);
                let flowRecords = JSON.parse(parsedResult.flowsSerialized);
                let flowDefinitionRecords = JSON.parse(parsedResult.flowDefinitionSerialized);
                let devNameMap = {}
                for (let flowDefinition of flowDefinitionRecords) {
                    devNameMap[flowDefinition.ActiveVersionId] = (flowDefinition.NamespacePrefix ? flowDefinition.NamespacePrefix + '__' : '') + flowDefinition.DeveloperName;
                }
                for (let flow of flowRecords) {
                    options.push({ label: flow.MasterLabel, value: devNameMap[flow.Id] })
                }
                this.flowsOptions = options;
            }
        });
    }

    // Handle Import Settings Template Change
    handleImportSettingsTemplateChange(event) {
        this.instance.currentTemplate.importSettingsTemplate = event.detail.value;
    }

    handleAddFlow() {
        this.actions.screenFlows.push({ value: '', label: '', icon: 'utility:forward_up', displayType: 'Action', isAction: true, isIcon: false, isButton: false });
    }

    handleChangeFlow(event) {
        let index = event.target.dataset.index;
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.actions.screenFlows[index][field] = value;
        if (field == 'displayType') {
            this.actions.screenFlows[index].isButton = value === 'Button';
            this.actions.screenFlows[index].isIcon = value === 'Icon';
            this.actions.screenFlows[index].isAction = value === 'Action';
            if (this.actions.screenFlows[index].isAction) {
                this.actions.screenFlows[index].icon = 'utility:forward_up';
            }
        }
        if (field == 'icon' && this.actions.screenFlows[index].isIcon) {
            this.handleChangeIconChange(this.actions.screenFlows[index], 'icon');
        }
    }
    handleChangeIconChange(object, field) {
        console.log('handleChangeIconChange')
        let inputImage = document.createElement('input');
        inputImage.type = 'file';
        inputImage.accept = 'image/*';
        inputImage.onchange = (event) => {
            let file = event.target.files[0];
            let fileName = file.name;
            if (!file) {
                showNotification(this, 'Error', 'Please select a file to upload.', 'error');
                return;
            }
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64data = reader.result.split(',')[1];
                uploadImage({ base64Image: base64data, imageName: fileName }).then(result => {
                    /*console.log('result: ' + result)
                    // module.iconUrl = result;
                    this.settingsList[index].sectionIconStyle = `background-image:url('${result}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    this.settingsList[index].sectionIcon = result;*/
                    object[field] = result
                }).catch(error => {
                    console.log('error.message', error)
                    showNotification(this, 'error :', error.message, 'error');
                });
            };
            reader.readAsDataURL(file);
        }
        inputImage.click();
    }

    validateScreenFlows() {
        const flows = this.actions?.screenFlows || [];
        for (const f of flows) {
            if (!f || (!f.value && !f.label)) continue;
            const type = f.displayType
                || (f.hasOwnProperty('displayInAction') ? (f.displayInAction ? 'Action' : 'Icon') : (!f.icon ? 'Action' : 'Icon'));
            const name = f.label || f.value || 'Flow';
            if (type === 'Action') {
                if (!f.icon) {
                    showNotification(this, 'Warning', `${name}: please select an Icon.`, 'Warning');
                    return false;
                }
            } else if (type === 'Icon') {
                if (!f.icon) {
                    showNotification(this, 'Warning', `${name}: please choose an image icon (or switch Display to Action/Button).`, 'Warning');
                    return false;
                }
            }
        }
        return true;
    }

    checkDeployementStatus(idDeployment, isSave) {
        let self = this;
        let counter = 0;
        let status;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            let fdone = JSON.parse(fresult).deployResult.done;
            let fsuccess = JSON.parse(fresult).deployResult.success;
            status = JSON.parse(fresult).deployResult.status;
            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        self.Loading = false;
                        clearInterval(interval);
                        toastInfo(self, self.Label.MSG_Request_Timed_Out + ' ' + self.Label.MSG_Deploy_Last_Status + ' ' + status);
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            self.Loading = false;
                            clearInterval(interval);
                            if (success) {
                                toastSuccess(self, self.Label.LBL_Save, self.Label.MSG_Save_Complete);
                                if (isSave) {
                                    this.compileActionHandler();
                                }
                            } else {
                                toastInfo(self, self.Label.MSG_Deploy_Ended_With_Status + ' ' + status);
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.Loading = false;
                if (fsuccess) {
                    toastSuccess(self, self.Label.LBL_Save, self.Label.MSG_Save_Complete);
                    if (isSave) {
                        this.compileActionHandler();
                    }
                } else {
                    toastInfo(self, self.Label.MSG_Deploy_Ended_With_Status + ' ' + status);
                }
            }
        });
    }

    closeDropdownTemplate(event) {
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            setTimeout(() => {
                templateOptionsSection.classList.remove("slds-is-open");
            }, 200);
        }
    }
    focusTemplateInput(event) {
        let self = this;
        this.hasLayouts = this.layouts.length > 0;
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            templateOptionsSection.classList.add("slds-is-open");
        }
    }
    searchTemplate(event) {
        this.searchTermTemplate = event.target.value;
        let queryTermTemplate = (event.target.value || '').trim() ? new RegExp((event.target.value || '').toLowerCase().trim()
            .split('*')
            .map(s => s.replace(/[\\^$.*+?()[\]{}|]/g, '\\$&'))
            .join('.*'), 'iu')
            : '';
        this.layouts = queryTermTemplate != '' ? this.instance.gridLayouts.filter(item => {
            let matchesLabel = item.label.match(queryTermTemplate);
            let matchesDevName = item.value.match(queryTermTemplate);
            return (matchesLabel && matchesLabel.length)
                || (matchesDevName && matchesDevName.length);
        }) : this.instance.gridLayouts.map(item => item);
        this.hasLayouts = this.layouts.length > 0;
        let templateOptionsSection = this.template.querySelector(".templateOptionsSection");
        if (templateOptionsSection) {
            templateOptionsSection.classList.add("slds-is-open");
        }
    }
    renderedCallback() {
        this.changeHeight();
        for (var elem of this.template.querySelectorAll('.menuItem')) {
            if (elem.dataset.id != this.instance.currentTemplate.value) {
                elem.setAttribute('aria-current', false);
            } else {
                elem.setAttribute('aria-current', 'page');
            }
        }
    }

    changeHeight = () => {
        if (this.template.querySelector('.header') != null) {
            let header = this.template.querySelector('.header').getBoundingClientRect().height;
            let body = this.template.querySelector('.body');
            let templatesSplitView = this.template.querySelector('.templatesSplitView');
            body.style.height = (window.innerHeight - header - 150) + 'px';
            templatesSplitView.style.height = body.style.height;
        }
    };

    handleDeleteFlow(event) {
        let index = event.currentTarget.dataset.index;
        this.actions.screenFlows.splice(index, 1);
    }
    LoadGridLayouts() {
        let self = this;
        this.instance.Templates = [];
        this.instance.gridLayouts = [];
        this.Loading = true;
        getGridLayouts().then(result => {
            let Templates = JSON.parse(JSON.stringify(result));
            let gridLayouts = [];
            let objectsNameList = [];
            for (let item in Templates) {
                gridLayouts.push({
                    label: Templates[item].MasterLabel,
                    //+ (Templates[item][self.normalizedApiName.Object_Name__c] ? " [" + Templates[item][self.normalizedApiName.Object_Name__c] + "]" : "") + (Templates[item].hasOwnProperty(self.normalizedApiName.Master_Object_Name__c) && Templates[item][self.normalizedApiName.Master_Object_Name__c] ? " [" + Templates[item][self.normalizedApiName.Master_Object_Name__c] + "]" : ""),
                    value: item,
                    type: Templates[item][self.normalizedApiName.Type__c],
                    namespacePrefix: Templates[item].NamespacePrefix,
                    currentObject: Templates[item][self.normalizedApiName.Object_Name__c],
                    masterObject: Templates[item].hasOwnProperty(self.normalizedApiName.Master_Object_Name__c) && Templates[item][self.normalizedApiName.Master_Object_Name__c] ? Templates[item][self.normalizedApiName.Master_Object_Name__c] : undefined
                });
                if (!objectsNameList.includes(Templates[item][self.normalizedApiName.Object_Name__c])) {
                    objectsNameList.push(Templates[item][self.normalizedApiName.Object_Name__c]);
                }
                if (Templates[item].hasOwnProperty(self.normalizedApiName.Master_Object_Name__c) && Templates[item][self.normalizedApiName.Master_Object_Name__c] && !objectsNameList.includes(Templates[item][self.normalizedApiName.Master_Object_Name__c])) {
                    objectsNameList.push(Templates[item][self.normalizedApiName.Master_Object_Name__c]);
                }
            }
            if (objectsNameList && objectsNameList.length > 0) {
                self.getObjectDetail(objectsNameList);
            }
            let objectsNamesList = [[],];
            let index = 0;
            self.instance.__objects.forEach(item => {
                if (!objectsNameList.includes(item.value)) {
                    if (objectsNamesList[index].length < 100) {
                        objectsNamesList[index].push(item.value);
                    } else {
                        index++;
                        objectsNamesList.push([item.value]);
                    }
                }
            });
            objectsNamesList.forEach(table => {
                self.getObjectDetail(table);
            });
            setTimeout(() => {
                self.instance.Templates = Templates;
                self.instance.gridLayouts = gridLayouts;
                self.layouts = gridLayouts;
                self.Loading = false;
                if (self.instance.currentTemplate.value == self.instance.defaultNewTemplate.value) {
                    self.TemplateChange(self.instance.currentTemplate.value);
                }
                if (this.currentPageReference.state.c__templateName) {
                    this.templateApiName = this.currentPageReference.state.c__templateName;
                }
                let templateValue = this.templateApiName;
                if (this.templateApiName && this.instance.Templates[this.templateApiName].NamespacePrefix) {
                    templateValue = this.instance.Templates[this.templateApiName].NamespacePrefix + '__' + this.templateApiName;
                }
                if (templateValue) {
                    this.TemplateChange(templateValue);
                }
                this.closeDropdownTemplate();
            }, 100);
        }).catch(error => {
            toastError(self, error);
        });
    }
    @wire(getGridSettingsTypes)
    getGridSettingsTypes({ error, data }) {
        if (data) {
            this.instance.types = JSON.parse(data).sort((item1, item2) => item1.label.localeCompare(item2.label));
        } else {
            toastError(this, error);
        }
    }
    @wire(getObjects)
    getObjects({ error, data }) {
        if (data) {
            this.instance.__objects = JSON.parse(data).map(item => {
                item.label = item.objectLabel;
                item.value = item.objectName;
                return item;
            }).sort((item1, item2) => item1.label.localeCompare(item2.label));
            this.currentObject = this.instance.__objects.length > 0 ? this.instance.__objects[0].value : '';
        } else {
            toastError(this, error);
        }
    }
    @wire(getIconsNamePicklist)
    getIconsNamePicklist({ error, data }) {
        if (data) {
            let results = JSON.parse(data);
            this.instance.iconNamesList = results.map(item => {
                return { label: item, value: item, iconName: item };
            });
        }
        else {
            toastError(this, error);
        }
    }
    @wire(getAllFields, { objectName: "$currentObjectValue" })
    getAllFields({ error, data }) {
        if (this.currentObjectValue) {
            this.getObjectDetail([this.currentObjectValue]);
        }
        if (data) {
            let self = this;
            let likenessMap = {};
            let fields = [];
            this.instance.currentObject.objectFields = [];
            this.instance.currentObject.fieldsMap = {};
            let fieldsMap = {};
            let filterableFieldsList = [];
            for (let index in data) {
                let item = {};
                for (let property in data[index]) {
                    item[property] = data[index][property];
                }
                let name = data[index].fieldName;
                let label = data[index].fieldLabel;
                let Field = { label: label, value: name };
                fields.push(Field);
                fieldsMap[name] = item;
                fieldsMap[name].isNumber = data[index].fieldType == 'DOUBLE' || data[index].fieldType == 'INTEGER' || data[index].fieldType == 'LONG' ||
                    data[index].fieldType == 'CURRENCY' || data[index].fieldType == 'PERCENT'
            }
            this.instance.currentObject.fieldsMap = fieldsMap;
            this.instance.currentObject.objectFields = fields.sort((item1, item2) => {
                if ((item1.label.includes('>') && item2.label.includes('>')) || (!item1.label.includes('>') && !item2.label.includes('>'))) {
                    return item1.label.localeCompare(item2.label);
                } else if (item1.label.includes('>')) {
                    return 1;
                } else {
                    return -1;
                }
            });
            this.instance.currentObject.objectFields.forEach(item1 => {
                self.instance.currentObject.objectFields.forEach(item2 => {
                    if (item1.value.includes('__c', '') && item2.value.includes('__c', '') && item1.value != item2.value && item1.value.replace(/[\d]/g, '') == item2.value.replace(/[\d]/g, '')) {
                        if (!likenessMap.hasOwnProperty(item1.value)) {
                            likenessMap[item1.value] = [];
                        }
                        likenessMap[item1.value].push(item2);
                    }
                });
            });
            this.filteredFieldsList = this.instance.currentObject.objectFields;
            this.likenessMap[this.instance.currentObject.value] = likenessMap;
            let excludedTypes = [
                'ADDRESS',
                'TEXTAREA',
                'LOCATION',
            ];
            Object.values(this.instance.currentObject.fieldsMap).forEach(item => {
                if (!item.fieldLabel.includes('>') && !item.fieldName.includes('.') && item.isFilterable && !excludedTypes.includes(item.fieldType)) {
                    let newItem = JSON.parse(JSON.stringify(item));
                    if (!this.defaultUserFilter.some(filterItem => filterItem.value === newItem.fieldName || filterItem.label === newItem.fieldLabel)) {
                        filterableFieldsList.push({ label: newItem.fieldLabel, value: newItem.fieldName });
                    }
                }
            });
            this.filterableFieldsList = filterableFieldsList.sort((item1, item2) => item1.label.localeCompare(item2.label));
            this.filterableFilteredFieldsList = this.filterableFieldsList;
            this.setSelectedFieldStyle();
        }
        else {
            toastError(this, error);
        }
        this.deselectAllSelects();
        this.Loading = false;
    }
    getObjectDetail(objectsNameList) {
        this.Loading = true;
        let self = this;
        getObjectDetail({ objectsNameList: objectsNameList }).then(data => {
            JSON.parse(data).map(item => {
                item.label = item.objectLabel;
                item.value = item.objectName;
                return item;
            }).sort((item1, item2) => item1.label.localeCompare(item2.label)).forEach(item => {
                self.instance.__objects.map(subItem => {
                    if (subItem.value == item.value) {
                        Object.assign(subItem, item);
                    }
                })
            });
            this.Loading = false;
        }).catch(error => {
            // console.error(error);
            toastError(this, error);
            this.Loading = false;
        });
    }
    @wire(getAllFields, { objectName: "$currentMasterObjectValue" })
    getAllMasterFields({ error, data }) {
        if (data) {
            let self = this;
            let likenessMap = {};
            let fields = [];
            this.instance.currentMasterObject.objectFields = [];
            this.instance.currentMasterObject.fieldsMap = {};
            let fieldsMap = {};
            for (let index in data) {
                let item = {};
                for (let field in data[index]) {
                    item[field] = data[index][field];
                }
                let name = data[index].fieldName;
                let label = data[index].fieldLabel;
                let field = { label: label, value: name };
                if (!field.label.includes('>')) {
                    fields.push(field);
                    fieldsMap[name] = item;
                }
            }
            this.instance.currentMasterObject.fieldsMap = fieldsMap;
            // let fieldsMap = this.instance.currentMasterObject.fieldsMap;
            let readOnlyCriteria = { expression: '', rulesMap: {}, fieldsMap: {} };
            if (this.instance.currentTemplate.readOnlyCriteria) {
                readOnlyCriteria = Object.assign(readOnlyCriteria, JSON.parse(this.instance.currentTemplate.readOnlyCriteria));
            }
            this.readOnlyCriteriasJSON = JSON.stringify({ fieldsMap: fieldsMap, expression: readOnlyCriteria.expression, rulesMap: readOnlyCriteria.rulesMap, });
            let gridSettingsExpressionEditorComp = this.template.querySelector("[data-comp='gridSettingsExpressionEditor']");
            if (gridSettingsExpressionEditorComp) {
                gridSettingsExpressionEditorComp.updateFields(this.readOnlyCriteriasJSON);
            }
            this.instance.currentMasterObject.objectFields = fields.sort((item1, item2) => {
                if ((item1.label.includes('>') && item2.label.includes('>')) || (!item1.label.includes('>') && !item2.label.includes('>'))) {
                    return item1.label.localeCompare(item2.label);
                } else if (item1.label.includes('>')) {
                    return 1;
                } else {
                    return -1;
                }
            });
            this.instance.currentMasterObject.objectFields.forEach(item1 => {
                self.instance.currentMasterObject.objectFields.forEach(item2 => {
                    if (item1.value.includes('__c', '') && item2.value.includes('__c', '') && item1.value != item2.value && item1.value.replace(/[\d]/g, '') == item2.value.replace(/[\d]/g, '')) {
                        if (!likenessMap.hasOwnProperty(item1.value)) {
                            likenessMap[item1.value] = [];
                        }
                        likenessMap[item1.value].push(item2);
                    }
                });
            });
            this.likenessMap[this.instance.currentMasterObject.value] = likenessMap;
        }
        else {
            toastError(this, error);
        }
        this.deselectAllSelects();
        this.Loading = false;
        this.filteredMasterObjFieldsList = this.instance.currentMasterObject.objectFields;
        this.setSelectedFieldStyle();
    }
    @wire(getAllReferenceFields, { fieldName: "$selectedObjectRefField", objectName: "$currentObjectValue" })
    getAllReferenceFields({ error, data }) {
        if (data) {
            let fields = [];
            this.ObjectRelatedFieldsFields = [];
            for (let index in data) {
                let item = {};
                for (let field in data[index]) {
                    item[field] = data[index][field];
                }
                let name = data[index].fieldName;
                let label = data[index].fieldLabel;
                let Field = { label: label, value: name, fieldName: name };
                fields.push(Field);
                this.instance.currentObject.fieldsMap[name] = item;
            }
            this.ObjectRelatedFieldsFields = fields.sort((item1, item2) => {
                if ((item1.label.includes('>') && item2.label.includes('>')) || (!item1.label.includes('>') && !item2.label.includes('>'))) {
                    return item1.label.localeCompare(item2.label);
                } else if (item1.label.includes('>')) {
                    return 1;
                } else {
                    return -1;
                }
            });
            this.filteredRefFieldsList = this.ObjectRelatedFieldsFields;
            if (this.instance.currentObject.value && this.selectedObjectRefField) {
                this.ObjectRelatedFieldsFieldsShowStatus = true;
                this.ObjectRelatedFieldsFieldsDisableStatus = !this.ObjectRelatedFieldsFieldsShowStatus;
            }
            this.setSelectedFieldStyle();
            this.getTimeLineData();
        }
        else {
            toastError(this, error);
        }
        this.Loading = false;
    }
    handleRightClickSettings(event) {
        event.preventDefault();
        let key = event.currentTarget.dataset.key;
        let selectedWantedFields = this.instance.currentTemplate.fields.filter(item => item.key == key);
        selectedWantedFields[0].isDisabled = this.instance.currentTemplate.fields?.filter(item => item.value == selectedWantedFields[0].value).length >= 2;
        let pickListValues = this.instance.currentObject.fieldsMap.hasOwnProperty(selectedWantedFields[0].value) ? this.instance.currentObject.fieldsMap[selectedWantedFields[0].value].pickListValues : undefined;
        this.selectedWantedFieldspickListValuesJSON = JSON.stringify(pickListValues);
        if (selectedWantedFields.length > 0) {
            this.currentFieldsSettingsLabel = selectedWantedFields[0].fieldLabel;
            this.selectedWantedFields = selectedWantedFields;
            this.selectedWantedFieldsJSON = JSON.stringify(selectedWantedFields);
            this.instance.fieldSettings.show = true;
        } else {
            toastInfo(this, this.Label.MSG_No_Items_Selected);
        }
        return false;
    }
    preventDefaultHandler(event) {
        event.preventDefault();
        return false;
    }
    iconChangeHandler(event) {
        this.instance.currentTemplate.icon = event.detail.value;
    }
    TemplateChangeHandler(event) {
        let templateValue = event.currentTarget.dataset.id;
        this.TemplateChange(templateValue);
        this.closeDropdownTemplate();
    }
    getTimeLineData() {
        this.picklistObjectFields = [];
        this.dateObjectFields = [];
        this.referenceObjectFields = [];
        this.masterObjectFields = [];
        getTimeLineFields({
            currentObjectValue: this.currentObjectValue,
            currentMasterObjectValue: this.currentMasterObjectValue
        }).then(result => {
            let data = JSON.parse(result);
            this.picklistObjectFields = data.picklistFields;
            this.dateObjectFields = data.dateFields;
            this.referenceObjectFields = data.referenceFields;
            this.masterObjectFields = data.masterFields;
        }).catch(error => {
            console.log(error);
        })
    }
    TemplateChange(templateValue) {
        this.instance.currentTemplate.showUserFilter = false;
        this.hasAdminFilter = false;
        this.queryTermDetail = '';
        this.queryTermMaster = '';
        this.queryTermRef = '';
        this.queryTermFilterField = '';
        this.objectRefFields = [];
        this.objectFields = [];
        this.selectedActions = [];
        this.searchFields(null);
        try {
            // this.filterableFieldsList = [];
            this.instance.currentTemplate.fields = [];
            this.instance.currentTemplate.masterfields = [];
            this.instance.calendarSettingsData = { startDate: '', endDate: '', pickListValue: '', showCalendarSettings: false };
            this.instance.timeLineSettings = { levelControl: 1, masterLookup: '', masterLookupParent: '', isTimeLineSettings: false };
            this.defaultUserFilter = [];
            this.userFiltersList = [];
            this.exposedFilterBackup = null;
            this.deselectAllSelects();
            this.separatorIndex = 0;
            this.currentFormulaIndex = 0;
            if (templateValue == this.instance.defaultNewTemplate.value) {
                //this.Default_Page_Size = '50';
                this.instance.currentTemplate.value = this.instance.defaultNewTemplate.value;
                this.instance.currentTemplate.type = 'Detail';
                this.instance.currentTemplate.name = '';
                this.instance.currentTemplate.slogan = '';
                this.instance.currentTemplate.label = this.instance.Templates.hasOwnProperty(templateValue) ? this.instance.Templates[templateValue].MasterLabel : '';
                // this.instance.currentTemplate.customJS = '';
                this.instance.currentTemplate.filters = '[]';
                this.instance.currentTemplate.icon = 'standard:orders';
                this.currentObjectValue = this.instance.currentObject.value = this.instance.currentObject.value || this.instance.__objects[0].value;
                this.instance.currentMasterObject.value = '';
                this.instance.currentMasterObject.relationName = '';
                this.currentMasterObjectValue = this.instance.currentMasterObject.value;
                this.instance.currentTemplate.fields = [];
                this.instance.currentTemplate.readOnlyCriteria = '{}';
                this.instance.currentTemplate.masterfields = [];
                this.selectedObjectRefField = '';
                this.selectedObjectRefFieldLabel = '';
                this.ObjectRelatedFieldsFieldsShowStatus = false;
                this.ObjectRelatedFieldsFieldsDisableStatus = !this.ObjectRelatedFieldsFieldsShowStatus;
                this.instance.currentTemplate.namespacePrefix = '';
                this.instance.currentTemplate.gridTypeValue = 'normal';
                this.instance.currentTemplate.importSettingsTemplate = '';
                this.instance.currentTemplate.isShowFilterOnColumnHeader = false;
                this.groupableFieldsOptions = [];
                this.generateJSON();
                this.generateMasterJSON();
                getAllFields({ objectName: this.currentObjectValue }).then(result => {
                    for (let field of Object.values(result)) {
                        this.objectFields.push({ label: field.fieldLabel, value: field.fieldName, type: field.fieldType });
                    }
                });
                getListViewActions({ objectName: this.instance.currentObject.value })
                    .then(result => {
                        this.actionDescribe = JSON.parse(result);
                    }).catch(error => {
                        console.log("🚀 ~ GridSettingsManager ~ TemplateChange ~ error:", error)
                    })
                this.getImportSettingsOptions();
                this.selectedActions = [];
            } else {
                this.instance.calendarSettingsData = this.instance.Templates[templateValue][this.normalizedApiName.Calendar_Setting__c] != '{}' ? JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Calendar_Setting__c]) : this.instance.calendarSettingsData;
                this.instance.timeLineSettings = this.instance.Templates[templateValue][this.normalizedApiName.Time_Line_Settings__c] != '{}' ? JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Time_Line_Settings__c]) : this.instance.timeLineSettings;
                // console.table(JSON.parse(JSON.stringify(this.instance.Templates[templateValue])));
                this.instance.currentTemplate.value = templateValue + '';
                this.instance.currentTemplate.name = templateValue;
                this.instance.currentTemplate.slogan = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Grid_Slogan__c] : '';
                this.instance.currentTemplate.label = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue].MasterLabel : '';
                this.instance.currentTemplate.type = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Type__c] : 'Detail';
                // this.instance.currentTemplate.customJS = this.instance.Templates[templateValue][this.normalizedApiName.Custom_JS__c] || '';
                this.instance.currentTemplate.filters = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Filters__c] : '[]';
                this.instance.currentTemplate.readOnlyCriteria = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.ReadOnly_Criteria__c] : '{}';
                this.readOnlyCriteriasJSON = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.ReadOnly_Criteria__c] : '{}';
                this.instance.currentTemplate.namespacePrefix = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue].NamespacePrefix : '';
                this.instance.currentTemplate.icon = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Icon__c] : 'standard:orders';
                this.instance.currentTemplate.Default_Page_Size = (this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).Default_Page_Size || '50') + '';
                this.instance.currentTemplate.displayAsTree = (this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).gridTypeValue || 'normal') == 'tree' ? true : false;
                this.instance.currentTemplate.hierarchyParentField = (this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).hierarchyParentField || []);
                this.instance.currentTemplate.displayAsGroupable = (this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).gridTypeValue || 'normal') == 'grouped' ? true : false;
                this.instance.currentTemplate.groupedField = (this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).groupedField || '');
                this.instance.currentTemplate.gridTypeValue = (this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).gridTypeValue || 'normal');
                this.actions = JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).actions || { screenFlows: [], quickActions: [] };
                this.actions.screenFlows = (this.actions.screenFlows || []).map(f => ({ ...f, isButton: f.displayType === 'Button', isIcon: f.displayType === 'Icon', isAction: f.displayType === 'Action' }));
                this.instance.currentTemplate.isShowFilterOnColumnHeader = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).isShowFilterOnColumnHeader : false;
                this.instance.currentTemplate.overrideFilter = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] && JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).overrideFilter : false;
                this.instance.currentTemplate.importSettingsTemplate = this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c] ? (JSON.parse(this.instance.Templates[templateValue][this.normalizedApiName.Grid_Configuration__c]).importSettingsTemplate || '') : '';
                this.instance.currentObject.value = this.instance.Templates[templateValue] ? this.instance.Templates[templateValue][this.normalizedApiName.Object_Name__c] : '';
                this.currentObjectValue = this.instance.currentObject.value;
                this.updateHierarchyLevels();
                getListViewActions({ objectName: this.instance.currentObject.value })
                    .then(result => {
                        this.actionDescribe = JSON.parse(result);
                        this.selectedActions = this.actions.quickActions;
                        if (this.selectedActions.length > 0) {
                            for (let i = 0; i < this.actionDescribe.length; i++) {
                                for (let j = 0; j < this.selectedActions.length; j++) {
                                    if (this.actionDescribe[i]?.Id == this.selectedActions[j]?.Id) {
                                        this.actionDescribe.splice(i, 1);
                                    }
                                }
                            }
                        }
                    }).catch(error => {
                        console.log("🚀 ~ GridSettingsManager ~ TemplateChange ~ error:", error)
                    })
                this.getImportSettingsOptions();
                this.instance.currentMasterObject.value = this.instance.Templates[templateValue] && this.instance.Templates[templateValue][this.normalizedApiName.Master_Object_Name__c] !== undefined
                    ? this.instance.Templates[templateValue][this.normalizedApiName.Master_Object_Name__c] : '';
                const relationshipName = this.instance.Templates[templateValue][this.normalizedApiName.Relationship_Name__c];
                if (this.instance.Templates[templateValue] && relationshipName !== undefined) {
                    this.instance.currentMasterObject.relationName = relationshipName !== undefined ? relationshipName : '';
                } else {
                    this.instance.currentMasterObject.relationName = this.instance.masterRelation;
                }
                let fieldsMap = {};
                this.adminFiltersCount = JSON.parse(this.instance.currentTemplate.filters).filter(item => !item.hasOwnProperty("userFilterable")).length;
                getAllFields({ objectName: this.currentObjectValue }).then(result => {
                    for (let field of Object.values(result)) {
                        this.objectFields.push({ label: field.fieldLabel, value: field.fieldName, type: field.fieldType })
                        fieldsMap[field.fieldName] = field.fieldLabel;
                    }
                    this.defaultUserFilter = JSON.parse(this.instance.currentTemplate.filters).filter(item => {
                        if (item && item.hasOwnProperty("userFilterable")) {
                            if (item.userFilterable)
                                return item;
                        } else if (item && !item.hasOwnProperty("userFilterable")) {
                            this.hasAdminFilter = true;
                        }
                    }).map(item => {
                        return {
                            label: fieldsMap[item.fieldName],
                            value: item.fieldName
                        };
                    });
                    let filterableFieldsList = [];
                    let excludedTypes = [
                        'ADDRESS',
                        'TEXTAREA',
                        'LOCATION',
                    ];
                    Object.values(this.instance.currentObject.fieldsMap).forEach(item => {
                        if (!item.fieldLabel.includes('>') && !item.fieldName.includes('.') && item.isFilterable && !excludedTypes.includes(item.fieldType)) {
                            let newItem = JSON.parse(JSON.stringify(item));
                            if (!this.defaultUserFilter.some(filterItem => filterItem.value === newItem.fieldName || filterItem.label === newItem.fieldLabel)) {
                                filterableFieldsList.push({ label: newItem.fieldLabel, value: newItem.fieldName });
                            }
                        }
                    });
                    this.filterableFieldsList = filterableFieldsList.sort((item1, item2) => item1.label.localeCompare(item2.label));
                    this.filterableFilteredFieldsList = this.filterableFieldsList;
                    this.userFiltersList = this.defaultUserFilter;
                    this.instance.currentTemplate.showUserFilter = this.userFiltersList.length > 0;
                });
                if (this.instance.currentMasterObject.relationName) {
                    getAllReferenceFields({ fieldName: this.instance.currentMasterObject.relationName, objectName: this.currentObjectValue }).then(result => {
                        for (let field of Object.values(result)) {
                            this.objectRefFields.push({ label: field.fieldLabel.includes('>') ? field.fieldLabel.substring(0, field.fieldLabel.length - 1) : field.fieldLabel, value: field.fieldName, type: field.fieldType })
                        }
                    });
                }
                this.instance.currentMasterObject.key = this.instance.currentMasterObject.relationName != '' ? this.instance.currentMasterObject.relationName + '-' + this.instance.currentMasterObject.value : this.instance.currentMasterObject.value;
                this.currentMasterObjectValue = this.instance.currentMasterObject.value;
                this.Loading = true;
                let self = this;
                let referenceFields = [];
                if (self.instance.currentObject.value) {
                    getGridSettingsFieldsLabel({
                        'objectName': self.instance.currentObject.value,
                        'columns': self.instance.Templates[templateValue] ? self.instance.Templates[templateValue][self.normalizedApiName.Columns__c] : '[]'
                    }).then(resultJSON => {
                        if (resultJSON) {
                            self.instance.currentTemplate.fields = [];
                            let separatorIndex = 0;
                            let currentFormulaIndex = 0;
                            ////let listField = [];
                            let result = JSON.parse(resultJSON);
                            result.forEach(item => {
                                if (item && item.isDefaultSortable) {
                                    this.instance.currentTemplate.currentDefaultSortableField = item.fieldName;
                                    this.instance.currentTemplate.currentdefaultSortDirection = item.defaultSortDirection;
                                    this.instance.currentTemplate.isdefaultSortDirectionAsc = this.instance.currentTemplate.currentdefaultSortDirection == 'ASC' || this.instance.currentTemplate.currentdefaultSortDirection == '';
                                    this.instance.currentTemplate.isdefaultSortDirectionDesc = this.instance.currentTemplate.currentdefaultSortDirection == 'DESC';
                                }
                            });
                            let temp = result.map(item => {
                                let cssClass = '';
                                if (item.isFormula) {
                                    currentFormulaIndex++;
                                    return {
                                        key: item.fieldName,
                                        fieldLabel: item.fieldLabel,
                                        label: item.fieldLabel,
                                        value: item.fieldName,
                                        equation: item.equation,
                                        isFormula: true,
                                        fieldName: item.fieldName,
                                        cssClass: 'formula-text',
                                        scale: item.scale,
                                    };
                                } else if (item.fieldName.search('Separator') == 0) {
                                    separatorIndex++;
                                    return {
                                        key: '--- Separator(' + (separatorIndex) + ') ---',
                                        label: '--- Separator(' + (separatorIndex) + ') ---',
                                        fieldLabel: '--- Separator(' + (separatorIndex) + ') ---',
                                        value: '--- Separator(' + (separatorIndex) + ') ---',
                                        isSeparator: true,
                                        separatorSettings: item.separatorSettings,
                                        cssClass: cssClass
                                    };
                                } else {
                                    if (item.isPersonalised) {
                                        cssClass = 'Personalised';
                                    } else if (!item.isCalculated && item.isCreateable && item.isUpdateable && item.isInputField) {
                                        cssClass = 'In';
                                    } else {
                                        cssClass = 'Out';
                                    }
                                    if (item.fieldName.split('.').length > 1) {
                                        referenceFields.push(item.fieldName.split('.')[0]);
                                    }
                                    let itemW = {
                                        key: item.fieldName,
                                        label: item.fieldLabel,
                                        fieldName: item.fieldName,
                                        fieldLabel: item.fieldLabel,
                                        helpText: item.helpText,
                                        value: item.fieldName,
                                        isCalculated: item.isCalculated,
                                        isCreateable: item.isCreateable,
                                        isUpdateable: item.isUpdateable,
                                        scale: item.scale,
                                        isEncrypted: item.isEncrypted,
                                        isFilterable: item.isFilterable,
                                        isPersonalised: item.isPersonalised,
                                        stringFieldType: item.stringFieldType,
                                        newLabel: item.newLabel,
                                        bgColor: item.bgColor,
                                        action: item.action,
                                        picklistColorsMap: item.picklistColorsMap,
                                        hasFileInput: item.hasFileInput,
                                        displayFullURL: item.displayFullURL,
                                        URLOption: item.URLOption,
                                        replaceURLWith: item.replaceURLWith,
                                        isInputField: !item.isCalculated && item.isCreateable && item.isUpdateable && item.isInputField,
                                        showInTotal: item.showInTotal || false,
                                        internallyCalculated: item.internallyCalculated || false,
                                        isMassUpdate: item.isMassUpdate,
                                        totalType: item.totalType || '',
                                        fieldType: item.fieldType || '',
                                        hasConditionalFormating: item.hasConditionalFormating,
                                        nonConditional: item.nonConditional,
                                        headerStyle: item.headerStyle,
                                        customJS: item.customJS,
                                        formattingRulesList: item.formattingRulesList,
                                        cssClass: cssClass,
                                        defaultValue: item.defaultValue,
                                        defaultExpression: item.defaultExpression,
                                        defaultType: item.defaultType,
                                        isHidden: item.isHidden,
                                        isNotExportable: item.isNotExportable,
                                        clearOnClone: item.clearOnClone,
                                        isSortable: item.isSortable,
                                        isDefaultSortable: item.isDefaultSortable,
                                        defaultSortDirection: item.defaultSortDirection,
                                        conditionalRules: item.conditionalRules,
                                    };
                                    if (!itemW.fieldName.includes('.')) {
                                        itemW.key += itemW.cssClass;
                                        // itemW.value += item.cssClass;
                                    }
                                    return itemW;
                                }
                            });
                            /* let columns = JSON.parse(self.instance.Templates[templateValue][self.normalizedApiName.Columns__c]);
                            let missingFields = [];
                            for (let index = 0; index < columns.length; index++) {
                            if (columns[index].FieldName.toLowerCase() && !listField.includes(columns[index].FieldName.toLowerCase())) {
                            missingFields.push(columns[index].FieldName);
                            }
                            }
                            if (missingFields.length > 0) {
                            if (missingFields.length > 1) {
                            toastInfo(self,'info', 'Fields: ' + missingFields.join(', ') + ' don\'t exist anymore.');
                            } else {
                            toastInfo(self,'info', 'Field: ' + missingFields[0] + ' doesn\'t exist anymore.');
                            }
                            self.showDissmisableMessage = true;
                            }*/
                            self.selectedObjectRefField = '';
                            self.selectedObjectRefFieldLabel = '';
                            self.ObjectRelatedFieldsFieldsShowStatus = false;
                            self.ObjectRelatedFieldsFieldsDisableStatus = !self.ObjectRelatedFieldsFieldsShowStatus;
                            setTimeout(() => {
                                self.separatorIndex = separatorIndex;
                                self.currentFormulaIndex = currentFormulaIndex;
                                self.instance.currentTemplate.fields = temp;
                                self.groupableFieldsOptions = self.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
                                self.setSelectedFieldStyle();
                                self.Loading = false;
                                self.generateJSON();
                                if (referenceFields.length > 0) {
                                    self.loadReferenceData(referenceFields);
                                }
                            }, 100);
                        }
                        self.Loading = false;
                    }).catch(error => {
                        console.log('%c' + error.message, 'color : red');
                        console.log('%c' + error.body?.message, 'color : red');
                        toastError(self, error);
                        self.Loading = false;
                    });
                }
                if (self.instance.currentMasterObject.value) {
                    self.Loading = true;
                    getGridSettingsFieldsLabel({
                        'objectName': self.instance.currentMasterObject.value,
                        'columns': self.instance.Templates[templateValue][self.normalizedApiName.Master_Object_Columns__c]
                    }).then(resultMasterJSON => {
                        self.instance.currentTemplate.masterfields = [];
                        if (resultMasterJSON) {
                            let result = JSON.parse(resultMasterJSON);
                            let temp = result.map(item => {
                                return {
                                    key: item.fieldName,
                                    label: item.fieldLabel,
                                    fieldLabel: item.fieldLabel,
                                    value: item.fieldName,
                                    fieldName: item.fieldName,
                                };
                            });
                            setTimeout(() => {
                                self.instance.currentTemplate.masterfields = temp;
                                self.Loading = false;
                                self.generateMasterJSON();
                            }, 100);
                        }
                        self.Loading = false;
                    }).catch(error => {
                        toastError(self, error);
                        self.Loading = false;
                    });
                }
            }
            this.getGridTypeOptions();
            this.showPreview = false;
            this.showPreviewValue = false;
            this.previewTable = [];
        } catch (error) {
            console.log('>>>>error ');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    getImportSettingsOptions() {
        // Load Import Settings Options
        getImportSettingsOptions({ objectName: this.instance.currentObject.value })
            .then(result => {
                if (result) {
                    let parsedResult = JSON.parse(result);
                    // Add empty option at the beginning
                    this.importSettingsOptions = [
                        { label: this.Label.LBL_None, value: '' },
                        ...parsedResult.map(item => ({
                            label: item.label,
                            value: item.value
                        }))
                    ];
                }
            }).catch(error => {
                console.error('Error loading import settings options:', error);
            });
    }
    ObjectTypeChangeHandler(event) {
        let newObjectValue = event && event.detail ? event.detail.value : '';
        if (newObjectValue != this.instance.currentObject.value) {
            this.currentObjectValue = this.instance.currentObject.value = newObjectValue;
            this.instance.currentTemplate.fields = [];
            this.instance.currentTemplate.filters = '[]';
            this.defaultUserFilter = [];
            this.userFiltersList = [];
            this.exposedFilterBackup = null;
            this.generateJSON();
        }
        let masterObjects = this.instance.masterObjects;
        let currentMasterObjectValue = this.currentMasterObjectValue;
        if (!masterObjects || (masterObjects && currentMasterObjectValue && !masterObjects.some(item => item.value == currentMasterObjectValue || item.key == currentMasterObjectValue))) {
            this.MasterObjectTypeChangeHandler('');
        }
    }
    MasterObjectTypeChangeHandler(event) {
        let newObjectValue = event && event.detail ? event.detail.value : '';
        if (newObjectValue != this.instance.currentMasterObject.value) {
            this.instance.currentMasterObject.key = newObjectValue;
            if (newObjectValue.split('-').length > 1) {
                this.instance.currentMasterObject.value = newObjectValue.split('-')[1];
                this.instance.currentMasterObject.relationName = newObjectValue.split('-')[0];
            } else {
                this.instance.currentMasterObject.value = newObjectValue;
                this.instance.currentMasterObject.relationName = this.instance.masterRelation;
            }
            //TODO
            this.currentMasterObjectValue = this.instance.currentMasterObject.value;
            this.instance.currentTemplate.masterfields = [];
            this.generateMasterJSON();
        }
    }
    handleComboboxClick(event) {
        event.target.classList.toggle('slds-has-focus');
        this.template.querySelector('.comboboxTemplates').classList.toggle('slds-is-open');
    }
    get defaultPageSizeOptions() {
        return [
            { label: '5', value: '5' },
            { label: '10', value: '10' },
            { label: '25', value: '25' },
            { label: '50', value: '50' },
            { label: '75', value: '75' },
            { label: '100', value: '100' },
        ];
    }
    get sortableFields() {
        return this.instance.currentTemplate.sortableFields;
    }
    handleDefaultPageSizeChange(event) {
        this.instance.currentTemplate.Default_Page_Size = event.detail.value;
    }
    defaultSortingChangeHandler(event) {
        this.instance.currentTemplate.currentDefaultSortableField = event.target.value;
        let selectedField = this.instance.currentTemplate.fields.find(
            field => field.value === this.instance.currentTemplate.currentDefaultSortableField
        );
        if (selectedField && selectedField.defaultSortDirection) {
            this.instance.currentTemplate.currentdefaultSortDirection = selectedField.defaultSortDirection;
        } else {
            this.instance.currentTemplate.currentdefaultSortDirection = 'ASC';
        }
        this.instance.currentTemplate.isdefaultSortDirectionAsc = this.instance.currentTemplate.currentdefaultSortDirection == 'ASC' || this.instance.currentTemplate.currentdefaultSortDirection == '';
        this.instance.currentTemplate.isdefaultSortDirectionDesc = this.instance.currentTemplate.currentdefaultSortDirection == 'DESC';
    }
    handleChangedefaultSortDirection(event) {
        let direction = event.currentTarget.dataset.direction;
        this.instance.currentTemplate.currentdefaultSortDirection = direction;
        this.instance.currentTemplate.isdefaultSortDirectionAsc = this.instance.currentTemplate.currentdefaultSortDirection == 'ASC' || this.instance.currentTemplate.currentdefaultSortDirection == '';
        this.instance.currentTemplate.isdefaultSortDirectionDesc = this.instance.currentTemplate.currentdefaultSortDirection == 'DESC';
        let selectedField = this.instance.currentTemplate.fields.find(
            field => field.value === this.instance.currentTemplate.currentDefaultSortableField
        );
        if (selectedField) {
            selectedField.defaultSortDirection = direction;
        }
    }
    ObjectFieldsSelectChangedHandler() {
        let selectedFields = this.template.querySelector('select[data-recordid="ObjectFields"]').selectedOptions;
        this.instance.selection.selectedObjectFields = [];
        let hasReference = false;
        for (let index = 0; index < selectedFields.length; index++) {
            if (selectedFields[index].selected) {
                let item = { label: selectedFields[index].label, value: selectedFields[index].value };
                this.instance.selection.selectedObjectFields.push(item);
                if (!hasReference && item.label.includes('>')) {
                    hasReference = true;
                }
            }
        }
        if (hasReference && this.instance.selection.selectedObjectFields.length == 1) {
            this.ObjectRelatedFieldsFieldsShowStatus = false;
            this.ObjectRelatedFieldsFieldsDisableStatus = !this.ObjectRelatedFieldsFieldsShowStatus;
            this.selectedObjectRefFieldLabel = this.instance.selection.selectedObjectFields[0].label;
            this.selectedObjectRefField = this.instance.selection.selectedObjectFields[0].value.includes('__r') ? this.instance.selection.selectedObjectFields[0].value.replace(/__r/g, '__c') : this.instance.selection.selectedObjectFields[0].value + 'Id';
            this.Loading = true;
        } else {
            this.selectedObjectRefField = '';
            this.selectedObjectRefFieldLabel = '';
            this.ObjectRelatedFieldsFieldsShowStatus = false;
            this.ObjectRelatedFieldsFieldsDisableStatus = !this.ObjectRelatedFieldsFieldsShowStatus;
        }
        this.deselectList2();
        this.setSelectedFieldStyle();
    }
    MasterObjectFieldsSelectChangedHandler() {
        let selectedFields = this.template.querySelector('select[data-recordid="MasterObjectFields"]').selectedOptions;
        this.instance.selection.selectedMasterObjectFields = [];
        for (let index = 0; index < selectedFields.length; index++) {
            if (selectedFields[index].selected) {
                let item = { label: selectedFields[index].label, value: selectedFields[index].value };
                this.instance.selection.selectedMasterObjectFields.push(item);
            }
        }
    }
    ObjectRefFieldFieldsSelectChangedHandler() {
        let selectedFields = this.template.querySelector('select[data-recordid="ObjectRelatedFieldsFields"]').selectedOptions;
        this.selectedObjectRefFieldFields = [];
        for (let index = 0; index < selectedFields.length; index++) {
            if (selectedFields[index].selected) {
                let item = { label: selectedFields[index].label, value: selectedFields[index].value };
                this.selectedObjectRefFieldFields.push(item);
            }
        }
        this.setSelectedFieldStyle();
    }
    WantedFieldsChangeHandler() {
        let selectedOptions = this.template.querySelector('select[data-recordid="wantedFields"]').selectedOptions;
        let selectedFields = [];
        for (let index = 0; selectedOptions && index < selectedOptions.length; index++) {
            selectedFields.push(selectedOptions[index].dataset.key);
        }
        this.selectedWantedFields = this.instance.currentTemplate.fields.filter(item => selectedFields.includes(item.key));
        this.currentFieldsSettingsLabel = this.selectedWantedFields.map(item => item.fieldLabel).join(', ');
        this.selectedWantedFieldsJSON = JSON.stringify(this.selectedWantedFields);
        console.log('this.selectedWantedFieldsJSON >> ' + this.selectedWantedFieldsJSON)
        this.setSelectedFieldStyle();
    }
    WantedMasterFieldsChangeHandler() {
        let selectedOptions = this.template.querySelector('select[data-recordid="wantedMasterFields"]').selectedOptions;
        let selectedFields = [];
        for (let index = 0; selectedOptions && index < selectedOptions.length; index++) {
            selectedFields.push(selectedOptions[index].value);
        }
        this.selectedMasterWantedFields = this.instance.currentTemplate.masterfields.filter(item => selectedFields.includes(item.value));
        this.selectedMasterWantedFieldsJSON = JSON.stringify(this.selectedMasterWantedFields);
    }
    checkValidity() {
        if (!this.instance.currentTemplate.name) {
            toastInfo(this, this.Label.MSG_Template_No_Name);
            return;
        }
        if (!this.instance.currentObject.value && this.instance.currentTemplate.displayDetail) {
            toastInfo(this, this.Label.MSG_Template_No_Detail_Object);
            return;
        }
        if (!this.instance.currentMasterObject.value && this.instance.currentTemplate.displayMaster) {
            toastInfo(this, this.Label.MSG_Template_No_Master_Detail_Object);
            return;
        }
        if (this.instance.calendarSettingsData.showCalendarSettings) {
            let notContainPicklistField = true;
            this.instance.currentTemplate.fields.forEach(item => {
                if (item.value == this.instance.calendarSettingsData.pickListValue) {
                    notContainPicklistField = false;
                }
            });
            if (notContainPicklistField) {
                toastInfo(this, this.instance.calendarSettingsData.pickListValue + ' does not exist in detail object selected fields');
                return;
            }
        }
    }

    checkCompile() {
        try {
            this.checkValidity();
            this.compileActionHandler();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    checkSave() {
        try {
            this.checkValidity();
            if (!this.validateScreenFlows()) return;
            let templateValue = trimDeveloperName(this.instance.currentTemplate.name).replace(/ /g, '_').replace(/_+/g, '_').substring(0, 40);
            if (this.instance.currentTemplate.value == this.instance.defaultNewTemplate.value && this.instance.gridLayouts.some(item => item.value == templateValue)) {
                this.showConfirmOverwrite = true;
                this.instance.newTemplatePopUp.display = false;
                return;
            }
            if (this.instance.currentTemplate.name) {
                this.instance.newTemplatePopUp.display = false;
                this.saveActionHandler();
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    checkCompileAndSave() {
        try {
            this.checkValidity();
            if (!this.validateScreenFlows()) return;
            let templateValue = trimDeveloperName(this.instance.currentTemplate.name).replace(/ /g, '_').replace(/_+/g, '_').substring(0, 40);
            if (this.instance.currentTemplate.value == this.instance.defaultNewTemplate.value && this.instance.gridLayouts.some(item => item.value == templateValue)) {
                this.showConfirmOverwrite = true;
                this.instance.newTemplatePopUp.display = false;
                return;
            }
            if (this.instance.currentTemplate.name) {
                this.instance.newTemplatePopUp.display = false;
                this.saveActionHandler();
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    confirmSave() {
        this.showConfirmOverwrite = false;
        this.instance.newTemplatePopUp.display = false;
        this.saveActionHandler();
    }
    compileActionHandler() {
        console.log('compileActionHandler')
        let selectedTemplate = this.instance.currentTemplate.value == undefined || this.instance.currentTemplate.value == 'Custom_Template' ? null : this.instance.currentTemplate.value.replace(/ /g, '_').replace(/_+/g, '_');
        let templateName = trimDeveloperName(this.instance.currentTemplate.name).substring(0, 40);
        let objectName = this.instance.currentObject.value;
        let templateLabel = this.instance.currentTemplate.label;
        compile({
            'selectedTemplate': selectedTemplate,
            'templateName': templateName,
            'masterLabel': templateLabel,
            'namespacePrefix': this.instance.currentTemplate.namespacePrefix,
            'masterObjectName': this.instance.currentMasterObject.value,
            'objectName': objectName
        }).then(result => {
            console.log('result: ' + result)
            let parsedResult = JSON.parse(result);
            if (parsedResult.message != null) {
                console.error(parsedResult.message)
                if (parsedResult.errors != null) {
                    let errorString = parsedResult.errors.join('\n');
                    toastError(this, errorString);
                }
            } else {
                this.checkDeployementStatus(parsedResult.jobId, false);
            }
        }).catch(error => {
            toastError(this, error);
            this.Loading = false;
        });
    }
    saveActionHandler() {
        console.log('saveActionHandler')
        if (!this.validateScreenFlows()) { return; }
        if (this.readOnlyCriteriaHasError) {
            toastError(this, this.Label.MSG_Invalid_Expression);
            return;
        }
        if (this.instance.currentTemplate.isMaster) {
            this.instance.currentTemplate.fields = [];
            this.instance.currentObject.value = '';
            this.instance.masterRelation = '';
        } else if (this.instance.currentTemplate.isDetail) {
            this.instance.currentTemplate.masterfields = [];
            this.instance.currentMasterObject.value = '';
            this.instance.masterRelation = '';
        }
        let objectName = this.instance.currentObject.value;
        let masterObjectName = this.instance.currentMasterObject.value;
        let relationName = this.instance.currentMasterObject.relationName;
        let selectedTemplate = this.instance.currentTemplate.value == undefined || this.instance.currentTemplate.value == 'Custom_Template' ? null : this.instance.currentTemplate.value;
        let templateName = trimDeveloperName(this.instance.currentTemplate.name).substring(0, 40);
        let templateLabel = this.instance.currentTemplate.label;
        let slogan = this.instance.currentTemplate.slogan;
        let icon = this.instance.currentTemplate.icon;
        // let filters = this.instance.currentTemplate.filters;
        var filtersArray = JSON.parse(this.instance.currentTemplate.filters);
        //filtersArray = filtersArray.filter(item => (!item.hasOwnProperty('userFilterable') || (item.hasOwnProperty('userFilterable') && ((item.hasOwnProperty('values') && item.values.length > 0) || (item.hasOwnProperty('value1') || item.hasOwnProperty('value2'))))));
        let orderedFiltersArray = [];
        if (this.userFiltersList.length > 0) {
            for (var userFilter of this.userFiltersList) {
                let filter = filtersArray.filter(obj => obj.fieldName == userFilter.value);
                if (filter.length == 0) {
                    orderedFiltersArray.push({ "fieldName": userFilter.value, "values": [], "userFilterable": true });
                } else {
                    orderedFiltersArray.push({ "fieldName": filter[0].fieldName, "values": filter[0].values, "value1": filter[0].value1, "value2": filter[0].value2, "userFilterable": true });
                }
            }
        }
        for (var filter of filtersArray) {
            let filterData = orderedFiltersArray.filter(obj => obj.fieldName == filter.fieldName);
            if (filterData.length == 0) {
                if (/*!filter.hasOwnProperty("userFilterable") &&*/
                    ((filter.values && filter.values.length > 0) || (filter.value1 && filter.value1 != '') || (filter.value2 && filter.value2 != ''))) {
                    orderedFiltersArray.push({ "fieldName": filter.fieldName, "values": filter.values, "value1": filter.value1, "value2": filter.value2 });
                }
            }
        }
        let filters = JSON.stringify(orderedFiltersArray);
        let readOnlyCriteria = this.instance.currentTemplate.readOnlyCriteria;
        this.instance.currentTemplate.filters = filters;
        let type = this.instance.currentTemplate.type;
        this.generateJSON();
        this.generateMasterJSON();
        let columns = this.instance.currentTemplate.GeneratedJSON;
        let masterColumns = this.instance.currentTemplate.GeneratedMasterJSON;
        if (this.instance.currentTemplate.value != this.instance.defaultNewTemplate.value) {
            this.instance.Templates[this.instance.currentTemplate.value][this.normalizedApiName.Columns__c] = this.instance.currentTemplate.GeneratedJSON;
            this.instance.Templates[this.instance.currentTemplate.value][this.normalizedApiName.Master_Object_Columns__c] = this.instance.currentTemplate.GeneratedMasterJSON;
            this.instance.Templates[this.instance.currentTemplate.value][this.normalizedApiName.Master_Object_Name__c] = this.instance.currentMasterObject.value;
        }
        let self = this;
        this.Loading = true;
        console.log('columns >>>> ' + JSON.stringify(columns))
        save({
            'objectName': objectName,
            'masterObjectName': masterObjectName,
            'selectedTemplate': selectedTemplate,
            'templateName': templateName,
            'masterLabel': templateLabel,
            'columns': columns,
            'masterColumns': masterColumns,
            'relationName': relationName,
            'icon': icon,
            'filters': filters,
            'readOnlyCriteria': readOnlyCriteria,
            'type': type,
            'namespacePrefix': this.instance.currentTemplate.namespacePrefix,
            'calendarSettingsData': JSON.stringify(this.instance.calendarSettingsData),
            'timeLineSettings': JSON.stringify(this.instance.timeLineSettings),
            'gridConfiguration': JSON.stringify({
                Default_Page_Size: this.instance.currentTemplate.Default_Page_Size,
                hierarchyParentField: this.instance.currentTemplate.hierarchyParentField,
                groupedField: this.instance.currentTemplate.groupedField,
                gridTypeValue: this.instance.currentTemplate.gridTypeValue,
                isShowFilterOnColumnHeader: this.instance.currentTemplate.isShowFilterOnColumnHeader,
                overrideFilter: this.instance.currentTemplate.overrideFilter,
                actions: this.actions,
                importSettingsTemplate: this.instance.currentTemplate.importSettingsTemplate,
            }),
            'gridSlogan': slogan
        }).then(result => {
            self.checkDeployementStatus(result, true);
            if (self.instance.currentTemplate.value == self.instance.defaultNewTemplate.value) {
                self.instance.currentTemplate.value = trimDeveloperName(self.instance.currentTemplate.name).replace(/ /g, '_').replace(/_+/g, '_').substring(0, 40);
                let gridLayouts = self.instance.gridLayouts;
                self.instance.gridLayouts = [];
                let template = {};
                template[self.normalizedApiName.Object_Name__c] = self.instance.currentObject.value;
                template[self.normalizedApiName.Master_Object_Name__c] = self.instance.currentMasterObject.value;
                template[self.normalizedApiName.Columns__c] = self.instance.currentTemplate.GeneratedJSON;
                template[self.normalizedApiName.Calendar_Setting__c] = JSON.stringify(self.instance.calendarSettingsData);
                template[self.normalizedApiName.Time_Line_Settings__c] = JSON.stringify(self.instance.timeLineSettings);
                template[self.normalizedApiName.Master_Object_Columns__c] = self.instance.currentTemplate.GeneratedMasterJSON;
                template[self.normalizedApiName.Filters__c] = self.instance.currentTemplate.filters;
                template[self.normalizedApiName.ReadOnly_Criteria__c] = self.instance.currentTemplate.readOnlyCriteria;
                template[self.normalizedApiName.Icon__c] = self.instance.currentTemplate.icon;
                template[self.normalizedApiName.Grid_Slogan__c] = self.instance.currentTemplate.slogan;
                template[self.normalizedApiName.Grid_Configuration__c] = JSON.stringify({
                    Default_Page_Size: self.instance.currentTemplate.Default_Page_Size,
                    hierarchyParentField: self.instance.currentTemplate.hierarchyParentField,
                    groupedField: self.instance.currentTemplate.groupedField,
                    gridTypeValue: self.instance.currentTemplate.gridTypeValue,
                    isShowFilterOnColumnHeader: this.instance.currentTemplate.isShowFilterOnColumnHeader,
                    overrideFilter: this.instance.currentTemplate.overrideFilter,
                    actions: this.actions,
                    importSettingsTemplate: this.instance.currentTemplate.importSettingsTemplate
                });
                template[self.normalizedApiName.Type__c] = self.instance.currentTemplate.type;
                template.MasterLabel = self.instance.currentTemplate.label;
                self.instance.Templates[self.instance.currentTemplate.value] = template;
                gridLayouts.forEach(item => {
                    if (item.value == self.instance.currentTemplate.value) {
                        gridLayouts = gridLayouts.filter(elm => elm.value != item.value);
                    }
                });
                gridLayouts.unshift({
                    label: self.instance.currentTemplate.label,
                    //+ (self.instance.currentObject.value ? " [" + self.instance.currentObject.value + "]" : "") + (self.instance.currentMasterObject.value ? " [" + self.instance.currentMasterObject.value + "]" : ""),
                    value: self.instance.currentTemplate.value,
                    type: self.instance.currentTemplate.type,
                    currentObject: self.instance.currentObject.value,
                    masterObject: self.instance.currentMasterObject.value
                });
                self.instance.gridLayouts = gridLayouts;
                self.layouts = gridLayouts;
            } else {
                // self.instance.currentTemplate.value = trimDeveloperName(self.instance.currentTemplate.name).replace(/ /g, '_').replace(/_+/g, '_').substring(0, 40);
                self.instance.gridLayouts = self.instance.gridLayouts.map(item => {
                    if (item.value == self.instance.currentTemplate.value) {
                        item.label = self.instance.currentTemplate.label,
                            //+ " [" + self.instance.currentObject.value + "]" + (self.instance.currentMasterObject.value ? " [" + self.instance.currentMasterObject.value + "]" : "");
                            item.value = self.instance.currentTemplate.value,
                            item.type = self.instance.currentTemplate.type,
                            item.currentObject = self.instance.currentObject.value,
                            item.masterObject = self.instance.currentMasterObject.value
                    }
                    return item;
                });
                // self.instance.Templates[self.instance.currentTemplate.value] = {
                //   Object_Name__c: self.instance.currentObject.value,
                //   Master_Object_Name__c: self.instance.currentMasterObject.value,
                //   Columns__c: self.instance.currentTemplate.GeneratedJSON,
                //   Master_Object_Columns__c: self.instance.currentTemplate.GeneratedMasterJSON,
                //   Filters__c: self.instance.currentTemplate.filters,
                //   Icon__c: self.instance.currentTemplate.icon,
                //   Type__c: self.instance.currentTemplate.type
                // };
                let template = {};
                template[self.normalizedApiName.Object_Name__c] = self.instance.currentObject.value;
                template[self.normalizedApiName.Master_Object_Name__c] = self.instance.currentMasterObject.value;
                template[self.normalizedApiName.Columns__c] = self.instance.currentTemplate.GeneratedJSON;
                template[self.normalizedApiName.Calendar_Setting__c] = JSON.stringify(self.instance.calendarSettingsData);
                template[self.normalizedApiName.Time_Line_Settings__c] = JSON.stringify(self.instance.timeLineSettings);
                template[self.normalizedApiName.Master_Object_Columns__c] = self.instance.currentTemplate.GeneratedMasterJSON;
                template[self.normalizedApiName.Filters__c] = self.instance.currentTemplate.filters;
                template[self.normalizedApiName.ReadOnly_Criteria__c] = self.instance.currentTemplate.readOnlyCriteria;
                template[self.normalizedApiName.Icon__c] = self.instance.currentTemplate.icon;
                template[self.normalizedApiName.Grid_Slogan__c] = self.instance.currentTemplate.slogan;
                template[self.normalizedApiName.Grid_Configuration__c] = JSON.stringify({
                    Default_Page_Size: self.instance.currentTemplate.Default_Page_Size,
                    hierarchyParentField: self.instance.currentTemplate.hierarchyParentField,
                    groupedField: self.instance.currentTemplate.groupedField,
                    gridTypeValue: self.instance.currentTemplate.gridTypeValue,
                    isShowFilterOnColumnHeader: this.instance.currentTemplate.isShowFilterOnColumnHeader,
                    overrideFilter: this.instance.currentTemplate.overrideFilter,
                    actions: this.actions,
                    importSettingsTemplate: this.instance.currentTemplate.importSettingsTemplate,
                });
                template[self.normalizedApiName.Type__c] = self.instance.currentTemplate.type;
                template[self.normalizedApiName.Relationship_Name__c] = relationName;
                template.MasterLabel = self.instance.currentTemplate.label;
                self.instance.Templates[self.instance.currentTemplate.value] = template;
            }
            // setTimeout(() => {
            //   self.Loading = false;
            //   // toastSuccess(self, self.Label.LBL_Save, self.Label.MSG_Save_Complete);
            //   // self.TemplateChange(self.instance.currentTemplate.value);
            // }, 100);
        }).catch(error => {
            toastError(self, error);
            self.Loading = false;
        });
    }
    loadReferenceData(referenceFields) {
        let self = this;
        if (this.currentObjectValue && referenceFields) {
            referenceFields.forEach(referenceField => {
                referenceField = !referenceField.endsWith('__r') && !referenceField.endsWith('Id') ? referenceField + 'Id' : referenceField.replace(/__r/g, '__c');
                getAllReferenceFields({ fieldName: referenceField, objectName: self.currentObjectValue }).then(result => {
                    if (result) {
                        for (let index in result) {
                            let item = {};
                            for (let field in result[index]) {
                                item[field] = result[index][field];
                            }
                            let name = result[index].fieldName;
                            self.instance.currentObject.fieldsMap[name] = item;
                        }
                    }
                    this.Loading = false;
                }).catch(error => {
                    toastError(self, error);
                });
            });
        }
    }
    saveAsBtnHandler() {
        this.instance.saveAsTemplateName = this.instance.currentTemplate.label;
        if (this.instance.currentTemplate.namespacePrefix != null && this.instance.currentTemplate.namespacePrefix != "" && this.instance.saveAsTemplateName.includes(this.instance.currentTemplate.namespacePrefix)) {
            this.instance.saveAsTemplateName = this.instance.saveAsTemplateName.replace(this.instance.currentTemplate.namespacePrefix + '__', '');
        }
        this.showSaveAsMenu = true;
    }
    personalisedFieldHide() {
        this.showPersonalizedAddForm = false;
    }
    saveAsHide() {
        this.showSaveAsMenu = false;
        this.instance.saveAsTemplateName = '';
    }
    cancelConfirmOverwrite() {
        this.showConfirmOverwrite = false;
        this.instance.newTemplatePopUp.display = true;
    }
    cancelAsConfirm() {
        this.showAlreadyExistPOPUP = false;
        this.showSaveAsMenu = true;
    }
    deleteConfirmationHide() {
        this.showDeleteConfirm = false;
    }
    saveAsTemplateNameChangeHandler(event) {
        this.instance.saveAsTemplateName = event.detail.value;
    }
    personalisedFieldNameChangeHandler(event) {
        this.instance.personalisedField.name = event.detail.value;
    }
    personalisedFieldTypeChangeHandler(event) {
        this.instance.personalisedField.type = event.detail.value;
    }
    personalisedActionChangeHandler(event) {
        this.instance.personalisedField.action = event.detail.value;
    }
    personalisedRerenderChangeHandler(event) {
        this.instance.personalisedField.rerender = event.detail.value;
    }
    checkSaveAs() {
        if (!this.instance.saveAsTemplateName) {
            toastError(this, this.Label.MSG_Template_No_Name);
            return;
        }
        let templateValue = trimDeveloperName(this.instance.saveAsTemplateName).replace(/ /g, '_').replace(/_+/g, '_').substring(0, 40);
        if (this.instance.gridLayouts.some(item => item.value == templateValue)) {
            this.showAlreadyExistPOPUP = true;
            this.instance.newTemplatePopUp.display = false;
            this.showSaveAsMenu = false;
            return;
        } else {
            this.showSaveAsMenu = false;
            this.instance.newTemplatePopUp.display = false;
            this.saveAsActionHandler();
        }
    }

    saveAsActionHandler() {
        if (this.readOnlyCriteriaHasError) {
            toastError(this, this.Label.MSG_Invalid_Expression);
            return;
        }
        if (this.instance.currentTemplate.isMaster) {
            this.instance.currentTemplate.fields = [];
            this.instance.currentObject.value = undefined;
            this.instance.masterRelation = '';
        } else if (this.instance.currentTemplate.isDetail) {
            this.instance.currentTemplate.masterfields = [];
            this.instance.currentMasterObject.value = undefined;
            this.instance.masterRelation = '';
        }
        this.generateJSON();
        this.generateMasterJSON();
        let self = this;
        this.Loading = true;
        if (this.instance.currentTemplate.namespacePrefix != null && this.instance.currentTemplate.namespacePrefix != "" && this.instance.saveAsTemplateName.includes(this.instance.currentTemplate.namespacePrefix)) {
            this.instance.saveAsTemplateName = this.instance.saveAsTemplateName.replace(this.instance.currentTemplate.namespacePrefix + '__', '');
            // toastInfo(this, `Don't enter the name space prefix`);
        }
        let templateLabel = this.instance.saveAsTemplateName + '';
        this.instance.saveAsTemplateName = trimDeveloperName(this.instance.saveAsTemplateName.replace(/\_\_+/g, '_').replace(/ /g, '_')).substring(0, 40);
        save({
            'objectName': this.instance.currentObject.value,
            'masterObjectName': this.instance.currentMasterObject.value,
            'selectedTemplate': '',
            'templateName': this.instance.saveAsTemplateName,
            'masterLabel': templateLabel,
            'columns': this.instance.currentTemplate.GeneratedJSON,
            'masterColumns': this.instance.currentTemplate.GeneratedMasterJSON,
            'relationName': this.instance.masterRelation,
            'icon': this.instance.currentTemplate.icon,
            'gridConfiguration': JSON.stringify({
                Default_Page_Size: this.instance.currentTemplate.Default_Page_Size,
                hierarchyParentField: this.instance.currentTemplate.hierarchyParentField,
                groupedField: this.instance.currentTemplate.groupedField,
                gridTypeValue: this.instance.currentTemplate.gridTypeValue,
                isShowFilterOnColumnHeader: this.instance.currentTemplate.isShowFilterOnColumnHeader,
                overrideFilter: this.instance.currentTemplate.overrideFilter,
                actions: this.actions,
                importSettingsTemplate: this.instance.currentTemplate.importSettingsTemplate,
            }),
            'filters': this.instance.currentTemplate.filters,
            'readOnlyCriteria': this.instance.currentTemplate.readOnlyCriteria,
            'type': this.instance.currentTemplate.type,
            'namespacePrefix': null,
            'calendarSettingsData': JSON.stringify(this.instance.calendarSettingsData),
            'timeLineSettings': JSON.stringify(this.instance.timeLineSettings),
        }).then(result => {
            self.checkDeployementStatus(result, true);
            self.searchTermTemplate = '';
            self.instance.currentTemplate.value = self.instance.saveAsTemplateName;
            self.instance.currentTemplate.name = self.instance.currentTemplate.value;
            self.instance.currentTemplate.label = templateLabel;
            let gridLayouts = JSON.parse(JSON.stringify(self.instance.gridLayouts));
            self.instance.gridLayouts = [];
            if (gridLayouts.some(item => item.value == self.instance.currentTemplate.value)) {
                self.instance.currentTemplate.name = self.instance.currentTemplate.value;
            } else {
                gridLayouts.unshift({
                    label: self.instance.currentTemplate.label,
                    type: self.instance.currentTemplate.type,
                    value: self.instance.currentTemplate.value,
                    currentObject: self.instance.currentObject.value,
                    masterObject: self.instance.currentMasterObject.value
                });
            }
            let template = {};
            template[self.normalizedApiName.Object_Name__c] = self.instance.currentObject.value;
            template[self.normalizedApiName.Master_Object_Name__c] = self.instance.currentMasterObject.value;
            template[self.normalizedApiName.Columns__c] = self.instance.currentTemplate.GeneratedJSON;
            template[self.normalizedApiName.Master_Object_Columns__c] = self.instance.currentTemplate.GeneratedMasterJSON;
            template[self.normalizedApiName.Filters__c] = self.instance.currentTemplate.filters;
            template[self.normalizedApiName.ReadOnly_Criteria__c] = self.instance.currentTemplate.readOnlyCriteria;
            template[self.normalizedApiName.Icon__c] = self.instance.currentTemplate.icon;
            template[self.normalizedApiName.Grid_Slogan__c] = self.instance.currentTemplate.slogan;
            template[self.normalizedApiName.Grid_Configuration__c] = JSON.stringify({
                Default_Page_Size: self.instance.currentTemplate.Default_Page_Size,
                hierarchyParentField: self.instance.currentTemplate.hierarchyParentField,
                groupedField: self.instance.currentTemplate.groupedField,
                gridTypeValue: self.instance.currentTemplate.gridTypeValue,
                isShowFilterOnColumnHeader: this.instance.currentTemplate.isShowFilterOnColumnHeader,
                overrideFilter: this.instance.currentTemplate.overrideFilter,
                actions: this.actions,
                importSettingsTemplate: this.instance.currentTemplate.importSettingsTemplate,
            });
            template[self.normalizedApiName.Type__c] = self.instance.currentTemplate.type;
            template[self.normalizedApiName.Calendar_Setting__c] = JSON.stringify(self.instance.calendarSettingsData);
            template[self.normalizedApiName.Time_Line_Settings__c] = JSON.stringify(self.instance.timeLineSettings);
            self.instance.Templates[self.instance.currentTemplate.value] = template;
            setTimeout(() => {
                self.instance.gridLayouts = gridLayouts;
                self.layouts = gridLayouts;
                // toastSuccess(self, self.Label.LBL_Save_As, self.Label.MSG_Save_As_Complete);
                self.saveAsHide();
                self.showAlreadyExistPOPUP = false;
                self.instance.newTemplatePopUp.display = false;
                this.instance.Templates[self.instance.currentTemplate.value].MasterLabel = self.instance.currentTemplate.label;
                self.Loading = false;
                self.TemplateChange(self.instance.currentTemplate.value);
            }, 100);
        }).catch(error => {
            toastError(self, error);
            self.Loading = false;
        });
    }

    changeTypePopUpHandler(event) {
        this.instance.changeTypePopUp.type = event.detail.value;
        this.instance.currentTemplate.type = this.instance.changeTypePopUp.type;
        let objects = this.instance.objects;
        let currentObjectValue = this.currentObjectValue;
        if (!objects || (objects && currentObjectValue && !objects.some(item => item.value == currentObjectValue || item.key == currentObjectValue))) {
            this.ObjectTypeChangeHandler('');
        }
    }
    newBtnHandler() {
        this.instance.currentTemplate.showUserFilter = false;
        this.TemplateChange(this.instance.defaultNewTemplate.value);
        this.instance.newTemplatePopUp.display = true;
    }
    cancelNewTemplate() {
        this.TemplateChange(this.instance.defaultNewTemplate.value);
        this.instance.newTemplatePopUp.display = false;
    }
    saveNewTemplate() {
        this.checkSave();
        this.searchTermTemplate = '';
        getAllFields({ objectName: this.currentObjectValue }).then(result => {
            for (let field of Object.values(result)) {
                this.objectFields.push({ label: field.fieldLabel, value: field.fieldName, type: field.fieldType });
            }
        });
    }
    setTemplateTypeHandler(event) {
        this.instance.currentTemplate.type = event?.detail?.value ?? this.instance.currentTemplate.type;
        if (this.instance.currentTemplate.type != 'Master-Detail-Lookup' && this.instance.currentTemplate.type != 'Master-Detail') {
            this.instance.currentTemplate.gridTypeValue = this.instance.currentTemplate.gridTypeValue == 'grouped' ? 'grouped' : 'normal';
            this.instance.currentTemplate.displayAsTree = false;
            this.instance.currentTemplate.hierarchyParentField = [];
            this.updateHierarchyLevels();
        }
        this.getGridTypeOptions();
    }
    setTemplateNameHandler(event) {
        this.instance.currentTemplate.label = event.detail.value;
        this.instance.currentTemplate.name = trimDeveloperName(event.detail.value).substring(0, 40);
    }
    setTemplateSloganHandler(event) {
        this.instance.currentTemplate.slogan = event.detail.value;
    }
    cancelBtnHandler() {
        this.searchTermTemplate = '';
        // this[NavigationMixin.Navigate]({
        //   type: 'standard__namedPage',
        //   attributes: {
        //     pageName: 'home'
        //   },
        // });
        this.instance.currentTemplate.value = this.instance.defaultNewTemplate.value;
        this.actions.screenFlows = [];
        this.actions.quickActions = [];
        this.LoadGridLayouts();
    }
    templateNameChangeHandler(event) {
        this.instance.currentTemplate.name = event.detail.value;
    }

    setSelectedFieldStyle() {
        this.filteredFieldsList.forEach(item1 => {
            const matches = this.instance.currentTemplate.fields?.filter(item2 => item2.fieldName === item1.value);
            item1.cssClass = (matches.length > 1 || (matches.length == 1 && (matches[0].isCalculated || !matches[0].isCreateable || !matches[0].isUpdateable))) ? 'dimmedField' : '';
        });
        this.ObjectRelatedFieldsFields.forEach(item1 => {
            if (this.instance.currentTemplate.fields.some(item2 => item2.fieldName == item1.fieldName && item2.value == item1.value)) {
                item1.cssClass = "dimmedField";
            } else {
                item1.cssClass = "";
            }
        });
        console.log('this.filteredMasterObjFieldsList >>> ' + JSON.stringify(this.filteredMasterObjFieldsList))
        console.log('this.instance.currentTemplate.masterfields >>> ' + JSON.stringify(this.instance.currentTemplate.masterfields))
        this.filteredMasterObjFieldsList.forEach(item1 => {
            if (this.instance.currentTemplate.masterfields.some(item2 => item2.value == item1.value)) {
                item1.cssClass = "dimmedField";
            } else {
                item1.cssClass = "";
            }
        });
    }
    clearSearchQueries() {
        this.currentMasterObjectValue = null;
        setTimeout(() => {
            this.currentMasterObjectValue = this.instance.currentMasterObject.value;
        }, 0);
        this.queryTermDetail = '';
        this.queryTermMaster = '';
        this.queryTermRef = '';
        this.queryTermFilterField = '';
        this.searchFields(null);
    }
    handleSearchFields(event) {
        let tabName = event.currentTarget.dataset.tab;
        let value = trimRegex(event.target.value);
        let hasChange = false;
        if (tabName == 'detail') {
            hasChange = this.queryTermDetail != value;
            this.queryTermDetail = value;
        } else if (tabName == 'master') {
            hasChange = this.queryTermMaster != value;
            this.queryTermMaster = value;
        } else if (tabName == 'ref-detail') {
            hasChange = this.queryTermRef != value;
            this.queryTermRef = value;
        } else if (tabName == 'filter-field') {
            hasChange = this.queryTermFilterField != value;
            this.queryTermFilterField = value;
        }
        if (hasChange) {
            this.searchFields(tabName);
        }
    }
    searchFields(tabName) {
        if (!tabName || tabName == 'detail') {
            let queryTermDetail = this.queryTermDetail ? new RegExp(this.queryTermDetail.toLowerCase().trim().replace(/\*/g, '.*'), "i") : '';
            this.filteredFieldsList = queryTermDetail != '' ? this.instance.currentObject.objectFields.filter(item => {
                let match1 = item.label.match(queryTermDetail);
                let match2 = item.value.match(queryTermDetail);
                return (match1 && match1.length) || (match2 && match2.length);
            }) : this.instance.currentObject.objectFields.map(item => item);
            this.deselectAllSelects();
        }
        if (!tabName || tabName == 'master') {
            let queryTermMaster = this.queryTermMaster ? new RegExp(this.queryTermMaster.toLowerCase().trim().replace(/\*/g, '.*'), "i") : '';
            this.filteredMasterObjFieldsList = queryTermMaster != '' ? this.instance.currentMasterObject.objectFields.filter(item => {
                let match1 = item.label.match(queryTermMaster);
                let match2 = item.value.match(queryTermMaster);
                return (match1 && match1.length) || (match2 && match2.length);
            }) : this.instance.currentMasterObject.objectFields.map(item => item);
            this.deselectAllSelects();
        }
        if (!tabName || tabName == 'ref-detail') {
            let queryTermRef = this.queryTermRef ? new RegExp(this.queryTermRef.toLowerCase().trim().replace(/\*/g, '.*'), "i") : '';
            this.filteredRefFieldsList = queryTermRef != '' ? this.ObjectRelatedFieldsFields.filter(item => {
                let match1 = item.label.match(queryTermRef);
                let match2 = item.value.match(queryTermRef);
                return (match1 && match1.length) || (match2 && match2.length);
            }) : this.ObjectRelatedFieldsFields.map(item => item);
            this.deselectList2();
        }
        if (!tabName || tabName === 'filter-field') {
            let queryTermFilterField = this.queryTermFilterField ? new RegExp(this.queryTermFilterField.toLowerCase().trim().replace(/\*/g, '.*'), 'i') : '';
            this.filterableFilteredFieldsList = queryTermFilterField !== '' ? this.filterableFieldsList.filter(item => {
                let match1 = item.label.match(queryTermFilterField);
                let match2 = item.value.match(queryTermFilterField);
                return (match1 && match1.length) || (match2 && match2.length);
            }) : this.filterableFieldsList.map(item => item);
            this.deselectFilterList();
        }
        this.setSelectedFieldStyle();
    }
    generateJSON() {
        let arrSelectedField = this.instance.currentTemplate.fields;
        let savedFields = [];
        this.instance.currentTemplate.sortableFields = [];
        var filtersArray = JSON.parse(this.instance.currentTemplate.filters);
        if (arrSelectedField != undefined) {
            for (let field in arrSelectedField) {
                let item = {};
                item.label = arrSelectedField[field].label;
                if (arrSelectedField[field].value.includes('.')) {
                    let referenceApiName = arrSelectedField[field].value.split('.')[1];
                    if (referenceApiName.includes('Product2')) {
                        referenceApiName = 'Product__r';
                        item.FieldName = referenceApiName + '.' + arrSelectedField[field].value.split('.')[2];
                    } else {
                        item.FieldName = arrSelectedField[field].value;
                    }
                } else if (arrSelectedField[field].value.includes('Separator')) {
                    item.FieldName = "";
                    if (arrSelectedField[field].separatorSettings) {
                        item.separatorSettings = arrSelectedField[field].separatorSettings;
                    }
                    savedFields.push(item);
                    continue;
                } else {
                    item.FieldName = arrSelectedField[field].value;
                }
                if (arrSelectedField[field].customJS) {
                    item.customJS = arrSelectedField[field].customJS.replace(/(?:\r\n|\r|\n)/g, "");
                }
                if (arrSelectedField[field].nonConditional) {
                    item.nonConditional = arrSelectedField[field].nonConditional;
                }
                if (arrSelectedField[field].headerStyle) {
                    item.headerStyle = arrSelectedField[field].headerStyle;
                }
                // Formula FIELD HANDLING
                if (arrSelectedField[field].isFormula) {
                    item.isFormula = arrSelectedField[field].isFormula;
                    item.fieldLabel = arrSelectedField[field].fieldLabel;
                }
                if (arrSelectedField[field].equation) {
                    item.equation = arrSelectedField[field].equation;
                }
                if (arrSelectedField[field].hasConditionalFormating) {
                    item.hasConditionalFormating = arrSelectedField[field].hasConditionalFormating;
                }
                if (arrSelectedField[field].isPersonalised) {
                    item.isPersonalised = arrSelectedField[field].isPersonalised;
                    item.stringFieldType = arrSelectedField[field].stringFieldType;
                    item.action = arrSelectedField[field].action;
                    item.rerender = arrSelectedField[field].rerender;
                }
                if (arrSelectedField[field].isInputField) {
                    item.isInputField = arrSelectedField[field].isInputField;
                }
                if (arrSelectedField[field].showInTotal) {
                    item.showInTotal = arrSelectedField[field].showInTotal;
                    item.totalType = arrSelectedField[field].totalType;
                }
                if (arrSelectedField[field].internallyCalculated) {
                    item.internallyCalculated = arrSelectedField[field].internallyCalculated;
                }
                if (arrSelectedField[field].isMassUpdate) {
                    item.isMassUpdate = arrSelectedField[field].isMassUpdate;
                }
                if (arrSelectedField[field].picklistColorsMap) {
                    item.picklistColorsMap = arrSelectedField[field].picklistColorsMap;
                }
                if (arrSelectedField[field].newLabel) {
                    item.newLabel = arrSelectedField[field].newLabel;
                }
                if (arrSelectedField[field].conditionalRules) {
                    item.conditionalRules = arrSelectedField[field].conditionalRules;
                }
                if (arrSelectedField[field].hasFileInput != null) {
                    item.hasFileInput = arrSelectedField[field].hasFileInput;
                }
                if (arrSelectedField[field].scale != null) {
                    item.scale = arrSelectedField[field].scale;
                }
                if (arrSelectedField[field].displayFullURL != null) {
                    item.displayFullURL = arrSelectedField[field].displayFullURL;
                }
                if (arrSelectedField[field].URLOption != null) {
                    item.URLOption = arrSelectedField[field].URLOption;
                }
                if (arrSelectedField[field].replaceURLWith != null) {
                    item.replaceURLWith = arrSelectedField[field].replaceURLWith;
                }
                if (arrSelectedField[field].defaultType) {
                    item.defaultType = arrSelectedField[field].defaultType;
                }
                if (arrSelectedField[field].bgColor) {
                    item.bgColor = arrSelectedField[field].bgColor;
                }
                if (arrSelectedField[field].defaultValue) {
                    item.defaultValue = arrSelectedField[field].defaultValue;
                }
                if (arrSelectedField[field].defaultExpression) {
                    item.defaultExpression = arrSelectedField[field].defaultExpression;
                }
                if (arrSelectedField[field].isHidden) {
                    item.isHidden = arrSelectedField[field].isHidden;
                }
                if (arrSelectedField[field].isNotExportable) {
                    item.isNotExportable = arrSelectedField[field].isNotExportable;
                }
                if (arrSelectedField[field].clearOnClone) {
                    item.clearOnClone = arrSelectedField[field].clearOnClone;
                }
                if (arrSelectedField[field].isSortable != null) {
                    item.isSortable = arrSelectedField[field].isSortable;
                }
                if (arrSelectedField[field].defaultSortDirection) {
                    item.defaultSortDirection = arrSelectedField[field].defaultSortDirection;
                }
                if (arrSelectedField[field].value == this.instance.currentTemplate.currentDefaultSortableField) {
                    item.isDefaultSortable = true;
                    if (!item.defaultSortDirection) {
                        item.defaultSortDirection = this.instance.currentTemplate.currentdefaultSortDirection;
                    }
                }
                if (arrSelectedField[field].formattingRulesList && arrSelectedField[field].formattingRulesList != []) {
                    let formattingRulesList = arrSelectedField[field].formattingRulesList;
                    for (let index = 0; index < formattingRulesList.length; index++) {
                        if (formattingRulesList[index].style) {
                            formattingRulesList[index].style = formattingRulesList[index].style;
                        }
                        if (formattingRulesList[index].oppositeStyle) {
                            formattingRulesList[index].oppositeStyle = formattingRulesList[index].oppositeStyle;
                        }
                    }
                    item.formattingRulesList = formattingRulesList;
                }
                if (arrSelectedField[field].isSortable) {
                    this.instance.currentTemplate.sortableFields.push({ label: item.label, value: item.FieldName })
                }
                savedFields.push(item);
            }
        }
        this.instance.currentTemplate.sortableFields = this.sortableFields.sort((item1, item2) => item1.label.localeCompare(item2.label));
        this.instance.currentTemplate.GeneratedJSON = JSON.stringify(savedFields);
        if (this.instance.currentTemplate.GeneratedJSON.length > 131072) {
            toastInfo(this, this.Label.MSG_Field_Length_Limit);
        }
        this.generatePreview();
    }
    get hasSortableFields() {
        return this.instance.currentTemplate.sortableFields && this.instance.currentTemplate.sortableFields.length > 0;
    }
    generateMasterJSON() {
        let arrSelectedField = this.instance.currentTemplate.masterfields;
        let savedFields = [];
        if (arrSelectedField != undefined) {
            for (let field in arrSelectedField) {
                let item = {};
                if (arrSelectedField[field].value.includes('.')) {
                    let referenceApiName = arrSelectedField[field].value.split('.')[1];
                    if (referenceApiName.includes('Product2')) {
                        referenceApiName = 'Product__r';
                        item.FieldName = referenceApiName + '.' + arrSelectedField[field].value.split('.')[2];
                    } else {
                        item.FieldName = arrSelectedField[field].value;
                    }
                } else {
                    item.FieldName = arrSelectedField[field].value;
                }
                savedFields.push(item);
            }
        }
        this.instance.currentTemplate.GeneratedMasterJSON = JSON.stringify(savedFields);
        if (this.instance.currentTemplate.GeneratedMasterJSON.length > 131072) {
            toastInfo(this, this.Label.MSG_Field_Length_Limit);
        }
    }
    generatePreview() {
        this.showPreview = false;
        this.previewTable = [];
        let savedFields = [];
        let lastField;
        for (let index = 0; index < this.instance.currentTemplate.fields.length; index++) {
            let label = this.instance.currentTemplate.fields[index].label;
            if (label && label.split('.').length > 1) {
                label = this.instance.currentTemplate.fields[index].label.split('.')[1];
            }
            let item = {};
            item.FieldLabel = this.instance.currentTemplate.fields[index].newLabel && this.instance.currentTemplate.fields[index].newLabel != '' ? this.instance.currentTemplate.fields[index].newLabel : label;
            item.formattingRulesList = this.instance.currentTemplate.fields[index].formattingRulesList;
            item.isCalculated = this.instance.currentTemplate.fields[index].isCalculated;
            // Formula FIELD HANDLING
            item.isFormula = this.instance.currentTemplate.fields[index].isFormula;
            item.isEncrypted = this.instance.currentTemplate.fields[index].isEncrypted;
            item.scale = this.instance.currentTemplate.fields[index].scale;
            item.isFilterable = this.instance.currentTemplate.fields[index].isFilterable;
            item.isFormulaAndLogo = item.isCalculated && item.FieldLabel.toLowerCase().includes('logo');
            item.isPersonalised = this.instance.currentTemplate.fields[index].isPersonalised;
            item.isButton = item.isPersonalised && this.instance.currentTemplate.fields[index].stringFieldType == 'Button';
            item.isLink = item.isPersonalised && this.instance.currentTemplate.fields[index].stringFieldType == 'Link';
            item.isInputField = !item.isCalculated && item.isCreateable && item.isUpdateable && this.instance.currentTemplate.fields[index].isInputField;
            item.fieldType = this.instance.currentTemplate.fields[index].fieldType;
            item.fieldApiName = this.instance.currentTemplate.fields[index].value;
            item.isSeparator = this.instance.currentTemplate.fields[index].isSeparator;
            item.nonConditional = this.instance.currentTemplate.fields[index].nonConditional;
            item.headerStyle = this.instance.currentTemplate.fields[index]?.headerStyle || '';
            item.isBoolean = item.fieldType == 'BOOLEAN';
            item.isString = item.fieldType == 'STRING';
            item.isTextArea = item.fieldType == 'TEXTAREA';
            item.isDouble = item.fieldType == 'DOUBLE';
            item.isPickList = item.fieldType == 'PICKLIST';
            item.isMultiPickList = item.fieldType == 'MULTIPICKLIST';
            item.isReference = item.fieldType == 'REFERENCE';
            item.isInteger = item.fieldType == 'INTEGER';
            item.isPercent = item.fieldType == 'PERCENT';
            item.isDate = item.fieldType == 'DATE';
            item.isDateTime = item.fieldType == 'DATETIME';
            item.isId = item.fieldType == 'ID';
            item.isCurrency = item.fieldType == 'CURRENCY';
            item.hasHelpText = this.instance.currentTemplate.fields[index].helpText ? true : false;
            item.helpText = this.instance.currentTemplate.fields[index].helpText;
            if (item.isSeparator) {
                item.separatorSettings = this.instance.currentTemplate.fields[index].separatorSettings ? this.instance.currentTemplate.fields[index].separatorSettings : {};
                item.separatorSettings.size = item.separatorSettings.size ? item.separatorSettings.size : '1px';
                item.separatorSettings.color = item.separatorSettings.color ? item.separatorSettings.color : '#000000';
                item.separatorSettings.pattern = item.separatorSettings.pattern ? item.separatorSettings.pattern : 'solid';
            }
            let fieldStyle = item.nonConditional || '';
            let nonConditional = '';
            if (fieldStyle) {
                let textStyle = fieldStyle.textStyle;
                let borderStyle = fieldStyle.borderStyle;
                nonConditional += fieldStyle.width ? 'min-width: ' + fieldStyle.width + '; max-width: ' + fieldStyle.width + '; width: ' + fieldStyle.width + ';' : '';
                nonConditional += fieldStyle.bgColor ? 'background-color: ' + fieldStyle.bgColor + ';' : '';
                if (textStyle) {
                    nonConditional += textStyle.isItalic ? 'font-style: italic;' : '';
                    nonConditional += textStyle.isBold ? 'font-weight: bold;' : '';
                    nonConditional += textStyle.isUnderLine || textStyle.isStrikeThrought ? 'text-decoration:' + (textStyle.isUnderLine ? ' underline ' : '') + (textStyle.isStrikeThrought ? ' line-through ' : '') + ';' : '';
                    nonConditional += textStyle.color ? 'color: ' + textStyle.color + ';' : '';
                    nonConditional += textStyle.size ? 'font-size: ' + textStyle.size + ';' : '';
                    nonConditional += textStyle.align ? 'text-align: ' + textStyle.align + ';' : '';
                }
                if (borderStyle) {
                    nonConditional += borderStyle.size ? 'border-width: ' + borderStyle.size + ';' : '';
                    nonConditional += borderStyle.color ? 'border-color: ' + borderStyle.color + ';' : '';
                    nonConditional += borderStyle.pattern ? 'border-style: ' + borderStyle.pattern + ';' : '';
                }
                if (fieldStyle.isAdvanced) {
                    nonConditional = fieldStyle.style;
                }
            }
            item.thnonConditional = 'white-space : nowrap;' + (lastField && lastField.isSeparator ? 'border-left: ' + lastField.separatorSettings.size + ' ' + lastField.separatorSettings.pattern + ' ' + lastField.separatorSettings.color + ';' : ' ') + nonConditional;
            if (item.isSeparator) {
                lastField = item;
            } else {
                lastField = null;
                savedFields.push(item);
            }
        }
        let self = this;
        setTimeout(() => {
            self.previewTable = savedFields;
            self.showPreview = self.showPreviewValue && self.hasPreview;
        }, 100);
    }
    get hasPreview() {
        return this.previewTable && this.previewTable.length > 0;
    }
    previewTableActionHandler(event) {
        let fieldApiName = event.currentTarget.dataset.fieldApiName;
        let field = this.instance.currentTemplate.fields.find(item => item.value == fieldApiName);
        if (field) {
            if (field.customJS) {
                try {
                    eval(field.customJS);
                } catch (error) {
                    console.log(error);
                }
            }
        }
    }
    pickViewhandler() {
        this.showPreviewValue = !this.showPreviewValue;
        this.showPreview = this.showPreviewValue && this.hasPreview;
    }
    resetMasterObjecthandler() {
        this.instance.currentMasterObject.value = '';
        this.instance.currentMasterObject.objectFields = [];
        this.instance.currentTemplate.masterfields = [];
        this.currentMasterObjectValue = this.instance.currentMasterObject.value;
        this.selectedMasterWantedFields = [];
    }
    resetIconhandler() {
        this.instance.currentTemplate.icon = 'standard:orders';
    }
    openListViewPopup() {
        this.instance.templateSettings.show = true;
    }
    openSettings(event) {
        if (event)
            event.preventDefault();
        if (this.selectedWantedFieldsJSON) {
            let selectedWantedFields = JSON.parse(this.selectedWantedFieldsJSON);
            if (selectedWantedFields && selectedWantedFields.length == 1) {
                let pickListValues = this.instance.currentObject.fieldsMap.hasOwnProperty(selectedWantedFields[0].value) ? this.instance.currentObject.fieldsMap[selectedWantedFields[0].value].pickListValues : undefined;
                this.selectedWantedFieldspickListValuesJSON = pickListValues ? JSON.stringify(pickListValues) : undefined;
            } else {
                this.selectedWantedFieldspickListValuesJSON = undefined;
            }
            this.instance.fieldSettings.show = true;
        } else {
            toastInfo(this, this.Label.MSG_No_Items_Selected);
        }
    }
    closeSettings() {
        this.instance.fieldSettings.show = false;
    }
    confirmSettings(event) {
        let self = this;
        this.Loading = true;
        let fieldsJSON = event.detail.value;
        let newFieldsList = JSON.parse(fieldsJSON);
        if (!newFieldsList || (newFieldsList && newFieldsList.length == 0)) {
            this.Loading = false;
            return;
        }
        let allFormulaValidated = true;
        newFieldsList.forEach(item => {
            if (item.isFormula) {
                this.currentFormula = item;
                allFormulaValidated &= this.validateFormula(true);
            }
        });
        if (!allFormulaValidated) {
            this.Loading = false;
            return;
        }
        this.closeSettings();
        let temp = this.instance.currentTemplate.fields;
        this.instance.currentTemplate.fields = [];
        this.selectedWantedFields = [];
        temp = temp.map(item => {
            let newItem = JSON.parse(JSON.stringify(item));
            newFieldsList.forEach(item2 => {
                if (item.key == item2.key) {
                    newItem = JSON.parse(JSON.stringify(item2));
                    newItem.isInputField = !newItem.isCalculated && newItem.isCreateable && newItem.isUpdateable && newItem.isInputField && !newItem.fieldLabel.includes('>');
                    if (!newItem.isSeparator) {
                        if (newItem.isPersonalised) {
                            newItem.cssClass = 'Personalised';
                            newItem.label = newItem.value;
                            newItem.fieldLabel = newItem.value;
                        } else if (newItem.isFormula) {
                            newItem.cssClass = 'formula-text';
                        } else if (newItem.isInputField) {
                            newItem.cssClass = 'In';
                        } else {
                            newItem.cssClass = 'Out';
                        }
                    }
                    self.selectedWantedFields.push(item);
                }
            });
            return newItem;
        });
        setTimeout(() => {
            self.instance.currentTemplate.fields = temp;
            self.groupableFieldsOptions = self.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
            self.generateJSON();
            self.Loading = false;
            self.deselectList3();
            self.selectList3(self.selectedWantedFields);
        }, 100);
    }
    confirmReadOnlyExpressionEditor(event) {
        this.Loading = true;
        let readOnlyCriteriasJSON = event.detail.value;
        this.readOnlyCriteriaHasError = event.detail.hasError;
        this.readOnlyCriteriasJSON = readOnlyCriteriasJSON;
        this.instance.currentTemplate.readOnlyCriteria = readOnlyCriteriasJSON;
        this.Loading = false;
    }
    // openFilterSettings() {
    //   let self = this;
    //   let arrSelectedField = this.instance.currentTemplate.fields;
    //   let filters = JSON.parse(this.instance.currentTemplate.filters);
    //   let filtersMap = {};
    //   filters.forEach(item => {
    //     filtersMap[item.fieldName] = item;
    //   });
    //   if (arrSelectedField != undefined) {
    //     let excludedTypes = [
    //       'ADDRESS',
    //       'TEXTAREA',
    //       'LOCATION',
    //     ];
    //     this.instance.filterSettings.fields = [];
    //     let fields = [];
    //     let key = 'RecordTypeId';
    //     if (this.instance.currentObject.fieldsMap.hasOwnProperty(key)) {
    //       let field = this.instance.currentObject.fieldsMap[key];
    //       filtersMap[field.fieldName] = Object.assign(JSON.parse(JSON.stringify(filtersMap.hasOwnProperty(field.fieldName) ? filtersMap[field.fieldName] : {})), JSON.parse(JSON.stringify({ fieldName: field.fieldName, fieldLabel: field.fieldLabel, stringFieldType: 'RECORDTYPE', pickListValues: field.pickListValues, isMultiLevel: field.fieldName.includes('.') })));
    //     }
    //     arrSelectedField.filter(item => {
    //       return item.isFilterable && !item.isCalculated && !excludedTypes.includes(item.fieldType);
    //     }).forEach(item => {
    //       let pickListValues = self.instance.currentObject.fieldsMap.hasOwnProperty(item.key) ? self.instance.currentObject.fieldsMap[item.key].pickListValues : undefined;
    //       filtersMap[item.key] = Object.assign(JSON.parse(JSON.stringify(filtersMap.hasOwnProperty(item.key) ? filtersMap[item.key] : {})), JSON.parse(JSON.stringify({ fieldName: item.key, fieldLabel: item.fieldLabel, stringFieldType: !item.key.includes('RecordTypeId') ? item.fieldType : 'RECORDTYPE', pickListValues: pickListValues && pickListValues.length ? JSON.parse(JSON.stringify(pickListValues)) : [], isMultiLevel: item.key.includes('.') })));
    //     });
    //     fields = Object.values(filtersMap).sort((item1, item2) => item1.fieldName.includes('RecordTypeId') || item2.fieldName.includes('RecordTypeId') ? 1 : item2.fieldName.localeCompare(item2.fieldName));
    //     if (fields.length) {
    //       this.instance.filterSettings.fields = JSON.stringify(fields);
    //       this.instance.filterSettings.show = true;
    //     }
    //   }
    // }
    openFilterSettings() {
        let self = this;
        let excludedTypes = [
            'ADDRESS',
            'TEXTAREA',
            'LOCATION',
        ];
        let arrSelectedField = [];
        Object.values(this.instance.currentObject.fieldsMap).forEach(item => {
            if (!item.fieldLabel.includes('>') && item.isFilterable && !excludedTypes.includes(item.fieldType)) {
                let newItem = JSON.parse(JSON.stringify(item));
                newItem.key = newItem.fieldName;
                arrSelectedField.push(newItem);
            }
        });
        let filters = JSON.parse(this.instance.currentTemplate.filters);
        let filtersMap = {};
        filters.forEach(item => {
            filtersMap[item.fieldName] = item;
        });
        if (arrSelectedField) {
            this.instance.filterSettings.fields = [];
            let fields = [];
            let key = 'RecordTypeId';
            if (this.instance.currentObject.fieldsMap.hasOwnProperty(key)) {
                let field = this.instance.currentObject.fieldsMap[key];
                filtersMap[field.fieldName] = Object.assign(JSON.parse(JSON.stringify(filtersMap.hasOwnProperty(field.fieldName) ? filtersMap[field.fieldName] : {})), JSON.parse(JSON.stringify({ fieldName: field.fieldName, fieldLabel: field.fieldLabel, stringFieldType: 'RECORDTYPE', pickListValues: field.pickListValues, isMultiLevel: field.fieldName.includes('.') })));
            }
            arrSelectedField.forEach(item => {
                let pickListValues = self.instance.currentObject.fieldsMap.hasOwnProperty(item.key) ? self.instance.currentObject.fieldsMap[item.key].pickListValues : undefined;
                filtersMap[item.key] = Object.assign(JSON.parse(JSON.stringify(filtersMap.hasOwnProperty(item.key) ? filtersMap[item.key] : {})), JSON.parse(JSON.stringify({ fieldName: item.key, fieldLabel: item.fieldLabel, stringFieldType: !item.key.includes('RecordTypeId') ? item.fieldType : 'RECORDTYPE', pickListValues: pickListValues && pickListValues.length ? JSON.parse(JSON.stringify(pickListValues)) : [], isMultiLevel: item.key.includes('.') })));
            });
            fields = Object.values(filtersMap).sort((item1, item2) => item1.fieldName.includes('RecordTypeId') || item2.fieldName.includes('RecordTypeId') ? 1 : item2.fieldName.localeCompare(item2.fieldName));
            if (fields.length) {
                this.instance.filterSettings.fields = JSON.stringify(fields);
                this.instance.filterSettings.show = true;
            }
        }
    }
    closeFilterSettings() {
        this.instance.filterSettings.show = false;
    }
    confirmFilterSettings(event) {
        const filters = JSON.parse(event.detail.value);
        let count = filters.filter(item => item && !item.hasOwnProperty('userFilterable'));
        this.adminFiltersCount = count.length;
        this.hasAdminFilter = this.adminFiltersCount > 0;
        this.instance.currentTemplate.filters = JSON.stringify(filters);
        this.instance.filterSettings.show = false;
    }
    selectedItems = [];

    handleItemClick(event) {
        let value = event.currentTarget.dataset.value;
        let label = event.currentTarget.dataset.label;
        let selectedItem = this.filterableFieldsList.filter(item => item.value === value)[0];
        selectedItem.isSelected = !selectedItem.isSelected;
        if (selectedItem.isSelected) {
            this.selectedItems.push({ label: label, value: value });
        } else {
            this.selectedItems = this.selectedItems.filter(item => item.value !== value);
        }
    }
    addSelectedFields() {
        this.defaultUserFilter = this.defaultUserFilter.concat(this.selectedItems);
        let selectedValues = this.selectedItems.map(item => item.value);
        this.filterableFilteredFieldsList = this.filterableFilteredFieldsList.filter(item => {
            return !selectedValues.includes(item.value);
        });
        this.filterableFieldsList = this.filterableFieldsList.filter(item => {
            return !selectedValues.includes(item.value);
        });
        this.userFiltersList = this.defaultUserFilter;
        this.selectedItems = [];
    }
    removedItems = [];
    handleItemSelect(event) {
        let value = event.currentTarget.dataset.value;
        let label = event.currentTarget.dataset.label;
        let removedItem = this.defaultUserFilter.filter(item => item.value === value)[0];
        removedItem.isSelected = !removedItem.isSelected;
        if (removedItem.isSelected) {
            this.removedItems.push({ label: label, value: value });
        } else {
            this.removedItems = this.removedItems.filter(item => item.value !== value);
        }
    }

    removeSelectedFields() {
        this.filterableFilteredFieldsList = this.filterableFilteredFieldsList.concat(this.removedItems);
        this.filterableFilteredFieldsList = this.filterableFilteredFieldsList.sort((item1, item2) => item1.label.localeCompare(item2.label));
        this.filterableFieldsList = this.filterableFieldsList.concat(this.removedItems);
        this.filterableFieldsList = this.filterableFieldsList.sort((item1, item2) => item1.label.localeCompare(item2.label));
        let selectedValues = this.removedItems.map(item => item.value);
        this.defaultUserFilter = this.defaultUserFilter.filter(item => {
            return !selectedValues.includes(item.value);
        });
        this.userFiltersList = this.defaultUserFilter;
        this.removedItems = [];
    }

    moveUpDownSelectedFields(event) {
        let direction = event.currentTarget.dataset.direction;
        let selectedValues = this.removedItems.map(item => item.value);
        let array = JSON.parse(JSON.stringify(this.defaultUserFilter));
        // Determine the loop direction based on the user's action
        let start = direction === 'up' ? 0 : array.length - 1;
        let end = direction === 'up' ? array.length : -1;
        let step = direction === 'up' ? 1 : -1;
        for (let i = start; i !== end; i += step) {
            let item = array[i];
            if (selectedValues.includes(item.value)) {
                var currentIndex = i;
                var newIndex = direction === 'up' ? currentIndex - 1 : currentIndex + 1;
                if (newIndex >= 0 && newIndex < array.length && !selectedValues.includes(array[newIndex].value)) {
                    var changedItem = array.splice(currentIndex, 1)[0]; // Remove the item from the current index
                    array.splice(newIndex, 0, changedItem); // Insert the item at the new index
                    i += direction === 'up' ? -1 : 1; // Adjust the loop counter based on direction
                }
            }
        }
        this.defaultUserFilter = array;
        this.userFiltersList = this.defaultUserFilter;
    }

    addSelectedFieldsHandler(event) {
        if (this.InOutValue != event.currentTarget.dataset.recordid) {
            this.InOutValue = event.currentTarget.dataset.recordid;
            this.isInputField = this.InOutValue == 'input';
        }
        if (this.selectedObjectRefFieldFields.length > 0) {
            let temp = this.instance.currentTemplate.fields;
            this.instance.currentTemplate.fields = [];
            let fields = this.selectedObjectRefFieldFields;
            for (let index = 0; index < fields.length; index++) {
                let originalField = this.instance.currentObject.fieldsMap[fields[index].value];
                if (temp.filter(item => !item.key.includes('--- Separator(')).length > (this.instance.limit.detail - 1)) {
                    toastInfo(this, this.selectedObjectRefFieldLabel + originalField.fieldLabel + ' ' + this.Label.MSG_Field_Count_Exceded + ' ' + this.instance.limit.detail);
                } else {
                    let isInputField = false;
                    let cssclass = isInputField ? 'In' : 'Out';
                    let item = {
                        key: fields[index].value,
                        fieldName: fields[index].value,
                        fieldLabel: this.selectedObjectRefFieldLabel + originalField.fieldLabel,
                        label: this.selectedObjectRefFieldLabel + originalField.fieldLabel,
                        value: fields[index].value,
                        isPersonalised: false,
                        isInputField: isInputField,
                        isSeparator: false,
                        cssClass: cssclass,
                        fieldType: this.instance.currentObject.fieldsMap[fields[index].value].fieldType,
                        showInTotal: false,
                        internallyCalculated: false,
                        isMassUpdate: false,
                        totalType: ''
                    };
                    if (!fields[index].value.includes('.')) {
                        item.key += item.cssClass;
                        // item.value += item.cssClass;
                    }
                    addToArrayIfDoesntExist('key', item, temp);
                }
            }
            this.deselectList2();
            this.instance.currentTemplate.fields = temp;
            this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
            this.setSelectedFieldStyle();
            this.generateJSON();
        } else if (this.instance.selection.selectedObjectFields.length > 0) {
            let tobeadded = [];
            let likenessMap = this.likenessMap[this.instance.currentObject.value];
            this.instance.addrelatedFields.fieldStack = [];
            this.instance.selection.selectedObjectFields.forEach(item => {
                if (!item.label.includes('>') && !tobeadded.includes(item)) {
                    tobeadded.push(item);
                    let relatedFields = [];
                    if (likenessMap && likenessMap.hasOwnProperty(item.value)) {
                        likenessMap[item.value].forEach(likeField => {
                            if (!likeField.label.includes('>') && !tobeadded.includes(likeField) && likeField.value != item.value) {
                                tobeadded.push(likeField);
                                relatedFields.push(likeField);
                            }
                        });
                    }
                    this.instance.addrelatedFields.fieldStack.push({ field: item, relatedFields: relatedFields });
                }
            });
            tobeadded = undefined;
            this.checkAddFromStack();
            this.deselectList2();
        } else {
            toastInfo(this, this.Label.MSG_No_Items_Selected);
        }
    }
    checkAddFromStack() {
        if (this.instance.addrelatedFields.fieldStack && this.instance.addrelatedFields.fieldStack.length > 0) {
            if (this.instance.addrelatedFields.fieldStack[0].relatedFields && this.instance.addrelatedFields.fieldStack[0].relatedFields.length > 0) {
                this.instance.addrelatedFields.originafieldLabel = this.instance.addrelatedFields.fieldStack[0].field.label;
                this.instance.addrelatedFields.relatedFieldsLabel = this.instance.addrelatedFields.fieldStack[0].relatedFields.map(item => item.label).join(', ');
                this.showAddrelatedPopup = true;
            } else {
                this.removeFromStack();
            }
        } else {
            this.showAddrelatedPopup = false;
            this.deselectList1();
            this.generateJSON();
        }
    }
    addFromStack() {
        if (this.instance.addrelatedFields.fieldStack && this.instance.addrelatedFields.fieldStack.length > 0) {
            let temp = this.instance.currentTemplate.fields;
            this.instance.currentTemplate.fields = [];
            let fields = this.instance.addrelatedFields.fieldStack[0].relatedFields;
            fields.push(this.instance.addrelatedFields.fieldStack[0].field);
            fields.sort((item1, item2) => item1.value.toLowerCase().localeCompare(item2.value.toLowerCase()));
            for (let index = 0; index < fields.length; index++) {
                if (temp.filter(item => !item.key.includes('--- Separator(')).length > (this.instance.limit.detail - 1)) {
                    toastInfo(this, fields[index].label.replace(/>/g, '') + ' ' + this.Label.MSG_Field_Count_Exceded + ' ' + this.instance.limit.detail);
                } else {
                    let isInputField = this.instance.currentObject.fieldsMap[fields[index].value].isCalculated || fields[index].label.includes('>') ? false : this.InOutValue == 'input' ? true : false;
                    let cssclass = isInputField ? 'In' : 'Out';
                    let item = {
                        key: fields[index].value,
                        fieldName: fields[index].value,
                        label: fields[index].label.replace(/>/g, ''),
                        fieldLabel: fields[index].label.replace(/>/g, ''),
                        value: fields[index].value,
                        /*isPersonalised: false,*/ isInputField: isInputField,
                        scale: this.instance.currentObject.fieldsMap[fields[index].value].scale,
                        isSeparator: false,
                        cssClass: cssclass,
                        fieldType: this.instance.currentObject.fieldsMap[fields[index].value].fieldType,
                        showInTotal: false, totalType: '',
                        isCalculated: this.instance.currentObject.fieldsMap[fields[index].value].isCalculated,
                        isEncrypted: this.instance.currentObject.fieldsMap[fields[index].value].isEncrypted,
                        isFilterable: this.instance.currentObject.fieldsMap[fields[index].value].isFilterable
                    };
                    if (!item.fieldName.includes('.')) {
                        item.key += item.cssClass;
                        // item.value += item.cssClass;
                    }
                    addToArrayIfDoesntExist('key', item, temp);
                }
            }
            this.instance.currentTemplate.fields = temp;
            this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
            this.setSelectedFieldStyle();
            this.instance.addrelatedFields.fieldStack.shift();
            this.showAddrelatedPopup = false;
            this.checkAddFromStack();
        }
    }
    removeFromStack() {
        if (this.instance.addrelatedFields.fieldStack.length > 0) {
            let temp = this.instance.currentTemplate.fields;
            this.instance.currentTemplate.fields = [];
            let fields = [];
            fields.push(this.instance.addrelatedFields.fieldStack[0].field);
            for (let index = 0; index < fields.length; index++) {
                if (temp.filter(item => !item.key.includes('--- Separator(')).length > (this.instance.limit.detail - 1)) {
                    toastInfo(this, this.Label.MSG_Field_Count_Exceded + ' ' + this.instance.limit.detail);
                } else {
                    let isInputField = !this.instance.currentObject.fieldsMap[fields[index].value].isCalculated && this.instance.currentObject.fieldsMap[fields[index].value].isCreateable && this.instance.currentObject.fieldsMap[fields[index].value].isUpdateable && this.InOutValue == 'input';
                    let cssclass = isInputField ? 'In' : 'Out';
                    let item = {
                        key: fields[index].value,
                        fieldName: fields[index].value,
                        label: fields[index].label.replace(/>/g, ''),
                        fieldLabel: fields[index].label.replace(/>/g, ''),
                        value: fields[index].value,/* isPersonalised: false, */
                        isInputField: isInputField,
                        scale: this.instance.currentObject.fieldsMap[fields[index].value].scale,
                        isSeparator: false,
                        cssClass: cssclass,
                        fieldType: this.instance.currentObject.fieldsMap[fields[index].value].fieldType,
                        showInTotal: false, totalType: '',
                        internallyCalculated: false,
                        isMassUpdate: false,
                        isCalculated: this.instance.currentObject.fieldsMap[fields[index].value].isCalculated,
                        isCreateable: this.instance.currentObject.fieldsMap[fields[index].value].isCreateable,
                        isUpdateable: this.instance.currentObject.fieldsMap[fields[index].value].isUpdateable,
                        isEncrypted: this.instance.currentObject.fieldsMap[fields[index].value].isEncrypted,
                        isFilterable: this.instance.currentObject.fieldsMap[fields[index].value].isFilterable
                    };
                    if (!item.fieldName.includes('.')) {
                        item.key += item.cssClass;
                        // item.value += item.cssClass;
                    }
                    addToArrayIfDoesntExist('key', item, temp);
                }
            }
            this.instance.currentTemplate.fields = temp;
            this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
            this.setSelectedFieldStyle();
            this.instance.addrelatedFields.fieldStack.shift();
            this.showAddrelatedPopup = false;
            this.checkAddFromStack();
        }
    }
    addSelectedMasterFieldsHandler() {
        let temp = this.instance.currentTemplate.masterfields;
        let changed = false;
        this.instance.currentTemplate.masterfields = [];
        if (this.instance.selection.selectedMasterObjectFields.length > 0) {
            changed = true;
            let fields = [];
            let likenessMap = this.likenessMap[this.instance.currentMasterObject.value];
            this.instance.selection.selectedMasterObjectFields.forEach(item => {
                if (!fields.includes(item)) {
                    fields.push(item);
                }
                if (likenessMap && likenessMap.hasOwnProperty(item.value)) {
                    likenessMap[item.value].forEach(likeField => {
                        if (!fields.includes(likeField)) {
                            fields.push(likeField);
                        }
                    });
                }
            });
            for (let index = 0; index < fields.length; index++) {
                if (temp.length > (this.instance.limit.banner - 1)) {
                    toastInfo(this, fields[index].label.replace(/ >/g, '') + this.Label.MSG_Field_Count_Exceded + ' ' + this.instance.limit.banner);
                } else {
                    let item = { key: fields[index].value, label: fields[index].label.replace(/ >/g, ''), fieldLabel: fields[index].label.replace(/ >/g, ''), value: fields[index].value };
                    addToArrayIfDoesntExist('key', item, temp);
                }
            }
        }
        this.deselectList4();
        this.deselectList5();
        this.instance.currentTemplate.masterfields = temp;
        this.setSelectedFieldStyle();
        if (changed) {
            this.generateMasterJSON();
        }
    }
    addSeperatorHandler() {
        let temp = this.instance.currentTemplate.fields;
        this.instance.currentTemplate.fields = [];
        let separatorIndex = this.separatorIndex++;
        let item = { key: '--- Separator(' + separatorIndex + ') ---', fieldLabel: '--- Separator(' + separatorIndex + ') ---', label: '--- Separator(' + separatorIndex + ') ---', value: '--- Separator(' + separatorIndex + ') ---', isSeparator: true, class: '', separatorSettings: { borderSize: '1px', borderColor: '#000000', borderPatern: 'solid' } };
        addToArrayIfDoesntExist('key', item, temp);
        this.instance.currentTemplate.fields = temp;
        this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
        this.generateJSON();
    }
    moveUpHandler() {
        if (this.selectedWantedFields.length == 0) {
            return;
        }
        let temp = this.instance.currentTemplate.fields;
        // this.instance.currentTemplate.fields = [];
        let SelectedField = this.selectedWantedFields;
        let oldIndexList = [];
        for (let k = 0; k < temp.length; k++) {
            for (let l = 0; l < SelectedField.length; l++) {
                if (temp[k].key == SelectedField[l].key) {
                    oldIndexList[l] = k;
                    break;
                }
            }
        }
        oldIndexList.sort(function (a, b) {
            return a - b
        });
        for (let t = 0; t < oldIndexList.length; t++) {
            temp = array_move_one_item(temp, oldIndexList[t], oldIndexList[t] - 1);
        }
        this.instance.currentTemplate.fields = temp;
        this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
        this.generateJSON();
        let self = this;
        setTimeout(() => { self.selectList3(this.selectedWantedFields); }, 100);
    }
    moveUpMasterHandler() {
        if (this.selectedMasterWantedFields.length == 0) {
            return;
        }
        let temp = this.instance.currentTemplate.masterfields;
        this.instance.currentTemplate.masterfields = [];
        let SelectedField = this.selectedMasterWantedFields;
        let oldIndexList = [];
        for (let k = 0; k < temp.length; k++) {
            for (let l = 0; l < SelectedField.length; l++) {
                if (temp[k].value == SelectedField[l].value) {
                    oldIndexList[l] = k;
                    break;
                }
            }
        }
        oldIndexList.sort(function (a, b) {
            return a - b
        });
        for (let t = 0; t < oldIndexList.length; t++) {
            temp = array_move_one_item(temp, oldIndexList[t], oldIndexList[t] - 1);
        }
        this.instance.currentTemplate.masterfields = temp;
        this.generateMasterJSON();
        let self = this;
        setTimeout(() => { self.selectList5(this.selectedMasterWantedFields); }, 100);
    }
    moveDownHandler() {
        if (this.selectedWantedFields.length == 0) {
            return;
        }
        let temp = this.instance.currentTemplate.fields;
        this.instance.currentTemplate.fields = [];
        let SelectedField = this.selectedWantedFields;
        let oldIndexList = [];
        for (let k = 0; k < temp.length; k++) {
            for (let l = 0; l < SelectedField.length; l++) {
                if (temp[k].key == SelectedField[l].key) {
                    oldIndexList[l] = k;
                    break;
                }
            }
        }
        oldIndexList.sort(function (a, b) {
            return b - a;
        });
        for (let t = 0; t < oldIndexList.length; t++) {
            temp = array_move_one_item(temp, oldIndexList[t], oldIndexList[t] + 1);
        }
        this.instance.currentTemplate.fields = temp;
        this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
        this.generateJSON();
        let self = this;
        setTimeout(() => { self.selectList3(this.selectedWantedFields); }, 100);
    }
    moveDownMasterHandler() {
        if (this.selectedMasterWantedFields.length == 0) {
            return;
        }
        let temp = this.instance.currentTemplate.masterfields;
        this.instance.currentTemplate.masterfields = [];
        let SelectedField = this.selectedMasterWantedFields;
        let oldIndexList = [];
        for (let k = 0; k < temp.length; k++) {
            for (let l = 0; l < SelectedField.length; l++) {
                if (temp[k].value == SelectedField[l].value) {
                    oldIndexList[l] = k;
                    break;
                }
            }
        }
        oldIndexList.sort(function (a, b) {
            return b - a;
        });
        for (let t = 0; t < oldIndexList.length; t++) {
            temp = array_move_one_item(temp, oldIndexList[t], oldIndexList[t] + 1);
        }
        this.instance.currentTemplate.masterfields = temp;
        this.generateMasterJSON();
        let self = this;
        setTimeout(() => { self.selectList5(this.selectedMasterWantedFields); }, 100);
    }
    moveToTopBottom(event) {
        const key = event.currentTarget && event.currentTarget.dataset ? event.currentTarget.dataset.target : null;
        const direction = event.currentTarget && event.currentTarget.dataset ? event.currentTarget.dataset.direction : null;
        if (!key) {
            return;
        }
        if ((key === 'detailFields' && this.selectedWantedFields.length == 0) || (key === 'masterFields' && this.selectedMasterWantedFields.length == 0)) {
            return;
        }
        let temp;
        let SelectedField;
        let selectedItems = [];
        let remainingItems = [];
        let self = this;
        if (key === 'detailFields') {
            temp = this.instance.currentTemplate.fields;
            SelectedField = this.selectedWantedFields;
        } else if (key === 'masterFields') {
            temp = this.instance.currentTemplate.masterfields;
            SelectedField = this.selectedMasterWantedFields;
        }

        for (let i = 0; i < temp.length; i++) {
            let isSelected = false;
            for (let j = 0; j < SelectedField.length; j++) {
                if (temp[i].key == SelectedField[j].key) {
                    selectedItems.push(temp[i]);
                    isSelected = true;
                    break;
                }
            }
            if (!isSelected) {
                remainingItems.push(temp[i]);
            }
        }
        console.log('selectedItems >> ' + JSON.stringify(selectedItems))
        if (key === 'detailFields') {
            this.instance.currentTemplate.fields = direction == 'top' ? [...selectedItems, ...remainingItems] : [...remainingItems, ...selectedItems];
            this.generateJSON();
            setTimeout(() => { self.selectList3(this.selectedWantedFields); }, 100);
        } else if (key === 'masterFields') {
            this.instance.currentTemplate.masterfields = direction == 'top' ? [...selectedItems, ...remainingItems] : [...remainingItems, ...selectedItems];
            this.generateMasterJSON();
            setTimeout(() => { self.selectList5(this.selectedMasterWantedFields); }, 100);
        }
    }

    removeSelectedFieldsHandler() {
        if (this.selectedWantedFields.length === 0) {
            return;
        }
        let temp = this.instance.currentTemplate.fields;
        this.instance.currentTemplate.fields = [];
        let toRemoveIndex = [];
        for (let index = 0; index < this.selectedWantedFields.length; index++) {
            let selected = this.selectedWantedFields[index];
            for (let index2 = 0; index2 < temp.length; index2++) {
                let cur = temp[index2];
                if (cur.label === selected.label && cur.key === selected.key) {
                    toRemoveIndex.push(index2);
                }
            }
        }
        toRemoveIndex.sort(function (a, b) {
            return b - a;
        });
        for (let index in toRemoveIndex) {
            temp.splice(toRemoveIndex[index], 1);
        }
        this.selectedWantedFields = [];
        this.instance.currentTemplate.fields = temp;
        this.groupableFieldsOptions = this.instance.currentTemplate.fields?.filter((field) => field.fieldType === 'PICKLIST' || (field.fieldType === 'STRING' && !field.value.includes('.')) || (field.fieldType === 'REFERENCE' && !field.value.includes('.')));
        this.deselectList3();
        this.generateJSON();
        this.setSelectedFieldStyle();
    }
    removeSelectedMasterFieldsHandler() {
        if (this.selectedMasterWantedFields.length === 0) {
            return;
        }
        let temp = JSON.parse(JSON.stringify(this.instance.currentTemplate.masterfields));
        this.instance.currentTemplate.masterfields = [];
        let toRemoveIndex = [];
        for (let index = 0; index < this.selectedMasterWantedFields.length; index++) {
            let selected = this.selectedMasterWantedFields[index];
            for (let index2 = 0; index2 < temp.length; index2++) {
                let cur = temp[index2];
                if (cur.label === selected.label && cur.value === selected.value) {
                    toRemoveIndex.push(index2);
                }
            }
        }
        toRemoveIndex.sort(function (a, b) {
            return b - a;
        });
        for (let index in toRemoveIndex) {
            temp.splice(toRemoveIndex[index], 1);
        }
        this.selectedMasterWantedFields = [];
        this.instance.currentTemplate.masterfields = temp;
        this.generateMasterJSON();
        this.deselectList5();
    }
    actionSelectChangedHandler(event) {
        this.allActions = [];
        let values = new Set(Array.from(event.target.selectedOptions).map(option => option.value));
        for (let index = 0; index < this.actionDescribe.length; index++) {
            if (values.has(this.actionDescribe[index].Name)) {
                this.allActions.push(this.actionDescribe[index]);
            }
        }
    }

    addSelectedActionsHandler() {
        if (this.allActions.length > 0) {
            let fields = this.allActions;
            let moved = false;
            for (let index = 0; index < fields.length; index++) {
                let originalField = fields[index].Name;
                let actionIndex = this.actionDescribe.findIndex(action => action.Name === originalField);
                if (actionIndex !== -1) {
                    this.actionDescribe.splice(actionIndex, 1);
                    this.selectedActions.push(fields[index]);
                    this.actions.quickActions.push(fields[index]);
                    moved = true;
                }
            }
            if (moved) {
                fields = [];
                this.allActions = [];
                const tempActions = [...this.actionDescribe];
                this.actionDescribe = [];
                setTimeout(() => {
                    this.actionDescribe = tempActions;
                }, 0);
            }
        }
    }
    WantedActionsChangeHandler(event) {
        this.allActions = [];
        let values = new Set(Array.from(event.target.selectedOptions).map(option => option.value));
        for (let index = 0; index < this.selectedActions.length; index++) {
            if (values.has(this.selectedActions[index].Name)) {
                this.allActions.push(this.selectedActions[index]);
            }
        }
    }
    removeSelectedActionsHandler() {
        if (this.allActions.length > 0) {
            let fields = this.allActions;
            let moved = false;
            for (let index = 0; index < fields.length; index++) {
                let originalField = fields[index].Name;
                let actionIndex = this.selectedActions.findIndex(action => action.Name === originalField);
                if (actionIndex !== -1) {
                    this.selectedActions.splice(actionIndex, 1);
                    let qIndex = this.actions.quickActions.findIndex(action => action.Name === originalField);
                    if (qIndex !== -1) this.actions.quickActions.splice(qIndex, 1);
                    this.actionDescribe.push(fields[index]);
                    moved = true;
                }
            }
            if (moved) {
                fields = [];
                this.allActions = [];
                const tempActions = [...this.selectedActions];
                this.selectedActions = [];
                setTimeout(() => {
                    this.selectedActions = tempActions;
                }, 0);
            }
        }
    }
    deselectAllSelects() {
        this.deselectList1();
        this.deselectList2();
        this.deselectList3();
        this.deselectList4();
        this.deselectList5();
    }
    deselect(list) {
        let selectedFields = list.selectedOptions;
        let count = selectedFields.length;
        for (let index = 0; selectedFields && index < count; index++) {
            if (selectedFields[0]) {
                selectedFields[0].selected = false;
            }
        }
    }
    deselectList1() {
        let list = this.template.querySelector('select[data-recordid="ObjectFields"]');
        if (list) {
            this.deselect(list);
        }
        this.instance.selection.selectedObjectFields = [];
        this.selectedObjectRefField = '';
        this.selectedObjectRefFieldLabel = '';
        this.ObjectRelatedFieldsFieldsShowStatus = false;
        this.ObjectRelatedFieldsFieldsDisableStatus = !this.ObjectRelatedFieldsFieldsShowStatus;
    }
    deselectList2() {
        let list = this.template.querySelector('select[data-recordid="ObjectRelatedFieldsFields"]');
        if (list) {
            this.deselect(list);
        }
        this.selectedObjectRefFieldFields = [];
    }
    deselectFilterList() {
        this.filterableFieldsList.forEach(item => item.isSelected = false);
        this.selectedItems = [];
    }
    deselectList3() {
        let list = this.template.querySelector('select[data-recordid="wantedFields"]');
        if (list) {
            this.deselect(list);
        }
        this.selectedWantedFieldsJSON = undefined;
        this.selectedWantedFields = [];
    }
    deselectList4() {
        let list = this.template.querySelector('select[data-recordid="MasterObjectFields"]');
        if (list) {
            this.deselect(list);
        }
        this.instance.selection.selectedObjectFields = [];
    }
    deselectList5() {
        let list = this.template.querySelector('select[data-recordid="wantedMasterFields"]');
        if (list) {
            this.deselect(list);
        }
        this.selectedMasterWantedFieldsJSON = undefined;
        this.selectedMasterWantedFields = [];
    }
    selectList3(selectedTab) {
        let wantedFields = this.template.querySelectorAll('select[data-recordid="wantedFields"] option');
        for (let index = 0; index < wantedFields.length; index++) {
            wantedFields[index].selected = false;
            for (let index2 = 0; index2 < selectedTab.length; index2++) {
                if (wantedFields[index].dataset.key == selectedTab[index2].key) {
                    wantedFields[index].selected = true;
                }
            }
        }
    }
    selectList5(selectedTab) {
        let wantedFields = this.template.querySelectorAll('select[data-recordid="wantedMasterFields"] option');
        for (let index = 0; index < wantedFields.length; index++) {
            wantedFields[index].selected = false;
            for (let index2 = 0; index2 < selectedTab.length; index2++) {
                if (wantedFields[index].value == selectedTab[index2].value) {
                    wantedFields[index].selected = true;
                }
            }
        }
    }
    handleSelectedCalendartFields(event) {
        let name = event.target.dataset.name;
        this.instance.calendarSettingsData[name] = event.detail.value;
        let self = this;
        if (this.instance.calendarSettingsData['startDate'] == this.instance.calendarSettingsData['endDate'] && this.instance.calendarSettingsData['endDate'] != '') {
            toastInfo(self, 'End date field must not be equal to Start date field');
        }
    }
    handleSelectedTimeLineFields(event) {
        let name = event.target.dataset.name;
        this.instance.timeLineSettings[name] = event.detail.value;
    }
    exposedFilterBackup = null;
    showUserFilterHandler(event) {
        const value = event.target.checked;
        // The click can be handled more than once (inner input + host): ignore calls that do not change the state,
        // otherwise a second "uncheck" would overwrite the backup with the already emptied lists
        if (!!this.instance.currentTemplate.showUserFilter === value) {
            return;
        }
        this.instance.currentTemplate.showUserFilter = value;
        let filtersArray = [];
        try {
            filtersArray = JSON.parse(this.instance.currentTemplate.filters || '[]');
        } catch (e) {
            filtersArray = [];
        }
        if (!value) {
            this.exposedFilterBackup = {
                selectedFields: JSON.parse(JSON.stringify(this.defaultUserFilter)),
                filters: filtersArray.filter(item => item && item.hasOwnProperty('userFilterable'))
            };
            this.instance.currentTemplate.filters = JSON.stringify(filtersArray.filter(item => item && !item.hasOwnProperty('userFilterable')));
            this.defaultUserFilter = [];
            this.userFiltersList = [];
        } else if (this.exposedFilterBackup) {
            const backup = this.exposedFilterBackup;
            const restoredValues = backup.selectedFields.map(item => item.value);
            this.instance.currentTemplate.filters = JSON.stringify(filtersArray.filter(item => item && !(item.hasOwnProperty('userFilterable') && restoredValues.includes(item.fieldName))).concat(backup.filters));
            this.defaultUserFilter = backup.selectedFields;
            this.userFiltersList = this.defaultUserFilter;
            this.filterableFieldsList = this.filterableFieldsList.filter(item => !restoredValues.includes(item.value));
            this.filterableFilteredFieldsList = this.filterableFieldsList;
            this.exposedFilterBackup = null;
        }
    }
    showFilterOnColumnHeaderHandler(event) {
        let value = event.target.checked;
        this.instance.currentTemplate.isShowFilterOnColumnHeader = value;
    }
    overrideFilterHandler(event) {
        let value = event.target.checked;
        this.instance.currentTemplate.overrideFilter = value;
    }
    showCalendarSettingsHandler(event) {
        let value = event.target.checked;
        this.instance.calendarSettingsData.showCalendarSettings = value;
    }
    showTimeLineSettings(event) {
        let value = event.target.checked;
        this.instance.timeLineSettings.isTimeLineSettings = value;
    }
    get disableTemplateNameInputAndObjectSelection() {
        return this.instance.currentTemplate.value != this.instance.defaultNewTemplate.value;
    }
    get disableSaveAs() {
        if (!this.instance.currentTemplate.name) {
            return true;
        }
        if (!this.instance.currentObject.value && !this.instance.currentTemplate.isMaster) {
            return true;
        }
        if (this.instance.currentTemplate.value == undefined || this.instance.currentTemplate.value == 'Custom_Template') {
            return true;
        }
    }
    cancelTemplatesOrder() {
        this.instance.templateSettings.show = false;
    }
    saveTemplatesOrder() {
        this.Loading = true;
        this.instance.templateSettings.show = false;
        setTimeout(() => {
            this.Loading = false;
        }, 4000);
        toastSuccess(this, this.Label.LBL_Save, this.Label.MSG_Save_Complete);
    }
    get masterObjectName() {
        return this.Label.LBL_Object_Title + ' : ' + this.instance.currentMasterObject.key;
    }
    get objectName() {
        return this.Label.LBL_Object_Title + ' : ' + this.instance.currentObject.value;
    }
    get previewIcon() {
        return this.showPreview ? 'utility:hide' : 'utility:preview';
    }
    get previewTitle() {
        return this.showPreview ? this.Label.LBL_Hide_Table : this.Label.LBL_Preview_Table;
    }

    get currentTypeDescription() {
        const type = this.instance.currentTemplate?.type || '';
        switch (type) {
            case 'Detail': return this.Label.LBL_GridSettingsManager_TypeDescription_Detail;
            case 'Master': return this.Label.LBL_GridSettingsManager_TypeDescription_Master;
            case 'Master-Detail': return this.Label.LBL_GridSettingsManager_TypeDescription_MasterDetail;
            case 'None-Master-Detail': return this.Label.LBL_GridSettingsManager_TypeDescription_NoneMasterDetail;
            case 'Master-Detail-Lookup': return this.Label.LBL_GridSettingsManager_TypeDescription_MasterDetailLookup;
        }
    }
    @track showAddCustomFieldPopup = false;
    @track isFormula = false;
    // Formula Settings Pop Up
    toggleAddCustomField() {
        this.currentFormula = {}
        this.showAddCustomFieldPopup = !this.showAddCustomFieldPopup;
        if (!this.showAddCustomFieldPopup) {
            this.isFormula = false;
        }
    }

    get customFieldOptions() {
        return [
            { label: 'Separator', value: 'SEPARATOR' },
            { label: 'Formula', value: 'FORMULA' }
        ];
    }
    // Handle Formula Changes
    handleFormulaChange(event) {
        const field = event.target.dataset.field;
        const newValue = event.detail.value;
        if (field === 'addFieldOrOperator') {
            this.currentFormula.equation += `${newValue} `;
        } else {
            this.currentFormula[field] = newValue.trim();
            if (field == 'fieldLabel') {
                this.currentFormula.label = newValue.trim();
            }
        }
    }
    handleChangeCustomField(event) {
        let selectedType = event.detail.value;
        if (selectedType === 'SEPARATOR') {
            this.addSeperatorHandler();
            this.toggleAddCustomField();
        }
        if (selectedType === 'FORMULA') {
            this.addNewFormula();
            this.isFormula = true;
        }
    }
    @track currentFormula = {};
    @track currentFormulaIndex = 0;
    addNewFormula() {
        let index = this.currentFormulaIndex + 1;
        let formula = {
            key: '--- Formula(' + index + ') ---',
            value: 'Formula' + index,
            label: null,
            fieldLabel: null,
            equation: '',
            isFormula: true,
            formulaType: 'NUMBER',
            cssClass: 'formula-text',
            scale: 0
        };
        this.currentFormula = formula;
    }
    confirmFormula() {
        try {
            let validate = this.validateFormula();
            if (validate) {
                this.currentFormulaIndex++;
                let temp = this.instance.currentTemplate.fields;
                this.instance.currentTemplate.fields = [];
                console.log('this.currentFormula.value >>> ' + this.currentFormula.value);
                console.log('temp >>> ' + JSON.stringify(temp));
                addToArrayIfDoesntExist('value', this.currentFormula, temp);
                this.instance.currentTemplate.fields = temp;
                this.generateJSON();
                this.toggleAddCustomField();
            }
        } catch (err) {
            showNotification(this, this.Label.MSG_Error, err.message, 'error', 'dismissable');
            return false;
        }
    }

    validateFormula(isEdit) {
        try {
            const equation = this.currentFormula.equation?.trim() || '';
            const label = this.currentFormula.fieldLabel?.trim() || '';
            const isBooleanFormula = this.currentFormula.formulaType === 'BOOLEAN';
            if (!isEdit) {
                if (!/^[a-zA-Z0-9 _-]+$/.test(label)) {
                    throw new Error('Formula name contains invalid characters.');
                }
                if (this.instance.currentTemplate.fields.some(f => f.isFormula && f.fieldLabel === label)) {
                    throw new Error('Formula name already exists.');
                }
            }
            if (!equation) {
                throw new Error('Formula cannot be empty.');
            }
            if (equation.length > 300) {
                throw new Error('Formula too long. Max 300 characters.');
            }
            const allowedPatternNumber = /^[\w\s+\-*/().^<>=&|]+$/;
            const allowedPatternBoolean = /^[\w\s+\-*/().^<>=&|!]+$/;

            if (isBooleanFormula) {
                if (!allowedPatternBoolean.test(equation)) {
                    throw new Error('Formula contains invalid characters for BOOLEAN formula.');
                }
            } else {
                if (!allowedPatternNumber.test(equation)) {
                    throw new Error('Formula contains invalid characters.');
                }
            }
            const allowedVariables = this.availableFieldsForFomrula.map(f => f.value);
            const variables = equation.match(/[a-zA-Z_]\w*/g) || [];
            const forbiddenJS = ['constructor', 'prototype', 'toString', 'eval', 'arguments'];
            for (const v of variables) {
                if (forbiddenJS.includes(v)) {
                    throw new Error(`Invalid field name: ${v}`);
                }
                if (!allowedVariables.includes(v)) {
                    if (!isBooleanFormula || (v !== 'true' && v !== 'false')) {
                        throw new Error(`Unknown field: ${v}`);
                    }
                }
            }
            let depth = 0;
            let maxDepth = 0;
            for (const ch of equation) {
                if (ch === '(') {
                    depth++;
                    maxDepth = Math.max(maxDepth, depth);
                }
                if (ch === ')') {
                    depth--;
                    if (depth < 0) {
                        throw new Error('Mismatched parentheses detected.');
                    }
                }
            }
            if (depth !== 0) {
                throw new Error('Unbalanced parentheses.');
            }
            if (maxDepth > 3) {
                throw new Error('Formula too complex (too many nested parentheses).');
            }
            let invalidSequences;
            if (isBooleanFormula) {
                invalidSequences = [
                    /\+\+/,
                    /\*\*/,
                    /\/\//,
                    /\^\^/,
                    /&&&+/,
                    /\|\|\|+/,
                    /!!+/,
                    /(?<![=!<>])([+\-*/^]){2,}/
                ];
            } else {
                invalidSequences = [
                    /\+\+/,
                    /--/,
                    /\*\*/,
                    /\/\//,
                    /\^\^/,
                    /[+\-*/^<>=&|]{2,}/
                ];
            }
            for (const seq of invalidSequences) {
                if (seq.test(equation)) {
                    throw new Error('Invalid operator sequence.');
                }
            }
            if (/^[+\-*/^]/.test(equation)) {
                throw new Error('Formula cannot start with an operator.');
            }
            if (/[+\-*/^]$/.test(equation)) {
                throw new Error('Formula cannot end with an operator.');
            }
            if (!isBooleanFormula && /\/\s*0(?![\d])/g.test(equation)) {
                throw new Error('Division by zero detected.');
            }
            try {
                let testExpr = equation;
                allowedVariables.forEach(col => {
                    const regex = new RegExp(`\\b${col}\\b`, 'g');
                    testExpr = testExpr.replace(regex, isBooleanFormula ? 'true' : '1');
                });
                if (isBooleanFormula) {
                    testExpr = testExpr.replace(/\btrue\b/gi, 'true');
                    testExpr = testExpr.replace(/\bfalse\b/gi, 'false');
                }
                const fn = new Function(`"use strict"; return (${testExpr});`);
                const result = fn();
                if (isBooleanFormula) {
                    if (typeof result !== 'boolean') {
                        throw new Error('BOOLEAN formula must return true or false.');
                    }
                } else {
                    if (typeof result !== 'number' || isNaN(result)) {
                        throw new Error('Formula must return a numeric result.');
                    }
                }
            } catch (err) {
                throw new Error('Invalid formula syntax.');
            }
            if (!label) {
                throw new Error('Formula name cannot be empty.');
            }
        } catch (err) {
            showNotification(this, this.Label.MSG_Error, err.message, 'error', 'dismissable');
            return false;
        }
        showNotification(this, this.Label.MSG_Success, 'No syntax error', 'success', 'dismissable');
        return true;
    }

    get operatorOptions() {
        const isBoolean = this.selectedFormula?.formulaType === 'BOOLEAN';
        if (isBoolean) {
            return [
                { label: '( Open Parenthesis', value: '(' },
                { label: ') Close Parenthesis', value: ')' },
                { label: '= Equal', value: '==' },
                { label: '<> Not Equal', value: '!=' },
                { label: '< Less Than', value: '<' },
                { label: '> Greater Than', value: '>' },
                { label: '<= Less Than or Equal', value: '<=' },
                { label: '>= Greater Than or Equal', value: '>=' },
                { label: '&& And', value: '&&' },
                { label: '|| Or', value: '||' },
                { label: '! Not', value: '!' }
            ];
        }
        return [
            { label: '+ Add', value: '+' },
            { label: '- Subtract', value: '-' },
            { label: '* Multiply', value: '*' },
            { label: '/ Divide', value: '/' },
            { label: '^ Exponentiation', value: '^' },
            { label: '( Open Parenthesis', value: '(' },
            { label: ') Close Parenthesis', value: ')' },
            { label: '& Concatenate', value: '&' }
        ];
    }

    get availableFieldsForFomrula() {
        const type = this.currentFormula?.formulaType;
        if (!type || type == 'NUMBER') {
            return Object.values(this.instance.currentObject.fieldsMap)
                .filter(item => item.isNumber === true)
                .map(item => ({
                    label: item.fieldLabel,
                    value: item.fieldName
                }));
        }
        if (type == 'BOOLEAN') {
            return Object.values(this.instance.currentObject.fieldsMap)
                .filter(item => item.fieldType != 'REFERENCE' && item.fieldType != 'PICKLIST')
                .map(item => ({
                    label: `${item.fieldLabel} (${item.fieldType})`,
                    value: item.fieldName
                }));
        }

        return Object.values(this.instance.currentObject.fieldsMap)
            .filter(item => item.fieldType === type)
            .map(item => ({
                label: item.fieldLabel,
                value: item.fieldName
            }));
    }
}