/**
* @author ULiT
* @date 24-06-2024
* @description AssortmentComparatorTreeGridExt
*******************************************************************************************************************************************
*/
import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//APEX
import getData from '@salesforce/apex/AssortmentMatrixComparatorCtrl.getData';
import getInitialData from '@salesforce/apex/AssortmentMatrixComparatorCtrl.getInitialData';

//NEW LABELS
import LBL_Matrix_Comparator_Title from "@salesforce/label/c.LBL_Matrix_Comparator_Title";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Assortment_Conso from "@salesforce/label/c.LBL_Assortment_Conso";


import Hierarchy__c from '@salesforce/schema/AssortmentDetail__c.Hierarchy__c';
import Product__c from '@salesforce/schema/AssortmentDetail__c.Product__c';
import Assortment__c from '@salesforce/schema/AssortmentDetail__c.Assortment__c';
import BusinessUnitTarget__c from '@salesforce/schema/Assortment__c.BusinessUnitTarget__c';
import Status__c from '@salesforce/schema/Assortment__c.Status__c';
import LongName__c from '@salesforce/schema/Assortment__c.LongName__c';
import WDChannelBaseBudget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget__c';
import ProductPriority__c from '@salesforce/schema/AssortmentDetail__c.ProductPriority__c';
import BusinessUnitCluster__c from '@salesforce/schema/AssortmentDetail__c.BusinessUnitCluster__c';
import WDChannelBaseNegoL4L_P1__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseNegoL4L_P1__c';
import WDChannelBaseTarget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget__c';
import WDChannelBasePanel_P1__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBasePanel_P1__c';


import WDChannelBaseBudget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget_NegoL4LP1Gap__c';
import PNChannelBaseBudget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.PNChannelBaseBudget_NegoL4LP1Gap__c';
import WDChannelBaseTarget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget_NegoL4LP1Gap__c';
import ASSORTMENT_OBJECT from '@salesforce/schema/Assortment__c';
import ASSORTMENTDETAIL_OBJECT from '@salesforce/schema/AssortmentDetail__c';

const ALIGN_TEXT_RIGHT = 'slds-text-align--right';
const ARROW_UP_CLASS = 'arrowup';
const ARROW_DOWN_CLASS = 'arrowdown';
const numberTypes = ['DOUBLE', 'INTEGER', 'PERCENT', 'LONG', 'CURRENCY'];
export default class assortmentMatrixComparatorTreeGrid extends LightningElement {
    @api recordId;
    filterWrapper = {
        year: '',
        selectedRecordType: '',
        buTarget: '',
        orgaHe: '',
        searchTerm: '',
        selectedFormats: ''
    }
    labels = {
        LBL_Matrix_Comparator_Title,
        LBL_No_Item_To_Display,
        LBL_Assortment_Conso,
    }
    isDataLoading = true;
    //BOOLEANS
    isLoading = true;
    //OBJECTS
    fieldsMap = {};
    //SET THE Assortment ID
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        console.log('this.currentPageReference.state: ' + JSON.stringify(this.currentPageReference.state))
        if (currentPageReference.state.hasOwnProperty('c__year')) {
            console.log('this.currentPageReference.state.c__year: ' + this.currentPageReference.state.c__year)
            this.filterWrapper.year = this.currentPageReference.state.c__year;
        }
        if (currentPageReference.state.hasOwnProperty('c__selectedRecordType')) {
            this.filterWrapper.selectedRecordType = this.currentPageReference.state.c__selectedRecordType;
        }
        if (currentPageReference.state.hasOwnProperty('c__buTarget')) {
            this.filterWrapper.buTarget = this.currentPageReference.state.c__buTarget;
        }
        if (currentPageReference.state.hasOwnProperty('c__orgaHe')) {
            this.filterWrapper.orgaHe = this.currentPageReference.state.c__orgaHe;
        }
        if (currentPageReference.state.hasOwnProperty('c__selectedFormats')) {
            this.filterWrapper.selectedFormats = decodeURI(this.currentPageReference.state.c__selectedFormats).split(',');
        }
        if (currentPageReference.state.hasOwnProperty('c__searchTerm')) {
            this.filterWrapper.searchTerm = this.currentPageReference.state.c__searchTerm;
        }
        console.log('this.filterWrapper: ' + JSON.stringify(this.filterWrapper))
    }
    connectedCallback() {
        window.addEventListener('resize', this.setPageSize);
        this.loadInitialData();
    }
    renderedCallback() {
        try {
            setTimeout(() => {
                this.setPageSize()
            }, 200);
        } catch (error) {
            console.log('%c' + error.message);
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    //LIFECYCLE
    setPageSize = () => {
        try {
            //SET PAGE SIZE
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBody = this.template.querySelector(".pageBody");
            // let pageFooter = this.template.querySelector(".footerDiv");
            if (
                mainContainer != null &&
                pageHeader != null &&
                // pageFooter != null &&
                pageBody != null
            ) {
                pageBody.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - 10 + "px";
            }
            //SET HEADER STICKY
            let stickyTd1 = this.template.querySelector(".assortmentTd1");
            let stickyTd2List = this.template.querySelectorAll(".assortmentTd2");
            if (
                stickyTd1 != null &&
                stickyTd2List != null
            ) {
                for (let td of stickyTd2List) {
                    td.style.top = stickyTd1.offsetHeight - 1 + 'px';
                }
            }
            //SET COLUMNS STICKY
            let firstColumn = this.template.querySelector(".firstColumn");
            let secondColumns = this.template.querySelectorAll(".secondColumn");
            let thirdColumns = this.template.querySelectorAll(".thirdColumn");
            let fourthColumns = this.template.querySelectorAll(".fourthColumn");
            if (
                firstColumn != null &&
                secondColumns != null &&
                thirdColumns != null &&
                fourthColumns != null
            ) {
                let left = firstColumn.offsetWidth;
                for (let td of secondColumns) {
                    td.style.left = left + 'px';
                }
                left += secondColumns[0].offsetWidth;
                for (let td of thirdColumns) {
                    td.style.left = left + 'px';
                }
                left += thirdColumns[0].offsetWidth;
                for (let td of fourthColumns) {
                    td.style.left = left + 'px';
                }
            }
        } catch (error) {
            console.log('here?')
            console.log('%c' + error.message ? error.message : error.body?.message);
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    //INITIAL LOAD
    loadInitialData() {
        try {
            this.isLoading = true;
            getInitialData({}).then((result) => {
                console.log('result: ' + result)
                if (result) {
                    this.afterInitialLoad(result);
                }
            }).catch((error) => {
                console.log('%c' + error.message);
                console.error(error.message)
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    afterInitialLoad(result) {
        let data = JSON.parse(result);
        this.fieldsMap = data.fieldsMap;
        console.log('this.fieldsMap: ' + JSON.stringify(this.fieldsMap))
        this.isLoading = false;
        this.loadData();
    }
    loadData() {
        getData({
            filterWrapperJSON: JSON.stringify(this.filterWrapper),
            pageSize: 1000
        }).then((result) => {
            console.log('result: ' + result)
            if (result) {
                this.afterload(result);
            }
        }).catch((error) => {
            console.log('%c' + error.message ? error.message : error.body?.message);
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }
    afterload(result) {
        let data = JSON.parse(result);
        console.log('data: ' + JSON.stringify(data))
        this.processData(data);
        this.isDataLoading = false;
        setTimeout(() => {
            this.setPageSize();
        }, 200)
    }
    treeList = [];
    subTotalsMap = {};
    hasNoData = false;
    processData(data) {
        console.log('this.assortmentStatusLabelsMap: ' + JSON.stringify(this.assortmentStatusLabelsMap))
        if (data.assList == null || data.assList.length == 0) {
            this.hasNoData = true;
            return;
        }
        this.assortmentList = data.assList;
        this.fieldList = data.fieldsToSum;
        this.subTotalsMap = data.subTotalsMap;
        console.log('this.subTotalsMap: ' + JSON.stringify(this.subTotalsMap))
        console.log('this.assortmentList: ' + JSON.stringify(this.assortmentList))
        if (data.assList == null || data.assList.length == 0) {
            return;
        }
        let assortment = data.assList[0];
        //BUILD TITLE
        let formatOriginList = assortment.BusinessUnitTarget__r?.Format__c?.split(';');
        let formatOriginString = formatOriginList.join('+');
        this.title = assortment.RecordType?.Name + ' | ' + assortment.BusinessUnitTarget__r.Name + ' | ' + assortment.Hierarchy__r.Name + ' | ' + formatOriginString + ' | ' + assortment.Year__c;
        console.log('data.categoryTreeMap 1: ' + JSON.stringify(data.categoryTreeMap))
        //FILL IN DATA FROM SUBTOTALMAP
        for (let key in data.categoryTreeMap) {
            this.fillTotals(data.categoryTreeMap[key], 1)
        }
        console.log('data.categoryTreeMap 2: ' + JSON.stringify(data.categoryTreeMap))

        // //CALCULATE SUM OF PARENTS
        // for (let key in data.categoryTreeMap) {
        //     this.calculateParentTotals(data.categoryTreeMap[key], 1)
        // }
        //BUILD HTML LIST
        for (let key in data.categoryTreeMap) {
            this.dataPreperation(data.categoryTreeMap[key], 1)
        }
        console.log('this.detailList: ' + JSON.stringify(this.detailList))
    }
    //Prepare the data (recursive)
    fillTotals(row, level) { 
        row.level = level;
        if (row.children != null && row.children.length > 0) {
            level++;
            let childrenSums = [];
            for (let item of row.children) {
                let childSums = this.fillTotals(item, level)
                if (childSums != null) {
                    childrenSums.push(childSums);
                }
            }
            console.log('childrenSums: ' + JSON.stringify(childrenSums))
            if (childrenSums.length == 0) {
                return;
            }
            for (let childSums of childrenSums) {
                for (let assortment of this.assortmentList) { 
                    for (let field of this.fieldList) {
                        let itemId = assortment.Id + "-" + field;
                        row.sums[itemId] += childSums[itemId];
                    }
                    row.sums['conso-' + this.fieldList[0]] += childSums[assortment.Id + '-' + this.fieldList[0]]
                    row.sums['conso-' + this.fieldList[1]] += childSums[assortment.Id + '-' + this.fieldList[1]]
                    row.sums['conso-' + this.fieldList[2]] += childSums[assortment.Id + '-' + this.fieldList[2]]
                }
            }
        } else {
            for (let assortment of this.assortmentList) {
                let subTotalKey = assortment.Id + '-' + row.key;
                console.log('subTotalKey: ' + subTotalKey)
                let subTotals = this.subTotalsMap[subTotalKey];
                if (subTotals != null) {
                    for (let field of this.fieldList) {
                        let itemId = assortment.Id + "-" + field;
                        row.sums[itemId] = subTotals[field];
                    }
                    row.sums['conso-' + this.fieldList[0]] += subTotals[this.fieldList[0]]
                    row.sums['conso-' + this.fieldList[1]] += subTotals[this.fieldList[1]]
                    row.sums['conso-' + this.fieldList[2]] += subTotals[this.fieldList[2]]
                }
            }
        }
        return row.sums;
    }
    fieldList = []
    dataPreperation(row, level) {
        row.level = level;
        row.consoClientBase = row.sums['conso-' + this.fieldList[0]];
        row.consoChannelBase = row.sums['conso-' + this.fieldList[1]];
        row.consoSOSNumber = row.sums['conso-' + this.fieldList[2]];
        let val = [];
        for (let assortment of this.assortmentList) {
            for (let field of this.fieldList) {
                let itemId = assortment.Id + "-" + field;
                val.push({ 
                    Id: itemId, 
                    value: (parseFloat(row.sums[itemId]))
                });
            }
        }
        row.values = val;
        row.show = level == 1;
        row.expanded = level == 1;
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
                this.dataPreperation(item, level);
            }
        }
    }

    // @track dataList = {};
    // buildToDisplayData() {
    //     this.dataList = {};
    //     let negoAsdMap = {};
    //     this.categoryWList = [];
    //     for (let negoAsd of this.resultsW.negoASDList) {
    //         negoAsdMap[negoAsd[Product__c.fieldApiName] + negoAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = negoAsd;
    //     }
    //     let targetAsdMap = {};
    //     for (let targetAsd of this.resultsW.targetASDList) {
    //         targetAsdMap[targetAsd[Product__c.fieldApiName] + targetAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = targetAsd;
    //     }
    //     for (let budgetAsd of this.resultsW.budgetASDList) {
    //         let categoryId = budgetAsd[Hierarchy__c.fieldApiName];
    //         if (!this.dataList[categoryId]) {
    //             let categoryW = {
    //                 categoryId: categoryId,
    //                 categoryName: budgetAsd[Hierarchy__c.fieldApiName.replace('__c', '__r')]?.Name,
    //                 categoryURL: '/' + categoryId,
    //                 categoryStyle: 'background-color:#595959;',
    //                 productList: [],
    //                 subTotalRow: []
    //             }
    //             this.dataList[categoryId] = categoryW;
    //         }

    //         this.dataList[categoryId].productList.push(this.buildProdRow(budgetAsd[Product__c.fieldApiName], budgetAsd, negoAsdMap, targetAsdMap));
    //     }
    //     console.log('this.dataList' + JSON.stringify(this.dataList))
    //     for (let categoryId of Object.keys(this.dataList)) {
    //         this.calculateSubTotal(categoryId);
    //     }
    //     this.loadingData = false;
    //     this.categoryWList = Object.values(this.dataList);
    //     // console.log('this.categoryWList >>>> ' + JSON.stringify(this.categoryWList))
    //     console.log('this.treeValuesMap: ' + JSON.stringify(this.treeValuesMap))
    //     this.buildTreeData();
    // }

    // treeValuesMap = {};
    // calculateSubTotal(categoryId) {
    //     let subTotalMap = {};
    //     this.treeValuesMap[categoryId] = {};
    //     for (let product of this.dataList[categoryId].productList) {
    //         for (let budgetField of product.budgetFields) {
    //             if (budgetField.isNumber) {
    //                 if (subTotalMap['budget' + budgetField.fieldName]) {
    //                     let total = subTotalMap['budget' + budgetField.fieldName] + (budgetField.fieldValue ? parseFloat(budgetField.fieldValue) : 0);
    //                     subTotalMap['budget' + budgetField.fieldName] = total;
    //                     this.treeValuesMap[categoryId][this.channelBU.Id + '-' + budgetField.fieldName] = total;
    //                 } else {
    //                     subTotalMap['budget' + budgetField.fieldName] = budgetField.fieldValue ? parseFloat(budgetField.fieldValue) : 0;
    //                     this.treeValuesMap[categoryId][this.channelBU.Id + '-' + budgetField.fieldName] = budgetField.fieldValue ? parseFloat(budgetField.fieldValue) : 0;
    //                 }
    //             } else {
    //                 subTotalMap['budget' + budgetField.fieldName] = '-';
    //             }
    //         }
    //         for (let negoField of product.negoFields) {
    //             if (negoField.isNumber) {
    //                 if (subTotalMap['nego' + negoField.fieldName + negoField.buId]) {
    //                     let total = subTotalMap['nego' + negoField.fieldName + negoField.buId] + (negoField.fieldValue ? parseFloat(negoField.fieldValue) : 0);
    //                     subTotalMap['nego' + negoField.fieldName + negoField.buId] = total;
    //                     this.treeValuesMap[categoryId][negoField.buId + '-' + negoField.fieldName] = total;
    //                 } else {
    //                     subTotalMap['nego' + negoField.fieldName + negoField.buId] = negoField.fieldValue ? parseFloat(negoField.fieldValue) : 0;
    //                     this.treeValuesMap[categoryId][negoField.buId + '-' + negoField.fieldName] = negoField.fieldValue ? parseFloat(negoField.fieldValue) : 0;
    //                 }
    //             } else {
    //                 subTotalMap['nego' + negoField.fieldName + negoField.buId] = '-';
    //             }
    //         }
    //     }
    //     this.dataList[categoryId].subTotalRow = Object.values(subTotalMap);
    // }

    // buildProdRow(productId, budgetASD, negoAsdMap, targetAsdMap) {
    //     let prodRow = {
    //         budgetFields: [],
    //         negoFields: []
    //     };
    //     for (let field of this.budgetFieldsList) {
    //         let fieldw = {
    //             fieldName: field.Name,
    //             fieldValue: field.stringFieldType == 'REFERENCE' ? (budgetASD[field.Name.replace('__c', '__r')] ? budgetASD[field.Name.replace('__c', '__r')].Name : '') : budgetASD[field.Name],
    //             isNumber: numberTypes.includes(field.stringFieldType),
    //             scale: field.scale
    //         }
    //         prodRow.budgetFields.push(fieldw);
    //     }
    //     for (let orgaBu of this.buTargetList) {
    //         if (orgaBu.isDisplayed) {
    //             let negoAss = negoAsdMap[productId + orgaBu.Id];
    //             let targetAss = targetAsdMap[productId + orgaBu.Id];
    //             for (let field of this.negoFieldsList) {
    //                 if (field.Name == WDChannelBaseTarget_NegoL4LP1Gap__c.fieldApiName || field.Name == WDChannelBaseTarget__c.fieldApiName) {
    //                     let fieldw = {
    //                         fieldName: field.Name,
    //                         fieldValue: targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] == 'Validate' ? targetAss[field.Name] : '',
    //                         isNumber: numberTypes.includes(field.stringFieldType),
    //                         scale: field.scale
    //                     }
    //                     prodRow.negoFields.push(fieldw);
    //                 } else {
    //                     let fieldw = {
    //                         fieldName: field.Name,
    //                         fieldValue: negoAss ? (field.stringFieldType == 'REFERENCE' ? (negoAss[field.Name.replace('__c', '__r')] ? negoAss[field.Name.replace('__c', '__r')].Name : '') : negoAss[field.Name]) : 0,
    //                         isNumber: numberTypes.includes(field.stringFieldType),
    //                         scale: field.scale
    //                     }
    //                     prodRow.negoFields.push(fieldw);
    //                 }
    //             }
    //         }
    //     }
    //     return prodRow;
    // }

    // buildTreeData() {
    //     console.log('hey buildTreeData()')
    //     this.loading = true;
    //     let buTargetMap = {};
    //     let BUColumns = {};
    //     buTargetMap[this.channelBU.Id] = this.channelBU.Name;
    //     BUColumns[this.channelBU.Id] = {};
    //     for (let budgetField of this.budgetFieldsList) {
    //         if (budgetField.isNumber) {
    //             BUColumns[this.channelBU.Id][budgetField.Name] = budgetField.label;
    //         }
    //     }
    //     for (let buTarget of this.buTargetList) {
    //         buTargetMap[buTarget.Id] = buTarget.Name;
    //         BUColumns[buTarget.Id] = {};
    //         for (let negoField of this.negoFieldsList) {
    //             if (negoField.isNumber) {
    //                 BUColumns[buTarget.Id][negoField.Name] = negoField.label;
    //             }
    //         }
    //     }
    //     loadTreeData({
    //         assortmentCategoryId: this.CurrentAssortment[Hierarchy__c.fieldApiName],
    //         buTargetMapSerialized: JSON.stringify(buTargetMap),
    //         columnsSerialized: JSON.stringify(BUColumns),
    //         valuesSerialized: JSON.stringify(this.treeValuesMap),
    //     }).then((res) => {
    //         // console.log('res: ' + res)
    //         this.jsonHeaders = JSON.parse(res).jsonHeadersTree;
    //         this.jsonData = JSON.parse(res).jsonDataTree;
    //         if (this.jsonHeaders) {
    //             this.headers = JSON.parse(decodeURIComponent(this.jsonHeaders));
    //             let headIndex = 0;
    //             for (var head of this.headers) {
    //                 if (headIndex == 0) {
    //                     head.style = 'background-color: rgb(20, 179, 187); color: white;border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
    //                     for (var header of head.columns) {
    //                         header.style = 'background-color: rgb(20, 179, 187); color: white;';
    //                     }
    //                     head.columns[head.columns.length - 1].style += 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
    //                 } else {
    //                     head.style = 'background-color: rgb(133, 219, 219); color: white;border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
    //                     for (var header of head.columns) {
    //                         header.style = 'background-color: rgb(133, 219, 219); color: white;';
    //                     }
    //                     head.columns[head.columns.length - 1].style += 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);';
    //                 }
    //                 headIndex++;
    //             }
    //             this.justOneHeaderDisplayed = this.headers.length == 1 && this.headers[0].headerName == "";
    //         }
    //         if (this.jsonData) {
    //             this.data = JSON.parse(decodeURIComponent(this.jsonData));
    //             this.buildData();
    //         }
    //     }).catch(error => {
    //         this.loading = false;
    //         this.showNotification('Error', error, 'error', 'dismissible ');
    //         console.error(error);
    //     });
    // }

    // //to build a data accepted by the tree
    // buildData() {
    //     if (this.headers.length != 0) {
    //         for (var head of this.headers) {
    //             for (var col of head.columns) {
    //                 this.dataHeaders.push(head.headerKey + '-' + col.fieldName);
    //             }
    //         }
    //     }
    //     for (var root of this.data) {
    //         for (var item of this.dataHeaders) {
    //             this.calculateParentTotal(root, item);
    //         }
    //     }
    //     if (this.data.length != 0) {
    //         for (var item of this.data) {
    //             this.dataPreperation(item, 1);
    //         }
    //         this.loading = false;
    //     }
    // }

    // //Prepare the data (recursive)
    // dataPreperation(row, level) {
    //     row.level = level;
    //     var val = [];
    //     console.log('this.dataHeaders: ' + JSON.stringify(this.dataHeaders))
    //     let cellIndex = 0;
    //     let cellNegoIndex = 0;
    //     for (var item of this.dataHeaders) {
    //         var itemId = row.key + "-" + item;
    //         let bgColor = '#FFFFF';
    //         let cellStyle = '';
    //         if (item.includes('WDChannelBaseNegoL4L_P1__c') || item.includes('WDChannelBasePanel_P1__c') || item.includes('WDChannelBaseBudget__c') || item.includes('WDChannelBaseBudget_NegoL4LP1Gap__c')) {
    //             bgColor = 'rgb(222, 243, 238)';
    //         } else if (item.includes('PNChannelBaseBudget_NegoL4LP1Gap__c')) {
    //             bgColor = 'rgb(221, 235, 247)';
    //         }
    //         if (cellIndex == this.budgetFieldsList.length - 1) {
    //             cellStyle = 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
    //         }
    //         if (cellIndex > this.budgetFieldsList.length - 1) {
    //             cellNegoIndex++;
    //             if (cellNegoIndex == 3) {
    //                 cellNegoIndex = 0;
    //                 cellStyle = 'border-right: 1.5mm ridge rgb(137 122 122 / 58%);'
    //             }
    //         }
    //         val.push({ Id: itemId, value: (parseFloat(row.values[item])), class: ALIGN_TEXT_RIGHT, style: 'background-color: ' + bgColor + '; padding-right:15px;' + cellStyle });
    //         cellIndex++;
    //     }
    //     row.values = val;
    //     row.show = level == 1 ? true : false;
    //     row.expanded = level == 1 ? true : false;
    //     row.ariaExpanded = false;
    //     var children = JSON.parse(JSON.stringify(row.children));
    //     row.children = [];
    //     row.hasOld = false;
    //     row.historyLevel = level + 1;
    //     row.oldValues = [];
    //     this.treeData.push(row);
    //     if (children != null && children.length > 0) {
    //         row.hasChildren = true;
    //         row.showChevronButton = (row.hasChildren || (row.hasOld && !this.hideHistory)) ? true : false;
    //         level++;
    //         for (var item of children) {
    //             this.dataPreperation(item, level);
    //         }
    //     }
    //     console.log('this.treeData: ' + JSON.stringify(this.treeData))
    // }

    // //calculate the parent based on their children
    // calculateParentTotal(root, item) {
    //     if (root.children) {
    //         root.children.forEach(child => {
    //             var val = this.calculateParentTotal(child, item);
    //             root.values[item] = (parseFloat(val) + parseFloat(root.values[item]));
    //         });
    //     }
    //     return root.values[item];
    // }

    // //to make the live update on the tree
    // @api
    // changeValue(message) {
    //     var data = JSON.parse(message);
    //     var rowValue = data.rowValue;
    //     this.headerValue = data.headerValue;
    //     this.fieldValue = data.fieldValue;
    //     var value = data.value;
    //     var modifiedRow = this.treeData.filter(obj => obj.key == rowValue)[0];
    //     if (modifiedRow != null) {
    //         if (!modifiedRow.hasOld) {
    //             modifiedRow.hasOld = true;
    //             modifiedRow.showChevronButton = (modifiedRow.hasChildren || (modifiedRow.hasOld && !this.hideHistory)) ? true : false;
    //             modifiedRow.oldValues = JSON.parse(JSON.stringify(modifiedRow.values));
    //         }
    //         var target = rowValue + '-' + this.headerValue + '-' + this.fieldValue;
    //         var modfifiedValue = modifiedRow.values.filter(obj => obj.Id == target) != null ? modifiedRow.values.filter(obj => obj.Id == target)[0] : null;
    //         if (modfifiedValue != null) {
    //             var diff = value - modfifiedValue.value;
    //             var diffOldNew = this.calculDiff(rowValue, value);
    //             if (diffOldNew == 0) {
    //                 modfifiedValue.class = ALIGN_TEXT_RIGHT;
    //                 modfifiedValue.value = parseFloat(value);
    //             } else if (diffOldNew > 0) {
    //                 modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_UP_CLASS;
    //                 modfifiedValue.value = parseFloat(value);
    //             } else if (diffOldNew < 0) {
    //                 modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_DOWN_CLASS;
    //                 modfifiedValue.value = parseFloat(value);
    //             }
    //             if (modifiedRow.parentId != null) {
    //                 this.updateParent(modifiedRow.parentId, diff);
    //             }
    //         } else {
    //             return;
    //         }
    //     }

    // }

    // //to Update the parent of children
    // updateParent(parentId, diffValue) {
    //     var parentRow = this.treeData.filter(obj => obj.key == parentId)[0];
    //     if (!parentRow.hasOld) {
    //         parentRow.hasOld = true;
    //         parentRow.oldValues = JSON.parse(JSON.stringify(parentRow.values));
    //     }
    //     var target = parentRow.key + '-' + this.headerValue + '-' + this.fieldValue;
    //     var modfifiedValue = parentRow.values.filter(obj => obj.Id == target)[0];
    //     var tdVal = parseFloat(modfifiedValue.value) + parseFloat(diffValue);
    //     var diffOldNew = this.calculDiff(parentRow.key, tdVal);
    //     if (diffOldNew == 0) {
    //         modfifiedValue.class = ALIGN_TEXT_RIGHT;
    //         modfifiedValue.value = tdVal;
    //     } else if (diffOldNew > 0) {
    //         modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_UP_CLASS;
    //         modfifiedValue.value = tdVal;
    //     } else if (diffOldNew < 0) {
    //         modfifiedValue.class = this.hideArrows ? ALIGN_TEXT_RIGHT : ALIGN_TEXT_RIGHT + " " + ARROW_DOWN_CLASS;
    //         modfifiedValue.value = tdVal;
    //     }
    //     if (parentRow.parentId != null) {
    //         this.updateParent(parentRow.parentId, diffValue);
    //     }
    // }

    // //difference between the old and new value
    // calculDiff(rowValue, val) {
    //     var row = this.treeData.filter(obj => obj.key == rowValue)[0];
    //     for (var oldVal of row.oldValues) {
    //         if (oldVal.Id == rowValue + '-' + this.headerValue + '-' + this.fieldValue) {
    //             return (val - oldVal.value);
    //         }
    //     }
    // }

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

    // @track nbOfFixedColumns = '1';

    // setnumberOfFixedColumns() {
    //     let tableTrs = this.template.querySelector('.main-table').rows;
    //     if (tableTrs) {
    //         for (let index = 0; tableTrs && index < tableTrs.length; index++) {
    //             let childrens = tableTrs[index].children;
    //             let left = 0;
    //             for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
    //                 if (index2 < this.nbOfFixedColumns) {
    //                     childrens[index2].style.position = 'sticky';
    //                     childrens[index2].style.left = left + 'px';
    //                     childrens[index2].style.zIndex = 3;
    //                     left += childrens[index2].offsetWidth;
    //                     childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
    //                 } else {
    //                     childrens[index2].style.position = 'unset';
    //                     childrens[index2].style.left = 'unset';
    //                     childrens[index2].style.zIndex = 'unset';
    //                 }
    //             }
    //         }
    //     }
    // }

    // show notification 
    showNotification(title, message, variant) {
        console.log('title: ' + title)
        console.log('message: ' + message)
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant == 'error' ? 'sticky' : 'dismissible'
        });
        this.dispatchEvent(evt);
    }
}