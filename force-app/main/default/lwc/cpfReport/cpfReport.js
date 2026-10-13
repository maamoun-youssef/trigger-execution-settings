import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadStyle, loadScript } from "lightning/platformResourceLoader";

import loadData from '@salesforce/apex/CPFReportController.loadData';
import saveCPF from '@salesforce/apex/CPFReportController.saveCPF';
import deleteCP from '@salesforce/apex/CPFReportController.deleteCP';

import CommercialPlanFollowup__OBJECT from '@salesforce/schema/CommercialPlanFollowup__c';
import QuantityGap__c from '@salesforce/schema/CommercialPlanFollowup__c.QuantityGap__c';
import ValueGap__c from '@salesforce/schema/CommercialPlanFollowup__c.ValueGap__c';
import VolumeGap__c from '@salesforce/schema/CommercialPlanFollowup__c.VolumeGap__c';
import CommercialPlan__OBJECT from '@salesforce/schema/CommercialPlan__c';
import Hierarchy__c from '@salesforce/schema/CommercialPlan__c.Hierarchy__c';
import Status__c from '@salesforce/schema/CommercialPlan__c.Status__c';
import SellOutBDate__c from '@salesforce/schema/CommercialPlan__c.SellOutBDate__c';
import SellOutEDate__c from '@salesforce/schema/CommercialPlan__c.SellOutEDate__c';
import Supplier__c from '@salesforce/schema/CommercialPlan__c.Supplier__c';
import BusinessUnitTarget__c from '@salesforce/schema/CommercialPlan__c.BusinessUnitTarget__c';

const Hierarchy__r = { fieldApiName: Hierarchy__c.fieldApiName.replace(/__c$/g, '__r') };

import cpfReport from '@salesforce/resourceUrl/cpfReport';
import CPFReportBRIcon from '@salesforce/resourceUrl/CPFReportBRIcon';

import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_CPF_BR_Report from "@salesforce/label/c.LBL_CPF_BR_Report";
import LBL_CPF_Report from "@salesforce/label/c.LBL_CPF_Report";
import LBL_KPI_filter from "@salesforce/label/c.LBL_KPI_filter";
import LBL_Budget_Type from "@salesforce/label/c.LBL_Budget_Type";
import LBL_Show_Hide_Columns from "@salesforce/label/c.LBL_Show_Hide_Columns";
import LBL_Select_Columns from "@salesforce/label/c.LBL_Select_Columns";
import LBL_Available from "@salesforce/label/c.LBL_Available";
import LBL_Selected from "@salesforce/label/c.LBL_Selected";
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_Export_To_Excel from "@salesforce/label/c.LBL_Export_To_Excel";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_Ok from "@salesforce/label/c.LBL_Ok";
import MSG_Confirm_Delete from "@salesforce/label/c.MSG_Confirm_Delete";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";

export default class CpfReport extends NavigationMixin(LightningElement) {

    @api recordId;
    @api displayReviewData;
    @track loadingData = false;
    API_NAMES = {
        commercialPlan: {
            objectApiName: CommercialPlan__OBJECT.objectApiName,
            Hierarchy__c: Hierarchy__c.fieldApiName,
            Status__c: Status__c.fieldApiName,
            Supplier__c: Supplier__c.fieldApiName,
            BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
        },
    }
    chidlrensMap = new Map();
    wFollowUpMap;
    statusPicklistValues = [];
    CPLayerNumbers;
    listOfDoubleRole = []
    colorsMap = {
        'white': '#dddddd96',
        '#dddddd96': 'white'
    };
    CPLayerIndex = 1;
    statusColors = [];
    editableFields = {};
    nbOfFixedColumns = '4';
    budgetTypeHeaderColors = ['#14BBBB', '#61BCA5', '#00E0E0', '#0C99CC', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''];
    currentCommercialPlan = {
        Id: '',
        Name: '',
        detailPopupFields: []
    }
    fieldToDisplay = [SellOutBDate__c.fieldApiName, SellOutEDate__c.fieldApiName, Supplier__c.fieldApiName, BusinessUnitTarget__c.fieldApiName];
    toDeleteData = [];
    changedIds = [];
    selectedKPI = [];
    packagePrefix = '';
    @track isFilterOpen;
    @track budgetTypeOptions = [];
    @track CPFDataArray = [];
    @track reviewFieldsData = [];
    @track budgetTypeList = [];
    @track budgetTypesListDisplayed = [];
    @track headerFields = [];
    @track label = {
        LBL_No_Item_To_Display,
        LBL_Filter,
        LBL_Search,
        LBL_Reset,
        LBL_Save,
        LBL_Cancel,
        MSG_Successfully_Saved,
        LBL_Success,
        LBL_CPF_BR_Report,
        LBL_CPF_Report,
        LBL_KPI_filter,
        LBL_Budget_Type,
        LBL_Show_Hide_Columns,
        LBL_Select_Columns,
        LBL_Available,
        LBL_Selected,
        LBL_Yes,
        LBL_Export_To_Excel,
        LBL_Number_Of_Fixed_Columns,
        LBL_Ok,
        MSG_Confirm_Delete,
        LBL_Delete,
        LBL_Confirm,
        commPlanFollowupObjInfo: {},
        commPlanObjInfo: {}
    }
    @track isExcelBtnDisplayed = false;
    @track isMonthBtnDisplayed = false;
    @track isBuReviewBtnDisplayed = false;
    @track isExecBuReviewActionDisplayed = false;
    @track isRequestForAppActionDisplayed = false;
    @track CPFReportBRIcon = '';
    @track isEditCpModelOpen;
    @track isDeleteRow = false;
    @track newLoad = true;
    @track toSaveData = [];
    @track advancedFilterParameter = {
        categoryParam: '',
        statusParam: '',
        buTargetParam: '',
        clientParam: '',
    };
    get fixedColumnsOptions() {
        return [
            //     { label: '1', value: '1' },
            // { label: '2', value: '2' },
            // { label: '3', value: '3' },
            { label: '4', value: '4' },
            { label: '5', value: '5' },
            { label: '6', value: '6' }];
    }
    get isEmptyData() {
        return this.CPFDataArray.length == 0
    }
    //SET THE ORGA BU ID
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }

    @wire(getObjectInfo, { objectApiName: CommercialPlanFollowup__OBJECT }) objectInfoCPF({ error, data }) {
        if (data) {
            this.label.commPlanFollowupObjInfo.apiName = data.apiName;
            this.label.commPlanFollowupObjInfo.label = data.label;
        } else if (error) {
            this.toastMsg('ERROR', error, 'ERROR');
        }
    }

    @wire(getObjectInfo, { objectApiName: CommercialPlan__OBJECT }) objectInfoCP({ error, data }) {
        if (data) {
            this.label.commPlanObjInfo.apiName = data.apiName;
            this.label.commPlanObjInfo.label = data.label;
            this.label.commPlanObjInfo.cpCategory = data.fields[Hierarchy__c.fieldApiName].label;
            this.label.commPlanObjInfo.cpStatus = data.fields[Status__c.fieldApiName].label;
            this.label.commPlanObjInfo.cpSupplier = data.fields[Supplier__c.fieldApiName].label;
            this.label.commPlanObjInfo.cpBUTarget = data.fields[BusinessUnitTarget__c.fieldApiName].label;
        } else if (error) {
            this.toastMsg('ERROR', error, 'ERROR');
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Status__c })
    statusValues({ error, data }) {
        if (data) {
            for (let status of data.values) {
                this.statusPicklistValues.push({ label: status.label, value: status.value });
            }
        } else {
            console.log(error);
        }
    }

    connectedCallback() {
        this.loadData(true);
        window.addEventListener('resize', this.changeHeight);
        Promise.all([
            loadStyle(this, cpfReport),
            loadScript(this, ExcelJSURL)
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style')
        });
        this.CPFReportBRIcon = CPFReportBRIcon;
        this.setTableDimension();
        const lightBorderStyle = document.createElement('style');
        lightBorderStyle.innerText = '.lightBtnBorderColor button{ border-color: #d9d7d7}';
        document.body.appendChild(lightBorderStyle);
    }
    renderedCallback() {
        this.setTableDimension();
        // if (this.newLoad && this.template.querySelector('.main-table') && this.template.querySelector('.main-table').rows[0].children[0].clientWidth) {
        //     this.setSticky();
        //     this.newLoad = false;
        // }
    }
    // setTableDimension
    setTableDimension() {
        let header = this.template.querySelector('.header');
        let tablecontainer = this.template.querySelector('.main-panel');
        if (header) {
            //Set table Height
            let headerHeight = header.getBoundingClientRect().height;
            let tableTableHeight = window.innerHeight - headerHeight - (4 * 32);
            this.tableStyleHeight = 'background-color: #FFFFFF !important; width: -webkit-fill-available; height:' + (tableTableHeight - 32) + 'px';
            if (tablecontainer)
                tablecontainer.style.height = (tableTableHeight) + 'px';
            // Set Filter Height
            if (this.template.querySelector('.filter-section')) {
                this.template.querySelector('.filter-section').style.height = (tableTableHeight) + 'px';
                // this.template.querySelector('.filter-section').style.width = (tableTableHeight) + 'px';
            }
        }
    }
    changeHeight = () => this.setTableDimension();
    @track kpiFieldsMap = [];
    //load data 
    loadData(firstLoad) {
        this.loadingData = true;
        loadData({ recordId: this.recordId, FilterParameterJSON: JSON.stringify(this.advancedFilterParameter) }).then((result) => {
            let parsedResult = JSON.parse(result);
            if (firstLoad) {
                this.packagePrefix = parsedResult.packagePrefix;
                this.reviewFieldsData = parsedResult.reviewFields;
                this.budgetTypeList = parsedResult.budgetTypeList;
                this.kpiFieldsMap = [];
                for (var key in parsedResult.kpiFieldsMap) {
                    this.kpiFieldsMap.push({ key: key, value: parsedResult.kpiFieldsMap[key] || [] });
                }
                this.budgetTypeOptions = [];
                for (let i = 0; i < this.budgetTypeList.length; i++) {
                    let bt = {
                        label: this.budgetTypeList[i].label,
                        value: this.budgetTypeList[i].value,
                        backgroundColor: this.budgetTypeHeaderColors[i],
                        color: 'background-color:' + this.budgetTypeHeaderColors[i] + ';color:white;',
                        filterStyle: 'color:white;background-color:' + this.budgetTypeHeaderColors[i] + ';width:60px;min-width:60px;max-width:60px;text-align:center;white-space:pre-wrap;',
                        style: 'background-color:' + this.budgetTypeHeaderColors[i] + '  !important;color:' + this.budgetTypeHeaderColors[i] + ' !important;width: 10px;height: 10px;display: inline-block;cursor: pointer;margin: auto;',
                        checked: true,//this.budgetTypeList[i].isDefault,
                    }
                    let kpiFields = this.kpiFieldsMap ? this.kpiFieldsMap.filter(item => item.key === bt.value).map(item => item.value) : [];
                    if (kpiFields && kpiFields.length) {
                        this.budgetTypeOptions.push(bt);
                    }
                }
                this.CPLayerNumbers = parsedResult.promoSettings.CPLayerNumbers;
                this.isBuReviewBtnDisplayed = this.displayReviewData ? false : parsedResult.promoSettings.availableButtons.filter(el => el == 'Business Review').length != 0;
                this.isExcelBtnDisplayed = parsedResult.promoSettings.availableButtons.filter(el => el == 'Export Excel').length != 0;
                this.isMonthBtnDisplayed = parsedResult.promoSettings.availableButtons.filter(el => el == 'Month x Month').length != 0;
                this.isExecBuReviewActionDisplayed = parsedResult.promoSettings.availableActions.filter(el => el == 'Exec Business Review').length != 0;
                this.isRequestForAppActionDisplayed = parsedResult.promoSettings.availableActions.filter(el => el == 'Request an approval').length != 0;
            }
            this.wFollowUpMap = new Map(Object.entries(parsedResult.wFollowUpMap));
            this.chidlrensMap = {};
            if (parsedResult.chidlrensMap != {}) {
                this.chidlrensMap = new Map(Object.entries(parsedResult.chidlrensMap));
            }
            this.statusColors = [];
            if (parsedResult.promoSettings.CPStatusColor1) {
                for (let key of Object.keys(parsedResult.promoSettings.CPStatusColor1)) {
                    this.statusColors.push({ value: key, color: parsedResult.promoSettings.CPStatusColor1[key].clr.trim(), bgcolor: parsedResult.promoSettings.CPStatusColor1[key].bg.trim() });
                }
            }
            if (parsedResult.promoSettings.CPStatusColor2) {
                for (let key of Object.keys(parsedResult.promoSettings.CPStatusColor2)) {
                    this.statusColors.push({ value: key, color: parsedResult.promoSettings.CPStatusColor2[key].clr.trim(), bgcolor: parsedResult.promoSettings.CPStatusColor2[key].bg.trim() });
                }
            }
            if (parsedResult.promoSettings.CPStatusColor3) {
                for (let key of Object.keys(parsedResult.promoSettings.CPStatusColor3)) {
                    this.statusColors.push({ value: key, color: parsedResult.promoSettings.CPStatusColor3[key].clr.trim(), bgcolor: parsedResult.promoSettings.CPStatusColor3[key].bg.trim() });
                }
            }
            if (parsedResult.promoSettings.CPStatusColor4) {
                for (let key of Object.keys(parsedResult.promoSettings.CPStatusColor4)) {
                    this.statusColors.push({ value: key, color: parsedResult.promoSettings.CPStatusColor4[key].clr.trim(), bgcolor: parsedResult.promoSettings.CPStatusColor4[key].bg.trim() });
                }
            }
            this.buildData();
        }).catch(error => {
            this.loadingData = false;
            console.log('error: ' + error.message);
            console.error(error);
        });
    }
    // build data structure
    buildData() {
        this.CPLayerIndex = 1;
        this.budgetTypesListDisplayed = [];
        for (let budgettype of this.budgetTypeOptions) {
            if (budgettype.checked) {
                this.budgetTypesListDisplayed.push(budgettype)
            }
        }
        this.headerFields = [];
        for (let type of this.budgetTypesListDisplayed) {
            let kpiFields = this.kpiFieldsMap ? this.kpiFieldsMap.filter(item => item.key === type.value).map(item => item.value) : [];
            let headerField = {
                label: type.label,
                color: type.color,
                fields: !this.displayReviewData ? JSON.parse(JSON.stringify(kpiFields[0])) : JSON.parse(JSON.stringify(this.reviewFieldsData)),
            }
            this.headerFields.push(headerField);
        }
        this.CPFDataArray = [];
        let dataFiltered = [];
        for (let cp of this.chidlrensMap.keys()) {
            let cpParent = this.buildCPParentWrapper(cp);
            for (let child of this.chidlrensMap.get(cp)) {
                let cpChild = this.buildChildFollowUpWrapper(cp, child);
                if (this.chidlrensMap.has(child)) {
                    this.listOfDoubleRole.push({ child: child, parent: cp })
                }
                cpParent.cpChildren.push(cpChild);
            }
            dataFiltered.push(cpParent);
        }
        if (this.chidlrensMap.size == 0) {
            let keys;
            let firstKey = '';
            this.budgetTypeList.forEach((item) => {
                if (this.wFollowUpMap.has(item.value) && this.wFollowUpMap.get(item.value) != undefined && firstKey == '') {
                    keys = Object.keys(this.wFollowUpMap.get(item.value));
                    firstKey = keys[0];
                }
            });
            let cpParent = this.buildCPParentWrapper(firstKey)
            dataFiltered.push(cpParent);
        }

        this.fillHierarchyData(dataFiltered);
        this.loadingData = false;
    }
    // fill parent/child data
    fillHierarchyData(dataList) {
        try {
            for (let cp of dataList) {
                if (this.listOfDoubleRole.filter(el => el.child == cp.cpId).length != 0) {
                    let parent = this.listOfDoubleRole.filter(el => el.child == cp.cpId)[0].parent;
                    let child = this.listOfDoubleRole.filter(el => el.child == cp.cpId)[0].child;
                    let parentIndex = dataList.findIndex(cp => cp.cpId == parent);
                    let childIndex = dataList.findIndex(cp => cp.cpId == child);
                    let childIndex1 = dataList[parentIndex].cpChildren.findIndex(cp => cp.cpId == child);
                    dataList[parentIndex].cpChildren[childIndex1] = dataList[childIndex];
                    dataList[parentIndex].canBeParent = true;
                }
            }
            for (let childf of this.listOfDoubleRole) {
                let duplicated = dataList.findIndex(el => el.cpId == childf.child)
                if (duplicated != -1) {
                    dataList.splice(duplicated, 1)
                }
            }
            this.checkIfCanBeParent(dataList);
            this.CPFDataArray = [...dataList];
        } catch (error) {

        }
    }
    checkIfCanBeParent(data) {
        for (let promo of data) {
            promo.canBeParent = true;
            this.CPLayerIndex++;
            if (this.CPLayerIndex < this.CPLayerNumbers) {
                this.checkIfCanBeParent(promo.cpChildren);
            }
        }
    }
    // build commercial plan parent wrapper
    buildCPParentWrapper(cp) {
        let cpParent = {
            cpName: '',
            cpCategory: '',
            cpCategoryURL: '',
            cpStatus: {
                label: '',
                value: ''
            },
            cpId: cp,
            cpURl: '/' + cp,
            cpPromoScreenURL: '/apex/' + this.packagePrefix + 'NegoptimNavigator?c__componentName=' + this.packagePrefix.replace(/__/g, '') + ':CommercialPlanSimulationLWC&a__recordId=' + cp,
            //cpBRReportScreenURL: '/apex/'+ this.packagePrefix +'NegoptimNavigator?c__componentName='+ this.packagePrefix.replace(/__/g, '') +':cpfReport&a__recordId=' + cp + '&a__displayReviewData=true',
            cpfollowUp: [],
            cpChildren: [],
            isDisplayedChildren: true,
            isShowInfoPanel: false,
            isEditInfoPanel: false,
            isShowInfoIcon: false,
            // isShowIcons: false,
            isShowEditIcon: false,
            statusStyle: "white-space: unset; text-align:center;",
            canBeParent: true,
            get hasChildren() {
                return cpParent.cpChildren.length != 0;
            }

        }
        let followUpList = [];
        for (let bt in this.budgetTypesListDisplayed) {
            let budgetType = {
                Name: '',
                color: '',
                FieldsValues: [],
                isHachured: false
            };
            budgetType.Name = this.budgetTypesListDisplayed[bt].label;
            budgetType.color = this.budgetTypesListDisplayed[bt].backgroundColor;
            let cpfbudgetMap;
            let fieldsData = [];//this.kpiFieldsMap ? this.kpiFieldsMap.filter(item => item.key === budgetType.Name).map(item => item.value) : [];
            if (!this.displayReviewData) {
                fieldsData = this.kpiFieldsMap ? this.kpiFieldsMap.filter(item => item.key === budgetType.Name).map(item => item.value)[0] : [];
            } else {
                fieldsData = this.reviewFieldsData;
            }
            if (this.wFollowUpMap.has(budgetType.Name)) {
                cpfbudgetMap = new Map(Object.entries(this.wFollowUpMap.get(budgetType.Name)));
                if (cpfbudgetMap.has(cp)) {
                    cpParent.cpName = cpfbudgetMap.get(cp).commercialPlan.Name;
                    cpParent.cpStatus.value = cpfbudgetMap.get(cp).commercialPlan[Status__c.fieldApiName];
                    cpParent.cpStatus.label = this.statusPicklistValues.filter(el => el.value == cpfbudgetMap.get(cp).commercialPlan[Status__c.fieldApiName])[0]?.label;
                    cpParent.cpCategory = cpfbudgetMap.get(cp).commercialPlan[Hierarchy__r.fieldApiName]?.Name;
                    cpParent.cpCategoryURL = '/' + cpfbudgetMap.get(cp).commercialPlan[Hierarchy__c.fieldApiName];
                    let cpfData = cpfbudgetMap.get(cp).wFollowUp;
                    let fieldIndex = 0;
                    let style = this.statusColors.filter(el => el.value == cpParent.cpStatus.value);
                    if (style.length != 0) {
                        cpParent.statusStyle += 'background-color:#' + style[0].bgcolor + ';color:#' + style[0].color + ';';
                    }
                    if (fieldsData && fieldsData.length) {
                        for (let field of fieldsData) {
                            let wField = {
                                id: cpfData.Id,
                                fieldApiName: field.fieldName,
                                fieldValue: cpfData[field.fieldName] ? cpfData[field.fieldName] : 0,
                                fieldType: field.fieldType,
                                isDouble: false,
                                isPercent: false,
                                isDate: false,
                                isCurrency: false,
                                isInput: false,
                                scale: field.scale,
                                fieldBgColor: '',
                                fieldColor: '',
                                fieldStyle: ' width: 100px;max-width: 100px; min-width: 100px; ',
                                get isDisplayed() {
                                    return field.isDisplayed;
                                }
                            }
                            switch (wField.fieldType) {
                                case 'DOUBLE':
                                    wField.isDouble = true;
                                    wField.fieldStyle += 'text-align: right;';
                                    wField.fieldStyle += 'padding-right:15px !important;';
                                    break;
                                case 'DATE':
                                    wField.isDate = true;
                                    wField.fieldValue = cpfData[field.fieldName];
                                    break;
                                case 'DATETIME':
                                    wField.isDate = true;
                                    wField.fieldValue = cpfData[field.fieldName];
                                    break;
                                case 'PERCENT':
                                    wField.isPercent = true;
                                    wField.fieldStyle += 'text-align: right;';
                                    wField.fieldStyle += 'padding-right:15px !important;';
                                    break;
                                case 'CURRENCY':
                                    wField.isCurrency = true;
                                    wField.fieldStyle += 'text-align: right;';
                                    wField.fieldStyle += 'padding-right:15px !important;';
                                    break;
                            }
                            if (field.fieldName == VolumeGap__c.fieldApiName || field.fieldName == ValueGap__c.fieldApiName || field.fieldName == QuantityGap__c.fieldApiName) {
                                if (wField.fieldValue >= 0) {
                                    wField.fieldStyle += ' font-weight: bold;color: green;'
                                } else {
                                    wField.fieldStyle += ' font-weight: bold;color: red;'
                                }
                            }
                            if (fieldIndex == fieldsData.length - 1) {
                                //wField.fieldStyle += '; border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
                            }
                            wField.fieldStyle += ' background-color:#595959;color:#FFFFFF;';
                            wField.fieldBgColor = '595959';
                            budgetType.FieldsValues.push(wField);
                            if (wField.isDisplayed)
                                fieldIndex++;
                        }
                    }
                }
            } else {
                budgetType.isHachured = true;
                let wField = {
                    fieldValue: '',
                    fieldStyle: 'width: 100%;height: 44px;',
                    colspan: fieldsData.length
                };
                wField.fieldStyle += ' background: repeating-linear-gradient(135deg, #595959 -15px, ' + budgetType.color + ' 25px);'
                wField.fieldStyle += ' border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
                budgetType.FieldsValues.push(wField);
            }
            followUpList.push(budgetType);
        }
        cpParent.cpfollowUp = followUpList;
        return cpParent;
    }
    // handle input changes
    handleEditFields(event) {
        let fieldname = event.target.dataset.fieldname;
        let type = event.target.dataset.type;
        this.editableFields[type] = [fieldname];
        this.CPFDataArray.forEach(item => {
            if (item.cpChildren.length > 0) {
                item.cpChildren.forEach(children1 => {
                    if (children1.cpChildren.length > 0) {
                        children1.cpChildren.forEach(children2 => {
                            children2.cpfollowUp.forEach(bType => {
                                if (this.editableFields[bType.Name]) {
                                    bType.FieldsValues.forEach(field => {
                                        if (this.editableFields[bType.Name].includes(field.fieldApiName)) {
                                            field.isInput = true;
                                        }
                                    });
                                }
                            });
                        });
                    } else {
                        children1.cpfollowUp.forEach(bType => {
                            if (this.editableFields[bType.Name]) {
                                bType.FieldsValues.forEach(field => {
                                    if (this.editableFields[bType.Name].includes(field.fieldApiName)) {
                                        field.isInput = true;
                                    }
                                });
                            }
                        });
                    }
                });
            } else {
                item.cpfollowUp.forEach(bType => {
                    if (this.editableFields[bType.Name]) {
                        bType.FieldsValues.forEach(field => {
                            if (this.editableFields[bType.Name].includes(field.fieldApiName)) {
                                field.isInput = true;
                            }
                        });
                    }
                });
            }
        });
    }
    // build followup child wrapper
    buildChildFollowUpWrapper(cpParent, cp) {
        let cpChild = {
            cpName: '',
            cpStatus: {
                label: '',
                value: ''
            },
            cpCategory: '',
            cpCategoryURL: '',
            cpId: cp,
            cpURl: '/' + cp,
            cpPromoScreenURL: '/apex/' + this.packagePrefix + 'NegoptimNavigator?c__componentName=' + this.packagePrefix.replace(/__/g, '') + ':CommercialPlanSimulationLWC&a__recordId=' + cp,
            //cpBRReportScreenURL: '/apex/'+ this.packagePrefix +'NegoptimNavigator?c__componentName='+ this.packagePrefix.replace(/__/g, '') +':cpfReport&a__recordId=' + cp + '&a__displayReviewData=true',
            cpfollowUp: [],
            cpChildren: [],
            cpParent: cpParent,
            isDisplayedChildren: true,
            isShowInfoPanel: false,
            canBeParent: false,
            statusStyle: "white-space: unset; text-align:center;",
            get hasChildren() {
                return cpChild.cpChildren.length != 0;
            }
        }
        if (cpParent)
            for (let bt in this.budgetTypesListDisplayed) {
                let budgetType = {
                    Name: '',
                    color: '',
                    FieldsValues: [],
                    isHachured: false
                };
                budgetType.Name = this.budgetTypesListDisplayed[bt].label;
                budgetType.color = this.budgetTypesListDisplayed[bt].backgroundColor;
                let fieldsData = [];//this.kpiFieldsMap ? this.kpiFieldsMap.filter(item => item.key === budgetType.Name).map(item => item.value) : [];
                if (!this.displayReviewData) {
                    fieldsData = this.kpiFieldsMap ? this.kpiFieldsMap.filter(item => item.key === budgetType.Name).map(item => item.value)[0] : [];
                } else {
                    fieldsData = this.reviewFieldsData;
                }
                if (this.wFollowUpMap.has(budgetType.Name)) {
                    let cpfbudgetMap = new Map(Object.entries(this.wFollowUpMap.get(budgetType.Name)));
                    if (cpfbudgetMap.has(cp)) {
                        cpChild.cpName = cpfbudgetMap.get(cp).commercialPlan.Name;
                        cpChild.cpStatus.value = cpfbudgetMap.get(cp).commercialPlan[Status__c.fieldApiName];
                        cpChild.cpStatus.label = this.statusPicklistValues.filter(el => el.value == cpfbudgetMap.get(cp).commercialPlan[Status__c.fieldApiName])[0]?.label
                        cpChild.cpCategory = cpfbudgetMap.get(cp).commercialPlan[Hierarchy__r.fieldApiName]?.Name;
                        cpChild.cpCategoryURL = '/' + cpfbudgetMap.get(cp).commercialPlan[Hierarchy__c.fieldApiName];
                        let cpfollowUp = cpfbudgetMap.get(cp).wFollowUp;
                        let style = this.statusColors.filter(el => el.value == cpChild.cpStatus.value);
                        if (style.length != 0) {
                            cpChild.statusStyle += 'background-color:#' + style[0].bgcolor + ';color:#' + style[0].color + ';';
                        }
                        let fieldIndex = 0;
                        if (fieldsData && fieldsData.length) {
                            for (let field of fieldsData) {
                                let wField = {
                                    id: cpfollowUp.Id,
                                    fieldApiName: field.fieldName,
                                    fieldValue: cpfollowUp[field.fieldName] ? cpfollowUp[field.fieldName] : 0,
                                    fieldType: field.fieldType,
                                    isDouble: false,
                                    isPercent: false,
                                    isDate: false,
                                    isCurrency: false,
                                    isInput: false,
                                    scale: field.scale,
                                    fieldBgColor: '',
                                    fieldColor: '',
                                    fieldStyle: ' width: 100px;max-width: 100px; min-width: 100px; ',
                                    get isDisplayed() {
                                        return field.isDisplayed;
                                    }
                                }
                                switch (wField.fieldType) {
                                    case 'DOUBLE':
                                        wField.isDouble = true;
                                        wField.fieldStyle += 'text-align: right;';
                                        wField.fieldStyle += 'padding-right:15px !important;';
                                        break;
                                    case 'DATE':
                                        wField.isDate = true;
                                        wField.fieldValue = cpfollowUp[field.fieldName];
                                        break;
                                    case 'DATETIME':
                                        wField.isDate = true;
                                        wField.fieldValue = cpfollowUp[field.fieldName];
                                        break;
                                    case 'PERCENT':
                                        wField.isPercent = true;
                                        wField.fieldStyle += 'text-align: right;';
                                        wField.fieldStyle += 'padding-right:15px !important;';
                                        break;
                                    case 'CURRENCY':
                                        wField.isCurrency = true;
                                        wField.fieldStyle += 'text-align: right;';
                                        wField.fieldStyle += 'padding-right:15px !important;';
                                        break;
                                }
                                if (field.fieldName == VolumeGap__c.fieldApiName || field.fieldName == ValueGap__c.fieldApiName || field.fieldName == QuantityGap__c.fieldApiName) {
                                    if (wField.fieldValue >= 0) {
                                        wField.fieldStyle += ' font-weight: bold;color: green;'
                                        wField.fieldColor = '008000'
                                    } else {
                                        wField.fieldStyle += ' font-weight: bold;color: red;'
                                        wField.fieldColor += 'FF0000'
                                    }
                                }
                                if (fieldIndex == fieldsData.length - 1) {
                                    //wField.fieldStyle += ' border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
                                }
                                budgetType.FieldsValues.push(wField);
                                if (wField.isDisplayed)
                                    fieldIndex++;
                            }
                        }
                    }
                } else {
                    budgetType.isHachured = true;
                    let wField = {
                        fieldValue: '',
                        fieldStyle: 'width: 100%;height: 44px;',
                        colspan: fieldsData.length
                    };
                    wField.fieldStyle += ' background: repeating-linear-gradient(135deg, #595959 -15px, ' + budgetType.color + '25px);'
                    wField.fieldStyle += ' border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
                    budgetType.FieldsValues.push(wField);
                }
                cpChild.cpfollowUp.push(budgetType);
            }
        return cpChild;
    }
    // toggle info icon next to the commercial plan name 
    showInfoIcon(event) {
        this.currentCommercialPlan.Id = event.target.dataset.cpId;
        let parentIndex = event.target.dataset.parentIndex;
        if (parentIndex != undefined) {
            let child1Index = event.target.dataset.child1Index;
            if (child1Index != undefined) {
                let child2Index = event.target.dataset.child2Index;
                if (child2Index != undefined) {
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowInfoIcon = true;
                }
                else {
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowInfoIcon = true;
                }
            } else {
                this.CPFDataArray[parentIndex].isShowInfoIcon = true;
            }
        }
    }
    hideInfoIcon(event) {
        this.currentCommercialPlan.Id = event.target.dataset.cpId;
        let parentIndex = event.target.dataset.parentIndex;
        if (parentIndex != undefined) {
            let child1Index = event.target.dataset.child1Index;
            if (child1Index != undefined) {
                let child2Index = event.target.dataset.child2Index;
                if (child2Index != undefined) {
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowInfoIcon = false;
                }
                else {
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowInfoIcon = false;
                }
            } else {
                this.CPFDataArray[parentIndex].isShowInfoIcon = false;
            }
        }
    }
    // toggle info panel and replace info icon with edit icon 
    openInfoPanel(event) {
        this.currentCommercialPlan = {
            Id: '',
            Name: '',
            detailPopupFields: []
        }
        let commercialPlan;
        this.currentCommercialPlan.Id = event.target.dataset.cpId;
        this.currentCommercialPlan.Name = event.target.dataset.cpName;
        let parentIndex = event.target.dataset.parentIndex;
        if (parentIndex != undefined) {
            let child1Index = event.target.dataset.child1Index;
            if (child1Index != undefined) {
                let child2Index = event.target.dataset.child2Index;
                if (child2Index != undefined) {
                    commercialPlan = this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index];
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowInfoPanel = true;
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowEditIcon = true;
                }
                else {
                    commercialPlan = this.CPFDataArray[parentIndex].cpChildren[child1Index];
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowInfoPanel = true;
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowEditIcon = true;
                }
            } else {
                commercialPlan = this.CPFDataArray[parentIndex];
                this.CPFDataArray[parentIndex].isShowInfoPanel = true;
                this.CPFDataArray[parentIndex].isShowEditIcon = true;
            }
        }

        for (let field of this.fieldToDisplay) {
            let fieldObj = {
                fieldApiName: field,
                // value: commercialPlan[field] ? commercialPlan[field] : '',
            }
            this.currentCommercialPlan.detailPopupFields.push(fieldObj);
        }
    }

    closeInfoPanel(event) {
        // this.currentCommercialPlan = {
        //     Id: '',
        //     Name: '',
        //     detailPopupFields: []
        // }
        let commercialPlan;
        this.currentCommercialPlan.Id = event.target.dataset.cpId;
        this.currentCommercialPlan.Name = event.target.dataset.cpName;
        let parentIndex = event.target.dataset.parentIndex;
        if (parentIndex != undefined) {
            let child1Index = event.target.dataset.child1Index;
            if (child1Index != undefined) {
                let child2Index = event.target.dataset.child2Index;
                if (child2Index != undefined) {
                    commercialPlan = this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index];
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowInfoPanel = false;
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowEditIcon = false;
                }
                else {
                    commercialPlan = this.CPFDataArray[parentIndex].cpChildren[child1Index];
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowInfoPanel = false;
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowEditIcon = false;
                }
            } else {
                commercialPlan = this.CPFDataArray[parentIndex];
                this.CPFDataArray[parentIndex].isShowInfoPanel = false;
                this.CPFDataArray[parentIndex].isShowEditIcon = false;
            }
        }
        // for (let field of this.fieldToDisplay) {
        //     let fieldObj = {
        //         fieldApiName: field,
        //         // value: commercialPlan[field] ? commercialPlan[field] : '',
        //     }
        //     this.currentCommercialPlan.detailPopupFields.push(fieldObj);
        // }
    }


    // toggle edit model
    toggleEditCPModel(event) {
        // this.isEditCpModelOpen = !this.isEditCpModelOpen;
        // let parentIndex = event.target.dataset.parentIndex;
        // if (parentIndex != undefined) {
        //     let child1Index = event.target.dataset.child1Index;
        //     if (child1Index != undefined) {
        //         let child2Index = event.target.dataset.child2Index;
        //         if (child2Index != undefined) {
        //             this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowInfoPanel = false;
        //             this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isShowEditIcon = true;
        //         }
        //         else {
        //             this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowInfoPanel = false;
        //             this.CPFDataArray[parentIndex].cpChildren[child1Index].isShowEditIcon = true;
        //         }
        //     } else {
        //         this.CPFDataArray[parentIndex].isShowInfoPanel = false;
        //         this.CPFDataArray[parentIndex].isShowEditIcon = true;
        //     }
        // }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.currentCommercialPlan.Id,
                actionName: 'edit'
            },
            state: {
                nooverride: '1'
            }
        });
    }
    isCompact = true;
    toggleStyle() {
        let rows = this.template.querySelectorAll('.compactStyle');
        if (this.isCompact) {
            rows.forEach(function (row) {
                row.classList.add("confortableStyle");
                row.classList.remove("compactStyle");
            });
        }
        else {
            let rows2 = this.template.querySelectorAll('.confortableStyle');
            if (rows2) {
                rows2.forEach(function (row) {
                    row.classList.toggle('compactStyle');
                    row.classList.remove("confortableStyle");
                });
            }
        }
        this.isCompact = !this.isCompact;
    }
    toggleShowEdit(event) {
        // this.currentCommercialPlan = {
        //     Id: '',
        //     detailPopupFields: []
        // }
        let commercialPlan;
        // this.currentCommercialPlan.Id = event.target.dataset.cpId;
        let parentIndex = event.target.dataset.parentIndex;
        if (parentIndex != undefined) {
            let child1Index = event.target.dataset.child1Index;
            if (child1Index != undefined) {
                let child2Index = event.target.dataset.child2Index;
                if (child2Index != undefined) {
                    commercialPlan = this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index];
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isEditInfoPanel = !this.CPFDataArray[parentIndex].cpChildren[child1Index].cpChildren[child2Index].isEditInfoPanel;
                }
                else {
                    commercialPlan = this.CPFDataArray[parentIndex].cpChildren[child1Index];
                    this.CPFDataArray[parentIndex].cpChildren[child1Index].isEditInfoPanel = !this.CPFDataArray[parentIndex].cpChildren[child1Index].isEditInfoPanel;
                }
            } else {
                commercialPlan = this.CPFDataArray[parentIndex];
                this.CPFDataArray[parentIndex].isEditInfoPanel = !this.CPFDataArray[parentIndex].isEditInfoPanel;
            }
        }
    }
    // get the id to delete
    setToDeleteCP(event) {
        this.isDeleteRow = true;
        let cpToDeleteId = event.target.dataset.cpId;
        this.toDeleteData.push(cpToDeleteId);
    }
    // handle delete in apex
    handleDeleteCp() {
        this.isDeleteRow = false;
        this.loadingData = true;
        // saveCPF({ cpfToSave: JSON.stringify(this.toSaveData) }).then((result) => {
        deleteCP({ cpToDelete: JSON.stringify(this.toDeleteData) }).then((res) => {
            this.showNotification(this.label.LBL_Success, this.label.MSG_Confirm_Delete, 'success');
            this.toDeleteData = [];
            this.loadData(false);
            this.loadingData = false;
        }).catch(error => {
            this.loadingData = false;
            this.showNotification('error', 'delete error', 'error', 'sticky');
            console.error(error);
        });
    }
    // remove id from cp to delete
    handleCancelDeleteCP() {
        this.isDeleteRow = false;
        this.toDeleteData.pop();
    }
    handleCPEdit(event) {
        let id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let value = event.target.value;
        let obj;
        if (this.changedIds.includes(id)) {
            obj = this.toSaveData.filter(item => item.Id == id)[0];
        } else {
            obj = {
                attributes: {
                    type: CommercialPlanFollowup__OBJECT.objectApiName,
                },
                Id: id
            };
        }
        obj[field] = value;
        if (!this.changedIds.includes(id)) {
            this.toSaveData.push(obj);
            this.changedIds.push(id);
        }
    }
    handleSave(event) {
        this.loadingData = true;
        saveCPF({ cpfToSave: JSON.stringify(this.toSaveData) }).then((result) => {
            this.showNotification(this.label.LBL_Success, this.label.MSG_Successfully_Saved, 'success');
            this.editableFields = {};
            this.toSaveData = [];
            this.loadData(false);
            this.loadingData = false;
        }).catch(error => {
            this.loadingData = false;
            this.showNotification('error', 'saving error', 'error', 'sticky');
            console.error(error);
        });
    }
    handleCancel(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
            state: {
                nooverride: '1'
            }
        });
    }
    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }

    fillAdvancedFilter(event) {
        let value = event.target.value;
        let typeParam = event.target.dataset.typeParam;
        this.advancedFilterParameter[typeParam] = value;
        // this.loadData(false);
    }
    openMonthxMonth() {

    }
    //open business review page
    openBusinessReview() {
        var url = '/apex/' + this.packagePrefix + 'NegoptimNavigator?c__componentName=' + this.packagePrefix.replace(/__/g, '') + ':cpfReport&a__recordId=' + this.recordId + '&a__displayReviewData=true'; // get from processing apex response
        window.open(url, "_blank");
    }
    //handle reset filters
    handleReset(event) {
        this.loadingData = true;
        this.nbOfFixedColumns = '4';
        this.budgetTypeOptions = [];
        this.loadData(true);
    }
    handleSearch(event) {
        //this.loadData(false);
        //this.loadingData = false;
        this.buildData();
    }
    handleMultiBudgetType(event) {
        let budgetType = event.target.dataset.budgetType;
        let btIndex = this.budgetTypeOptions.findIndex(el => el.label == budgetType);
        this.budgetTypeOptions[btIndex].checked = !this.budgetTypeOptions[btIndex].checked;
        // if(checked){

        // }
        // if (btIndex == -1) {
        //     // let color = 'background-color:' + this.budgetTypeOptions.filter(el => el.label == budgetType)[0].backgroundColor + ';color:white';
        //     // this.budgetTypesListDisplayed.push({ label: budgetType, color: color , checked: true });

        // } else if (this.budgetTypesListDisplayed.length > 1) {
        //     // this.budgetTypesListDisplayed.splice(btIndex, 1);
        //     this.budgetTypesListDisplayed[btIndex].checked = false;
        // }
        this.buildData();
    }
    handleCollapseChidlren(event) {
        this.CPFDataArray[event.target.dataset.index].isDisplayedChildren = !this.CPFDataArray[event.target.dataset.index].isDisplayedChildren;
    }
    handleCollapseChidlren1(event) {
        this.CPFDataArray[event.target.dataset.parentIndex].cpChildren[event.target.dataset.index].isDisplayedChildren = !this.CPFDataArray[event.target.dataset.parentIndex].cpChildren[event.target.dataset.index].isDisplayedChildren;
    }
    setnumberOfFixedColumns(event) {
        this.nbOfFixedColumns = event.detail.value;
        this.setSticky();
    }
    setSticky() {
        let tableTrs = this.template.querySelector('.main-table')?.rows;
        for (let index = 0; tableTrs && index < tableTrs.length; index++) {
            let fixColumns = index == 0 ? this.nbOfFixedColumns - 3 : this.nbOfFixedColumns;
            let childrens = tableTrs[index].children;
            let left = 0;
            for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                if (index2 < fixColumns) {
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.left = left + 'px';
                    childrens[index2].style.zIndex = index2 == 0 ? 8 : 4;
                    left += childrens[index2].offsetWidth;
                    childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                } else {
                    childrens[index2].style.position = 'unset';
                    childrens[index2].style.left = 'unset';
                    childrens[index2].style.zIndex = 'unset';
                }
            }
        }
    }
    openPromoScreen(event) {
        let screenLink = event.target.dataset.screenLink;
        window.open(screenLink, '_blank');
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
    // export Excel JS
    exportExcelJS() {
        try {
            let data = this.CPFDataArray;
            let fields = [];
            const workbook = new ExcelJS.Workbook();
            workbook.properties.date1904 = true;
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet('CPF Report', { properties: { tabColor: { argb: 'worksheet' } } });
            let columns = [];
            let columnsColors = ['0d807d', '0d807d', '0d807d'];
            this.headerFields.forEach((bt, index) => {
                let color = this.budgetTypeOptions.filter(el => el.label == bt.label)[0].backgroundColor.substring(1)
                bt.fields.forEach(field => {
                    field.fieldStyle = color;
                    if (field.isDisplayed) {
                        columnsColors.push(color)
                        fields.push(field);
                    }
                });
            });

            //commercialPlan column
            let cpItem = {
                header: '', width: 50, style: {}
            };
            columns.push(cpItem);
            //commercialPlan category column
            let cpCategItem = {
                header: this.label.commPlanObjInfo.cpCategory, width: 20, style: {}
            };
            columns.push(cpCategItem);
            //commercialPlan status column
            let cpStatusItem = {
                header: this.label.commPlanObjInfo.cpStatus, width: 20, style: {}
            };
            columns.push(cpStatusItem);
            fields.forEach((field, index) => {
                let newItem = {
                    header: field.fieldName, width: field?.fieldLabel?.length, style: {}
                };
                if (field.isNumber || field.isCurrency) {
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
            worksheet.columns = columns;
            //fields Label
            const headerApisRow = worksheet.getRow(1);
            headerApisRow.hidden = true;
            let headerValues = ['', this.label.commPlanObjInfo.cpCategory, this.label.commPlanObjInfo.cpStatus, ...fields.map(field => field.fieldLabel)];
            const headerRow = worksheet.getRow(2);
            headerRow.height = 27;
            headerRow.values = headerValues;
            let cc = 0;
            headerRow.eachCell(function (cell,) {
                let headerbgcolor = columnsColors[cc];
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: headerbgcolor },
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
                cc++;
            });
            let rowIndex = 3;
            data.forEach(item => {
                let dataRow = worksheet.getRow(rowIndex);
                let newRow = [item.cpName, item.cpCategory, item.cpStatus.label];
                let rowsBgColors = ['595959', '595959']
                let rowsColors = ['FFFFFF', 'FFFFFF']
                let style = this.statusColors.filter(el => el.value == item.cpStatus.value);
                if (style.length != 0) {
                    rowsBgColors.push(style[0].bgcolor);
                    rowsColors.push(style[0].color);
                }
                item.cpfollowUp.forEach(type => {
                    type.FieldsValues.forEach(field => {
                        if (field.isDisplayed) {
                            if (field.isBoolean) {
                                if (field.fieldValue) {
                                    newRow.push('✓');
                                } else {
                                    newRow.push('✗');
                                }
                            } else if (field.isPicklist) {
                                let picklistValue = field.fieldValue || '';
                                if (field.fieldValue && field.pickListValueMap && field.pickListValueMap.hasOwnProperty(field.fieldValue)) {
                                    picklistValue = field.pickListValueMap[field.fieldValue];
                                }
                                newRow.push(picklistValue);
                            } else if (field.isMultiPicklist) {
                                let picklistValue = field.fieldValue || '';
                                if (field.fieldValue && field.fieldValue.length) {
                                    picklistValue = field.fieldValue.map(val => {
                                        val = val.trim();
                                        return field.pickListValueMap && field.pickListValueMap.hasOwnProperty(val) ? field.pickListValueMap[val] : val;
                                    }).join(';');
                                }
                                newRow.push(picklistValue);
                            } else if (field.isText) {
                                if (field.fieldValue?.includes('<br>')) {
                                    newRow.push(field.fieldValue.replaceAll('<br>', '\n'));
                                } else {
                                    newRow.push(field.fieldValue);
                                }
                            } else if (field.isDate) {
                                newRow.push(new Date(field.dateValue));
                            } else if (field.isDateTime) {
                                newRow.push(field.dateTimeValue);
                            } else if (field.isReference) {
                                newRow.push(field.refValue);
                            } else {
                                newRow.push(field.fieldValue);
                            }
                            rowsBgColors.push(field.fieldBgColor);
                            rowsColors.push('FFFFFF');
                        }
                    });
                })
                dataRow.values = newRow;
                let colorIndex = 0;
                dataRow.eachCell(function (cell,) {
                    let rowbgcolor = rowsBgColors[colorIndex];
                    let rowcolor = rowsColors[colorIndex];
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: rowbgcolor }
                    };
                    cell.font = {
                        'bold': true,
                        color: { argb: rowcolor },
                    };
                    cell.border = {
                        top: { style: 'thin', color: { argb: 'E6E6E6' } },
                        left: { style: 'thin', color: { argb: 'E6E6E6' } },
                        bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                        right: { style: 'thin', color: { argb: 'E6E6E6' } }
                    };
                    colorIndex++;
                });
                rowIndex++;
                if (item.cpChildren.length > 0) {
                    item.cpChildren.forEach(c1 => {
                        let dataRow1 = worksheet.getRow(rowIndex);
                        let newRow1 = [c1.cpName, c1.cpCategory, c1.cpStatus.label];
                        let rowsBgColors1 = ['', '']
                        let rowsColors1 = ['', '']
                        let style = this.statusColors.filter(el => el.value == c1.cpStatus.value);
                        if (style.length != 0) {
                            rowsBgColors1.push(style[0].bgcolor);
                            rowsColors1.push(style[0].color);
                        }
                        c1.cpfollowUp.forEach(type => {
                            type.FieldsValues.forEach(field => {
                                if (field.isDisplayed) {
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
                                    } else if (field.isDate) {
                                        newRow1.push(new Date(field.dateValue));
                                    } else if (field.isDateTime) {
                                        newRow1.push(field.dateTimeValue);
                                    } else if (field.isReference) {
                                        newRow1.push(field.refValue);
                                    } else {
                                        newRow1.push(field.fieldValue);
                                    }
                                    rowsBgColors1.push(field.fieldBgColor);
                                    rowsColors1.push(field.fieldColor);
                                }
                            });
                        })
                        dataRow1.values = newRow1;
                        let colorIndex1 = 0;
                        dataRow1.eachCell(function (cell,) {
                            let rowbgcolor = rowsBgColors1[colorIndex1];
                            let rowcolor = rowsColors1[colorIndex1];
                            cell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: rowbgcolor }
                            };
                            if (rowcolor != '')
                                cell.font = {
                                    'bold': true,
                                    color: { argb: rowcolor },
                                };
                            cell.border = {
                                top: { style: 'thin', color: { argb: 'E6E6E6' } },
                                left: { style: 'thin', color: { argb: 'E6E6E6' } },
                                bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                                right: { style: 'thin', color: { argb: 'E6E6E6' } }
                            };
                            colorIndex1++;
                        });
                        rowIndex++;
                        if (c1.cpChildren.length > 0) {
                            c1.cpChildren.forEach(c2 => {
                                let dataRow2 = worksheet.getRow(rowIndex);
                                let newRow2 = [c2.cpName, c2.cpCategory, c2.cpStatus.label];
                                let rowsBgColors2 = ['', '']
                                let rowsColors2 = ['', '']
                                let style = this.statusColors.filter(el => el.value == c2.cpStatus.value);
                                if (style.length != 0) {
                                    rowsBgColors2.push(style[0].bgcolor);
                                    rowsColors2.push(style[0].color);
                                }
                                c2.cpfollowUp.forEach(type => {
                                    type.FieldsValues.forEach(field => {
                                        if (field.isDisplayed) {
                                            if (field.isBoolean) {
                                                if (field.fieldValue) {
                                                    newRow2.push('✓');
                                                } else {
                                                    newRow2.push('✗');
                                                }
                                            } else if (field.isPicklist) {
                                                let picklistValue = field.fieldValue || '';
                                                if (field.fieldValue && field.pickListValueMap && field.pickListValueMap.hasOwnProperty(field.fieldValue)) {
                                                    picklistValue = field.pickListValueMap[field.fieldValue];
                                                }
                                                newRow2.push(picklistValue);
                                            } else if (field.isMultiPicklist) {
                                                let picklistValue = field.fieldValue || '';
                                                if (field.fieldValue && field.fieldValue.length) {
                                                    picklistValue = field.fieldValue.map(val => {
                                                        val = val.trim();
                                                        return field.pickListValueMap && field.pickListValueMap.hasOwnProperty(val) ? field.pickListValueMap[val] : val;
                                                    }).join(';');
                                                }
                                                newRow2.push(picklistValue);
                                            } else if (field.isText) {
                                                if (field.fieldValue?.includes('<br>')) {
                                                    newRow2.push(field.fieldValue.replaceAll('<br>', '\n'));
                                                } else {
                                                    newRow2.push(field.fieldValue);
                                                }
                                            } else if (field.isDate) {
                                                newRow2.push(new Date(field.dateValue));
                                            } else if (field.isDateTime) {
                                                newRow2.push(field.dateTimeValue);
                                            } else if (field.isReference) {
                                                newRow2.push(field.refValue);
                                            } else {
                                                newRow2.push(field.fieldValue);
                                            }
                                            rowsBgColors2.push(field.fieldBgColor);
                                            rowsColors2.push(field.fieldColor);
                                        }
                                    });
                                })
                                dataRow2.values = newRow2;
                                let colorIndex2 = 0;
                                dataRow2.eachCell(function (cell,) {
                                    let rowbgcolor = rowsBgColors2[colorIndex2];
                                    let rowcolor = rowsColors2[colorIndex2];
                                    cell.fill = {
                                        type: 'pattern',
                                        pattern: 'solid',
                                        fgColor: { argb: rowbgcolor }
                                    };
                                    if (rowcolor != '')
                                        cell.font = {
                                            'bold': true,
                                            color: { argb: rowcolor },
                                        };
                                    cell.border = {
                                        top: { style: 'thin', color: { argb: 'E6E6E6' } },
                                        left: { style: 'thin', color: { argb: 'E6E6E6' } },
                                        bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                                        right: { style: 'thin', color: { argb: 'E6E6E6' } }
                                    };
                                    colorIndex2++;
                                });
                                rowIndex++;
                            });
                        }
                    });
                }
            });
            worksheet._rows[0]._cells.forEach(cell => {
                cell.protection = { locked: true, lockText: false };
            });
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement("a");
                document.body.appendChild(a);
                a.style = "display: none";
                let base64Bin = result.toString('base64');
                a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
                a.download = 'CPF Report.xlsx'; //File name Here
                a.click();
                //setTimeout(() => { if (callback) { callback(); } }, 600);
                this.loadingtable = false;
            });
            this.allRecordToExport = [];
        } catch (error) {
            this.loadingtable = false;
            console.log('error: ' + error)
        }
    }
}