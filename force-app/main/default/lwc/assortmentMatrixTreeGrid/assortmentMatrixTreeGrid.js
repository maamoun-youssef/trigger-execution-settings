/**
* @author ULiT
* @date 03-07-2024
* @description AssortmentMatrixTreeGrid
*******************************************************************************************************************************************
*/
import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//APEX
import loadTreeGridData from '@salesforce/apex/AssortmentMatrixCtrl.loadTreeGridData';
import initTreeGridData from '@salesforce/apex/AssortmentMatrixCtrl.initTreeGridData';

//NEW LABELS
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
export default class AssortmentMatrixTreeGrid extends LightningElement {
    @api recordId;
    @api gridLayout;
    //BOOLEANS
    isDataLoading = true;
    isLoading = true;
    labels = {
        LBL_No_Item_To_Display,
    }
    //STRINGS
    gridSettingsJSON;
    //SET THE Assortment ID
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        console.log('this.currentPageReference.state: ' + JSON.stringify(this.currentPageReference.state))
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            console.log('this.currentPageReference.state.c__recordId: ' + this.currentPageReference.state.c__recordId)
            this.recordId = this.currentPageReference.state.c__recordId;
        }
        if (currentPageReference.state.hasOwnProperty('c__gridLayout')) {
            this.gridLayout = this.currentPageReference.state.c__gridLayout;
        }
    }
    //LIFECYCLE
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
                pageBody.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight + "px";
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
                secondColumns.length > 0 &&
                thirdColumns.length > 0 &&
                fourthColumns.length > 0
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
            initTreeGridData({
                assortmentId: this.recordId,
                gridLayout: this.gridLayout
            }).then((result) => {
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
    @track fieldsToDisplay = [];
    currentAssortment = {};
    afterInitialLoad(result) {
        let data = JSON.parse(result);
        console.log('data: ' + JSON.stringify(data))
        this.title = data.assortmentObjLabel
        console.log('this.title : ' + this.title)
        this.gridSettings = data.gridSettingsManager;
        console.log('this.gridSettings : ' + JSON.stringify(this.gridSettings))
        this.currentAssortment = data.currentAssortment;
        this.fieldsToDisplay = this.gridSettings.GRID_FIELDS.filter(item => {
            item.fieldLabel = item.fieldLabel.toUpperCase();
            item.headerstyle = item.headerStyle?.style
            return item.isNumberField;
        });
        this.isLoading = false;
        this.loadData();
    }
    //ACTUAL DATA
    fieldsToSum = [];
    loadData() {
        this.fieldsToSum = [];
        this.fieldsToDisplay.forEach(field => {
            this.fieldsToSum.push(field.fieldName);
        });
        console.log('this.fieldsToSum: ' + JSON.stringify(this.fieldsToSum))
        loadTreeGridData({
            currentAssortmentJSON: JSON.stringify(this.currentAssortment),
            fieldsToSum: this.fieldsToSum
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

        this.subTotalsMap = data.subTotalsMap;
        console.log('this.subTotalsMap: ' + JSON.stringify(this.subTotalsMap))
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
        console.log(' this.fieldsToDisplay: ' + JSON.stringify(this.fieldsToDisplay))
        for (let key in data.categoryTreeMap) {
            this.dataPreperation(data.categoryTreeMap[key], 1)
        }
        console.log('this.treeList: ' + JSON.stringify(this.treeList))
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
                for (let field of this.fieldsToSum) {
                    row.sums[field] += childSums[field];
                }
            }
        } else {
            let subTotalKey = row.key;
            console.log('subTotalKey: ' + subTotalKey)
            let subTotals = this.subTotalsMap[subTotalKey];
            if (subTotals != null) {
                for (let field of this.fieldsToSum) {
                    row.sums[field] = subTotals[field.replace('.', '')];
                }
            }
        }
        return row.sums;
    }
    fieldList = []
    dataPreperation(row, level) {
        row.level = level;
        let val = [];
        for (let field of this.fieldsToDisplay) {
            let itemId = field.fieldName;
            val.push({
                Id: itemId,
                scale: field.scale,
                style: field.style,
                value: (parseFloat(row.sums[itemId]))
            });
        }
        row.values = val;
        row.show = level == 1 || level == 2;
        row.expanded = level == 1 || level == 2;
        row.ariaExpanded = level == 1;
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