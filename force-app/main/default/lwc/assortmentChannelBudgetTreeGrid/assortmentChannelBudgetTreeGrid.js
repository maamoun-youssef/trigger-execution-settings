import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import loadGridData from '@salesforce/apex/AssortmentChannelBudgetCtrl.loadGridData';
import loadTreeData from '@salesforce/apex/AssortmentChannelBudgetCtrl.loadTreeData';

import Hierarchy__c from '@salesforce/schema/AssortmentDetail__c.Hierarchy__c';
import Product__c from '@salesforce/schema/AssortmentDetail__c.Product__c';
import Assortment__c from '@salesforce/schema/AssortmentDetail__c.Assortment__c';
import BusinessUnitTarget__c from '@salesforce/schema/Assortment__c.BusinessUnitTarget__c';
import Status__c from '@salesforce/schema/Assortment__c.Status__c';
import LongName__c from '@salesforce/schema/Assortment__c.LongName__c';
import WDChannelBaseTarget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget__c';
import WDChannelBaseTarget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget_NegoL4LP1Gap__c';
import ASSORTMENT_OBJECT from '@salesforce/schema/Assortment__c';
import ASSORTMENTDETAIL_OBJECT from '@salesforce/schema/AssortmentDetail__c';

const ALIGN_TEXT_RIGHT = 'slds-text-align--right';
const ARROW_UP_CLASS = 'arrowup';
const ARROW_DOWN_CLASS = 'arrowdown';
const numberTypes = ['DOUBLE', 'INTEGER', 'PERCENT', 'LONG', 'CURRENCY'];
export default class AssortmentBudgetTreeGridExt extends LightningElement {

    @api recordId;
    @track filters = {
        buTarget: [],
        categories: [],
        productGTIN: '',
        brand: '',
        priority: '',
    }
    label = {}
    resultsW;
    buTargetList = [];
    budgetFieldsList = [];
    negoFieldsList = [];
    isFirstLoad = true;
    @track CurrentAssortment;
    @track assortmentLongName;
    @track assortmentDetailObjName;
    @track assortmentDetailCategory;
    @track channelBU = {};
    @track ASDFields = {};
    @track loadingData = true;
    @track categoryWList = [];
    @track buTargetOptions = [];
    //SET THE Assortment ID
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }

    //WIRES
    @wire(getObjectInfo, { objectApiName: ASSORTMENT_OBJECT.objectApiName }) objectInfoAssortment({ error, data }) {
        if (data) {
            // console.log('data >>>> ' + JSON.stringify(data))
            this.label.AssortmentLabel = data.label;
        } else if (error) {
            console.log('ERROR');
        }
    }
    //WIRES
    @wire(getObjectInfo, { objectApiName: ASSORTMENTDETAIL_OBJECT.objectApiName }) objectInfoAssortmentDetail({ error, data }) {
        if (data) {
            this.ASDFields = data.fields;
        } else if (error) {
            console.log('ERROR');
        }
    }

    @track data = [];
    @track headers = [];

    @track dataHeaders = [];
    @track treeData = [];
    @track loading = true;
    @track justOneHeaderDisplayed;

    @track headerValue = '';
    @track fieldValue = '';

    @api jsonData = '';
    @api jsonHeaders = '';
    @api scale = '';
    @api hideHistory = false;
    @api hideArrows = false;


    connectedCallback() {
        this.loadData();
        window.addEventListener('resize', this.changeHeight);
    }

    rendered = false;
    renderedCallback() {
        this.setnumberOfFixedColumns();
        let header = this.template.querySelector('.header');
        let body = this.template.querySelector('.main-panel');
        if (!this.rendered && header && body) {
            this.changeHeight();
            this.rendered = true;
        }
    }
    changeHeight = () => this.setTableDimension();
    // setTableDimension
    setTableDimension() {
        let header = this.template.querySelector('.header');
        let body = this.template.querySelector('.main-panel');
        if (header && body) {
            //Set table Height
            let headerHeight = header.getBoundingClientRect().height;
            this.template.querySelector('.main-panel').style.height = window.innerHeight - headerHeight - (4 * 45) + 'px';
            // Set Filter Height
            if (this.template.querySelector('.filter-section')) {
                this.template.querySelector('.filter-section').style.height = window.innerHeight - headerHeight - (4 * 45) + 'px';
            }
        }
    }
    fieldsMap = {};
    loadData() {
        this.loadingData = true;
        loadGridData({ assortmentId: this.recordId, filtersSerialized: JSON.stringify(this.filters) }).then((res) => {
            // console.log('res: ' + res);
            this.resultsW = JSON.parse(res);
            this.fieldsMap = this.resultsW.fieldsMap;
            if (this.isFirstLoad) {
                this.CurrentAssortment = this.resultsW.budgetAssortment;
                this.channelBU = { Id: this.CurrentAssortment[BusinessUnitTarget__c.fieldApiName], Name: this.CurrentAssortment[BusinessUnitTarget__c.fieldApiName.replace('__c', '__r')].Name, url: this.CurrentAssortment[BusinessUnitTarget__c.fieldApiName], style: 'background-color: #14b3bb;color:white;' }
                this.assortmentLongName = this.CurrentAssortment[LongName__c.fieldApiName];

                if (this.resultsW.assTargetList) {
                    for (let buTarget of this.resultsW.assTargetList) {
                        this.buTargetList.push({ Name: buTarget.Name, Id: buTarget.Id, url: '/' + buTarget.Id, style: 'background-color: #85DBDB;color:white;', isDisplayed: true });
                        this.buTargetOptions.push({ value: buTarget.Id, label: buTarget.Name });
                        this.filters.buTarget.push(buTarget.Id);
                    }
                }
                if (this.resultsW.budgetASDFields) {
                    let index = 0;
                    for (let field of this.resultsW.budgetAssAPIFields) {
                        this.budgetFieldsList.push({
                            Name: field,
                            label: this.resultsW.budgetASDFields[field],
                            stringFieldType: this.ASDFields[field].dataType.toUpperCase(),
                            isNumber: numberTypes.includes(this.ASDFields[field].dataType.toUpperCase()),
                            scale: this.ASDFields[field].scale
                        });
                        index++;
                    }
                }
                // console.log('this.ASDFields: ' + JSON.stringify(this.ASDFields))
                // console.log('this.budgetFieldsList: ' + JSON.stringify(this.budgetFieldsList))
                if (this.resultsW.negoASDFields) {
                    let index = 0;
                    for (let field of this.resultsW.negoAssAPIFields) {
                        this.negoFieldsList.push({
                            Name: field,
                            label: this.resultsW.negoASDFields[field],
                            stringFieldType: this.ASDFields[field].dataType.toUpperCase(),
                            isNumber: numberTypes.includes(this.ASDFields[field].dataType.toUpperCase(),),
                            scale: this.ASDFields[field].scale
                        });
                        index++;
                    }
                }
                this.isFirstLoad = false;
            }
            this.buildToDisplayData();
            console.log('this.resultsW: ' + JSON.stringify(this.resultsW))
        }).catch(error => {
            this.loading = false;
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
        });
    }

    @track dataList = {};
    buildToDisplayData() {
        this.dataList = {};
        let negoAsdMap = {};
        this.categoryWList = [];
        for (let negoAsd of this.resultsW.negoASDList) {
            negoAsdMap[negoAsd[Product__c.fieldApiName] + negoAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = negoAsd;
        }
        let targetAsdMap = {};
        for (let targetAsd of this.resultsW.targetASDList) {
            targetAsdMap[targetAsd[Product__c.fieldApiName] + targetAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = targetAsd;
        }
        for (let budgetAsd of this.resultsW.budgetASDList) {
            let categoryId = budgetAsd[Hierarchy__c.fieldApiName];
            if (!this.dataList[categoryId]) {
                let categoryW = {
                    categoryId: categoryId,
                    categoryName: budgetAsd[Hierarchy__c.fieldApiName.replace('__c', '__r')]?.Name,
                    categoryURL: '/' + categoryId,
                    categoryStyle: 'background-color:#595959;',
                    productList: [],
                    subTotalRow: []
                }
                this.dataList[categoryId] = categoryW;
            }

            this.dataList[categoryId].productList.push(this.buildProdRow(budgetAsd[Product__c.fieldApiName], budgetAsd, negoAsdMap, targetAsdMap));
        }
        console.log('this.dataList' + JSON.stringify(this.dataList))
        for (let categoryId of Object.keys(this.dataList)) {
            this.calculateSubTotal(categoryId);
        }
        this.loadingData = false;
        this.categoryWList = Object.values(this.dataList);
        // console.log('this.categoryWList >>>> ' + JSON.stringify(this.categoryWList))
        console.log('this.treeValuesMap: ' + JSON.stringify(this.treeValuesMap))
        this.buildTreeData();
    }

    treeValuesMap = {};
    calculateSubTotal(categoryId) {
        let subTotalMap = {};
        this.treeValuesMap[categoryId] = {};
        for (let product of this.dataList[categoryId].productList) {
            for (let budgetField of product.budgetFields) {
                if (budgetField.isNumber) {
                    if (subTotalMap['budget' + budgetField.fieldName]) {
                        let total = subTotalMap['budget' + budgetField.fieldName] + (budgetField.fieldValue ? parseFloat(budgetField.fieldValue) : 0);
                        subTotalMap['budget' + budgetField.fieldName] = total;
                        this.treeValuesMap[categoryId][this.channelBU.Id + '-' + budgetField.fieldName] = total;
                    } else {
                        subTotalMap['budget' + budgetField.fieldName] = budgetField.fieldValue ? parseFloat(budgetField.fieldValue) : 0;
                        this.treeValuesMap[categoryId][this.channelBU.Id + '-' + budgetField.fieldName] = budgetField.fieldValue ? parseFloat(budgetField.fieldValue) : 0;
                    }
                } else {
                    subTotalMap['budget' + budgetField.fieldName] = '-';
                }
            }
            for (let negoField of product.negoFields) {
                if (negoField.isNumber) {
                    if (subTotalMap['nego' + negoField.fieldName + negoField.buId]) {
                        let total = subTotalMap['nego' + negoField.fieldName + negoField.buId] + (negoField.fieldValue ? parseFloat(negoField.fieldValue) : 0);
                        subTotalMap['nego' + negoField.fieldName + negoField.buId] = total;
                        this.treeValuesMap[categoryId][negoField.buId + '-' + negoField.fieldName] = total;
                    } else {
                        subTotalMap['nego' + negoField.fieldName + negoField.buId] = negoField.fieldValue ? parseFloat(negoField.fieldValue) : 0;
                        this.treeValuesMap[categoryId][negoField.buId + '-' + negoField.fieldName] = negoField.fieldValue ? parseFloat(negoField.fieldValue) : 0;
                    }
                } else {
                    subTotalMap['nego' + negoField.fieldName + negoField.buId] = '-';
                }
            }
        }
        this.dataList[categoryId].subTotalRow = Object.values(subTotalMap);
    }

    buildProdRow(productId, budgetASD, negoAsdMap, targetAsdMap) {
        let prodRow = {
            budgetFields: [],
            negoFields: []
        };
        for (let field of this.budgetFieldsList) {
            let fieldw = {
                fieldName: field.Name,
                fieldValue: field.stringFieldType == 'REFERENCE' ? (budgetASD[field.Name.replace('__c', '__r')] ? budgetASD[field.Name.replace('__c', '__r')].Name : '') : budgetASD[field.Name],
                isNumber: numberTypes.includes(field.stringFieldType),
                scale: field.scale
            }
            prodRow.budgetFields.push(fieldw);
        }
        for (let orgaBu of this.buTargetList) {
            if (orgaBu.isDisplayed) {
                let negoAss = negoAsdMap[productId + orgaBu.Id];
                let targetAss = targetAsdMap[productId + orgaBu.Id];
                for (let field of this.negoFieldsList) {
                    if (field.Name == WDChannelBaseTarget_NegoL4LP1Gap__c.fieldApiName || field.Name == WDChannelBaseTarget__c.fieldApiName) {
                        let fieldw = {
                            fieldName: field.Name,
                            fieldValue: targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] == 'Validate' ? targetAss[field.Name] : '',
                            isNumber: numberTypes.includes(field.stringFieldType),
                            scale: field.scale
                        }
                        prodRow.negoFields.push(fieldw);
                    } else {
                        let fieldw = {
                            fieldName: field.Name,
                            fieldValue: negoAss ? (field.stringFieldType == 'REFERENCE' ? (negoAss[field.Name.replace('__c', '__r')] ? negoAss[field.Name.replace('__c', '__r')].Name : '') : negoAss[field.Name]) : 0,
                            isNumber: numberTypes.includes(field.stringFieldType),
                            scale: field.scale
                        }
                        prodRow.negoFields.push(fieldw);
                    }
                }
            }
        }
        return prodRow;
    }

    buildTreeData() {
        console.log('hey buildTreeData()')
        this.loading = true;
        let buTargetMap = {};
        let BUColumns = {};
        buTargetMap[this.channelBU.Id] = this.channelBU.Name;
        BUColumns[this.channelBU.Id] = {};
        for (let budgetField of this.budgetFieldsList) {
            if (budgetField.isNumber) {
                BUColumns[this.channelBU.Id][budgetField.Name] = budgetField.label;
            }
        }
        for (let buTarget of this.buTargetList) {
            buTargetMap[buTarget.Id] = buTarget.Name;
            BUColumns[buTarget.Id] = {};
            for (let negoField of this.negoFieldsList) {
                if (negoField.isNumber) {
                    BUColumns[buTarget.Id][negoField.Name] = negoField.label;
                }
            }
        }
        loadTreeData({
            assortmentCategoryId: this.CurrentAssortment[Hierarchy__c.fieldApiName],
            buTargetMapSerialized: JSON.stringify(buTargetMap),
            columnsSerialized: JSON.stringify(BUColumns),
            valuesSerialized: JSON.stringify(this.treeValuesMap),
        }).then((res) => {
            // console.log('res: ' + res)
            this.jsonHeaders = JSON.parse(res).jsonHeadersTree;
            this.jsonData = JSON.parse(res).jsonDataTree;
            if (this.jsonHeaders) {
                this.headers = JSON.parse(decodeURIComponent(this.jsonHeaders));
                let headIndex = 0;
                for (var head of this.headers) {
                    console.log('this.headers: ' + JSON.stringify(this.headers))
                    if (headIndex == 0) {
                        head.style = 'background-color: rgb(20, 179, 187); color: white;border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
                        for (var header of head.columns) {
                            header.style = 'background-color: rgb(20, 179, 187); color: white;';
                        }
                        head.columns[head.columns.length - 1].style += 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
                    } else {
                        head.style = 'background-color: rgb(133, 219, 219); color: white;border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
                        for (var header of head.columns) {
                            header.style = 'background-color: rgb(133, 219, 219); color: white;';
                        }
                        head.columns[head.columns.length - 1].style += 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
                    }
                    headIndex++;
                }
                this.justOneHeaderDisplayed = this.headers.length == 1 && this.headers[0].headerName == "";
            }
            if (this.jsonData) {
                this.data = JSON.parse(decodeURIComponent(this.jsonData));
                this.buildData();
            }
        }).catch(error => {
            this.loading = false;
            this.showNotification('Error', error, 'error', 'dismissible ');
            console.error(error);
        });
    }

    //to build a data accepted by the tree
    buildData() {
        if (this.headers.length != 0) {
            for (var head of this.headers) {
                for (var col of head.columns) {
                    this.dataHeaders.push(head.headerKey + '-' + col.fieldName);
                }
            }
        }
        for (var root of this.data) {
            for (var item of this.dataHeaders) {
                this.calculateParentTotal(root, item);
            }
        }
        if (this.data.length != 0) {
            for (var item of this.data) {
                this.dataPreperation(item, 1);
            }
            this.loading = false;
        }
    }

    //Prepare the data (recursive)
    dataPreperation(row, level) {
        row.level = level;
        var val = [];
        console.log('this.dataHeaders: ' + JSON.stringify(this.dataHeaders))
        console.log('this.fieldsMap: ' + JSON.stringify(this.fieldsMap))
        let cellIndex = 0;
        let cellNegoIndex = 0;
        for (var item of this.dataHeaders) {
            var itemId = row.key + "-" + item;
            let fieldName = item.split('-')[1];
            console.log('fieldName: ' + fieldName)
            let bgColor = '#FFFFF';
            let cellStyle = '';
            if (item.includes('WDChannelBaseNegoL4L_P1__c') || item.includes('WDChannelBasePanel_P1__c') || item.includes('WDChannelBaseBudget__c') || item.includes('WDChannelBaseBudget_NegoL4LP1Gap__c')) {
                bgColor = 'rgb(222, 243, 238)';
            } else if (item.includes('PNChannelBaseBudget_NegoL4LP1Gap__c')) {
                bgColor = 'rgb(221, 235, 247)';
            }
            if (cellIndex == this.budgetFieldsList.length - 1) {
                cellStyle = 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
            }
            if (cellIndex > this.budgetFieldsList.length - 1) {
                cellNegoIndex++;
                if (cellNegoIndex == 3) {
                    cellNegoIndex = 0;
                    cellStyle = 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
                }
            }
            console.log('this.fieldsMap[ASSORTMENTDETAIL_OBJECT.objectApiName]: ' + JSON.stringify(this.fieldsMap[ASSORTMENTDETAIL_OBJECT.objectApiName]))
            console.log('ASSORTMENTDETAIL_OBJECT.fieldApiName: ' + ASSORTMENTDETAIL_OBJECT.fieldApiName)
            val.push({
                Id: itemId,
                value: (parseFloat(row.values[item])),
                class: ALIGN_TEXT_RIGHT, style: 'background-color: ' + bgColor + '; padding-right:15px;' + cellStyle,

                scale: this.fieldsMap.hasOwnProperty(ASSORTMENTDETAIL_OBJECT.objectApiName) ? this.fieldsMap[ASSORTMENTDETAIL_OBJECT.objectApiName][fieldName].scale : this.scale});
            cellIndex++;
        }
        row.values = val;
        row.show = level <= 2 ? true : false;
        row.expanded = level <= 2 ? true : false;
        row.ariaExpanded = false;
        var children = JSON.parse(JSON.stringify(row.children));
        row.children = [];
        row.hasOld = false;
        row.historyLevel = level + 1;
        row.oldValues = [];
        this.treeData.push(row);
        if (children != null && children.length > 0) {
            row.hasChildren = true;
            row.showChevronButton = (row.hasChildren || (row.hasOld && !this.hideHistory)) ? true : false;
            level++;
            for (var item of children) {
                this.dataPreperation(item, level);
            }
        }
        console.log('this.treeData: ' + JSON.stringify(this.treeData))
    }

    //calculate the parent based on their children
    calculateParentTotal(root, item) {
        if (root.children) {
            root.children.forEach(child => {
                var val = this.calculateParentTotal(child, item);
                root.values[item] = (parseFloat(val) + parseFloat(root.values[item]));
            });
        }
        return root.values[item];
    }

    //to make the live update on the tree
    @api
    changeValue(message) {
        var data = JSON.parse(message);
        var rowValue = data.rowValue;
        this.headerValue = data.headerValue;
        this.fieldValue = data.fieldValue;
        var value = data.value;
        var modifiedRow = this.treeData.filter(obj => obj.key == rowValue)[0];
        if (modifiedRow != null) {
            if (!modifiedRow.hasOld) {
                modifiedRow.hasOld = true;
                modifiedRow.showChevronButton = (modifiedRow.hasChildren || (modifiedRow.hasOld && !this.hideHistory)) ? true : false;
                modifiedRow.oldValues = JSON.parse(JSON.stringify(modifiedRow.values));
            }
            var target = rowValue + '-' + this.headerValue + '-' + this.fieldValue;
            var modfifiedValue = modifiedRow.values.filter(obj => obj.Id == target) != null ? modifiedRow.values.filter(obj => obj.Id == target)[0] : null;
            if (modfifiedValue != null) {
                var diff = value - modfifiedValue.value;
                var diffOldNew = this.calculDiff(rowValue, value);
                if (diffOldNew == 0) {
                    modfifiedValue.class = ALIGN_TEXT_RIGHT;
                    modfifiedValue.value = parseFloat(value);
                } else if (diffOldNew > 0) {
                    modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_UP_CLASS;
                    modfifiedValue.value = parseFloat(value);
                } else if (diffOldNew < 0) {
                    modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_DOWN_CLASS;
                    modfifiedValue.value = parseFloat(value);
                }
                if (modifiedRow.parentId != null) {
                    this.updateParent(modifiedRow.parentId, diff);
                }
            } else {
                return;
            }
        }

    }

    //to Update the parent of children
    updateParent(parentId, diffValue) {
        var parentRow = this.treeData.filter(obj => obj.key == parentId)[0];
        if (!parentRow.hasOld) {
            parentRow.hasOld = true;
            parentRow.oldValues = JSON.parse(JSON.stringify(parentRow.values));
        }
        var target = parentRow.key + '-' + this.headerValue + '-' + this.fieldValue;
        var modfifiedValue = parentRow.values.filter(obj => obj.Id == target)[0];
        var tdVal = parseFloat(modfifiedValue.value) + parseFloat(diffValue);
        var diffOldNew = this.calculDiff(parentRow.key, tdVal);
        if (diffOldNew == 0) {
            modfifiedValue.class = ALIGN_TEXT_RIGHT;
            modfifiedValue.value = tdVal;
        } else if (diffOldNew > 0) {
            modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_UP_CLASS;
            modfifiedValue.value = tdVal;
        } else if (diffOldNew < 0) {
            modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_DOWN_CLASS;
            modfifiedValue.value = tdVal;
        }
        if (parentRow.parentId != null) {
            this.updateParent(parentRow.parentId, diffValue);
        }
    }

    //difference between the old and new value
    calculDiff(rowValue, val) {
        var row = this.treeData.filter(obj => obj.key == rowValue)[0];
        for (var oldVal of row.oldValues) {
            if (oldVal.Id == rowValue + '-' + this.headerValue + '-' + this.fieldValue) {
                return (val - oldVal.value);
            }
        }
    }

    expandAndCollapse(event) {
        var rowKey = event.currentTarget.dataset.recordid;
        var dataModi = JSON.parse(JSON.stringify(this.treeData));
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
        this.treeData = JSON.parse(JSON.stringify(dataModi));
    }

    @track nbOfFixedColumns = '1';

    setnumberOfFixedColumns() {
        let tableTrs = this.template.querySelector('.main-table').rows;
        if (tableTrs) {
            let top = 0;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                let left = 0;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < this.nbOfFixedColumns) {
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
                    if (childrens[index2].classList.contains('fixedHeader')) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.top = top + 'px';
                        if (index2 == childrens.length - 1) {
                            top += childrens[index2].offsetHeight;
                        }
                        childrens[index2].style.zIndex = childrens[index2].textContent == '' ? 5 : 4;
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
}