import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import initData from '@salesforce/apex/AssortmentFollowupReportController.initData';
import loadTargetData from '@salesforce/apex/AssortmentFollowupReportController.loadTargetData';

import AssortmentDetail__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Product__OBJECT from '@salesforce/schema/Product2';
import Path__c from "@salesforce/schema/Hierarchy__c.Path__c";
import Assortment__c from "@salesforce/schema/AssortmentDetail__c.Assortment__c";
import BusinessUnitTarget__c from "@salesforce/schema/Assortment__c.BusinessUnitTarget__c";
import BusinessUnitSource__c from "@salesforce/schema/Assortment__c.BusinessUnitSource__c";

//Dv / Ref
import WDChannelBaseNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.WDChannelBaseNego_TargetGap__c";
import PNChannelBaseNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.PNChannelBaseNego_TargetGap__c";
import Product__c from "@salesforce/schema/AssortmentDetail__c.Product__c";
import BusinessUnitCluster__c from "@salesforce/schema/AssortmentDetail__c.BusinessUnitCluster__c";
//Qty / Volume
import KVolumeBudget__c from "@salesforce/schema/AssortmentDetail__c.KVolumeBudget__c";
import KVolumeNego__c from "@salesforce/schema/AssortmentDetail__c.KVolumeNego__c";
import QtyNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.QtyNego_TargetGap__c";
import KVolumeNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.KVolumeNego_TargetGap__c";
//Sell / GP
//import SelloutNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.SelloutNego_TargetGap__c";
import GPNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.GPNego_TargetGap__c";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_Scope_Name from "@salesforce/label/c.LBL_Scope_Name";
import LBL_WD_Ref from "@salesforce/label/c.LBL_WD_Ref";
import LBL_Qty_Volume from "@salesforce/label/c.LBL_Qty_Volume";
import LBL_Sell_GP from "@salesforce/label/c.LBL_Sell_GP";

const API_NAMES = {
    Assortment__c: {
        BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
        BusinessUnitTarget__r: BusinessUnitTarget__c.fieldApiName.replace(/__c$/, '__r'),
        BusinessUnitSource__r: BusinessUnitSource__c.fieldApiName.replace(/__c$/, '__r'),
    },
    AssortmentDetail__c: {
        objectApiName: AssortmentDetail__OBJECT.objectApiName,
        Assortment__r: Assortment__c.fieldApiName.replace(/__c$/, '__r'),
        Product__c: Product__c.fieldApiName,
        Product__r: Product__c.fieldApiName.replace(/__c$/, '__r'),
        WDChannelBaseNego_TargetGap__c: WDChannelBaseNego_TargetGap__c.fieldApiName,
        PNChannelBaseNego_TargetGap__c: PNChannelBaseNego_TargetGap__c.fieldApiName,
        BusinessUnitCluster__c: BusinessUnitCluster__c.fieldApiName,
        BusinessUnitCluster__r: BusinessUnitCluster__c.fieldApiName.replace(/__c$/, '__r'),
        KVolumeBudget__c: KVolumeBudget__c.fieldApiName,
        KVolumeNego__c: KVolumeNego__c.fieldApiName,
        QtyNego_TargetGap__c: QtyNego_TargetGap__c.fieldApiName,
        KVolumeNego_TargetGap__c: KVolumeNego_TargetGap__c.fieldApiName,
        // SelloutNego_TargetGap__c: SelloutNego_TargetGap__c.fieldApiName,
        GPNego_TargetGap__c: GPNego_TargetGap__c.fieldApiName
    },
    Hierarchy__c: {
        Path__c: Path__c.fieldApiName
    }
}

export default class AssortmentFollowupReport extends LightningElement {

    @api selectedYear;
    @api selectedchannelId;
    pageNumber = 1;
    asdFields;
    prodFields;
    @track tableLoading = true;
    @track isEmptyList = true;
    @track resultsAsdArray = [];
    @track productFields = [];
    @track budgetFields = {
        dvrefBudgetFields: [],
        qtyvolumeBudgetFields: [],
        sellgpBudgetFields: [],
    };
    @track targetFields = {
        dvrefTargetFields: [],
        qtyvolumeTargetFields: [],
        sellgpTargetFields: [],
    };
    @track selectedScopes = [];
    @track channel = {
        Id: '',
        Name: '',
        link: ''
    };
    @track labels = {
        LBL_No_Record_To_Display,
        LBL_Scope_Name,
        LBL_WD_Ref,
        LBL_Qty_Volume,
        LBL_Sell_GP,
    }
    @track wiresIsDone = {
        objectInfoASD: false,
        objectInfoProduct: false,
    }
    @wire(getObjectInfo, { objectApiName: AssortmentDetail__OBJECT }) objectInfoASD({ error, data }) {
        if (data) {
            this.asdFields = data.fields;
            this.wiresIsDone.objectInfoASD = true;
            this.checkWireIsDone();
        } else if (error) {
            this.toastMsg('ERROR', error, 'ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: Product__OBJECT }) objectInfoProduct({ error, data }) {
        if (data) {
            this.prodFields = data.fields;
            this.wiresIsDone.objectInfoProduct = true;
            this.checkWireIsDone();
        } else if (error) {
            this.toastMsg('ERROR', error, 'ERROR');
        }
    }
    checkWireIsDone() {
        if (this.wiresIsDone.objectInfoASD && this.wiresIsDone.objectInfoProduct) {
            this.initData();
        }
    }
    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
    }
    rendered = false;
    renderedCallback() {
        this.setnumberOfFixedColumns();
        let body = this.template.querySelector('.main-panel');
        let tabHeader = this.template.querySelector('.tabHeader');
        if (!this.rendered && body && tabHeader) {
            this.changeHeight();
            this.rendered = true;
        }
    }

    @track asdList = []
    asdQuery;
    heMap = {};
    initData() {
        this.tableLoading = true;
        this.resultsAsdArray = [];
        this.asdList = [];
        this.asdWQtyVolumeList = [];
        this.asdWSellGPList = [];
        initData({ year: this.selectedYear, channelId: this.selectedchannelId }).then((result) => {
            this.channel = {
                Id: this.selectedchannelId,
                Name: '',
                link: '/' + this.selectedchannelId
            };
            let fieldNamesWhite = [
                API_NAMES.AssortmentDetail__c.WDChannelBaseNego_TargetGap__c,
                API_NAMES.AssortmentDetail__c.PNChannelBaseNego_TargetGap__c,
                API_NAMES.AssortmentDetail__c.KVolumeBudget__c,
                API_NAMES.AssortmentDetail__c.KVolumeNego__c,
                API_NAMES.AssortmentDetail__c.QtyNego_TargetGap__c,
                API_NAMES.AssortmentDetail__c.KVolumeNego_TargetGap__c,
                // API_NAMES.AssortmentDetail__c.SelloutNego_TargetGap__c,
                API_NAMES.AssortmentDetail__c.GPNego_TargetGap__c
            ]
            let resultWrapper = JSON.parse(result);
            for (let field of resultWrapper.productFields) {
                this.productFields.push({ fieldName: field, fieldLabel: this.prodFields[field].label });
            }
            for (let field of resultWrapper.dvrefBudgetFields) {
                this.budgetFields.dvrefBudgetFields.push({ fieldName: field, fieldLabel: this.asdFields[field].label, style: !fieldNamesWhite.includes(field) ? 'background-color:#daf2d0;' : 'background-color:#FFFFFF;' });
            }
            for (let field of resultWrapper.qtyvolumeBudgetFields) {
                this.budgetFields.qtyvolumeBudgetFields.push({ fieldName: field, fieldLabel: this.asdFields[field].label, style: !fieldNamesWhite.includes(field) ? 'background-color:#f8e4f6;' : 'background-color:#FFFFFF;' });
            }
            for (let field of resultWrapper.sellgpBudgetFields) {
                this.budgetFields.sellgpBudgetFields.push({ fieldName: field, fieldLabel: this.asdFields[field].label, style: !fieldNamesWhite.includes(field) ? 'background-color:#dae9f8;' : 'background-color:#FFFFFF;' });
            }
            for (let field of resultWrapper.dvrefTargetFields) {
                this.targetFields.dvrefTargetFields.push({ fieldName: field, fieldLabel: this.asdFields[field].label, style: !fieldNamesWhite.includes(field) ? 'background-color:#daf2d0;' : 'background-color:#FFFFFF;' });
            }
            for (let field of resultWrapper.qtyvolumeTargetFields) {
                this.targetFields.qtyvolumeTargetFields.push({ fieldName: field, fieldLabel: this.asdFields[field].label, style: !fieldNamesWhite.includes(field) ? 'background-color:#f8e4f6;' : 'background-color:#FFFFFF;' });
            }
            for (let field of resultWrapper.sellgpTargetFields) {
                this.targetFields.sellgpTargetFields.push({ fieldName: field, fieldLabel: this.asdFields[field].label, style: !fieldNamesWhite.includes(field) ? 'background-color:#dae9f8;' : 'background-color:#FFFFFF;' });
            }
            this.selectedScopes = resultWrapper.selectedScopes;
            this.asdQuery = resultWrapper.asdQuery;
            if (resultWrapper.heList.length > 0) {
                for (let he of resultWrapper.heList) {
                    this.heMap[he[API_NAMES.Hierarchy__c.Path__c]] = he.Name;
                }
            }
            this.loadChunkData();
        }).catch(error => {
            console.log('error init data');
            console.error(error);
        });
    }
    loadChunkData() {
        this.tableLoading = true;
        loadTargetData({ asdQuery: this.asdQuery, pageNumber: this.pageNumber }).then((result) => {
            if (result == '') {
                this.isEmptyList = true;
                this.tableLoading = false;
            } else {
                let resultWrapper = JSON.parse(result);
                this.resultsAsdArray.push(...resultWrapper.asdList);
                if (resultWrapper.totalSize == this.resultsAsdArray.length) {
                    if (this.resultsAsdArray.length != 0) {
                        this.buildDataToDisplay();
                    }
                } else {
                    this.pageNumber++;
                    this.loadChunkData();
                }
            }
        }).catch(error => {
            console.log('error load data');
            console.error(error);
        });
    }
    @track tabMgt = {
        first: true,
        second: false,
        third: false,
    }

    get categoryColspan() {
        if (this.tabMgt.first) {
            return this.asdList[0].scopeValues[0].fieldsDvRef.length;
        } else if (this.tabMgt.second) {
            return this.asdList[0].scopeValues[0].fieldsQtyVolume.length;
        }
        return this.asdList[0].scopeValues[0].fieldsSellGP.length;
    }

    setnumberOfFixedColumns() {
        // Sticky / Fixed columns for first Table
        if (this.template.querySelector('.main-table')) {
            let tableTrs = this.template.querySelector('.main-table').rows;
            let nbOfFixedColumns = 2;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                let left = 0;
                if (tableTrs[index].classList?.contains('category') || index == 0) {
                    nbOfFixedColumns = 1;
                } else {
                    nbOfFixedColumns = 2;
                }
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index != 1 && index2 < nbOfFixedColumns) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = index == 0 ? 5 : 3;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : childrens[index2].tagName === 'TH' ? '' : 'white';
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.left = 'unset';
                        childrens[index2].style.zIndex = 'unset';
                    }
                }
            }
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = index2 == 0 ? 5 : 4;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
            let secondHeader = tableTrs[1].children;
            for (let index2 = 0; secondHeader && index2 < secondHeader.length; index2++) {
                secondHeader[index2].style.position = 'sticky';
                secondHeader[index2].style.top = tableTrs[0].offsetHeight + 'px';
                secondHeader[index2].style.zIndex = 4;
                secondHeader[index2].style.backgroundColor = secondHeader[index2].style.backgroundColor ? secondHeader[index2].style.backgroundColor : '';
            }
        }
        // Sticky / Fixed columns for second Table
        if (this.template.querySelector('.product-table')) {
            let tableTrs = this.template.querySelector('.product-table').rows;
            let nbOfFixedColumns = 3;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                let left = 0;
                if (tableTrs[index].classList?.contains('category') || index == 0) {
                    nbOfFixedColumns = 1;
                } else {
                    nbOfFixedColumns = 3;
                }
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < nbOfFixedColumns) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = index == 0 || index == 1 ? 5 : 3;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : childrens[index2].tagName === 'TH' ? '' : 'white';
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.left = 'unset';
                        childrens[index2].style.zIndex = 'unset';
                    }
                }
            }
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = index2 == 0 ? 5 : 4;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
            let secondHeader = tableTrs[1].children;
            for (let index2 = 0; secondHeader && index2 < secondHeader.length; index2++) {
                secondHeader[index2].style.position = 'sticky';
                secondHeader[index2].style.top = tableTrs[0].offsetHeight + 'px';
                secondHeader[index2].style.zIndex = index2 < nbOfFixedColumns ? 5 : 4;
                secondHeader[index2].style.backgroundColor = secondHeader[index2].style.backgroundColor ? secondHeader[index2].style.backgroundColor : '';
            }
        }
    }

    @track selectedStyle = 'background-color:#92d050;color:white;';
    changeTab(event) {
        console.log('changeTab')
        let tab = event.target.dataset.tab;
        let firstTab = this.template.querySelector('.firstTab');
        let secondTab = this.template.querySelector('.secondTab');
        let thirdTab = this.template.querySelector('.thirdTab');
        if (tab == 'first') {
            this.tabMgt.first = true;
            this.tabMgt.second = false;
            this.tabMgt.third = false;
            firstTab.style.backgroundColor = '#92d050';
            secondTab.style.backgroundColor = '';
            thirdTab.style.backgroundColor = '';
            firstTab.style.color = 'white';
            secondTab.style.color = '';
            thirdTab.style.color = '';
            this.selectedStyle = 'background-color:#92d050;color:white;';
        } else if (tab == 'second') {
            this.tabMgt.first = false;
            this.tabMgt.second = true;
            this.tabMgt.third = false;
            firstTab.style.backgroundColor = '';
            secondTab.style.backgroundColor = '#e49edd';
            thirdTab.style.backgroundColor = '';
            firstTab.style.color = '';
            secondTab.style.color = 'white';
            thirdTab.style.color = '';
            this.selectedStyle = 'background-color:#e49edd;color:white;';
        } else if (tab == 'third') {
            this.tabMgt.first = false;
            this.tabMgt.second = false;
            this.tabMgt.third = true;
            firstTab.style.backgroundColor = '';
            secondTab.style.backgroundColor = '';
            thirdTab.style.backgroundColor = '#0c769e';
            firstTab.style.color = '';
            secondTab.style.color = '';
            thirdTab.style.color = 'white';
            this.selectedStyle = 'background-color:#0c769e;color:white;';
        }
        this.showDetailedData = false;
        this.changeHeight();
    }

    @track scopeDvRefColspan = 1;
    @track scopeQtyVolumeColspan = 1;
    @track scopeSellGPColspan = 1;

    buTargetMap = new Map();
    @track buTargetList = [];
    buildDataToDisplay() {
        this.isEmptyList = false;
        this.tableLoading = true;
        let asdBudgetList = [];
        let asdTargetMap = new Map();
        console.log('this.resultsAsdArray >>> ' + JSON.stringify(this.resultsAsdArray))
        for (let asd of this.resultsAsdArray) {
            if (asd[API_NAMES.AssortmentDetail__c.Assortment__r].RecordType.DeveloperName == 'ChannelBudget') {
                asdBudgetList.push(asd);
                if (this.channel.Name == '') {
                    this.channel.Name = asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__r].Name;
                }
            } else if (asd[API_NAMES.AssortmentDetail__c.Assortment__r].RecordType.DeveloperName == 'Target') {
                if (!asdTargetMap.has(asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c])) {
                    asdTargetMap.set(asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c], []);
                }
                asdTargetMap.get(asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c]).push(asd);
                if (this.channel.Name == '') {
                    this.channel.Name = asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitSource__r].Name;
                }
            }
            // BU Target 
            if (asd[API_NAMES.AssortmentDetail__c.Assortment__r].RecordType.DeveloperName == 'Target' && !this.buTargetMap.has(asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c])) {
                this.buTargetMap.set(asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c], asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__r].Name);
                this.buTargetList.push({ Id: asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c], Name: asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__r].Name, link: '/' + asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c] })
            }
        }

        let initDvRefFields = [];
        for (let field of this.budgetFields.dvrefBudgetFields) {
            let fieldWrapper = {
                fieldType: 'Budget',
                fieldApiName: field.fieldName,
                scale: this.asdFields[field.fieldName].scale,
                fieldValue: 0,
                style: field.style
            }
            initDvRefFields.push(fieldWrapper);
        }
        for (let bu of this.buTargetMap.keys()) {
            for (let field of this.targetFields.dvrefTargetFields) {
                let fieldWrapper = {
                    fieldType: 'Target',
                    buId: bu,
                    buName: this.buTargetMap.get(bu),
                    buLink: '/' + bu,
                    fieldApiName: field.fieldName,
                    scale: this.asdFields[field.fieldName].scale,
                    fieldValue: 0,
                    style: field.style
                }
                initDvRefFields.push(fieldWrapper);
            }
        }

        let initQtyVolumeFields = [];
        for (let field of this.budgetFields.qtyvolumeBudgetFields) {
            let fieldWrapper = {
                fieldType: 'Budget',
                fieldApiName: field.fieldName,
                scale: this.asdFields[field.fieldName].scale,
                fieldValue: 0,
                style: field.style
            }
            initQtyVolumeFields.push(fieldWrapper);
        }
        for (let bu of this.buTargetMap.keys()) {
            for (let field of this.targetFields.qtyvolumeTargetFields) {
                let fieldWrapper = {
                    fieldType: 'Target',
                    buId: bu,
                    buName: this.buTargetMap.get(bu),
                    buLink: '/' + bu,
                    fieldApiName: field.fieldName,
                    scale: this.asdFields[field.fieldName].scale,
                    fieldValue: 0,
                    style: field.style
                }
                initQtyVolumeFields.push(fieldWrapper);
            }
        }

        let initSellGPFields = [];
        for (let field of this.budgetFields.sellgpBudgetFields) {
            let fieldWrapper = {
                fieldType: 'Budget',
                fieldApiName: field.fieldName,
                scale: this.asdFields[field.fieldName].scale,
                fieldValue: 0,
                style: field.style
            }
            initSellGPFields.push(fieldWrapper);
        }
        for (let bu of this.buTargetMap.keys()) {
            for (let field of this.targetFields.sellgpTargetFields) {
                let fieldWrapper = {
                    fieldType: 'Target',
                    buId: bu,
                    buName: this.buTargetMap.get(bu),
                    buLink: '/' + bu,
                    fieldApiName: field.fieldName,
                    scale: this.asdFields[field.fieldName].scale,
                    fieldValue: 0,
                    style: field.style
                }
                initSellGPFields.push(fieldWrapper);
            }
        }

        for (let scope of this.selectedScopes) {
            let scopeWrapper = this.buildAsdData(scope, asdBudgetList, asdTargetMap, initDvRefFields, initQtyVolumeFields, initSellGPFields)
            this.asdList.push(scopeWrapper);

        }
        // for (let scope of this.selectedScopes) {
        //     let scopeWrapper = this.buildQtyVolumeAsdData(scope, asdBudgetList, asdTargetMap, initQtyVolumeFields)
        //     this.asdWQtyVolumeList.push(scopeWrapper);

        // }
        // for (let scope of this.selectedScopes) {
        //     let scopeWrapper = this.buildSellGPAsdData(scope, asdBudgetList, asdTargetMap, initSellGPFields)
        //     this.asdWSellGPList.push(scopeWrapper);

        // }
        this.addBorderTable();
        this.scopeDvRefColspan = this.budgetFields.dvrefBudgetFields.length + (this.buTargetList.length * this.targetFields.dvrefTargetFields.length) + 2;
        this.scopeQtyVolumeColspan = this.budgetFields.qtyvolumeBudgetFields.length + (this.buTargetList.length * this.targetFields.qtyvolumeTargetFields.length) + 2;
        this.scopeSellGPColspan = this.budgetFields.sellgpBudgetFields.length + (this.buTargetList.length * this.targetFields.sellgpTargetFields.length) + 2;
        this.tableLoading = false;
    }

    addBorderTable() {
        for (let scopeWrapper of this.asdList) {
            scopeWrapper.scopeValues[0].style = 'border-top:solid black;';
            scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].style += 'border-bottom: solid black;';
            for (let field of scopeWrapper.scopeValues[0].fieldsDvRef) {
                field.style += 'border-top:solid black;';
            }
            for (let field of scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].fieldsDvRef) {
                field.style += 'border-bottom: solid black;';
            }
            for (let field of scopeWrapper.scopeValues[0].fieldsQtyVolume) {
                field.style += 'border-top:solid black;';
            }
            for (let field of scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].fieldsQtyVolume) {
                field.style += 'border-bottom: solid black;';
            }
            for (let field of scopeWrapper.scopeValues[0].fieldsSellGP) {
                field.style += 'border-top:solid black;';
            }
            for (let field of scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].fieldsSellGP) {
                field.style += 'border-bottom: solid black;';
            }
            for (let row of scopeWrapper.scopeValues) {
                for (let i = 0; i < row.fieldsDvRef.length; i++) {
                    if (i == this.budgetFields.dvrefBudgetFields.length - 1 ||
                        row.fieldsDvRef[i].fieldApiName == this.targetFields.dvrefTargetFields[this.targetFields.dvrefTargetFields.length - 1].fieldName) {
                        row.fieldsDvRef[i].style += 'border-right: 2px solid black;';
                    }
                }
                for (let i = 0; i < row.fieldsQtyVolume.length; i++) {
                    if (i == this.budgetFields.qtyvolumeBudgetFields.length - 1 ||
                        row.fieldsQtyVolume[i].fieldApiName == this.targetFields.qtyvolumeTargetFields[this.targetFields.qtyvolumeTargetFields.length - 1].fieldName) {
                        row.fieldsQtyVolume[i].style += 'border-right: 2px solid black;';
                    }
                }
                for (let i = 0; i < row.fieldsSellGP.length; i++) {
                    if (i == this.budgetFields.sellgpBudgetFields.length - 1 ||
                        row.fieldsSellGP[i].fieldApiName == this.targetFields.sellgpTargetFields[this.targetFields.sellgpTargetFields.length - 1].fieldName) {
                        row.fieldsSellGP[i].style += 'border-right: 2px solid black;';
                    }
                }
            }
        }
        // for (let scopeWrapper of this.asdWQtyVolumeList) {
        //     scopeWrapper.scopeValues[0].style = 'border-top:solid black;';
        //     scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].style += 'border-bottom: solid black;';
        //     for (let field of scopeWrapper.scopeValues[0].fields) {
        //         field.style += 'border-top:solid black;';
        //     }
        //     for (let field of scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].fields) {
        //         field.style += 'border-bottom: solid black;';
        //     }
        // }
        // for (let scopeWrapper of this.asdWSellGPList) {
        //     scopeWrapper.scopeValues[0].style = 'border-top:solid black;';
        //     scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].style += 'border-bottom: solid black;';
        //     for (let field of scopeWrapper.scopeValues[0].fields) {
        //         field.style += 'border-top:solid black;';
        //     }
        //     for (let field of scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].fields) {
        //         field.style += 'border-bottom: solid black;';
        //     }
        // }
    }

    productdetailsMap = {};

    buildAsdData(scope, asdBudgetList, asdTargetMap, initDvRefFields, initQtyVolumeFields, initSellGPFields) {
        let scopeWrapper = {
            Name: scope.Name,
            label: scope.label,
            scopeValues: []
        }
        let scopeValues = [];

        for (let asdBudget of asdBudgetList) {
            let scopeFieldValues = scope.Name.split('.');
            let scopeValue = asdBudget[API_NAMES.AssortmentDetail__c.Product__r][scopeFieldValues[0]];
            for (let index = 1; index < scopeFieldValues.length; index++) {
                if (scopeValue) {
                    scopeValue = scopeValue[scopeFieldValues[index]];
                }
            }
            if (scope.level != null && scopeValue) {
                let splittedPathValues = scopeValue.split('|');
                let value = '';
                for (let index = 0; index <= scope.level; index++) {
                    value += splittedPathValues[index] + (index < parseInt(scope.level) ? '|' : '');
                }
                if (this.heMap.hasOwnProperty(value)) {
                    scopeValue = this.heMap[value];
                }
            }
            if (!scopeValues.includes(scopeValue)) {
                scopeValues.push(scopeValue);
                scopeWrapper.scopeValues.push({
                    value: scopeValue,
                    fieldsDvRef: JSON.parse(JSON.stringify(initDvRefFields)),
                    fieldsQtyVolume: JSON.parse(JSON.stringify(initQtyVolumeFields)),
                    fieldsSellGP: JSON.parse(JSON.stringify(initSellGPFields)), style: ''
                });
            }
            let scopeW = scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0];
            if (!this.productdetailsMap.hasOwnProperty(scope.Name)) {
                this.productdetailsMap[scope.Name] = {};
            }
            if (!this.productdetailsMap[scope.Name].hasOwnProperty(scopeValue)) {
                this.productdetailsMap[scope.Name][scopeValue] = {};
            }
            if (!this.productdetailsMap[scope.Name][scopeValue].hasOwnProperty(asdBudget[API_NAMES.AssortmentDetail__c.Product__c])) {
                this.productdetailsMap[scope.Name][scopeValue][asdBudget[API_NAMES.AssortmentDetail__c.Product__c]] = {};
            }
            this.productdetailsMap[scope.Name][scopeValue][asdBudget[API_NAMES.AssortmentDetail__c.Product__c]].Budget = asdBudget;
            for (let field of scopeW.fieldsDvRef) {
                if (field.fieldType == 'Budget') {
                    field.fieldValue = field.fieldValue + (asdBudget[field.fieldApiName] != null ? asdBudget[field.fieldApiName] : 0)
                }
            }
            for (let field of scopeW.fieldsQtyVolume) {
                if (field.fieldType == 'Budget') {
                    field.fieldValue = field.fieldValue + (asdBudget[field.fieldApiName] != null ? asdBudget[field.fieldApiName] : 0)
                }
            }
            for (let field of scopeW.fieldsSellGP) {
                if (field.fieldType == 'Budget') {
                    field.fieldValue = field.fieldValue + (asdBudget[field.fieldApiName] != null ? asdBudget[field.fieldApiName] : 0)
                }
            }
        }
        for (let bu of this.buTargetMap.keys()) {
            for (let asdTarget of asdTargetMap.get(bu)) {
                let scopeFieldValues = scope.Name.split('.');
                let scopeValue = asdTarget[API_NAMES.AssortmentDetail__c.Product__r][scopeFieldValues[0]];
                for (let index = 1; index < scopeFieldValues.length; index++) {
                    if (scopeValue) {
                        scopeValue = scopeValue[scopeFieldValues[index]];
                    }
                }
                if (scope.level != null && scopeValue) {
                    let splittedPathValues = scopeValue.split('|');
                    let value = '';
                    for (let index = 0; index <= scope.level; index++) {
                        value += splittedPathValues[index] + (index < parseInt(scope.level) ? '|' : '');
                    }
                    if (this.heMap.hasOwnProperty(value)) {
                        scopeValue = this.heMap[value];
                    }
                }
                if (!scopeValues.includes(scopeValue)) {
                    scopeValues.push(scopeValue);
                    scopeWrapper.scopeValues.push({
                        value: scopeValue,
                        fieldsDvRef: initDvRefFields,
                        fieldsQtyVolume: initQtyVolumeFields,
                        fieldsSellGP: initSellGPFields,
                        style: ''
                    });
                }
                let scopeW = scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0];
                if (!this.productdetailsMap.hasOwnProperty(scope.Name)) {
                    this.productdetailsMap[scope.Name] = {};
                }
                if (!this.productdetailsMap[scope.Name].hasOwnProperty(scopeValue)) {
                    this.productdetailsMap[scope.Name][scopeValue] = {};
                }
                if (!this.productdetailsMap[scope.Name][scopeValue].hasOwnProperty(asdTarget[API_NAMES.AssortmentDetail__c.Product__c])) {
                    this.productdetailsMap[scope.Name][scopeValue][asdTarget[API_NAMES.AssortmentDetail__c.Product__c]] = {};
                }
                this.productdetailsMap[scope.Name][scopeValue][asdTarget[API_NAMES.AssortmentDetail__c.Product__c]][bu] = asdTarget;
                for (let field of scopeW.fieldsDvRef) {
                    if (field.fieldType == 'Target' && field.buId == bu) {
                        field.fieldValue = field.fieldValue + (asdTarget[field.fieldApiName] != null ? asdTarget[field.fieldApiName] : 0)
                    }
                }
                for (let field of scopeW.fieldsQtyVolume) {
                    if (field.fieldType == 'Target' && field.buId == bu) {
                        field.fieldValue = field.fieldValue + (asdTarget[field.fieldApiName] != null ? asdTarget[field.fieldApiName] : 0)
                    }
                }
                for (let field of scopeW.fieldsSellGP) {
                    if (field.fieldType == 'Target' && field.buId == bu) {
                        field.fieldValue = field.fieldValue + (asdTarget[field.fieldApiName] != null ? asdTarget[field.fieldApiName] : 0)
                    }
                }
            }
        }
        return scopeWrapper;
    }

    // buildQtyVolumeAsdData(scope, asdBudgetList, asdTargetMap, initFields) {
    //     let scopeWrapper = {
    //         Name: scope.Name,
    //         label: scope.label,
    //         scopeValues: []
    //     }
    //     let scopeValues = [];

    //     for (let asdBudget of asdBudgetList) {
    //         let scopeFieldValues = scope.Name.split('.');
    //         let scopeValue = asdBudget.Product__r[scopeFieldValues[0]];
    //         for (let index = 1; index < scopeFieldValues.length; index++) {
    //             scopeValue = scopeValue[scopeFieldValues[index]];
    //         }
    //         if (scope.level != null && scopeValue) {
    //             let splittedPathValues = scopeValue.split('|');
    //             let value = '';
    //             for (let index = 0; index <= scope.level; index++) {
    //                 value += splittedPathValues[index] + (index < parseInt(scope.level) ? '|' : '');
    //             }
    //             if (this.heMap.hasOwnProperty(value)) {
    //                 scopeValue = this.heMap[value];
    //             }
    //         }
    //         if (!scopeValues.includes(scopeValue)) {
    //             scopeValues.push(scopeValue);
    //             scopeWrapper.scopeValues.push({ value: scopeValue, fields: JSON.parse(JSON.stringify(initFields)), style: '' });
    //         }
    //         for (let field of scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0].fields) {
    //             if (field.fieldType == 'Budget') {
    //                 field.fieldValue = field.fieldValue + (asdBudget[field.fieldApiName] != null ? asdBudget[field.fieldApiName] : 0)
    //             }
    //         }
    //     }
    //     for (let bu of this.buTargetMap.keys()) {
    //         for (let asdTarget of asdTargetMap.get(bu)) {
    //             let scopeFieldValues = scope.Name.split('.');
    //             let scopeValue = asdTarget.Product__r[scopeFieldValues[0]];
    //             for (let index = 1; index < scopeFieldValues.length; index++) {
    //                 scopeValue = scopeValue[scopeFieldValues[index]];
    //             }
    //             if (scope.level != null && scopeValue) {
    //                 let splittedPathValues = scopeValue.split('|');
    //                 let value = '';
    //                 for (let index = 0; index <= scope.level; index++) {
    //                     value += splittedPathValues[index] + (index < parseInt(scope.level) ? '|' : '');
    //                 }
    //                 if (this.heMap.hasOwnProperty(value)) {
    //                     scopeValue = this.heMap[value];
    //                 }
    //             }
    //             if (!scopeValues.includes(scopeValue)) {
    //                 scopeValues.push(scopeValue);
    //                 scopeWrapper.scopeValues.push({ value: scopeValue, fields: initFields, style: '' });
    //             }
    //             for (let field of scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0].fields) {
    //                 if (field.fieldType == 'Target' && field.buId == bu) {
    //                     field.fieldValue = field.fieldValue + (asdTarget[field.fieldApiName] != null ? asdTarget[field.fieldApiName] : 0)
    //                 }
    //             }
    //         }
    //     }
    //     return scopeWrapper;
    //     //console.log('scopeWrapper >>> ' + JSON.stringify(scopeWrapper));
    // }

    // buildSellGPAsdData(scope, asdBudgetList, asdTargetMap, initFields) {
    //     let scopeWrapper = {
    //         Name: scope.Name,
    //         label: scope.label,
    //         scopeValues: []
    //     }
    //     let scopeValues = [];

    //     for (let asdBudget of asdBudgetList) {
    //         let scopeFieldValues = scope.Name.split('.');
    //         let scopeValue = asdBudget.Product__r[scopeFieldValues[0]];
    //         for (let index = 1; index < scopeFieldValues.length; index++) {
    //             scopeValue = scopeValue[scopeFieldValues[index]];
    //         }
    //         if (scope.level != null && scopeValue) {
    //             let splittedPathValues = scopeValue.split('|');
    //             let value = '';
    //             for (let index = 0; index <= scope.level; index++) {
    //                 value += splittedPathValues[index] + (index < parseInt(scope.level) ? '|' : '');
    //             }
    //             if (this.heMap.hasOwnProperty(value)) {
    //                 scopeValue = this.heMap[value];
    //             }
    //         }
    //         if (!scopeValues.includes(scopeValue)) {
    //             scopeValues.push(scopeValue);
    //             scopeWrapper.scopeValues.push({ value: scopeValue, fields: JSON.parse(JSON.stringify(initFields)), style: '' });
    //         }
    //         for (let field of scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0].fields) {
    //             if (field.fieldType == 'Budget') {
    //                 field.fieldValue = field.fieldValue + (asdBudget[field.fieldApiName] != null ? asdBudget[field.fieldApiName] : 0)
    //             }
    //         }
    //     }
    //     for (let bu of this.buTargetMap.keys()) {
    //         for (let asdTarget of asdTargetMap.get(bu)) {
    //             let scopeFieldValues = scope.Name.split('.');
    //             let scopeValue = asdTarget.Product__r[scopeFieldValues[0]];
    //             for (let index = 1; index < scopeFieldValues.length; index++) {
    //                 scopeValue = scopeValue[scopeFieldValues[index]];
    //             }
    //             if (scope.level != null && scopeValue) {
    //                 let splittedPathValues = scopeValue.split('|');
    //                 let value = '';
    //                 for (let index = 0; index <= scope.level; index++) {
    //                     value += splittedPathValues[index] + (index < parseInt(scope.level) ? '|' : '');
    //                 }
    //                 if (this.heMap.hasOwnProperty(value)) {
    //                     scopeValue = this.heMap[value];
    //                 }
    //             }
    //             if (!scopeValues.includes(scopeValue)) {
    //                 scopeValues.push(scopeValue);
    //                 scopeWrapper.scopeValues.push({ value: scopeValue, fields: initFields, style: '' });
    //             }
    //             for (let field of scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0].fields) {
    //                 if (field.fieldType == 'Target' && field.buId == bu) {
    //                     field.fieldValue = field.fieldValue + (asdTarget[field.fieldApiName] != null ? asdTarget[field.fieldApiName] : 0)
    //                 }
    //             }
    //         }
    //     }
    //     return scopeWrapper;
    //     //console.log('scopeWrapper >>> ' + JSON.stringify(scopeWrapper));
    // }

    @track productDetailedData = [];
    @track showDetailedData = false;
    @track productBudgetFields = [];
    @track productTargetFields = [];
    buildDetailSection(event) {
        const currentButton = event.currentTarget;
        const allButtons = this.template.querySelectorAll('lightning-button-icon');
        allButtons.forEach(button => {
            button.style.border = "";
        });
        currentButton.style.border = "2px solid rgb(1, 68, 134)";
        currentButton.style.borderRadius = "5px";
        currentButton.style.paddingBottom = "5px";
        currentButton.style.paddingTop = "1px";

        this.showDetailedData = true;
        console.log('buildDetailSection >>> ' + JSON.stringify(this.productdetailsMap));
        this.productDetailedData = [];
        let scopeName = event.target.dataset.scopeName;
        let scopeValue = event.target.dataset.scopeValue;
        let budgetFields = event.target.dataset.budgetFields;
        let targetFields = event.target.dataset.targetFields;
        this.productBudgetFields = this.budgetFields[budgetFields];
        this.productTargetFields = this.targetFields[targetFields];
        let product;
        for (let prodId of Object.keys(this.productdetailsMap[scopeName][scopeValue])) {
            let productWrapper = {
                prodId: prodId,
                fields: []
            }
            let prodFieldsDone = false;
            let productBudgetFieldsIndex = 0;
            for (let field of this.productBudgetFields) {
                let fieldWrapper = {
                    fieldType: 'Budget',
                    fieldApiName: field.fieldName,
                    scale: this.asdFields[field.fieldName].scale,
                    isNumber: true,
                    fieldValue: this.productdetailsMap[scopeName][scopeValue][prodId].Budget[field.fieldName] != null ? this.productdetailsMap[scopeName][scopeValue][prodId].Budget[field.fieldName] : 0,
                    style: productBudgetFieldsIndex == this.productBudgetFields.length - 1 ? field.style += 'border-right: 2px solid black;' : field.style
                }
                productBudgetFieldsIndex++;
                product = this.productdetailsMap[scopeName][scopeValue][prodId].Budget[API_NAMES.AssortmentDetail__c.Product__r];
                if (!prodFieldsDone) {
                    let productFieldsIndex = 0;
                    for (let field of this.productFields) {
                        let fieldWrapper = {
                            fieldApiName: field.fieldName,
                            scale: this.prodFields[field.fieldName].scale,
                            //isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY' ? true : false,
                            fieldValue: product[field.fieldName],
                            style: productFieldsIndex == this.productFields.length - 1 ? 'border-right: 2px solid black;' : ''
                        }
                        productWrapper.fields.push(fieldWrapper);
                        productFieldsIndex++;
                    }
                    prodFieldsDone = true;
                }
                productWrapper.fields.push(fieldWrapper);
            }
            for (let bu of this.buTargetMap.keys()) {
                let fieldWrapper = {
                    fieldType: 'Target',
                    buId: bu,
                    buName: this.buTargetMap.get(bu),
                    buLink: '/' + bu,
                    fieldApiName: API_NAMES.AssortmentDetail__c.BusinessUnitCluster__c,
                    isNumber: false,
                    fieldValue: this.productdetailsMap[scopeName][scopeValue][prodId].hasOwnProperty(bu) && this.productdetailsMap[scopeName][scopeValue][prodId][bu][API_NAMES.AssortmentDetail__c.BusinessUnitCluster__r] != null ? this.productdetailsMap[scopeName][scopeValue][prodId][bu][API_NAMES.AssortmentDetail__c.BusinessUnitCluster__r].Name : '',
                    isHachured: !this.productdetailsMap[scopeName][scopeValue][prodId].hasOwnProperty(bu)
                }
                productWrapper.fields.push(fieldWrapper);
                let productTargetFieldsIndex = 0;
                for (let field of this.productTargetFields) {
                    let fieldWrapper = {
                        fieldType: 'Target',
                        buId: bu,
                        buName: this.buTargetMap.get(bu),
                        buLink: '/' + bu,
                        fieldApiName: field.fieldName,
                        scale: this.asdFields[field.fieldName].scale,
                        isNumber: true,
                        fieldValue: this.productdetailsMap[scopeName][scopeValue][prodId].hasOwnProperty(bu) && this.productdetailsMap[scopeName][scopeValue][prodId][bu][field.fieldName] != null ? this.productdetailsMap[scopeName][scopeValue][prodId][bu][field.fieldName] : 0,
                        isHachured: !this.productdetailsMap[scopeName][scopeValue][prodId].hasOwnProperty(bu),
                        style: productTargetFieldsIndex == this.productTargetFields.length - 1 ? field.style += 'border-right: 2px solid black;' : field.style
                    }
                    productWrapper.fields.push(fieldWrapper);
                    productTargetFieldsIndex++;
                }
            }
            this.productDetailedData.push(productWrapper);
        }
        this.changeHeight();
        console.log('productDetailedData >>> ' + JSON.stringify(productDetailedData))
    }

    get productTargetFieldsColspan() {
        return this.productTargetFields.length + 1;
    }

    changeHeight = () => {
        let body = this.template.querySelector('.main-panel');
        let tabHeader = this.template.querySelector('.tabHeader');
        if (body && tabHeader) {
            //Set table Height
            this.template.querySelector('.main-panel').style.height = window.innerHeight - (4 * 45) + 'px';
            let tabHeaderHeight = tabHeader.getBoundingClientRect().height;
            // Set First Table Height
            if (this.template.querySelector('.tabBody')) {
                this.template.querySelector('.tabBody').style.height = ((window.innerHeight - (4 * 45) - tabHeaderHeight) / (this.showDetailedData ? 2 : 1)) + 'px';
            }
            // Set First Table Height
            if (this.template.querySelector('.secondDiv')) {
                this.template.querySelector('.secondDiv').style.height = ((window.innerHeight - (4 * 45) - tabHeaderHeight) / 2) + 'px';
            }
        }
    };

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