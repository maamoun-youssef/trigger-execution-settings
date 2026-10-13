import { CurrentPageReference } from "lightning/navigation";
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getObjectInfos } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
// Services
import loadSimulation from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.loadSimulation";
import getProductsRecords from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.getProductsRecords";
import getCategoriesRecords from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.getCategoriesRecords";
import getBUsRecords from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.getBUsRecords";
import getProductsOfCategory from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.getProductsOfCategory";
import createNewDetail from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.createNewDetail";
import saveSimulation from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.saveSimulation";
import getCommercialPlanDetails from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.getCommercialPlanDetails";
import getFieldDependencies from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.getFieldDependencies";
import deleteCPDs from "@salesforce/apex/CommercialPlanSimulationCtrlLWC.deleteCPDs";
// Custom Labels
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_Show_Hide_Columns from "@salesforce/label/c.LBL_Show_Hide_Columns";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Cancel from "@salesforce/label/c.Cancel";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Advanced from "@salesforce/label/c.LBL_Advanced";
import LBL_End from "@salesforce/label/c.LBL_End";
import LBL_Start from "@salesforce/label/c.LBL_Start";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Maximum from "@salesforce/label/c.LBL_Maximum";
import LBL_Minimum from "@salesforce/label/c.LBL_Minimum";
import MSG_Filter_On_Id_Help_Text from "@salesforce/label/c.MSG_Filter_On_Id_Help_Text";
import LBL_True from "@salesforce/label/c.LBL_True";
import LBL_False from "@salesforce/label/c.LBL_False";
import LBL_Export from "@salesforce/label/c.LBL_Export";
import MSG_Confirm_Delete from "@salesforce/label/c.MSG_Confirm_Delete";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Product_List from "@salesforce/label/c.LBL_Product_List";
import LBL_Show_Only_HLP from "@salesforce/label/c.LBL_Show_Only_HLP";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Upload_File from "@salesforce/label/c.LBL_Upload_File";
import LBL_New from "@salesforce/label/c.LBL_New";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Mass_update from "@salesforce/label/c.LBL_Mass_update";
import LBL_Selected_Lines from "@salesforce/label/c.LBL_Selected_Lines";
import MSG_No_Items_Selected from "@salesforce/label/c.MSG_No_Items_Selected";
import LBL_Multi_Selection from "@salesforce/label/c.LBL_Multi_Selection";
import LBL_Single_Selection from "@salesforce/label/c.LBL_Single_Selection";
// Custom Fields
import CATEGORY_NAME from '@salesforce/schema/Hierarchy__c.Name';
import BRAND_NAME from '@salesforce/schema/Brand__c.Name';
import CommercialPlanDetail__c from '@salesforce/schema/CommercialPlanDetail__c.Name';
import Status__c from "@salesforce/schema/CommercialPlanDetail__c.Status__c";
import BudgetType__c from "@salesforce/schema/CommercialPlanDetail__c.BudgetType__c";
import BusinessUnitTarget__c from "@salesforce/schema/CommercialPlanDetail__c.BusinessUnitTarget__c";
const BusinessUnitTarget__r = { fieldApiName: BusinessUnitTarget__c.fieldApiName.replace(/__c$/, '__r') };
import Product__c from "@salesforce/schema/CommercialPlanDetail__c.Product__c";
const Product__r = { fieldApiName: Product__c.fieldApiName.replace(/__c$/, '__r') };
import Hierarchy__c from "@salesforce/schema/CommercialPlanDetail__c.Hierarchy__c";
import CPHierarchyElement from "@salesforce/schema/CommercialPlan__c.Hierarchy__c";
const Hierarchy__r = { fieldApiName: Hierarchy__c.fieldApiName.replace(/__c$/, '__r') };
import SellInDiscountUAmtNego__c from "@salesforce/schema/CommercialPlanDetail__c.SellInDiscountUAmtNego__c";
import SellInDiscountPerNego__c from "@salesforce/schema/CommercialPlanDetail__c.SellInDiscountPerNego__c";
import SellOutBDate__c from "@salesforce/schema/CommercialPlanDetail__c.SellOutBDate__c";
import SellOutEDate__c from "@salesforce/schema/CommercialPlanDetail__c.SellOutEDate__c";
import Product2 from "@salesforce/schema/Product2";
import Category__c from "@salesforce/schema/Product2.Hierarchy__c";
import Brand__c from "@salesforce/schema/Product2.Brand__c";
import ProductCode from "@salesforce/schema/Product2.ProductCode";
import GTIN__c from "@salesforce/schema/Product2.GTIN__c";
import BusinessUnit__OBJECT from "@salesforce/schema/BusinessUnit__c";
import Hierarchy__OBJECT from "@salesforce/schema/Hierarchy__c";
//import Market__c from "@salesforce/schema/Product2.Market__c";
import Family from "@salesforce/schema/Product2.Family";
import Animation__c from "@salesforce/schema/Product2.Animation__c";
import RecordTypeId from "@salesforce/schema/Product2.RecordTypeId";
import BusinessUnitSource__c from "@salesforce/schema/CommercialPlan__c.BusinessUnitSource__c";
const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_PICKLIST_TYPES = ['BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_SEARCH_TYPES = ['ID', 'STRING', 'REFERENCE'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class commercialPlanSimulationLWC extends LightningElement {
    // LOADING VARIABLES
    @api recordId;
    @api displayAddChildrenLine;
    @api displayCloneForMultipleProducts;
    @api displayHelpText;
    @api enableMassUpdate;
    @api allowOpenRecord;
    @api allowDelete;
    @api cmpHeight;
    @api templateName;

    @track loading = true;
    @track tableLoading = false;
    @track displayProductsFilter = false;
    fields = [];
    fieldsToFilterMap = {};
    @track fieldsToFilter = [];
    @track multilevelFields = [];
    @track CommercialPlanDetailObject = CommercialPlanDetail__c;
    @track commercialPlanId;
    @track templateNameURL = '';
    @track mainWrapper = {};
    @track productFields = {};
    @track cpdFields = {};
    @track wCPDApexList = [];
    @track wCPDJSList = [];

    // Product Pagination
    @track productsPageNumber = 1;
    @track productsPageSize = '100';
    @track multiProductWrapper = [];
    @track multiCloneInfo = {};
    @track productFilterWrapper = {
        generalSearch: '',
        categories: [],
        brands: [],
        //market: '',
        family: '',
        animation: '',
        recordType: '',
        StringifiedSelectedRecordType: ''
    };
    @track isEmpty = false;
    @track showMultipleProductsPopUp = false;
    @track isDeleteRow = false;
    @track deleteData = {
        rowIndex: '',
        childIndex: ''
    };
    @track picklistRelationshipMap = {};
    @track displayedFields = [];
    @track currentCommercialPlan = {};
    @track productSearch = '';
    @track categorySearch = '';
    @track BUSearch = '';
    @track editTimeout;
    @track currentJSCommercialPlanDetail = {};
    @track showFileUploadPopup = false;
    @track currentAPEXCommercialPlanDetail = {};
    @track BUsForSelection = [];
    @track BUsLoaded = false;
    @track showBUSelection = false;
    @track categories = [];
    @track categoriesForSelection = [];
    @track categoriesLoaded = false;
    @track showCategorySelection = false;
    @track products = [];
    @track productsForSelection = [];
    @track filteredProducts = [];
    @track fieldOptions = [];
    @track selectedFields = [];
    @track productsLoaded = false;
    @track showProductSelection = false;
    @track showFieldManager = false;
    @track discountPercentScale;
    // PAGINATION
    @track selectedCategories = [];
    @track selectedBrands = [];
    @track pageNumber = 1;
    @track pageSize = '25';
    get getMassUpdateLines() {
        return LBL_Selected_Lines.replace('{0}', this.selectedFilteredRecordsIds.length);
    }
    @track productsPageSizeOptions = [{ label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' }];
    @track pageSizeOptions = [{ label: '10', value: '10' }, { label: '25', value: '25' }, { label: '30', value: '30' }];
    @track labels = {
        LBL_Number_Of_Fixed_Columns,
        LBL_New,
        MSG_Filter_On_Id_Help_Text,
        LBL_Minimum,
        LBL_Maximum,
        LBL_Start,
        LBL_Save,
        LBL_End,
        LBL_Advanced,
        LBL_False,
        LBL_True,
        LBL_Filter,
        LBL_Search,
        LBL_Show_Hide_Columns,
        LBL_Delete,
        LBL_Cancel,
        LBL_Previous,
        LBL_Next,
        LBL_Export,
        LBL_Confirm,
        MSG_Confirm_Delete,
        LBL_No_Item_To_Display,
        LBL_Product_List,
        LBL_Show_Only_HLP,
        LBL_Close,
        LBL_Reset,
        LBL_Upload_File,
        LBL_Apply,
        LBL_Mass_update,
        LBL_Multi_Selection,
        LBL_Single_Selection,
        LBL_Multi_Product_Selection: '',
        LBL_Single_Product_Selection: '',
        LBL_Single_BU_Selection: '',
        LBL_Single_Hierarchy_Selection: '',
        MSG_No_Items_Selected,
        BUFieldLabels: [],
        categoryFieldLabels: []
    }

    @track filters = {
        searchValue: '',
        dynamicSearch: ''
    }

    // GLOBAL VARIABLES
    openedCPDsSet = new Set();
    totalRecordsCount = 0;
    totalProductsRecordsCount = 0;
    picklistColorsMap = [];
    recordTypesOptions = '';
    childIndex = null;
    totalpagesCount = 0;
    totalProductsPagesCount = 0;
    nbOfFixedColumns = '1';
    activeElement = '';
    @track isShowCategory = true;
    @track selectedCategory = '';
    @track selectedBrand = '';
    @track wireIsDone = {
        objectInfos: false,
        setCurrentPageReference: false,
        wiredCategoryRecords: false,
        wiredBrandRecords: false,
        recordTypeValues: false
    }
    @track headerFieldsSelection = {};
    dependentPicklistMap = {};
    @track productsFieldsInfo = [];
    massUpdateFields = [];
    @track selectedRecordsIds = [];
    node;
    prevNodeBorder;
    objectInfosResult;
    @wire(getObjectInfos, {
        objectApiNames: [Product2.objectApiName,
        BusinessUnit__OBJECT.objectApiName,
        Hierarchy__OBJECT.objectApiName]
    })
    wiredObjectInfos(result) {
        try {
            this.objectInfosResult = result;
            const { data, error } = result;
            if (error) {
                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.Labels.LBL_Error,
                        message: message,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }),
                );
            }
            if (data) {
                this.wireIsDone.objectInfos = true;
            }
            this.processObjectInfosResult(this, this.objectInfosResult);
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }
    processObjectInfosResult(self, result) {
        try {
            const { data, error } = result;
            if (data && data.results) {
                // Product2 fields
                let productResult = data.results.find(item => item.result.apiName == Product2.objectApiName);
                if (productResult) {
                    this.productFieldsMetadata = productResult.result;
                    this.labels.LBL_Multi_Product_Selection = productResult.result.labelPlural + ' - ' + LBL_Multi_Selection;
                    this.labels.LBL_Single_Product_Selection = productResult.result.labelPlural + ' - ' + LBL_Single_Selection;
                }
                // BusinessUnit__c fields
                let BUResult = data.results.find(item => item.result.apiName == BusinessUnit__OBJECT.objectApiName);
                if (BUResult) {
                    this.labels.LBL_Single_BU_Selection = BUResult.result.labelPlural + ' - ' + LBL_Single_Selection;
                }
                // Hierarchy__c fields
                let HierarchyResult = data.results.find(item => item.result.apiName == Hierarchy__OBJECT.objectApiName);
                if (HierarchyResult) {
                    this.labels.LBL_Single_Hierarchy_Selection = HierarchyResult.result.labelPlural + ' - ' + LBL_Single_Selection;
                }
            }
            this.checkIfWireIsDone();
        } catch (error) {
            console.log('ERROR: ' + error);
            self.dispatchEvent(new ShowToastEvent({
                title: self.Labels.LBL_Error,
                message: error,
                variant: ERROR_VARIANT,
                mode: STICKY_VARIANT
            }));
        }
    }
    //WIRES
    /*@wire(getObjectInfo, { objectApiName: Product2.objectApiName }) objectInfos({ error, data }) {
    if (data) {
    this.productFieldsMetadata = data;
    this.labels.LBL_Multi_Product_Selection = data.labelPlural + ' - ' + LBL_Multi_Selection;
    this.labels.LBL_Single_Product_Selection = data.labelPlural + ' - ' + LBL_Single_Selection;
    this.wireIsDone.objectInfos = true;
    this.checkIfWireIsDone();
    } else if (error) {
    console.log('ERROR');
    }
    }*/

    //GET THE COMMERCIAL PLAN ID FROM URL
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.commercialPlanId = currentPageReference.state.c__recordId != null ? currentPageReference.state.c__recordId : this.recordId;
        this.templateNameURL = currentPageReference.state.c__templateName != null ? currentPageReference.state.c__templateName : '';
        if (this.commercialPlanId != null) {
            this.wireIsDone.setCurrentPageReference = true;
            this.checkIfWireIsDone();
        }
    }

    @wire(getRecord, { recordId: '$selectedCategory', fields: [CATEGORY_NAME], }) wiredCategoryRecords(result) {
        const { data, error } = result;
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showNotification(ERROR_VARIANT, message, ERROR_VARIANT);
        }
        if (data) {
            this.selectedCategory = '';
            let i = this.selectedCategories.findIndex(elem => elem.id == data.id);
            if (i == -1) {
                this.selectedCategories.push({ id: data.id, name: data.fields.Name.value });
            }
        }
        this.isShowCategory = true;
        this.wireIsDone.wiredCategoryRecords = true;
    }

    @wire(getRecord, { recordId: '$selectedBrand', fields: [BRAND_NAME], }) wiredBrandRecords(result) {
        const { data, error } = result;
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showNotification(ERROR_VARIANT, message, ERROR_VARIANT);
        }
        if (data) {
            this.selectedBrand = '';
            let i = this.selectedBrands.findIndex(elem => elem.id == data.id);
            if (i == -1) {
                this.selectedBrands.push({ id: data.id, name: data.fields.Name.value });
            }
        }
        this.isShowCategory = true;
        this.wireIsDone.wiredBrandRecords = true;
    }

    @wire(getObjectInfo, { objectApiName: Product2 })
    recordTypeValues({ error, data }) {
        if (data) {
            var recordtypeinfo = data.recordTypeInfos;
            var uiCombobox = [];
            for (var eachRecordtype in recordtypeinfo) {
                if (recordtypeinfo.hasOwnProperty(eachRecordtype))
                    uiCombobox.push({ label: recordtypeinfo[eachRecordtype].name, value: recordtypeinfo[eachRecordtype].recordTypeId })
            }
            this.recordTypesOptions = JSON.stringify(uiCombobox);
            // }
            this.wireIsDone.recordTypeValues = true;
            this.checkIfWireIsDone();
        } else {
            console.log(error);
        }
    }

    checkIfWireIsDone() {
        if (this.wireIsDone.objectInfos && this.wireIsDone.setCurrentPageReference && this.wireIsDone.recordTypeValues) {
            this.loadCommercialPlans();
        }
    }

    renderedCallback() {
        if (!this.cmpHeight) {
            this.changeHeight();
        }
    }

    connectedCallback() {
        if (!this.cmpHeight) {
            window.addEventListener('resize', this.changeHeight);
        }
    }

    loadCommercialPlans() {
        this.tableLoading = true;
        if (this.commercialPlanId == null) {
            this.errorMessage = "No record Id";
            this.tableLoading = false;
        } else {
            loadSimulation({
                commercialPlanId: this.commercialPlanId,
                pageSize: this.pageSize,
                pageNumber: this.pageNumber,
                templateName: this.templateNameURL
            }).then((result) => {
                this.mainWrapper = JSON.parse(result);
                let filterableFields = JSON.parse(this.mainWrapper.FiltersJSON);
                this.currentCommercialPlan = this.mainWrapper.CommercialPlanWrapper.commercialPlan;
                this.wCPDApexList = this.mainWrapper.CommercialPlanWrapper.commercialPlanDetails;
                this.totalRecordsCount = this.mainWrapper.CommercialPlanWrapper.numberOfRecords;
                this.allowDelete = this.allowDelete && this.mainWrapper.profileDeleteAccess;
                this.totalpagesCount = Math.ceil((this.totalRecordsCount / this.pageSize));
                this.displayedFields = this.mainWrapper.gridSettings.GRID_FIELDS;
                this.discountPercentScale = this.mainWrapper.discountPercentScale;
                if (Object.entries(this.fieldsToFilterMap).length === 0) {
                    this.populateFiltersMap(filterableFields);
                }
                this.fieldOptions = [];
                this.selectedFields = [];
                let ind = 0;
                let array = Object.keys(this.fieldsToFilterMap);
                let picklistFields = [];
                this.displayedFields.forEach(item => {
                    item.isMassUpdate = item.isMassUpdate && item.isInputField && this.enableMassUpdate == 'true';
                    item.isShowFilterOnColumnHeader = this.mainWrapper.gridSettings.isShowFilterOnColumnHeader && this.fieldsToFilterMap.hasOwnProperty(item.fieldName) && this.fieldsToFilterMap[item.fieldName].userFilterable;
                    if (item.isShowFilterOnColumnHeader) {
                        item.hasFilter = false;
                    }
                    item.thStyle = item.headerStyle?.style;
                    item.isRange = SUPPORTED_RANGE_TYPES.includes(item.stringFieldType);
                    item.isPicklist = SUPPORTED_PICKLIST_TYPES.includes(item.stringFieldType);
                    item.isSearchBar = SUPPORTED_SEARCH_TYPES.includes(item.stringFieldType);
                    item.divStyle = item.isPicklist ? "box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;width:260px;max-height: 300px;" : "box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;width:260px;overflow:visible;"
                    item.values = [];
                    item.isDate = item.stringFieldType == 'DATE';
                    item.isReference = item.stringFieldType == 'REFERENCE';
                    item.isString = !item.isReference && !item.isBoolean && !item.isNumberField && !item.isDate && !item.isPicklist;
                    item.massUpdateValue = '';
                    item.hasDependentPicklist = false;
                    item.isCategory = item.fieldName == Hierarchy__c.fieldApiName;
                    item.isProduct = item.fieldName == Product__c.fieldApiName;
                    item.isBU = item.fieldName == BusinessUnitTarget__c.fieldApiName;
                    item.fieldIndex = ind;
                    item.displayMassUpdate = false;
                    if (item.isRange) {
                        if (item.scale) {
                            let step = '.';
                            for (let i = 0; i < item.scale; i++) {
                                if (i == item.scale - 1) {
                                    step += '1';
                                    break;
                                }
                                step += '0';
                            }
                            item.stepHtml = step;
                        }
                        item.dataType = item.stringFieldType == 'DATETIME' || item.stringFieldType == 'DATE' ? 'date' : item.stringFieldType == 'TIME' ? 'time' : 'number';
                    }
                    if (item.stringFieldType == 'BOOLEAN') {
                        let options = [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }];
                        item.pickListValues = options;
                    }
                    if (item.controllerName != null) {
                        this.picklistRelationshipMap[item.controllerName] = item.fieldName;
                        this.getFieldDependencies(item.controllerName, item.fieldName);
                    }
                    this.fieldOptions.push({ label: item.fieldLabel, value: item.fieldName, isSelected: item.massUpdateValue == item.fieldName });
                    if (item.isPicklist) {
                        item.pickListValues = filterableFields.filter(elt => elt.fieldName == item.fieldName).length > 0 ? filterableFields.filter(elt => elt.fieldName == item.fieldName)[0].pickListValues : [];
                        if (item.pickListValues && item.pickListValues.length == 0 && this.mainWrapper.gridSettings.picklistValuesMap.hasOwnProperty(item.fieldName)) {
                            for (let value of Object.keys(this.mainWrapper.gridSettings.picklistValuesMap[item.fieldName])) {
                                item.pickListValues.unshift({ label: this.mainWrapper.gridSettings.picklistValuesMap[item.fieldName][value], value: value })
                            }
                        }
                        item.pickListValues.unshift({ label: LBL_None_Picklist_Value, value: '' });
                        picklistFields.push(item);
                    }
                    ind++;
                });
                this.displayedFields.forEach(item => {
                    if (item.isPicklist && (Object.keys(this.picklistRelationshipMap).includes(item.fieldName) || Object.values(this.picklistRelationshipMap).includes(item.fieldName))) {
                        item.hasDependentPicklist = true;
                        let fieldWrapper = {
                            fieldName: item.fieldName,
                            fieldLabel: item.fieldLabel,
                            pickListValues: item.pickListValues,
                            fieldIndex: item.fieldIndex,
                            massUpdateValue: item.massUpdateValue,
                            disabled: true
                        }
                        item.dependentPicklist = [fieldWrapper];
                        if (Object.keys(this.picklistRelationshipMap).includes(item.fieldName)) {
                            let nextField = this.picklistRelationshipMap[item.fieldName];
                            while (nextField) {
                                let fieldInfo = picklistFields.filter(field => field.fieldName == nextField)[0];
                                let fieldWrapper = {
                                    fieldName: nextField,
                                    fieldLabel: fieldInfo.fieldLabel,
                                    pickListValues: fieldInfo.pickListValues,
                                    fieldIndex: fieldInfo.fieldIndex,
                                    massUpdateValue: fieldInfo.massUpdateValue,
                                    disabled: true
                                }
                                item.dependentPicklist.push(fieldWrapper);
                                nextField = this.picklistRelationshipMap[nextField];
                            }
                        }
                        if (Object.values(this.picklistRelationshipMap).includes(item.fieldName)) {
                            let indexField = Object.values(this.picklistRelationshipMap).indexOf(item.fieldName);
                            let prevField = Object.keys(this.picklistRelationshipMap)[indexField];
                            while (prevField) {
                                let fieldInfo = picklistFields.filter(field => field.fieldName == prevField)[0];
                                let fieldWrapper = {
                                    fieldName: prevField,
                                    fieldLabel: fieldInfo.fieldLabel,
                                    pickListValues: fieldInfo.pickListValues,
                                    fieldIndex: fieldInfo.fieldIndex,
                                    massUpdateValue: fieldInfo.massUpdateValue,
                                    disabled: true
                                }
                                item.dependentPicklist.unshift(fieldWrapper);
                                indexField = Object.values(this.picklistRelationshipMap).indexOf(prevField);
                                prevField = indexField != -1 ? Object.keys(this.picklistRelationshipMap)[indexField] : null;
                            }
                        }
                        item.dependentPicklist[0].disabled = false;
                    }
                });
                if (localStorage.getItem('DisplayedFieldsComm') != null) {
                    let fields = JSON.parse(localStorage.getItem('DisplayedFieldsComm'));
                    this.displayedFields = this.displayedFields.filter(field => fields.includes(field.fieldName));
                }
                for (let field of this.displayedFields) {
                    field.style += 'z-index: 5; min-width: 150px; white-space: unset;overflow: visible;';
                    if (field.fieldName == Status__c.fieldApiName) {
                        this.picklistColorsMap = field.picklistColorsMap;
                    }
                    this.selectedFields.push(field.fieldName);
                }
                this.labels.BUFieldLabels = this.mainWrapper.labels.BUFieldLabels;
                this.labels.categoryFieldLabels = this.mainWrapper.labels.categoryFieldLabels;
                this.productFields['category'] = { name: Category__c.fieldApiName, label: this.productFieldsMetadata.fields[Category__c.fieldApiName].label };
                this.productFields['brand'] = { name: Brand__c.fieldApiName, label: this.productFieldsMetadata.fields[Brand__c.fieldApiName].label };
                //this.productFields['market'] = { name: Market__c.fieldApiName, label: this.productFieldsMetadata.fields[Market__c.fieldApiName].label };
                this.productFields['animation'] = { name: Animation__c.fieldApiName, label: this.productFieldsMetadata.fields[Animation__c.fieldApiName].label };
                this.productFields['family'] = { name: Family.fieldApiName, label: this.productFieldsMetadata.fields[Family.fieldApiName].label };
                this.productFields['recordType'] = { name: RecordTypeId.fieldApiName, label: this.productFieldsMetadata.fields[RecordTypeId.fieldApiName].label };

                this.cpdFields['global'] = { label: this.productFieldsMetadata.fields[Category__c.fieldApiName].label + ', ' + this.productFieldsMetadata.fields[Brand__c.fieldApiName].label + ', ' + this.productFieldsMetadata.fields[ProductCode.fieldApiName].label + ', ' + this.productFieldsMetadata.fields[GTIN__c.fieldApiName].label };
                setTimeout(() => {
                    let CPDList = [];
                    let index = 0;
                    for (let CommercialPlanDetailWrapper of this.wCPDApexList) {
                        CPDList.push(this.buildCPDInfo(CommercialPlanDetailWrapper.commercialPlanDetail, CommercialPlanDetailWrapper.commercialPlanDetailChildren, index++));
                    }
                    this.wCPDJSList = CPDList;
                    this.isEmpty = this.wCPDJSList.length == 0;
                    this.loading = false;
                    this.tableLoading = false;
                    if (this.activeElement != '') {
                        this.activeElement.focus();
                    }
                }, 1000);
            }).catch(error => {
                this.tableLoading = false;
                this.showNotification('Error', error, 'error', 'dismissible ');
                console.error(error);
            });
        }
    }

    buildCPDInfo(commercialPlanDetail, commercialPlanDetailChildren, headIndex) {
        try {
            let self = this;
            let wCommercialPlanDetail = {
                id: commercialPlanDetail.Id,
                commercialPlanDetail: commercialPlanDetail,
                index: headIndex,
                values: [],
                children: [],
                isSelected: false,
                firstTdStyle: 'text-align: center;position: sticky; z-index: 3; left: 0;background: white;',
                get iconName() {
                    return this.hasChildrenAndOpened ? 'utility:chevrondown' : 'utility:chevronright';
                },
                get isNew() {
                    return this.id == null;
                },
                get rowStyle() {
                    let color = '';
                    color = self.picklistColorsMap ? self.picklistColorsMap[this.commercialPlanDetail[Status__c.fieldApiName]] != undefined ? 'background: ' + self.picklistColorsMap[this.commercialPlanDetail[Status__c.fieldApiName]] + ';' : 'background: white;' : 'background: white;';
                    return 'text-align: center;' + color;
                },
                get hasChildren() {
                    return this.children && this.children.length ? true : false;
                },
                get hasChildrenAndOpened() {
                    return self.openedCPDsSet.has(Number(this.index)) && this.hasChildren;
                }
            }
            //BUILD THE JSWRAPPER OF CPD CHILDREN IF THEY EXIST AND PLACE THEM IN 'CHILDREN' FIELD
            if (commercialPlanDetailChildren != null) {
                for (let child of commercialPlanDetailChildren) {
                    let index = 0;
                    wCommercialPlanDetail.children.push(this.buildCPDChildInfo(child, index, wCommercialPlanDetail.index));
                    index++;
                }
            }
            let i = 0;
            for (let field of this.displayedFields) {
                let fieldObject = {
                    fieldIndex: i,
                    fieldApiName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isNumberField: field.isNumberField,
                    scale: field.scale,
                    fieldValue: this.isNumberField && this.scale != null ? parseFloat(commercialPlanDetail[field.fieldName].toFixed(this.scale)) : commercialPlanDetail[field.fieldName],
                    fieldOutputValue: commercialPlanDetail[field.fieldName],
                    fieldType: field.fieldType,
                    controllerName: null,
                    controllerValue: null,
                    isText: false,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isPicklist: false,
                    isMultiPicklist: false,
                    isBoolean: false,
                    isReference: false,
                    isDate: false,
                    isURL: false,
                    isPercent: false,
                    isCategory: field.isCategory,
                    isProduct: field.isProduct,
                    isBU: field.isBU,
                    link: '',
                    get tdStyle() {
                        let color = '';
                        color = self.picklistColorsMap ? self.picklistColorsMap[wCommercialPlanDetail.commercialPlanDetail[Status__c.fieldApiName]] != undefined ? 'background: ' + self.picklistColorsMap[wCommercialPlanDetail.commercialPlanDetail[Status__c.fieldApiName]] + ';' : 'background: white;' : 'background: white;';
                        return (field.nonConditional?.textStyle?.style != null ? field.nonConditional.textStyle.style : '') + 'text-align: center;' + color + (field.separatorSettings != null ? field.separatorSettings.style : '') + field.widthStyle;
                    },
                    get isEmptyAndURL() {
                        if (wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == null || wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == '') {
                            return true;
                        } else {
                            return false;
                        }
                    },
                    get isHidden() {
                        return false;
                    },
                    get isInput() {
                        return field.isInputField;
                    },
                    picklistOptions: [],
                    stringifiedPicklistOptions: '',
                    stringifiedFieldOutputValue: '',
                    get step() {
                        if (this.scale) {
                            let step = '.';
                            for (let i = 0; i < this.scale; i++) {
                                if (i == this.scale - 1) {
                                    step += '1';
                                    break;
                                }
                                step += '0';
                            }
                            return step;
                        }
                    }
                }
                switch (field.fieldType) {
                    case "REFERENCE":
                        fieldObject.isReference = true;
                        fieldObject.link = "/" + fieldObject.fieldValue;
                        break;
                    case "DATE":
                        fieldObject.isDate = true;
                        break;
                    case "PICKLIST":
                        if (fieldObject.fieldValue == null) {
                            fieldObject.fieldValue = '';
                        }
                        fieldObject.fieldOutputValue = this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] != null ? this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] : fieldObject.fieldValue;
                        fieldObject.controllerName = field.controllerName;
                        fieldObject.controllerValue = wCommercialPlanDetail.commercialPlanDetail[field.controllerName];
                        if (field.controllerName != null && fieldObject.controllerValue != null && this.dependentPicklistMap[field.fieldName][fieldObject.controllerValue]) {
                            for (let option of this.dependentPicklistMap[field.fieldName][fieldObject.controllerValue]) {
                                fieldObject.picklistOptions.push({ label: option.label, value: option.value, isSelected: wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == option.value })
                            }
                        } else {
                            for (let value of Object.keys(this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName])) {
                                fieldObject.picklistOptions.unshift({ label: this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][value], value: value, isSelected: wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == value })
                            }
                        }
                        fieldObject.picklistOptions.unshift({ label: LBL_None_Picklist_Value, value: '', isSelected: wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == '' })
                        fieldObject.isPicklist = true;
                        break;
                    case "RECORDTYPE":
                        if (fieldObject.fieldValue == null) {
                            fieldObject.fieldValue = '';
                        }
                        fieldObject.fieldOutputValue = this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] != null ? this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] : fieldObject.fieldValue;
                        for (let value of Object.keys(this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName])) {
                            fieldObject.picklistOptions.unshift({ label: this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][value], value: value, isSelected: wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == value })
                        }
                        fieldObject.isPicklist = true;
                        break;
                    case "MULTIPICKLIST":
                        for (let value of Object.keys(this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName])) {
                            fieldObject.picklistOptions.unshift({ label: this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][value], value: value });
                        }
                        if (fieldObject.fieldValue == null) {
                            fieldObject.fieldValue = '';
                        }
                        fieldObject.fieldOutputValue = this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] != null ? this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] : fieldObject.fieldValue;
                        fieldObject.stringifiedFieldOutputValue = JSON.stringify(fieldObject.fieldOutputValue);
                        fieldObject.stringifiedPicklistOptions = JSON.stringify(fieldObject.picklistOptions);
                        fieldObject.picklistOptions.unshift({ label: LBL_None_Picklist_Value, value: '' });
                        fieldObject.isPicklist = false;
                        fieldObject.isMultiPicklist = true;
                        break;
                    case "BOOLEAN":
                        fieldObject.isBoolean = true;
                        break;
                    case "URL":
                        fieldObject.isURL = field.hasFileInput;
                        fieldObject.isText = !field.hasFileInput;;
                        break;
                    case "PERCENT":
                        fieldObject.isPercent = true;
                        if (fieldObject.fieldValue == 0 || !fieldObject.fieldValue) {
                            fieldObject.fieldValue = '';
                        }
                        break;
                    default:
                        fieldObject.isText = !fieldObject.isNumberField;
                }
                if (field.isReference && (!field.isInputField || field.isCategory || field.isProduct || field.isBU)) {
                    fieldObject.fieldOutputValue = commercialPlanDetail[field.fieldName.replace("__c", "__r")]?.Name;
                }
                if (field.fieldName.includes(".")) {
                    let temp1 = field.fieldName.split(".")[0];
                    let temp2 = field.fieldName.split(".")[1];
                    let temp3 = commercialPlanDetail[temp1];
                    if (temp3 != null) {
                        fieldObject.fieldValue = temp3[temp2];
                        fieldObject.fieldOutputValue = temp3[temp2];
                    }
                }
                if (field.fieldName == SellInDiscountPerNego__c.fieldApiName) {
                    fieldObject.scale = this.discountPercentScale;
                }
                wCommercialPlanDetail.values.push(fieldObject);
                i++;
            }
            return wCommercialPlanDetail;
        } catch (error) {
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
        }
    }

    buildCPDChildInfo(commercialPlanDetail, index, parentIndex) {
        let self = this;
        try {
            let wCommercialPlanDetail = {
                id: commercialPlanDetail.Id,
                commercialPlanDetail: commercialPlanDetail,
                values: [],
                get isNew() {
                    return this.id == null;
                },
                get rowStyle() {
                    let color = '';
                    color = self.picklistColorsMap ? self.picklistColorsMap[commercialPlanDetail[Status__c.fieldApiName]] != undefined ? 'background: ' + self.picklistColorsMap[commercialPlanDetail[Status__c.fieldApiName]] + ';' : 'background: white;' : 'background: white;';
                    return 'text-align: center;' + color;
                },
                firstTdStyle: 'text-align: center;position: sticky; z-index: 3; left: 0;background: white;',
                parentIndex: parentIndex,
                index: index
            }
            let i = 0;
            for (let field of this.displayedFields) {
                let fieldObject = {
                    fieldIndex: i,
                    fieldApiName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: commercialPlanDetail[field.fieldName],
                    fieldOutputValue: commercialPlanDetail[field.fieldName],
                    fieldType: field.fieldType,
                    get tdStyle() {
                        let color = '';
                        color = self.picklistColorsMap ? self.picklistColorsMap[commercialPlanDetail[Status__c.fieldApiName]] != undefined ? 'background: ' + self.picklistColorsMap[commercialPlanDetail[Status__c.fieldApiName]] + ';' : 'background: white;' : 'background: white;';
                        return (field.style != null ? field.style : '') + 'text-align: center;' + color + (field.separatorSettings != null ? field.separatorSettings.style : '') + field.widthStyle;
                    },
                    isNumberField: field.isNumberField,
                    scale: field.scale,
                    link: '',
                    isHTMLFormatted: field.isHTMLFormatted ? true : false,
                    isHidden: false,
                    stringifiedPicklistOptions: '',
                    stringifiedFieldOutputValue: '',
                    get isInput() {
                        return field.isInputField;
                    },
                    isText: true,
                    isReference: false,
                    isProduct: false,
                    isURL: false,
                    isPercent: false,
                    get isEmptyAndURL() {
                        if (wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == null || wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == '') {
                            return true;
                        } else {
                            return false;
                        }
                    },
                    isBoolean: false,
                    isCategory: false,
                    isBU: false,
                    isDate: false,
                    picklistOptions: [],
                    isPicklist: false,
                    isMultiPicklist: false,
                    get step() {
                        if (this.scale) {
                            let step = '.';
                            for (let i = 0; i < this.scale; i++) {
                                if (i == this.scale - 1) {
                                    step += '1';
                                    break;
                                }
                                step += '0';
                            }
                            return step;
                        }
                    }
                }
                switch (field.fieldType) {
                    case "REFERENCE":
                        fieldObject.isReference = true;
                        fieldObject.isText = false;
                        fieldObject.link = "/" + fieldObject.fieldValue;
                        break;
                    case "DATE":
                        fieldObject.isText = false;
                        fieldObject.isDate = true;
                        break;
                    case "PICKLIST":
                        //GET THE PICKLIST OPTIONS OF A FIELD FROM GRIDSETTINGS
                        for (let value of Object.keys(this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName])) {
                            fieldObject.picklistOptions.unshift({ label: this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][value], value: value, isSelected: wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == value });
                        }
                        //MAKE NULL VALUES
                        if (fieldObject.fieldValue == null) {
                            fieldObject.fieldValue = '';
                        }
                        fieldObject.picklistOptions.unshift({ label: LBL_None_Picklist_Value, value: '', isSelected: wCommercialPlanDetail.commercialPlanDetail[field.fieldName] == '' });
                        fieldObject.fieldOutputValue = this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] != null ? this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] : fieldObject.fieldValue;
                        fieldObject.isPicklist = true;
                        fieldObject.isMultiPicklist = false;
                        fieldObject.isText = false;
                        break;
                    case "MULTIPICKLIST":
                        //GET THE PICKLIST OPTIONS OF A FIELD FROM GRIDSETTINGS
                        for (let value of Object.keys(this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName])) {
                            fieldObject.picklistOptions.unshift({ label: this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][value], value: value });
                        }
                        //MAKE NULL VALUES
                        if (fieldObject.fieldValue == null) {
                            fieldObject.fieldValue = '';
                        }
                        fieldObject.picklistOptions.unshift({ label: LBL_None_Picklist_Value, value: '' });
                        fieldObject.fieldOutputValue = this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] != null ? this.mainWrapper.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] : fieldObject.fieldValue;
                        fieldObject.stringifiedFieldOutputValue = JSON.stringify(fieldObject.fieldOutputValue);
                        fieldObject.stringifiedPicklistOptions = JSON.stringify(fieldObject.picklistOptions);
                        fieldObject.isPicklist = false;
                        fieldObject.isMultiPicklist = true;
                        fieldObject.isText = false;
                        break;
                    case "BOOLEAN":
                        fieldObject.isBoolean = true;
                        fieldObject.isText = false;
                        break;
                    case "URL":
                        fieldObject.isURL = true;
                        fieldObject.isText = false;
                        break;
                    case "PERCENT":
                        fieldObject.isPercent = true;
                        if (fieldObject.fieldValue == 0 || !fieldObject.fieldValue) {
                            fieldObject.fieldValue = '';
                        }
                        break;
                    default:
                        fieldObject.isText = !fieldObject.isNumberField;
                }
                if (field.fieldName == Hierarchy__c.fieldApiName) {
                    fieldObject.isCategory = true;
                }
                fieldObject.isCategory = field.isCategory;
                fieldObject.isProduct = field.isProduct;
                fieldObject.isBU = field.isBU;
                if (field.isReference && (!field.isInputField || field.isCategory || field.isProduct || field.isBU)) {
                    fieldObject.fieldOutputValue = commercialPlanDetail[field.fieldName.replace("__c", "__r")]?.Name;
                }
                if (field.fieldName.includes(".")) {
                    let temp1 = field.fieldName.split(".")[0];
                    let temp2 = field.fieldName.split(".")[1];
                    let temp3 = commercialPlanDetail[temp1];
                    if (temp3 != null) {
                        fieldObject.fieldValue = temp3[temp2];
                        fieldObject.fieldOutputValue = temp3[temp2];
                    }
                }
                if (field.fieldName == SellInDiscountPerNego__c.fieldApiName) {
                    fieldObject.scale = this.discountPercentScale;
                }
                wCommercialPlanDetail.values.push(fieldObject);
            }
            return wCommercialPlanDetail;
        } catch (error) {
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
        }
    }

    getFieldDependencies(controllerField, fieldName) {
        getFieldDependencies({
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

    toggleDropDownFilter(event) {
        let fieldName = event.target.dataset.field;
        let actionType = event.target.dataset.actiontype;
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        if (actionType == 'search') {
            this.template.querySelectorAll('.headerFilterSection').forEach(element => {
                if (!element.classList.contains("slds-hide")) {
                    // If not, add the 'slds-hide' class
                    element.classList.add("slds-hide");
                }
            });
            let hasFilter = Boolean(this.fieldsToFilterMap[fieldName]
                && ((this.fieldsToFilterMap[fieldName].values && (this.fieldsToFilterMap[fieldName].values.length > 1 || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                    || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 != '')
                    || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 != '')));
            this.displayedFields.forEach(element => {
                if (element.fieldName == fieldName) {
                    element.hasFilter = hasFilter;
                    this.headerFieldsSelection[fieldName] = hasFilter;
                }
            });
            this.search();
        }
    }

    createNewCPD() {
        try {
            this.tableLoading = true;
            createNewDetail({
                commPlanJSON: JSON.stringify(this.currentCommercialPlan)
            }).then((result) => {
                let newCPD = JSON.parse(result);
                this.wCPDApexList.push(newCPD);
                let newJSCPD = this.buildCPDInfo(newCPD.commercialPlanDetail, newCPD.commercialPlanDetailChildren, this.wCPDApexList.length - 1);
                this.wCPDJSList.push(newJSCPD);
                this.isEmpty = false;
                this.tableLoading = false;
            }).catch((error) => {
                console.error(error);
            });
        } catch (error) {
            console.error(error);
        }
    }

    populateFiltersMap(fields) {
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
                if (field.stringFieldType === 'STRING') {
                    fieldToFilter.isText = true;
                }
                if (field.stringFieldType === 'REFERENCE') {
                    fieldToFilter.isReference = true;
                }
                if (field.stringFieldType === 'BOOLEAN') {
                    fieldToFilter.isCheckboxGroup = true;
                    let options = [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }];
                    fieldToFilter.options = options;
                }
                if (field.pickListValues
                    && (field.stringFieldType === 'PICKLIST' || field.stringFieldType === 'MULTIPICKLIST'
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
            this.changePageHandler();
        } catch (error) {
            console.log(error);
        }
    }

    cloneCPD(event) {
        try {
            let id = event.target.dataset.id;
            let childIndex = event.target.dataset.childindex;
            let rowIndex = event.target.dataset.rowindex;
            this.cloningHandler(id, childIndex, rowIndex);
        } catch (error) {
            console.error('error: ' + error);
        }
    }

    cloningHandler(id, childIndex, rowIndex) {
        try {
            let clonedChildrenList = null;
            //CASE OF CHILD
            if (childIndex) {
                //GET THE CPD OF THE CHILD
                let currentCommercialPlanDetail = this.wCPDApexList[rowIndex].commercialPlanDetailChildren[childIndex];
                let newCPD = JSON.parse(JSON.stringify(currentCommercialPlanDetail));
                newCPD.Id = null;
                newCPD.attributes = null;
                newCPD.InvoiceDocumentURL__c = '';
                newCPD.PowerofAttornayURL__c = '';
                newCPD.Agreement__r = null;
                newCPD.Agreement__c = '';
                newCPD.ContractPromoURL__c = '';
                newCPD.SellInDiscountMassValueNego__c = null;
                newCPD.ExtractStatus__c = null;
                newCPD.Status__c = 'Attempt';
                newCPD.AgreementLine1__c = null;
                newCPD.VolumeFact_c = null;
                newCPD.SalesExecutionRateFact__c = null;
                newCPD.VolumeValidate__c = null;
                this.wCPDApexList[rowIndex].commercialPlanDetailChildren.push(newCPD);
                this.wCPDApexList[rowIndex].hasChanged = true;
                this.wCPDJSList[rowIndex].children.push(this.buildCPDChildInfo(newCPD, this.wCPDApexList[rowIndex].commercialPlanDetailChildren.length, rowIndex));
            } else {
                if (this.wCPDApexList[rowIndex].commercialPlanDetailChildren != null && this.wCPDApexList[rowIndex].commercialPlanDetailChildren.length > 0) {
                    this.wCPDApexList[rowIndex].commercialPlanDetail.VolumeTarget__c = null;
                }
                let currentCommercialPlanDetail = this.wCPDApexList[rowIndex].commercialPlanDetail;
                let newCPD = JSON.parse(JSON.stringify(currentCommercialPlanDetail));
                newCPD.Id = null;
                newCPD.attributes = null;
                if (!this.showMultipleProductsPopUp) {
                    newCPD.InvoiceDocumentURL__c = '';
                    newCPD.PowerofAttornayURL__c = '';
                    newCPD.ContractPromoURL__c = '';
                    newCPD.Agreement__r = null;
                    newCPD.Agreement__c = '';
                    newCPD.SellInDiscountMassValueNego__c = null;
                    newCPD.ExtractStatus__c = null;
                    newCPD.Status__c = 'Attempt';
                    newCPD.AgreementLine1__c = null;
                    newCPD.VolumeFact_c = null;
                    newCPD.SalesExecutionRateFact__c = null;
                    newCPD.VolumeValidate__c = null;
                }
                if (this.wCPDApexList[rowIndex].commercialPlanDetailChildren != null && this.wCPDApexList[rowIndex].commercialPlanDetailChildren.length > 0) {
                    clonedChildrenList = JSON.parse(JSON.stringify(this.wCPDApexList[rowIndex].commercialPlanDetailChildren));
                    for (let child of clonedChildrenList) {
                        child.Id = null;
                        child.attributes = null;
                        if (!this.showMultipleProductsPopUp) {
                            child.InvoiceDocumentURL__c = '';
                            child.PowerofAttornayURL__c = '';
                            child.Agreement__r = null;
                            child.Agreement__c = '';
                            child.ContractPromoURL__c = '';
                            child.SellInDiscountMassValueNego__c = null;
                            child.ExtractStatus__c = null;
                            child.Status__c = 'Attempt';
                            child.AgreementLine1__c = null;
                            child.VolumeFact_c = null;
                            child.SalesExecutionRateFact__c = null;
                            child.VolumeValidate__c = null;
                        }
                    }
                }
                this.wCPDApexList.splice((parseInt(rowIndex) + 1), 0, { JSIndex: null, hasChanged: true, CPDLink: '', commercialPlanDetail: newCPD, commercialPlanDetailChildren: clonedChildrenList });
                this.wCPDJSList.splice((parseInt(rowIndex) + 1), 0, this.buildCPDInfo(newCPD, clonedChildrenList, (parseInt(rowIndex) + 1)));
                for (let index = parseInt(rowIndex) + 2; index < this.wCPDJSList.length; index++) {
                    this.wCPDJSList[index].index++;
                }
            }
        } catch (error) {
            console.error('error: ' + error);
        }
    }

    handleProductsCheckboxChange(event) {
        let id = event.target.dataset.id;
        let index = event.target.dataset.index;
        let selected = event.target.checked;
        let targetIndex = this.filteredProducts.findIndex(wrapper => wrapper.Id == id);
        this.filteredProducts[targetIndex].isChecked = selected;
        if (selected) {
            this.multiProductWrapper.push({ id: id, index: index });
        } else {
            let indexToRemoveIndex = this.multiProductWrapper.findIndex(wrapper => wrapper.id == id);
            this.multiProductWrapper.splice(parseInt(indexToRemoveIndex), 1);
        }
    }

    createCloneForMultipleProducts(event) {
        try {
            let id = event.target.dataset?.id;
            let childIndex = event.target.dataset?.childindex;
            let rowIndex = event.target.dataset?.rowindex;
            this.multiCloneInfo.id = id;
            this.multiCloneInfo.childIndex = childIndex;
            this.multiCloneInfo.rowIndexid = rowIndex;
            this.tableLoading = true;
            getProductsRecords({
                commPlanCategoryId: this.currentCommercialPlan[CPHierarchyElement.fieldApiName],
                productFilter: JSON.stringify(this.productFilterWrapper),
                pageSize: this.productsPageSize,
                pageNumber: 1
            }).then((result) => {
                let prodresult = JSON.parse(result);
                this.handleProductData(prodresult, true);
                this.showMultipleProductsPopUp = true;
                this.showProductSelection = true;
                this.productsLoaded = true;
                this.tableLoading = false;
            }).catch((apexError) => {
                console.error(apexError);
            });
        } catch (error) {
            console.log(error);
        }
    }

    handleProductData(prodresult, checkboxLoop) {
        this.totalProductsRecordsCount = prodresult.numberOfRecords;
        this.totalProductsPagesCount = Math.ceil((this.totalProductsRecordsCount / this.productsPageSize));
        let ProductsWrapper = [];
        if (prodresult.products.length != 0) {
            this.productsFieldsInfo = prodresult.productsFieldsInfo;
            prodresult.products.forEach(item => {
                this.productsForSelection.push(JSON.parse(JSON.stringify(item)));
                let values = [];
                prodresult.productsFieldsInfo.forEach(field => {
                    let fieldObject = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldValue: item[field.fieldName],
                    };
                    if (field.fieldName.toLowerCase() == 'name') {
                        fieldObject.isReference = true;
                        fieldObject.isName = true;
                        fieldObject.link = "/" + item.Id;
                        fieldObject.fieldValue = item.Name;
                    } else {
                        switch (field.fieldType) {
                            case "REFERENCE":
                                fieldObject.isReference = true;
                                fieldObject.link = "/" + fieldObject.fieldValue;
                                fieldObject.fieldValue = item[field.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                                break;
                            case "DATE":
                                fieldObject.isDate = true;
                                break;
                            case "BOOLEAN":
                                fieldObject.isBoolean = true;
                                break;
                            case "CURRENCY":
                                fieldObject.isNumberField = true;
                                break;
                            case "NUMBER":
                                fieldObject.isNumberField = true;
                                break;
                            case "PERCENT":
                                fieldObject.isNumberField = true;
                                break;
                            default:
                                fieldObject.isText = true;
                        }
                    }
                    values.push(fieldObject);
                });
                ProductsWrapper.push({ Id: item.Id, values: values, isChecked: checkboxLoop && this.multiProductWrapper.some(wrapper => wrapper.id == item.Id) });
            });
        }
        this.filteredProducts = ProductsWrapper;
    }

    toggleMassUpdatePanel(event) {
        try {
            let field = event.target.dataset.field;
            this.displayedFields.forEach(item => {
                item.massUpdateValue = '';
                if (item.fieldName == field) {
                    item.displayMassUpdate = !item.displayMassUpdate;
                } else {
                    item.displayMassUpdate = false;
                }
            })
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    massUpdateHandler(event) {
        try {
            let value = event.target.value;
            let index = event.target.dataset.index;
            let parentindex = event.target.dataset.parentindex;
            let depindex = event.target.dataset.depindex;
            let fieldName = event.target.dataset.fieldName;
            this.displayedFields[index].massUpdateValue = value;
            if (this.displayedFields[index].isPicklist) {
                this.displayedFields[index].pickListValues.forEach((item) => {
                    item.isSelected = item.value == value;
                });
            }
            this.massUpdateFields.push(fieldName);
            let dependentValExist = this.picklistRelationshipMap.hasOwnProperty(fieldName);
            if (dependentValExist) {
                let picklistField = this.displayedFields[parentindex];
                depindex = parseInt(depindex);
                for (let i = depindex + 1; i < picklistField.dependentPicklist.length; i++) {
                    this.massUpdateFields.push(picklistField.dependentPicklist[i].fieldName);
                    if (i == depindex + 1 && value) {
                        picklistField.dependentPicklist[i].disabled = false;
                        picklistField.dependentPicklist[i].pickListValues = [];
                        if (this.dependentPicklistMap[picklistField.dependentPicklist[i].fieldName] && this.dependentPicklistMap[picklistField.dependentPicklist[i].fieldName][value]) {
                            for (let option of this.dependentPicklistMap[picklistField.dependentPicklist[i].fieldName][value]) {
                                picklistField.dependentPicklist[i].pickListValues.push({ label: option.label, value: option.value, isSelected: false })
                            }
                            picklistField.dependentPicklist[i].pickListValues.unshift({ label: LBL_None_Picklist_Value, value: '', isSelected: true })
                        }
                    } else {
                        picklistField.dependentPicklist[i].disabled = true;
                        picklistField.dependentPicklist[i].massUpdateValue = '';
                        picklistField.dependentPicklist[i].pickListValues = [];
                    }
                }
            }

        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    handleApplyMassUpdate(event) {
        try {
            let fieldstoUpdate = this.displayedFields.filter(item => this.massUpdateFields.includes(item.fieldName));
            if (this.selectedFilteredRecordsIds.length == 0) {
                this.showNotification('Warning', this.labels.MSG_No_Items_Selected, 'warning', 'dismissible ');
            }
            let records = this.wCPDJSList.filter(item => item.isSelected);
            records.forEach(item => {
                fieldstoUpdate.forEach(field => {
                    this.wCPDApexList[item.index].hasChanged = true;
                    this.wCPDApexList[item.index].commercialPlanDetail[field.fieldName] = field.massUpdateValue;
                    item.values.forEach(element => {
                        if (element.fieldApiName == field.fieldName) {
                            element.fieldValue = field.massUpdateValue;
                            element.fieldOutputValue = field.isReference && (field.isProduct || field.isCategory || field.isBU) ? field.massUpdateLabel : field.massUpdateValue;
                            if (element.controllerName != null) {
                                element.controllerValue = this.displayedFields.filter(item => item.fieldName == element.controllerName)[0].massUpdateValue;
                                element.picklistOptions = [];
                                if (this.dependentPicklistMap[field.fieldName] && this.dependentPicklistMap[field.fieldName][element.controllerValue]) {
                                    for (let option of this.dependentPicklistMap[field.fieldName][element.controllerValue]) {
                                        element.picklistOptions.push({ label: option.label, value: option.value, isSelected: false })
                                    }
                                }
                                element.picklistOptions.unshift({ label: LBL_None_Picklist_Value, value: '', isSelected: true })
                            }
                            element.picklistOptions.forEach((option) => {
                                option.isSelected = option.value == field.massUpdateValue;
                            });
                        }
                    })
                })
            });
            fieldstoUpdate.forEach(field => {
                if (this.massUpdateFields.includes(field.fieldName)) {
                    field.massUpdateValue = '';
                    field.massUpdateLabel = '';
                    if (field.isPicklist) {
                        field.pickListValues.forEach((item) => {
                            item.isSelected = item.value == '';
                        });
                    }
                    if (field.hasDependentPicklist) {
                        field.dependentPicklist.forEach(dependentField => {
                            dependentField.massUpdateValue = '';
                            if (field.dependentPicklist.indexOf(dependentField) != 0) {
                                dependentField.disabled = true;
                                dependentField.pickListValues = [{ label: LBL_None_Picklist_Value, value: '', isSelected: false }];
                            } else {
                                dependentField.pickListValues.forEach((option) => {
                                    option.isSelected = option.value == '';
                                });
                            }
                        });
                        field.dependentPicklist[0].disabled = false;
                    }
                }
                field.displayMassUpdate = false;
            });
            this.massUpdateFields = []
        } catch (error) {
            console.log(error.message);
            console.log(error.body?.message);
        }
    }

    toggleRecordSelect(event) {
        let id = event.target.dataset.id;
        let cpdIndex = event.target.dataset.cpdIndex;
        let isChecked = event.detail.checked;
        if (isChecked) {
            if (!this.selectedRecordsIds.includes(id)) {
                this.selectedRecordsIds.push(id);
            }
        } else {
            this.selectedRecordsIds = this.selectedRecordsIds.filter(item => item != id);
        }
        this.selectedFilteredRecordsIds = this.selectedRecordsIds;
        this.wCPDJSList[cpdIndex].isSelected = isChecked;
    }

    confirmMultipleProductsCloneCreation() {
        let index = 0;
        this.multiProductWrapper.forEach(row => {
            if (index != 0) {
                this.cloningHandler(this.multiCloneInfo.id, null, this.multiCloneInfo.rowIndexid);
                this.currentJSCommercialPlanDetail = this.wCPDJSList[parseInt(this.multiCloneInfo.rowIndexid) + 1];
                this.currentAPEXCommercialPlanDetail = this.wCPDApexList[parseInt(this.multiCloneInfo.rowIndexid) + 1];
            } else {
                this.currentJSCommercialPlanDetail = this.wCPDJSList[parseInt(this.multiCloneInfo.rowIndexid)];
                this.currentAPEXCommercialPlanDetail = this.wCPDApexList[parseInt(this.multiCloneInfo.rowIndexid)];
                index++;
            }
            this.handleProductSelectionChange(row.id);
        });
        this.closeproductSelection();
    }

    selectAllProducts(event) {
        const toggleList = this.template.querySelectorAll('[data-type^="productCheckbox"]');
        let selected = event.target.checked;
        if (selected) {
            let index = 0;
            this.multiProductWrapper = [];
            this.filteredProducts.productsList.forEach(product => {
                this.multiProductWrapper.push({ id: product.Id, index: index });
                product.isChecked = selected;
                index++;
            });
            for (const toggleElement of toggleList) {
                toggleElement.checked = selected;
            }
        } else {
            this.multiProductWrapper = [];
            this.filteredProducts.productsList.forEach(product => {
                product.isChecked = selected;
            });
            for (const toggleElement of toggleList) {
                toggleElement.checked = selected;
            }
        }
    }

    createNewCPDChild(event, product, currentCommercialPlanDetail) {
        try {
            this.tableLoading = true;
            let index = event.target.dataset.index;
            let newCPDChild;
            if (currentCommercialPlanDetail != null) {
                newCPDChild = JSON.parse(currentCommercialPlanDetail);
            } else {
                newCPDChild = JSON.parse(JSON.stringify(this.wCPDApexList[index].commercialPlanDetail));
            }
            newCPDChild.InvoiceDocumentURL__c = null;
            newCPDChild.Id = null;
            newCPDChild.PowerofAttornayURL__c = null;
            newCPDChild.ContractPromoURL__c = null;
            newCPDChild.ExtractStatus__c = null;
            newCPDChild.Agreement__r = null;
            newCPDChild.Agreement__c = '';
            newCPDChild.Hierarchy__c = null;
            newCPDChild.Hierarchy__r = null;
            newCPDChild[Product__c.fieldApiName] = product != null ? product.Id : this.wCPDApexList[index].commercialPlanDetail.Product__c;
            newCPDChild[Product__r.fieldApiName] = product != null ? product : this.wCPDApexList[index].commercialPlanDetail.Product__r;
            newCPDChild.ConsumerTradeItemPromoDetail__c = this.wCPDApexList[index].commercialPlanDetail.Id;
            if (!this.wCPDApexList[index].commercialPlanDetailChildren) {
                this.wCPDApexList[index].commercialPlanDetailChildren = [newCPDChild];
                this.wCPDApexList[index].commercialPlanDetail.Product__c = null;
                this.wCPDApexList[index].commercialPlanDetail.Product__r = null;
                this.wCPDApexList[index].commercialPlanDetail.Hierarchy__c = null;
                this.wCPDApexList[index].commercialPlanDetail.Hierarchy__r = null;
                this.wCPDApexList[index].commercialPlanDetail.SellInDiscountUAmtNego__c = null;
                this.wCPDApexList[index].commercialPlanDetail.AgreementLine1__c = null;
                this.wCPDApexList[index].commercialPlanDetail.AgreementLine1__r = null;
            } else {
                newCPDChild.VolumeTarget__c = null;
                newCPDChild.VolumeFact_c = null;
                newCPDChild.VolumeValidate__c = null;
                this.wCPDApexList[index].commercialPlanDetailChildren.push(newCPDChild);
            }
            if (currentCommercialPlanDetail == null) {
                this.wCPDJSList[index] = this.buildCPDInfo(this.wCPDApexList[index].commercialPlanDetail, this.wCPDApexList[index].commercialPlanDetailChildren, index);
                this.openedCPDsSet.add(Number(index));
            }
            this.wCPDApexList[index].hasChanged = true;
            this.tableLoading = false;
        } catch (error) {
            console.error(error);
        }
    }

    toggleChildren(event) {
        try {
            this.tableLoading = true;
            let index = event.target.dataset.index;
            let id = event.target.dataset.id
            if (!this.wCPDJSList[index].hasChildrenAndOpened) {
                this.openedCPDsSet.add(Number(index));
            } else {
                this.openedCPDsSet.delete(Number(index));
            }
            this.tableLoading = false;
        } catch (error) {
            console.error(error)
        }
    }

    getCommercialPlanDetailsToSave() {
        return this.wCPDApexList.filter(item => item.hasChanged);
    }

    handleCancel() {
        window.open('/' + this.currentCommercialPlan.Id, "_self");
    }

    saveSimulation() {
        try {
            let wCommercialPlanDetailsToSave = this.getCommercialPlanDetailsToSave();
            if (wCommercialPlanDetailsToSave != null && wCommercialPlanDetailsToSave != []) {
                this.tableLoading = true;
                saveSimulation({
                    wCommercialPlanDetailListJson: JSON.stringify(wCommercialPlanDetailsToSave),
                }).then((result) => {
                    if (result != null && result != '') {
                        this.tableLoading = false;
                        console.error('Error: ' + result);
                        this.showNotification('Save Error', result, 'error', 'dismissible ');
                    } else {
                        this.selectedRecordsIds = [];
                        this.selectedFilteredRecordsIds = [];
                        //LOADING CAN BE REMOVED FOR FASTER EXPERIENCE
                        //this.loadCommercialPlans();
                        this.wCPDJSList = [];
                        this.search();
                        this.showNotification('Save Successful', '', 'success', 'dismissible ');
                    }

                }).catch((error) => {
                    console.error(error);
                });
            }
        } catch (error) {
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
        }
    }

    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
        handleChangeMultiRT: 'handlechangemultirt'
    }

    handleChangeMultiPicklistValues(event) {
        let values = [];
        event.detail.selOptions.forEach(item => {
            values.push(item.value);
        })
        let wrapper = event;
        wrapper.target.value = values.join('; ');
        this.handleFieldEdits(event);
    }

    handleChangeMultiRT(event) {
        let values = [];
        event.detail.selOptions.forEach(item => {
            values.push(item.value);
        })
        this.productFilterWrapper.StringifiedSelectedRecordType = JSON.stringify(values);
        let wrapper = event;
        wrapper.target.value = values.join(',');
        this.fillFilterList(event);
    }

    handleFieldEdits(event) {
        try {
            //GET THE VALUE/INDEXES/IDS FROM HTML
            this.activeElement = event.target;
            let index = event.target.dataset.index;
            let fieldIndex = event.target.dataset.fieldindex;
            let rowIndex = event.target.dataset.rowindex;
            let field = event.target.dataset.field;
            let parentindex = event.target.dataset.parentindex;
            let value;
            if (event.target.tagName.toLowerCase() === 'select') {
                value = event.target.value;
            } else {
                value = event.detail.checked != null ? event.detail.checked : event.target.value;
                value = Array.isArray(value) ? value[0] : value == '' ? event.detail.checked != null ? value : null : value;
            }
            //INITIALIZE CURRENT CPD
            let currentCommercialPlanDetail = {};
            let currentJSCommercialPlanDetail = {};
            if (this.editTimeout) {
                window.clearTimeout(this.editTimeout);
            }
            this.editTimeout = setTimeout(() => {
                if (parentindex == null) {
                    //CASE OF PARENT
                    currentCommercialPlanDetail = this.wCPDApexList[rowIndex];
                    currentJSCommercialPlanDetail = this.wCPDJSList[rowIndex];
                    if (field == Status__c.fieldApiName && currentCommercialPlanDetail.commercialPlanDetail[field] != 'Validated' && value == 'Validated'
                        && (
                            currentCommercialPlanDetail.commercialPlanDetail[SellInDiscountUAmtNego__c.fieldApiName] != null)) {
                        if (confirm(SPHER_LBL_TMP_Values_Send_TO_SAP)) {
                            currentCommercialPlanDetail.commercialPlanDetail[field] = value;
                            if (currentJSCommercialPlanDetail.values[fieldIndex] != null) {
                                currentJSCommercialPlanDetail.values[fieldIndex].fieldValue = value;
                                currentJSCommercialPlanDetail.values[fieldIndex].fieldOutputValue = value;
                            }
                        } else {
                            if (currentJSCommercialPlanDetail.values[fieldIndex] != null) {
                                currentJSCommercialPlanDetail.values[fieldIndex].fieldValue = currentCommercialPlanDetail.commercialPlanDetail[field];
                                event.target.value = currentCommercialPlanDetail.commercialPlanDetail[field];
                            }
                        }
                    } else {
                        //SET THE VALUE IN APEX WRAPPER
                        currentCommercialPlanDetail.commercialPlanDetail[field] = value;
                        //SET THE VALUE IN JS WRAPPER
                        if (currentJSCommercialPlanDetail.values[fieldIndex] != null) {
                            currentJSCommercialPlanDetail.values[fieldIndex].fieldValue = value;
                            currentJSCommercialPlanDetail.values[fieldIndex].fieldOutputValue = value;
                        }
                    }
                    if (field == SellOutBDate__c.fieldApiName) {
                        let startDate = currentCommercialPlanDetail.commercialPlanDetail[SellOutBDate__c.fieldApiName];
                        let approvDays = 1;
                        let approvDate = new Date(startDate);
                        approvDate.setDate(approvDate.getDate() + approvDays);
                        for (let gridField of this.wCPDJSList[rowIndex].values) {
                            if (gridField.fieldApiName == SellOutEDate__c.fieldApiName) {
                                gridField.fieldValue = approvDate.toISOString().replace(/T.*/gi, '');
                                gridField.fieldOutputValue = approvDate.toISOString().replace(/T.*/gi, '');
                            }
                        }
                        currentCommercialPlanDetail.commercialPlanDetail[SellOutEDate__c.fieldApiName] = approvDate.toISOString().replace(/T.*/gi, '');
                        if (currentCommercialPlanDetail.commercialPlanDetail.Id == null) {
                            let endDate = new Date(startDate);
                            endDate.setDate(endDate.getDate() + 1);
                            for (let gridField of this.wCPDJSList[rowIndex].values) {
                                if (gridField.fieldApiName == SellOutEDate__c.fieldApiName) {
                                    gridField.fieldValue = endDate.toISOString().replace(/T.*/gi, '');
                                    gridField.fieldOutputValue = endDate.toISOString().replace(/T.*/gi, '');
                                }
                            }
                            currentCommercialPlanDetail.commercialPlanDetail[SellOutEDate__c.fieldApiName] = endDate.toISOString().replace(/T.*/gi, '');
                        }
                    }
                    if ((field == Status__c.fieldApiName || field == BudgetType__c.fieldApiName) && currentJSCommercialPlanDetail.hasChildren) {
                        for (let childIndex = 0; childIndex < currentJSCommercialPlanDetail.children.length; childIndex++) {
                            currentJSCommercialPlanDetail.children[childIndex].values[fieldIndex].fieldValue = value;
                            currentJSCommercialPlanDetail.children[childIndex].values[fieldIndex].fieldOutputValue = value;
                            currentCommercialPlanDetail.commercialPlanDetailChildren[childIndex][field] = value;
                        }
                    }
                    currentCommercialPlanDetail.hasChanged = true;
                } else {
                    currentCommercialPlanDetail = this.wCPDApexList[parentindex].commercialPlanDetailChildren[index];
                    currentJSCommercialPlanDetail = this.wCPDJSList[parentindex].children[index];
                    if (field == Status__c.fieldApiName && currentCommercialPlanDetail[field] != 'Validated' && value == 'Validated'
                        && (
                            currentCommercialPlanDetail[SellInDiscountUAmtNego__c.fieldApiName] != null)) {
                        if (confirm(SPHER_LBL_TMP_Values_Send_TO_SAP)) {
                            currentCommercialPlanDetail[field] = value;
                            this.wCPDApexList[parentindex].hasChanged = true;
                            if (currentJSCommercialPlanDetail.values[fieldIndex] != null) {
                                currentJSCommercialPlanDetail.values[fieldIndex].fieldValue = value;
                                currentJSCommercialPlanDetail.values[fieldIndex].fieldOutputValue = value;
                            }
                        } else {
                            if (currentJSCommercialPlanDetail.values[fieldIndex] != null) {
                                currentJSCommercialPlanDetail.values[fieldIndex].fieldValue = currentCommercialPlanDetail[field];
                                event.target.value = currentCommercialPlanDetail[field];

                            }
                        }
                    } else {
                        currentCommercialPlanDetail[field] = value;
                        this.wCPDApexList[parentindex].hasChanged = true;
                        currentJSCommercialPlanDetail = this.wCPDJSList[parentindex].children[index];
                        if (currentJSCommercialPlanDetail.values[fieldIndex] != null) {
                            currentJSCommercialPlanDetail.values[fieldIndex].fieldValue = value;
                            currentJSCommercialPlanDetail.values[fieldIndex].fieldOutputValue = value;
                        }
                    }
                }
                let picklistField = field;
                let dependentValExist = this.picklistRelationshipMap.hasOwnProperty(picklistField);
                let commercialPlanDetailWrapper = this.wCPDJSList.find(element => element.index == index);
                let depVal = value;
                while (dependentValExist) {
                    let fieldWrapper = commercialPlanDetailWrapper.values.find(element => element.fieldApiName == this.picklistRelationshipMap[picklistField]);
                    this.wCPDJSList[index].values[fieldWrapper.fieldIndex].controllerValue = depVal;
                    this.wCPDJSList[index].values[fieldWrapper.fieldIndex].fieldValue = '';
                    this.wCPDApexList[index].commercialPlanDetail[fieldWrapper.fieldApiName] = '';
                    this.wCPDJSList[index].values[fieldWrapper.fieldIndex].picklistOptions = [];
                    if (this.dependentPicklistMap[fieldWrapper.fieldApiName] && this.dependentPicklistMap[fieldWrapper.fieldApiName][value]) {
                        for (let option of this.dependentPicklistMap[fieldWrapper.fieldApiName][value]) {
                            this.wCPDJSList[index].values[fieldWrapper.fieldIndex].picklistOptions.push({ label: option.label, value: option.value, isSelected: false })
                        }
                    }
                    this.wCPDJSList[index].values[fieldWrapper.fieldIndex].picklistOptions.unshift({ label: LBL_None_Picklist_Value, value: '', isSelected: true })
                    dependentValExist = this.picklistRelationshipMap[fieldWrapper.fieldApiName] != null;
                    picklistField = fieldWrapper.fieldApiName;
                    depVal = this.wCPDJSList[index].values[fieldWrapper.fieldIndex].fieldValue;
                }
                this.wCPDJSList = [...this.wCPDJSList];
            }, 200);
        } catch (error) {
            console.error(error);
            this.showNotification('Error', error, 'error', 'dismissible ');
        }
    }

    openCPD(event) {
        let id = event.target.dataset.id;
        window.open('/' + id);
    }

    handleClickDetail(event) {
        try {
            let target = event.target;
            if (this.node != null) {
                this.node.style.border = this.prevNodeBorder;
            }
            this.node = target.closest("tr");
            this.prevNodeBorder = "";
            this.node.style.border = "2px black solid";
        } catch (error) {
            console.log('error: ' + error);
        }
    }

    handleCPDDeletePopUp(event) {
        try {
            let id = event.target.dataset.id;
            let childIndex = event.target.dataset.childindex;
            let rowIndex = event.target.dataset.rowindex;
            this.deleteData.childIndex = childIndex;
            this.deleteData.rowIndex = rowIndex;
            this.isDeleteRow = true;
        } catch (error) {
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
            this.tableLoading = false;
        }

    }

    handleCPDDeleteCancel() {
        this.isDeleteRow = false;
        this.deleteData = {
            childIndex: '',
            rowIndex: ''
        };
    }

    handleCPDDelete() {
        try {
            this.isDeleteRow = false;
            this.tableLoading = true;
            let childIndex = this.deleteData.childIndex;
            let rowIndex = this.deleteData.rowIndex;
            let CPDstoDelete = [];
            CPDstoDelete.push(childIndex != null ? this.wCPDApexList[rowIndex].commercialPlanDetailChildren[childIndex] : this.wCPDApexList[rowIndex].commercialPlanDetail);
            if (childIndex == null && this.wCPDApexList[rowIndex].commercialPlanDetailChildren != null && this.wCPDApexList[rowIndex].commercialPlanDetailChildren.length > 0) {
                CPDstoDelete.push(...this.wCPDApexList[rowIndex].commercialPlanDetailChildren);
            }
            if (CPDstoDelete[0].Id == null) {
                if (childIndex != null) {
                    this.wCPDApexList[rowIndex].commercialPlanDetailChildren.splice(childIndex, 1);
                    this.wCPDJSList[rowIndex].children.splice(childIndex, 1);
                } else {
                    this.wCPDApexList.splice(rowIndex, 1);
                    this.wCPDJSList.splice(rowIndex, 1);
                }
                this.wCPDJSList = [...this.wCPDJSList];
                for (let index = parseInt(0); index < this.wCPDJSList.length; index++) {
                    this.wCPDJSList[index].index = index;
                }
                for (let index = parseInt(0); index < this.wCPDApexList.length; index++) {
                    this.wCPDApexList[index].index = index;
                }
                this.isEmpty = this.wCPDJSList.length == 0;
                this.tableLoading = false;
            } else {
                deleteCPDs({
                    CPDtoDelete_JSON: JSON.stringify(CPDstoDelete)
                }).then((result) => {
                    // this.loadCommercialPlans();
                    if (childIndex != null) {
                        this.wCPDApexList[rowIndex].commercialPlanDetailChildren.splice(childIndex, 1);
                        this.wCPDJSList[rowIndex].children.splice(childIndex, 1);
                    } else {
                        this.wCPDApexList.splice(rowIndex, 1);
                        this.wCPDJSList.splice(rowIndex, 1);
                    }
                    this.wCPDJSList = [...this.wCPDJSList];
                    for (let index = parseInt(0); index < this.wCPDJSList.length; index++) {
                        this.wCPDJSList[index].index = index;
                    }
                    for (let index = parseInt(0); index < this.wCPDApexList.length; index++) {
                        this.wCPDApexList[index].index = index;
                    }
                    this.isEmpty = this.wCPDJSList.length == 0;
                    this.tableLoading = false;
                }).catch((errorApex) => {
                });
            }
        } catch (error) {
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
            this.tableLoading = false;
        }
    }

    showFieldManagerHandler(event) {
        let value = event.detail.value;
        if (value == 'fieldManager') {
            this.showFieldManager = true;
        } else if (value == 'exportExcel') {
            this.exportExcel();
        }
    }

    closeFieldManagerHandler(event) {
        this.showFieldManager = false;
    }

    handleDisplayedFieldsChange(event) {
        let value = event.target.value;
        localStorage.setItem('DisplayedFieldsComm', JSON.stringify(value));
        this.loadCommercialPlans();
    }

    loadPopupHandler(event) {
        try {
            this.tableLoading = true
            this.childIndex = null;
            this.childIndex = event.target.dataset.childindex;
            let rowIndex = event.target.dataset.rowindex;
            let popupType = event.target.dataset.popup;
            this.currentJSCommercialPlanDetail = this.childIndex == null ? this.wCPDJSList[rowIndex] : this.wCPDJSList[rowIndex].children[this.childIndex];
            this.currentAPEXCommercialPlanDetail = this.wCPDApexList[rowIndex];
            switch (popupType) {
                case "category":
                    getCategoriesRecords({
                        commPlanJSON: JSON.stringify(this.currentCommercialPlan),
                        categoryNameSearch: ''
                    })
                        .then((result) => {
                            this.categoriesForSelection = JSON.parse(result);
                            this.showCategorySelection = true;
                            this.categoriesLoaded = true;
                            this.tableLoading = false;
                        })
                        .catch((apexError) => {
                            console.error(apexError);
                        });
                    break;
                case "product":
                    getProductsRecords({
                        commPlanCategoryId: this.currentCommercialPlan[CPHierarchyElement.fieldApiName],
                        productFilter: JSON.stringify(this.productFilterWrapper),
                        pageSize: this.productsPageSize,
                        pageNumber: 1
                    }).then((result) => {
                        let prodresult = JSON.parse(result);
                        this.handleProductData(prodresult, false);
                        this.showProductSelection = true;
                        this.productsLoaded = true;
                        this.tableLoading = false;
                    }).catch((apexError) => {
                        console.error(apexError);
                    });
                    break;
                case "bu":
                    getBUsRecords({
                        commPlanJSON: JSON.stringify(this.currentCommercialPlan),
                        BUNameSearch: ''
                    })
                        .then((result) => {
                            this.BUsForSelection = JSON.parse(result);
                            this.showBUSelection = true;
                            this.BUsLoaded = true;
                            this.tableLoading = false;
                        })
                        .catch((apexError) => {
                            console.error(apexError);
                        });
                    break;
            }
        } catch (error) {
            console.error(error);
        }
    }

    handleProductSelection(event) {
        try {
            let productId = event.target.dataset.id;
            this.handleProductSelectionChange(productId);
            this.closeproductSelection();
        } catch (error) {
            console.error(error);
        }
    }

    handleProductSelectionChange(productId) {
        let product = this.productsForSelection.find(wrapper => wrapper.Id == productId);
        if (this.currentAPEXCommercialPlanDetail) {
            if (this.childIndex != null) {
                this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][Product__c.fieldApiName] = productId;
                this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][Product__r.fieldApiName] = product;
            } else {
                this.currentAPEXCommercialPlanDetail.commercialPlanDetail[Product__c.fieldApiName] = productId;
                this.currentAPEXCommercialPlanDetail.commercialPlanDetail[Product__r.fieldApiName] = product;
                this.currentAPEXCommercialPlanDetail.commercialPlanDetail[Hierarchy__c.fieldApiName] = product?.Hierarchy__c;
                this.currentAPEXCommercialPlanDetail.commercialPlanDetail[Hierarchy__r.fieldApiName] = product?.Hierarchy__r;
            }
            for (let gridField of this.currentJSCommercialPlanDetail.values) {
                if (gridField.isProduct) {
                    gridField.link = "/" + productId;
                    gridField.fieldOutputValue = product?.Name;
                    gridField.fieldValue = productId;
                }
                if (gridField.isCategory) {
                    gridField.link = "/" + product?.Hierarchy__c;
                    gridField.fieldOutputValue = product?.Hierarchy__r?.Name;
                    gridField.fieldValue = productId;
                }
            }
            this.wCPDJSList = [...this.wCPDJSList];
            this.currentAPEXCommercialPlanDetail.hasChanged = true;
        } else {
            let field = this.displayedFields.filter(item => item.fieldName == Product__c.fieldApiName)[0];
            field.massUpdateValue = productId;
            field.massUpdateLabel = product.Name;
            this.massUpdateFields.push(Product__c.fieldApiName);
        }
    }

    closeproductSelection() {
        this.loading = true;
        this.productsForSelection = [];
        this.resetProductFilter();
        this.showProductSelection = false;
        this.showMultipleProductsPopUp = false;
        this.displayProductsFilter = false;
        this.productsPageNumber = 1;
        this.multiProductWrapper = [];
        this.multiCloneInfo = {};
        this.loading = false;
    }

    filterProducts(event) {
        try {
            this.productSearch = event.target.dataset.button ? this.template.querySelector('[data-id="productInput"]').value : event.target.value;
            this.productFilterWrapper.generalSearch = this.productSearch;
            if (event.keyCode === 13 || event.target.dataset.button) {
                this.handleProductSearch();
            }
        } catch (error) {
            console.error(error);
        }
    }

    handleCategorySelection(event) {
        try {
            this.tableLoading = true;
            let self = this;
            let categoryId = event.target.dataset.id;
            let categoryIndex = event.target.dataset.categoryindex;
            if (this.currentAPEXCommercialPlanDetail) {
                if (this.childIndex != null) {
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][Hierarchy__c.fieldApiName] = categoryId;
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][Hierarchy__r.fieldApiName] = this.categoriesForSelection[categoryIndex];
                } else {
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetail[Hierarchy__c.fieldApiName] = categoryId;
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetail[Hierarchy__r.fieldApiName] = this.categoriesForSelection[categoryIndex];
                    getProductsOfCategory({
                        commPlanJSON: JSON.stringify(this.currentCommercialPlan),
                        categoryId: categoryId,
                        BuId: self.currentCommercialPlan[BusinessUnitSource__c.fieldApiName]
                    }).then((result) => {
                        let products = JSON.parse(result);
                        let event = {
                            target: {
                                dataset: {
                                    index: self.currentJSCommercialPlanDetail.index
                                }
                            }
                        }
                        let i = 0;
                        let currentCommercialPlanDetail = JSON.stringify(this.wCPDApexList[self.currentJSCommercialPlanDetail.index].commercialPlanDetail);
                        for (let product of products) {
                            this.createNewCPDChild(event, product, currentCommercialPlanDetail);
                            i++;
                        }
                        let index = event.target.dataset.index;
                        this.wCPDJSList[self.currentJSCommercialPlanDetail.index] = this.buildCPDInfo(this.wCPDApexList[self.currentJSCommercialPlanDetail.index].commercialPlanDetail, this.wCPDApexList[self.currentJSCommercialPlanDetail.index].commercialPlanDetailChildren, self.currentJSCommercialPlanDetail.index);
                        this.openedCPDsSet.add(Number(self.currentJSCommercialPlanDetail.index));
                        this.tableLoading = false;
                    }).catch((apexError) => {
                        this.tableLoading = false;
                        console.error(apexError);
                    });
                }
                for (let gridField of this.currentJSCommercialPlanDetail.values) {
                    if (gridField.isCategory) {
                        gridField.link = "/" + categoryId;
                        gridField.fieldOutputValue = this.categoriesForSelection[categoryIndex]?.Name;
                        gridField.fieldValue = categoryId;
                        break;
                    }
                }
                this.currentAPEXCommercialPlanDetail.hasChanged = true;
            } else {
                let field = this.displayedFields.filter(item => item.fieldName == Hierarchy__c.fieldApiName)[0];
                field.massUpdateValue = categoryId;
                field.massUpdateLabel = this.categoriesForSelection[categoryIndex].Name;
                this.massUpdateFields.push(Hierarchy__c.fieldApiName);
            }
            this.closeCategorySelection();
        } catch (error) {
            console.error(error);
        }
    }

    closeCategorySelection() {
        this.showCategorySelection = false;
    }

    filterCategories(event) {
        try {
            this.categorySearch = event.target.dataset.button ? this.template.querySelector('[data-id="categoryInput"]').value : event.target.value;
            if (event.keyCode === 13 || event.target.dataset.button) {
                getCategoriesRecords({
                    commPlanJSON: JSON.stringify(this.currentCommercialPlan),
                    categoryNameSearch: this.categorySearch
                })
                    .then((result) => {
                        this.categoriesForSelection = JSON.parse(result);
                        this.showcategorySelection = true;
                        this.categoriesLoaded = true;
                        this.tableLoading = false;
                    })
                    .catch((apexError) => {
                        console.error(apexError);
                    });
            }
        } catch (error) {
            console.error(error);
        }
    }

    handleBUSelection(event) {
        try {
            let BUId = event.target.dataset.id;
            let BUIndex = event.target.dataset.index;
            if (this.currentAPEXCommercialPlanDetail) {
                if (this.childIndex != null) {
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][BusinessUnitTarget__c.fieldApiName] = BUId;
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][BusinessUnitTarget__r.fieldApiName] = this.BUsForSelection[BUIndex];
                } else {
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetail[BusinessUnitTarget__c.fieldApiName] = BUId;
                    this.currentAPEXCommercialPlanDetail.commercialPlanDetail[BusinessUnitTarget__r.fieldApiName] = this.BUsForSelection[BUIndex];
                }
                for (let gridField of this.currentJSCommercialPlanDetail.values) {
                    if (gridField.isBU) {
                        gridField.link = "/" + BUId;
                        gridField.fieldOutputValue = this.BUsForSelection[BUIndex]?.Name;
                        gridField.fieldValue = BUId;
                        break;
                    }
                }
                this.currentAPEXCommercialPlanDetail.hasChanged = true;
            } else {
                let field = this.displayedFields.filter(item => item.fieldName == BusinessUnitTarget__c.fieldApiName)[0];
                field.massUpdateValue = BUId;
                field.massUpdateLabel = this.BUsForSelection[BUIndex].Name;
                this.massUpdateFields.push(BusinessUnitTarget__c.fieldApiName);
            }
            this.closeBUSelection();
        } catch (error) {
            console.error(error);
        }
    }

    closeBUSelection() {
        this.showBUSelection = false;
    }

    filterBUs(event) {
        try {
            this.BUSearch = event.target.dataset.button ? this.template.querySelector('[data-id="BUInput"]').value : event.target.value;
            if (event.keyCode === 13 || event.target.dataset.button) {
                getBUsRecords({
                    commPlanJSON: JSON.stringify(this.currentCommercialPlan),
                    BUNameSearch: this.BUSearch
                }).then((result) => {
                    this.BUsForSelection = JSON.parse(result);
                    this.showBUSelection = true;
                    this.BUsLoaded = true;
                    this.tableLoading = false;
                }).catch((apexError) => {
                    console.error(apexError);
                });
            }
        } catch (error) {
            console.error(error);
        }
    }

    toggleFilter(event) {
        let filterBtn = this.template.querySelector('.filterBtn');
        filterBtn.classList.toggle('slds-is-selected');
        let filterPanel = this.template.querySelector('.filter-panel');
        filterPanel.classList.toggle('slds-hide');
    }

    setnumberOfFixedColumns(event) {
        this.filters.nbOfFixedColumns = event.detail.value;
        let tableTrs = this.template.querySelector('.initial-table').rows;
        for (let index = 0; tableTrs && index < tableTrs.length; index++) {
            let childrens = tableTrs[index].children;
            let left = 0;
            for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                if (index2 < this.filters.nbOfFixedColumns) {
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.left = left + 'px';
                    childrens[index2].style.zIndex = 3;
                    left += childrens[index2].offsetWidth;
                    childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                } else {
                    childrens[index2].style.position = 'unset';
                    childrens[index2].style.left = 'unset';
                    childrens[index2].style.zIndex = 'unset';
                }
                if (index2 == (childrens.length - 1)) {
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.right = '0';
                    childrens[index2].style.zIndex = '3';
                }
            }
        }
    }

    setSearchValue(event) {
        if (this.editTimeout) {
            window.clearTimeout(this.editTimeout);
        }
        this.editTimeout = setTimeout(() => {
            this.filters.searchValue = event.detail.value;
        }, 200);
    }

    reset(event) {
        let type = event.target.dataset.type;
        this.tableLoading = true;
        this.pageNumber = 1;
        if (type == 'filter') {
            this.filters.dynamicSearch = '[]';
            let fieldName = event.target.dataset.field;
            if (this.fieldsToFilterMap[fieldName]) {
                if (this.fieldsToFilterMap[fieldName].hasOwnProperty('values')) {
                    this.fieldsToFilterMap[fieldName].values = [];
                }
                if (this.fieldsToFilterMap[fieldName].hasOwnProperty('value')) {
                    this.fieldsToFilterMap[fieldName].value = '';
                }
                if (this.fieldsToFilterMap[fieldName].hasOwnProperty('value1')) {
                    this.fieldsToFilterMap[fieldName].value1 = '';
                    this.fieldsToFilterMap[fieldName].value2 = '';
                }
            }
            this.template.querySelectorAll('.headerFilterSection').forEach(element => {
                if (!element.classList.contains("slds-hide")) {
                    // If not, add the 'slds-hide' class
                    element.classList.add("slds-hide");
                }
            });
            this.displayedFields.forEach(item => {
                if (item.isShowFilterOnColumnHeader) {
                    if (item.fieldName == fieldName) {
                        this.template.querySelectorAll('[data-header-filter="' + fieldName + '"]').forEach(element => {
                            element.value = '';
                        })
                        item.hasFilter = false;
                    } else {
                        this.headerFieldsSelection[item.fieldName] = item.hasFilter;
                    }
                }
            });
            this.confirmFilter();
        } else {
            this.filters = {
                searchValue: '',
                dynamicSearch: '[]'
            };
            if (!this.mainWrapper.gridSettings.isShowFilterOnColumnHeader) {
                this.fieldsToFilter.forEach(item => {
                    item.value = '';
                    item.values = '';
                    item.value1 = '';
                    item.value2 = '';
                })
                this.loadCommercialPlans();
            } else {
                this.confirmFilter();
            }
        }
    }

    search() {
        this.pageNumber = 1;
        this.confirmFilter();
    }

    searchProducts() {
        this.productsPageNumber = 1;
        this.handleProductSearch();
    }

    handleUploadFinished(event) {
        try {
            const uploadedFiles = event.detail.files;
            alert('No. of files uploaded : ' + uploadedFiles.length);
            if (this.childIndex != null) {
                this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][this.currentUploadField] = '/sfc/servlet.shepherd/document/download/' + uploadedFiles[0].documentId;
            } else {
                this.currentAPEXCommercialPlanDetail.commercialPlanDetail[this.currentUploadField] = '/sfc/servlet.shepherd/document/download/' + uploadedFiles[0].documentId;
            }
            this.currentAPEXCommercialPlanDetail.hasChanged = true;
            this.currentJSCommercialPlanDetail.values[this.currentUploadFieldIndex].fieldValue = '/sfc/servlet.shepherd/document/download/' + uploadedFiles[0].documentId;
            this.wCPDJSList = [...this.wCPDJSList];
        } catch (error) {
            console.error(error);
        }
    }

    openFileUploadPopup(event) {
        try {
            let rowIndex = event.target.dataset.rowindex;
            this.currentUploadField = event.target.dataset.field;
            this.currentUploadFieldIndex = event.target.dataset.fieldindex;
            this.childIndex = event.target.dataset.childindex;
            this.currentAPEXCommercialPlanDetail = this.wCPDApexList[rowIndex];
            this.currentJSCommercialPlanDetail = this.childIndex == null ? this.wCPDJSList[rowIndex] : this.wCPDJSList[rowIndex].children[this.childIndex];
            this.showFileUploadPopup = true;
        } catch (error) {
            console.error('error: ' + error)
        }
    }

    closeFileUploadPopup(event) {
        this.showFileUploadPopup = false;
    }

    handleDeleteFile(event) {
        try {
            let rowIndex = event.target.dataset.rowindex;
            this.currentUploadField = event.target.dataset.field;
            this.currentUploadFieldIndex = event.target.dataset.fieldindex;
            this.childIndex = event.target.dataset.childindex;
            this.currentAPEXCommercialPlanDetail = this.wCPDApexList[rowIndex];
            this.currentJSCommercialPlanDetail = this.childIndex == null ? this.wCPDJSList[rowIndex] : this.wCPDJSList[rowIndex].children[this.childIndex];

            if (this.childIndex != null) {
                this.currentAPEXCommercialPlanDetail.commercialPlanDetailChildren[this.childIndex][this.currentUploadField] = '';
            } else {
                this.currentAPEXCommercialPlanDetail.commercialPlanDetail[this.currentUploadField] = '';
            }
            this.currentAPEXCommercialPlanDetail.hasChanged = true;
            this.currentJSCommercialPlanDetail.values[this.currentUploadFieldIndex].fieldValue = '';
            this.wCPDJSList = [...this.wCPDJSList];
        } catch (error) {
            console.error(error)
        }
    }

    changePageSizeHandler(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.changePageHandler();
    }

    handleChangePage(event) {
        try {
            this.openedCPDsSet = new Set();
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            }
            this.changePageHandler();
        } catch (error) {
            console.error(error)
        }
    }

    changeProductsPageSizeHandler(event) {
        this.productsPageSize = event.target.value;
        this.productsPageNumber = 1;
        this.handleProductSearch();
    }

    handleChangePageProducts(event) {
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.productsPageNumber--;
            } else if (type == 'Next') {
                this.productsPageNumber++;
            }
            this.handleProductSearch();
        } catch (error) {
            console.error(error)
        }
    }

    productFilterHandler() {
        this.displayProductsFilter = !this.displayProductsFilter;
    }

    fillFilterList(event) {
        let name = event.target.dataset.name;
        let value = event.target.value;
        if (value != null) {
            if (name == 'generalSearch') {
                this.productFilterWrapper.generalSearch = value;
            } else if (name == 'Category') {
                this.isShowCategory = false;
                this.selectedCategory = value;
            } else if (name == 'Brand') {
                this.isShowCategory = false;
                this.selectedBrand = value;
            } else {
                this.productFilterWrapper[name] = value;
            }
        }
    }

    handleProductSearch() {
        this.productsLoaded = false;
        this.productFilterWrapper.categories = [];
        for (let selectedCategory of this.selectedCategories) {
            this.productFilterWrapper.categories.push(selectedCategory.id);
        }
        this.productFilterWrapper.brands = [];
        for (let selectedBrand of this.selectedBrands) {
            this.productFilterWrapper.brands.push(selectedBrand.id);
        }
        getProductsRecords({
            commPlanCategoryId: this.currentCommercialPlan[CPHierarchyElement.fieldApiName],
            productFilter: JSON.stringify(this.productFilterWrapper),
            pageSize: this.productsPageSize,
            pageNumber: this.productsPageNumber
        }).then((result) => {
            let prodresult = JSON.parse(result);
            this.handleProductData(prodresult, true);
            this.showProductSelection = true;
            this.productsLoaded = true;
        })
            .catch((apexError) => {
                console.error(apexError);
            });
    }

    resetProductScreen() {
        this.loading = true;
        this.resetProductFilter();
        this.handleProductSearch();
        this.loading = false;
    }

    resetProductFilter() {
        this.selectedBrand = '';
        this.selectedCategory = '';
        this.selectedCategories = [];
        this.selectedBrands = [];
        this.productFilterWrapper = {
            generalSearch: '',
            categories: [],
            brands: [],
            //market: '',
            family: '',
            animation: '',
            recordType: ''
        };
        this.displayProductsFilter = false;
    }

    handleRemove(event) {
        let name = event.target.dataset.name;
        let id = event.target.dataset.id;
        if (name == 'Category') {
            let i = this.selectedCategories.findIndex(elem => elem.id == id);
            if (i > -1) {
                this.selectedCategories.splice(i, 1);
            }
            this.selectedCategory = '';
        }
        if (name == 'Brand') {
            let i = this.selectedBrands.findIndex(elem => elem.id == id);
            if (i > -1) {
                this.selectedBrands.splice(i, 1);
            }
            this.selectedBrand = '';
        }
    }
    selectedFilteredRecordsIds = [];
    changePageHandler() {
        this.tableLoading = true;
        getCommercialPlanDetails({
            commercialPlanJSON: JSON.stringify(this.currentCommercialPlan),
            gridsettingsJSON: JSON.stringify(this.mainWrapper.gridSettings),
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            filtersJSON: JSON.stringify(this.filters)
        }).then((result) => {
            let resultParsed = JSON.parse(result);
            this.mainWrapper.CommercialPlanWrapper.commercialPlanDetails = resultParsed.commercialPlanDetailsWrapperList;
            this.totalRecordsCount = resultParsed.numberOfRecords;
            this.totalpagesCount = Math.ceil((this.totalRecordsCount / this.pageSize));
            let CPDList = [];
            let index = 0;
            let selectedIds = [];
            this.selectedFilteredRecordsIds = [];
            for (let CommercialPlanDetailWrapper of this.mainWrapper.CommercialPlanWrapper.commercialPlanDetails) {
                let builtCPD = this.buildCPDInfo(CommercialPlanDetailWrapper.commercialPlanDetail, CommercialPlanDetailWrapper.commercialPlanDetailChildren, index++);
                if (this.selectedRecordsIds.includes(CommercialPlanDetailWrapper.commercialPlanDetail.Id)) {
                    selectedIds.push(CommercialPlanDetailWrapper.commercialPlanDetail.Id);
                    builtCPD.isSelected = true;
                }
                CPDList.push(builtCPD);
            }
            this.selectedFilteredRecordsIds = selectedIds;
            let CPDApexList = this.mainWrapper.CommercialPlanWrapper.commercialPlanDetails;
            for (let i = 0; i < CPDApexList.length; i++) {
                let data = this.wCPDApexList.find(element => element.commercialPlanDetail.Id == CPDApexList[i].commercialPlanDetail.Id);
                if (data) {
                    CPDApexList[i] = data;
                }
            };
            this.wCPDApexList = CPDApexList;
            for (let i = 0; i < CPDList.length; i++) {
                let data = this.wCPDJSList.find(element => element.commercialPlanDetail.Id == CPDList[i].commercialPlanDetail.Id);
                if (data) {
                    data.index = CPDList[i].index;
                    CPDList[i] = data;
                    CPDList[i].isSelected = this.selectedRecordsIds.includes(CPDList[i].commercialPlanDetail.Id)
                }
            };
            this.wCPDJSList = CPDList;
            this.isEmpty = this.wCPDJSList.length == 0;
            this.pageNumber = this.isEmpty ? 0 : this.pageNumber;
            this.tableLoading = false;
        }).catch((error) => {
            console.error(error);
        });
    }

    showNotification(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    exportExcel() {
        try {
            getCommercialPlanDetails({
                commercialPlanJSON: JSON.stringify(this.currentCommercialPlan),
                gridsettingsJSON: JSON.stringify(this.mainWrapper.gridSettings),
                pageNumber: 0,
                pageSize: 0,
                filtersJSON: JSON.stringify(this.filters)
            }).then((result) => {
                let resultParsed = JSON.parse(result)
                let commercialPlanDetailsWrapperList = resultParsed.commercialPlanDetailsWrapperList;
                let wCPDApexListAll = commercialPlanDetailsWrapperList;
                let wCPDJSListAll = [];
                let index = 0;
                for (let CommercialPlanDetailWrapper of wCPDApexListAll) {
                    wCPDJSListAll.push(this.buildCPDInfo(CommercialPlanDetailWrapper.commercialPlanDetail, CommercialPlanDetailWrapper.commercialPlanDetailChildren, index++));
                }
                let tablebodyRows = this.fillTableBodyRow(wCPDJSListAll);
                let columns = JSON.parse(JSON.stringify(this.displayedFields));
                console.log('columns: ' + JSON.stringify(columns))
                let date = new Date(Date.now());
                let header = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel">';
                let style = '<Styles>';
                style += '<Style ss:ID="header"><Font ss:bgcolor="#e3deb8" ss:Bold="1" ss:FontName="Calibri" ss:Size="12"/><Interior ss:Color="#f8f8f8" ss:Pattern="Solid"/></Style>';
                for (let status of Object.keys(this.picklistColorsMap)) {
                    style += '<Style ss:ID="' + status.replace(/\s/g, '') + '"><Interior ss:Color="' + this.picklistColorsMap[status] + '" ss:Pattern="Solid"/></Style>';
                    style += '<Style ss:ID="Normal' + status.replace(/\s/g, '') + '" ss:Parent="' + status.replace(/\s/g, '') + '"></Style>';
                    style += '<Style ss:ID="NormalDateTime' + status.replace(/\s/g, '') + '" ss:Parent="' + status.replace(/\s/g, '') + '"><NumberFormat ss:Format="Short Date"/></Style>';
                }
                for (let column of columns) {
                    if (column.headerStyle != null) {
                        style += '<Style ss:ID="' + column.fieldName + '"><Interior ss:Color="' + column.headerStyle.bgColor + '" ss:Pattern="Solid"/><Font ss:Color="' + column.headerStyle.color + '" ss:Bold="1" ss:FontName="Calibri" ss:Size="12"/></Style>';
                    }
                }
                style += '<Style ss:ID="Normal"></Style>';
                style += '<Style ss:ID="NormalDateTime"><NumberFormat ss:Format="Short Date"/></Style>';

                style += '</Styles>';
                let tablebody = '<Row>';
                columns = columns.map(item => {
                    if (!item.isPersonalised) {
                        if (item.headerStyle != null) {
                            tablebody += '<Cell ss:StyleID="' + item.fieldName + '"><Data ss:Type="String">' + item.fieldLabel + '</Data></Cell>';
                        } else {
                            tablebody += '<Cell ss:StyleID="header"><Data ss:Type="String">' + item.fieldLabel + '</Data></Cell>';
                        }
                        if (!item.max_width || item.max_width < item.fieldLabel.length) {
                            item.max_width = item.fieldLabel.length;
                        }
                    }
                    return item;
                });
                tablebody += '</Row>';
                tablebody += tablebodyRows;
                let body = '<Worksheet ss:Name="Liste des TA">';
                body += '<Table>';
                columns.forEach(item => {
                    if (!item.isPersonalised) {
                        body += '<Column ss:Width="' + Math.trunc(item.max_width ? item.max_width * 6.5 : 80) + '"></Column>';
                    }
                });
                body += tablebody;
                body += '</Table>';
                body += '</Worksheet>';
                body += '</Workbook>';
                let a = document.createElement('a');
                a.style.display = 'none';
                a.href = 'data:application/vnd.ms-excel,' + encodeURIComponent(header + style + body);
                a.download = 'CommercialPlan' + '_' + date.toLocaleString().replace(/[:,\/]/g, '-') + ".xls";
                document.body.appendChild(a);
                a.click();
            }).catch((error) => {
                console.error(error);
            });

        } catch (error) {
            console.error('error: ' + error);
        }
    }

    fillTableBodyRow(wCPDJSList) {
        let tablebodyRows = '';
        wCPDJSList.forEach(item => {
            if (item.commercialPlanDetail.Status__c != null) {
                tablebodyRows += '<Row>';
            } else {
                tablebodyRows += '<Row>';
            }
            item.values.forEach(field => {
                tablebodyRows += '<Cell ss:StyleID="';
                if (field.isDate) {
                    tablebodyRows += 'NormalDateTime' + (item.commercialPlanDetail.Status__c != null && this.picklistColorsMap.hasOwnProperty(item.commercialPlanDetail.Status__c) ? item.commercialPlanDetail.Status__c.replace(/\s/g, '') : '') + '';
                } else {
                    tablebodyRows += 'Normal' + (item.commercialPlanDetail.Status__c != null && this.picklistColorsMap.hasOwnProperty(item.commercialPlanDetail.Status__c) ? item.commercialPlanDetail.Status__c.replace(/\s/g, '') : '') + '';
                }
                tablebodyRows += '"><Data ss:Type="';
                if (field.isNumberField) {
                    tablebodyRows += 'Number'
                } else if (field.isDate && (field.fieldOutputValue)) {
                    tablebodyRows += 'DateTime';
                } else {
                    tablebodyRows += 'String';
                }
                tablebodyRows += '">';
                if (field.fieldOutputValue) {
                    if (field.isNumberField) {
                        tablebodyRows += field.fieldOutputValue.toFixed(field.scale);
                    } else if (field.isBoolean) {
                        if (field.fieldOutputValue == true) {
                            tablebodyRows += '✓';
                        } else {
                            tablebodyRows += ''
                        }
                    } else {
                        tablebodyRows += field.fieldOutputValue;
                    }
                }
                tablebodyRows += '</Data></Cell>';
            });
            tablebodyRows += '</Row>';
            item.children.forEach(child => {
                if (child.commercialPlanDetail.Status__c != null) {
                    tablebodyRows += '<Row>';
                } else {
                    tablebodyRows += '<Row>';
                }
                child.values.forEach(childField => {
                    tablebodyRows += '<Cell ss:StyleID="';
                    if (childField.isDate) {
                        tablebodyRows += 'NormalDateTime' + (child.commercialPlanDetail.Status__c != null && this.picklistColorsMap.hasOwnProperty(child.commercialPlanDetail.Status__c) ? child.commercialPlanDetail.Status__c.replace(/\s/g, '') : '') + '';
                    } else {
                        tablebodyRows += 'Normal' + (child.commercialPlanDetail.Status__c != null && this.picklistColorsMap.hasOwnProperty(child.commercialPlanDetail.Status__c) ? child.commercialPlanDetail.Status__c.replace(/\s/g, '') : '') + '';
                    }
                    tablebodyRows += '"><Data ss:Type="';
                    if (childField.isNumberField) {
                        tablebodyRows += 'Number'
                    } else if (childField.isDate && (childField.fieldOutputValue)) {
                        tablebodyRows += 'DateTime';
                    } else {
                        tablebodyRows += 'String';
                    }
                    tablebodyRows += '">';
                    if (childField.fieldOutputValue) {
                        if (childField.isNumberField) {
                            tablebodyRows += childField.fieldOutputValue.toFixed(childField.scale);
                        } else if (childField.isBoolean) {
                            if (childField.fieldOutputValue == true) {
                                tablebodyRows += '✓';
                            } else {
                                tablebodyRows += ''
                            }
                        } else {
                            tablebodyRows += childField.fieldOutputValue;
                        }
                    }
                    tablebodyRows += '</Data></Cell>';
                });
                tablebodyRows += '</Row>';
            });
        });
        return tablebodyRows;
    }
    changeHeight = () => this.setTableDimension();
    setTableDimension() {
        let body = this.template.querySelector('.tableBody');
        let filterPanel = this.template.querySelector('.filter-panel');
        let header = this.template.querySelector('.pageHeader');
        let tableControl = this.template.querySelector('.tableControl');
        let tableControlHeight = tableControl ? tableControl.getBoundingClientRect().height : 0;
        let headerHeight = header ? header.getBoundingClientRect().height : 0;
        let tableContainer = this.template.querySelector('.tableContainer');
        let initialTable = this.template.querySelector('.initial-table');
        let windowHeight = window.innerHeight;
        if (body && tableContainer && initialTable) {
            if (filterPanel) {
                this.template.querySelector('.filter-panel').style.height = (windowHeight - (headerHeight == 0 ? 2 * tableControlHeight : headerHeight) - tableControlHeight - 135) + 'px';
            }
            this.template.querySelector('.tableBody').style.height = (windowHeight - (headerHeight == 0 ? 2 * tableControlHeight : headerHeight) - tableControlHeight - 135) + 'px';
            this.template.querySelector('.tableContainer').style.height = (this.template.querySelector('.tableBody')?.style.height) + 'px';
            this.template.querySelector('.initial-table').style.height = (this.template.querySelector('.tableBody')?.style.height) + 'px';
        }
    }

    //GETTTERS
    get acceptedFormats() {
        return ['.pdf', '.png', '.txt', '.docx'];
    }

    get nextDisabled() {
        return (this.pageNumber >= this.totalpagesCount);
    }

    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextProductsDisabled() {
        return (this.productsPageNumber >= this.totalProductsPagesCount);
    }

    get previousProductsDisabled() {
        return (this.productsPageNumber <= 1);
    }

    get fixedColumnsOptions() {
        return [{ label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5', value: '5' },
        { label: '6', value: '6' }];
    }
    get isDisplayLastTD() {
        return this.allowOpenRecord || this.allowDelete;
    }
    get hasFields() {
        return this.fieldsToFilter && this.fieldsToFilter.length > 0 && this.fieldsToFilter.some(item => item.hasOwnProperty('userFilterable') && item.userFilterable && !this.mainWrapper.gridSettings.isShowFilterOnColumnHeader);
    }
    get hasAdvancedFields() {
        return false && (this.multilevelFields && this.multilevelFields.length > 0 && this.multilevelFields.some(item => item.hasOwnProperty('userFilterable') && item.userFilterable));
    }
    get tableStyle() {
        return (this.cmpHeight ? 'height: ' + this.cmpHeight + ';' : '');
    }
}