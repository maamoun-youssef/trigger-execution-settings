import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import initData from '@salesforce/apex/AssortmentSimulatorController.initData';
import loadAssortmentDetailsData from '@salesforce/apex/AssortmentSimulatorController.loadAssortmentDetailsData';

import AssortmentDetail__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Product__OBJECT from '@salesforce/schema/Product2';

import Assortment__c from "@salesforce/schema/AssortmentDetail__c.Assortment__c";
import Product__c from "@salesforce/schema/AssortmentDetail__c.Product__c";
import BusinessUnitCluster__c from "@salesforce/schema/AssortmentDetail__c.BusinessUnitCluster__c";
import ProductCluster__c from "@salesforce/schema/AssortmentDetail__c.ProductCluster__c";
import ProductLifeStatusAss__c from "@salesforce/schema/AssortmentDetail__c.ProductLifeStatusAss__c";
import OnTop__c from "@salesforce/schema/Assortment__c.OnTop__c";
import IsInnovation__c from "@salesforce/schema/Product2.IsInnovation__c";
import Market_End_of_Life_Date__c from "@salesforce/schema/Product2.Market_End_of_Life_Date__c";
import Hierarchy__c from "@salesforce/schema/Product2.Hierarchy__c";
import Path__c from "@salesforce/schema/Hierarchy__c.Path__c";

import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Show_Only_Line_With_Difference from "@salesforce/label/c.LBL_Show_Only_Line_With_Difference";
import LBL_Show_Only_Inno_Product from "@salesforce/label/c.LBL_Show_Only_Inno_Product";
import LBL_Show_Only_Stop_Product from "@salesforce/label/c.LBL_Show_Only_Stop_Product";
import LBL_Compare_Bloc from "@salesforce/label/c.LBL_Compare_Bloc";
import LBL_Compare_Detail from "@salesforce/label/c.LBL_Compare_Detail";
import LBL_Cluster from "@salesforce/label/c.LBL_Cluster";
import LBL_Client_Status from "@salesforce/label/c.LBL_Client_Status";
import LBL_Scope_Name from "@salesforce/label/c.LBL_Scope_Name";
import LBL_Product_Info from "@salesforce/label/c.LBL_Product_Info";


export default class AssortmentDetailSimulator extends LightningElement {

    @api recordId;
    @api displayDataBasedOnBU;
    @api isBloc;
    @api headerName;
    @track loading = false;
    pageNumber = 1;
    asdFields;
    prodFields;
    @track wiresIsDone = {
        objectInfoASD: false,
        objectInfoProduct: false,
    }
    @track recordTypesAS = [];
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
    @track labels = {
        LBL_No_Item_To_Display,
        LBL_Show_Only_Line_With_Difference,
        LBL_Show_Only_Inno_Product,
        LBL_Show_Only_Stop_Product,
        LBL_Compare_Bloc,
        LBL_Compare_Detail,
        LBL_Cluster,
        LBL_Client_Status,
        LBL_Scope_Name,
        LBL_Product_Info
    }
    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
    }
    rendered = false;
    renderedCallback() {
        this.setnumberOfFixedColumns();
        let body = this.template.querySelector('.main-panel');
        let header = this.template.querySelector('.header');
        if (!this.rendered && body && header) {
            this.changeHeight();
            this.rendered = true;
        }
    }

    @track kpiGroups = [];
    @track negFields = [];
    @track targetFields = [];
    @track resultsAsdArray = [];
    @track productFields = [];
    @track selectedScopes = [];
    @track assortmentList = [];
    @track baseYear;
    productdetailsMap = {};
    asdQuery;
    heMap = {};
    initData() {
        this.loading = true;
        initData({ recordId: this.recordId, displayDataBasedOnBU: this.displayDataBasedOnBU }).then((result) => {
            let resultWrapper = JSON.parse(result);
            this.clustersMap = resultWrapper.clustersMap || {};
            this.recordTypesAS = resultWrapper.filteredRTs;
            this.baseYear = resultWrapper.baseYear;
            for (let field of resultWrapper.productFields) {
                this.productFields.push({ fieldName: field, fieldLabel: this.prodFields[field].label });
            }
            this.kpiGroups = [];
            (resultWrapper.kpiSetup || []).forEach((kpi, kpiIndex) => {
                let group = {
                    index: kpiIndex,
                    backgroundColor: kpi.backgroundColor,
                    textColor: kpi.textColor,
                    headerStyle: 'background-color:' + kpi.backgroundColor +';color:' + kpi.textColor + ';',
                    bgColorGradient: this.getSoftenedBackgroundColor(kpi.backgroundColor),
                    negFields: [],
                    targetFields: [],
                    detailColspan: 1,
                    assortmentHeaders : []
                };
                (kpi.negFields || []).forEach((field, index) => {
                    this.negFields.push(field);
                    group.negFields.push({
                        fieldLabel : this.asdFields[field].label,
                        fieldName: field,
                        style: group.headerStyle + (index === (kpi.negFields.length - 1) ? 'border-right: 2px solid black;' : '')
                    });
                });
                (kpi.targetFields || []).forEach((field, index) => {
                    this.targetFields.push(field);
                    group.targetFields.push({
                        fieldLabel : this.asdFields[field].label,
                        fieldName: field,
                        style: group.headerStyle + (index === (kpi.targetFields.length - 1) ? 'border-right: 2px solid black;' : '')
                    });
                });
                group.detailColspan = group?.negFields?.length + 2 || 1
                this.kpiGroups.push(group);
            });
            this.selectedScopes = resultWrapper.selectedScopes;
            this.asdQuery = resultWrapper.asdQuery;
            if (resultWrapper.heList.length > 0) {
                for (let he of resultWrapper.heList) {
                    this.heMap[he[Path__c.fieldApiName]] = he.Name;
                }
            }
            this.loadChunkData();
        }).catch(error => {
            console.log('error init data');
            console.error(error);
        });
    }
    loadChunkData() {
        this.loading = true;
        loadAssortmentDetailsData({ asdQuery: this.asdQuery, pageNumber: this.pageNumber, baseYear: this.baseYear }).then((result) => {
            if (result == '') {
                this.loading = false;
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
    @track records = []
    @track filters = {
        onlyInno: false,
        onlyStop: false,
        onlyLineWithDiff: false,
        RTs: ['Negotiation', 'Simulation', 'Target'],
    }

    handleChangeFilter(event) {
        let filterType = event.target.dataset.filterType;
        this.filters[filterType] = event.target.checked != null ? event.target.checked : event.target.value;
        this.buildDataToDisplay();
    }

    getSoftenedBackgroundColor(backgroundColor) {
        const match = backgroundColor.match(/#([0-9a-fA-F]{6})/g);
        if (!match || match.length === 0) return '';
        const baseColor = match[match.length - 1];
        return `background-color: ${baseColor}22;`;
    }

    buildDataToDisplay() {
        this.loading = true;
        this.records = [];
        this.assortmentList = [];
        this.productdetailsMap = {};
        this.productDetailedData = [];
        this.showDetailedData = false;
        let asListMap = {};
        let asdData = this.resultsAsdArray;
        if (this.filters.onlyLineWithDiff) {
            let properties = [Product__c.fieldApiName].concat(this.negFields);
            let targetProperties = [Product__c.fieldApiName].concat(this.targetFields);
            asdData = this.removeDuplicatesByProperties(this.resultsAsdArray, properties, targetProperties);
        }
        for (let asd of asdData) {
            if (this.filters.RTs.includes(asd[Assortment__c.fieldApiName.replace('__c', '__r')].RecordType.DeveloperName)) {
                if ((!this.filters.onlyInno && !this.filters.onlyStop)
                    || (this.filters.onlyInno && asd[Product__c.fieldApiName.replace('__c', '__r')][IsInnovation__c.fieldApiName])
                    || (this.filters.onlyStop && asd[Product__c.fieldApiName.replace('__c', '__r')][Market_End_of_Life_Date__c.fieldApiName] != null)) {
                    if (!asListMap.hasOwnProperty(asd[Assortment__c.fieldApiName])) {
                        asListMap[asd[Assortment__c.fieldApiName]] = [];
                        this.assortmentList.push({
                            Id: asd[Assortment__c.fieldApiName],
                            Name: asd[Assortment__c.fieldApiName.replace('__c', '__r')].Name,
                            link: '/' + asd[Assortment__c.fieldApiName],
                            isOnTop: asd[Assortment__c.fieldApiName.replace('__c', '__r')][OnTop__c.fieldApiName],                         
                            isTarget: asd[Assortment__c.fieldApiName.replace('__c', '__r')].RecordType.DeveloperName == 'Target',
                        });
                    }
                    asListMap[asd[Assortment__c.fieldApiName]].push(asd);
                }
            }
        }
        let initFields = [];
        this.kpiGroups.forEach(kpi => {
            kpi.assortmentHeaders = [];
            this.assortmentList.forEach(assortment => {
                let assortmentWrapper = {
                    ...assortment,
                    headerKey: kpi.index + '_' + assortment.Id,
                    fields: []
                }
                let fields = assortment.isTarget ? kpi.targetFields : kpi.negFields;
                fields.forEach((field, index) => {
                    initFields.push({
                        key: assortment.Id + '_' + field.fieldName,
                        asId: assortment.Id,
                        fieldName: field.fieldName,
                        scale: this.asdFields[field.fieldName]?.scale,
                        fieldValue: 0,
                        style: kpi.bgColorGradient + (index === (kpi.targetFields.length - 1) ? 'border-right: 2px solid black;' : ''),
                    });
                    let fieldWrapper = {
                            ...field,
                            key: kpi.index + assortment.Id + field.fieldName
                        }
                        assortmentWrapper.fields.push(fieldWrapper)
                    });
                kpi.assortmentHeaders.push(assortmentWrapper);
            });
        });
        for (let scope of this.selectedScopes) {
            let scopeWrapper = this.buildRowData(scope, asListMap, initFields);
            if (this.isBloc && scopeWrapper && scopeWrapper.scopeValues && scopeWrapper?.scopeValues.length != 0) {
                this.records.push(scopeWrapper);
            }
        }
        if (!this.isBloc) {
            this.buildDetailSection();
        } else {
            this.records.forEach(scopeW => {
                scopeW?.scopeValues.forEach(scopeValue => {
                    scopeValue.fields.forEach(field => {
                        if (field.color) {
                            field.style += 'color:' + field.color + ';';
                        }
                    })
                })
            })
            this.fillTotal();
        }
        this.addBorderTable();
        this.changeHeight();
        this.loading = false;
    }

    removeDuplicatesByProperties(arr, properties, targetProperties) {
        const keyCounts = new Map();
        const TargetKeyCounts = new Map();
        console.log('arr >>> ' + arr.length)
        // Count occurrences of each composite key
        arr.forEach(item => {
            const key = properties.map(prop => item[prop]).join('|');
            const targetkey = targetProperties.map(prop => item[prop]).join('|');
            if (item[Assortment__c.fieldApiName.replace('__c', '__r')].RecordType.DeveloperName != 'Target') {
                keyCounts.set(key, (keyCounts.get(key) || 0) + 1);
            } else {
                TargetKeyCounts.set(targetkey, (TargetKeyCounts.get(key) || 0) + 1);
            }
        });
        console.log('keyCounts >>> ' + JSON.stringify(keyCounts))
        // Filter out items where the composite key occurs more than once
        let filteredAssortments = arr.filter(item => {
            if (item[Assortment__c.fieldApiName.replace('__c', '__r')].RecordType.DeveloperName != 'Target') {
                const key = properties.map(prop => item[prop]).join('|');
                return keyCounts.get(key) === 1;
            }
        });
        let TargetFilteredAssortments = arr.filter(item => {
            if (item[Assortment__c.fieldApiName.replace('__c', '__r')].RecordType.DeveloperName == 'Target') {
                const key = targetProperties.map(prop => item[prop]).join('|');
                return TargetKeyCounts.get(key) === 1;
            }
        });
        return filteredAssortments.concat(TargetFilteredAssortments);
    }

    addBorderTable() {
        for (let scopeWrapper of this.records) {
            if (scopeWrapper?.scopeValues.length != 0) {
                scopeWrapper.scopeValues[0].style += 'border-top:2px solid black;';
                scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].style += 'border-bottom:2px solid black;';
                for (let field of scopeWrapper.scopeValues[0].fields) {
                    field.style += 'border-top:2px solid black;';
                }
                for (let field of scopeWrapper.scopeValues[scopeWrapper.scopeValues.length - 1].fields) {
                    field.style += 'border-bottom: 2px solid black;';
                }
            }
        }
    }

    get colspan() {
        return this.assortmentList.length * this.negFields.length;
    }

    buildRowData(scope, asListMap, initFields) {
        let scopeWrapper = {
            Name: scope.Name,
            label: scope.label,
            scopeValues: []
        }
        let scopeValues = [];

        for (let assortment of this.assortmentList) {
            if (asListMap.hasOwnProperty(assortment.Id)) {
                for (let asd of asListMap[assortment.Id]) {
                    let scopeFieldValues = scope.Name.split('.');
                    let scopeValue = asd[Product__c.fieldApiName.replace('__c', '__r')][scopeFieldValues[0]];
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
                    if (this.isBloc) {
                        if (!this.productdetailsMap.hasOwnProperty(scope.Name)) {
                            this.productdetailsMap[scope.Name] = {};
                        }
                        if (!this.productdetailsMap[scope.Name].hasOwnProperty(scopeValue)) {
                            this.productdetailsMap[scope.Name][scopeValue] = {};
                        }
                        if (!this.productdetailsMap[scope.Name][scopeValue].hasOwnProperty(asd[Product__c.fieldApiName])) {
                            this.productdetailsMap[scope.Name][scopeValue][asd[Product__c.fieldApiName]] = {};
                        }
                        this.productdetailsMap[scope.Name][scopeValue][asd[Product__c.fieldApiName]][assortment.Id] = asd;
                    } else {
                        if (!this.productdetailsMap.hasOwnProperty('AllProducts')) {
                            this.productdetailsMap['AllProducts'] = {};
                        }
                        if (!this.productdetailsMap['AllProducts'].hasOwnProperty(asd[Product__c.fieldApiName])) {
                            this.productdetailsMap['AllProducts'][asd[Product__c.fieldApiName]] = {};
                        }
                        this.productdetailsMap['AllProducts'][asd[Product__c.fieldApiName]][assortment.Id] = asd;
                    }
                    if (this.isBloc) {
                        if (!scopeValues.includes(scopeValue)) {
                            scopeValues.push(scopeValue);
                            scopeWrapper.scopeValues.push({ value: scopeValue, fields: JSON.parse(JSON.stringify(initFields)), style: 'background-color:white;' });
                        }
                        let scopeW = scopeWrapper.scopeValues.filter(item => item.value == scopeValue)[0];
                        for (let field of scopeW.fields) {
                            if (field.asId == assortment.Id) {
                                field.fieldValue = field.fieldValue + (asd[field.fieldName] != null ? asd[field.fieldName] : 0)
                            }
                        }
                    }
                }
            }
        }
        return scopeWrapper;
        //console.log('scopeWrapper >>> ' + JSON.stringify(scopeWrapper));
    }

    getclusterNames(prodDataId, assortmentId) {
        let clusterNames = [];
        if (prodDataId.hasOwnProperty(assortmentId)) {
            const asd = prodDataId[assortmentId];
            if (asd[BusinessUnitCluster__c.fieldApiName.replace('__c', '__r')]) {
                clusterNames.push(asd[BusinessUnitCluster__c.fieldApiName.replace('__c', '__r')].Name);
            }
            if (asd[ProductCluster__c.fieldApiName]) {
                const clusterJson = JSON.parse(asd[ProductCluster__c.fieldApiName]);
                const selectedCpltValues = clusterJson.Cplt?.filter(item => item.value).map(item => this.clustersMap[item.Id]?.Name).filter(name => name) || [];
                clusterNames = clusterNames.concat(selectedCpltValues);
            }
        }
        return clusterNames.join(' & ');
    }

    @track productDetailedData = [];
    @track showDetailedData = false;
    buildDetailSection(event) {
        if (event) {
            const currentButton = event.currentTarget;
            const allButtons = this.template.querySelectorAll('lightning-button-icon');
            allButtons.forEach(button => {
                button.style.border = "";
            });
            currentButton.style.border = "2px solid rgb(1, 68, 134)";
            currentButton.style.borderRadius = "5px";
            currentButton.style.paddingBottom = "6px";
            currentButton.style.paddingTop = "1px";
        }
        this.showDetailedData = true;
        this.productDetailedData = [];
        let scopeName = event ? event.target.dataset.scopeName : '';
        let scopeValue = event ? event.target.dataset.scopeValue : '';
        let product;
        let prodData = this.isBloc ? this.productdetailsMap[scopeName][scopeValue] : this.productdetailsMap['AllProducts'];
        console.log('prodData >>> ' + JSON.stringify(prodData))
        let categoryWMap = {};
        if (prodData) {
            for (let prodId of Object.keys(prodData)) {
                if (this.isBloc) {
                    let productWrapper = {
                        prodId: prodId,
                        fields: []
                    }
                    let prodFieldsDone = false;
                    (this.kpiGroups || []).forEach(kpi => {
                        (this.assortmentList || []).forEach(assortment => {
                            if (!prodFieldsDone && prodData[prodId][assortment.Id]) {
                                product = prodData[prodId][assortment.Id][Product__c.fieldApiName.replace('__c', '__r')];
                                let index = 0;
                                for (let field of this.productFields) {
                                    let fieldWrapper = {
                                        fieldName: field.fieldName,
                                        scale: this.prodFields[field.fieldName].scale,
                                        fieldValue: product[field.fieldName],
                                        fieldStyle: 'background-color:white;' + (index == this.productFields.length - 1 ? 'border-right: 2px solid black;' : ''),
                                    }
                                    productWrapper.fields.splice(index, 0, fieldWrapper);
                                    index++;
                                }
                                prodFieldsDone = true;
                            }
                            let fieldWrapper = {
                                fieldName: BusinessUnitCluster__c.fieldApiName,
                                assortmentId: assortment.Id,
                                isNumber: false,
                                fieldValue: this.getclusterNames(prodData[prodId], assortment.Id),
                                isHachured: !prodData[prodId].hasOwnProperty(assortment.Id),
                                fieldClass: assortment.isOnTop ? 'Ontop-blank-cell' : 'blank-cell',
                                fieldStyle: kpi.bgColorGradient
                            }
                            productWrapper.fields.push(fieldWrapper);
                            fieldWrapper = {
                                fieldName: ProductLifeStatusAss__c.fieldApiName,
                                assortmentId: assortment.Id,
                                isNumber: false,
                                fieldValue: prodData[prodId].hasOwnProperty(assortment.Id) && prodData[prodId][assortment.Id][ProductLifeStatusAss__c.fieldApiName] != null ? prodData[prodId][assortment.Id][ProductLifeStatusAss__c.fieldApiName] : '',
                                isHachured: !prodData[prodId].hasOwnProperty(assortment.Id),
                                fieldClass: assortment.isOnTop ? 'Ontop-blank-cell' : 'blank-cell',
                                fieldStyle: kpi.bgColorGradient
                            }
                            productWrapper.fields.push(fieldWrapper);
                            let fields = assortment.isTarget ? kpi.targetFields : kpi.negFields;
                            fields.forEach((field, index) => {
                                let value = prodData[prodId][assortment.Id] && prodData[prodId][assortment.Id][field.fieldName] != null ? prodData[prodId][assortment.Id][field.fieldName] : 0;
                                let style = kpi.bgColorGradient + (index === (kpi.targetFields.length - 1) ? 'border-right: 2px solid black;' : '')
                                productWrapper.fields.push({
                                    key: prodId + '_' + field.fieldName,
                                    fieldName: field.fieldName,
                                    isNumber: true,
                                    scale: this.asdFields?.[field.fieldName]?.scale || 0,
                                    isHachured: !prodData[prodId][assortment.Id],
                                    fieldValue: value,
                                    fieldStyle: style
                                });
                            });
                        });
                    });
                    this.productDetailedData.push(productWrapper);
                } else {
                    console.log('this.isBloc')
                    let categoryW = {
                        categoryId: '',
                        categoryName: '',
                        link: '',
                        fields: [],
                        prodList: [],
                    }
                    let productWrapper = {
                        prodId: prodId,
                        categoryId: '',
                        categoryName: '',
                        fields: []
                    }
                    let prodFieldsDone = false;
                    this.kpiGroups.forEach((kpi) => {
                        this.assortmentList.forEach(assortment => {
                            if (!prodFieldsDone && prodData[prodId][assortment.Id]) {
                                product = prodData[prodId][assortment.Id][Product__c.fieldApiName.replace('__c', '__r')];
                                let index = 0;
                                for (let field of this.productFields) {
                                    let fieldWrapper = {
                                        fieldName: field.fieldName,
                                        scale: this.prodFields[field.fieldName].scale,
                                        fieldValue: product[field.fieldName],
                                        fieldStyle: 'background-color:white;' + (index == this.productFields.length - 1 ? 'border-right: 2px solid black;' : '')
                                    }
                                    productWrapper.fields.splice(index, 0, fieldWrapper);
                                    index++;
                                }
                                productWrapper.categoryId = product[Hierarchy__c.fieldApiName];
                                productWrapper.categoryName = product[Hierarchy__c.fieldApiName.replace('__c', '__r')] ? product[Hierarchy__c.fieldApiName.replace('__c', '__r')].Name : '---';
                                prodFieldsDone = true;
                            }
                            let fieldWrapper = {
                                fieldName: BusinessUnitCluster__c.fieldApiName,
                                assortmentId: assortment.Id,
                                isNumber: false,
                                fieldValue: this.getclusterNames(prodData[prodId], assortment.Id),
                                isHachured: !prodData[prodId].hasOwnProperty(assortment.Id),
                                fieldClass: assortment.isOnTop ? 'Ontop-blank-cell' : 'blank-cell',
                                fieldStyle: kpi.bgColorGradient
                            }
                            productWrapper.fields.push(fieldWrapper);
                            fieldWrapper = {
                                fieldName: ProductLifeStatusAss__c.fieldApiName,
                                assortmentId: assortment.Id,
                                isNumber: false,
                                fieldValue: prodData[prodId].hasOwnProperty(assortment.Id) && prodData[prodId][assortment.Id][ProductLifeStatusAss__c.fieldApiName] != null ? prodData[prodId][assortment.Id][ProductLifeStatusAss__c.fieldApiName] : '',
                                isHachured: !prodData[prodId].hasOwnProperty(assortment.Id),
                                fieldClass: assortment.isOnTop ? 'Ontop-blank-cell' : 'blank-cell',
                                fieldStyle: kpi.bgColorGradient
                            }
                            productWrapper.fields.push(fieldWrapper);
                            let fields = assortment.isTarget ? kpi.targetFields : kpi.negFields;
                            fields.forEach((field, index) => {
                                let value = prodData[prodId][assortment.Id] && prodData[prodId][assortment.Id][field.fieldName] != null ? prodData[prodId][assortment.Id][field.fieldName] : 0;
                                let style = kpi.bgColorGradient + (index === (kpi.targetFields.length - 1) ? 'border-right: 2px solid black;' : '')
                                productWrapper.fields.push({
                                    key: assortment.Id + '_' + prodId + '_' + field.fieldName,
                                    fieldName: field.fieldName,
                                    isNumber: true,
                                    scale: this.asdFields?.[field.fieldName]?.scale || 0,
                                    isHachured: !prodData[prodId][assortment.Id],
                                    fieldValue: value,
                                    fieldStyle: style
                                });
                            });
                        });
                    });
                    console.log('productWrapper >>> ' + JSON.stringify(productWrapper));
                    if (!categoryWMap.hasOwnProperty(productWrapper.categoryId)) {
                        categoryW.categoryId = productWrapper.categoryId;
                        categoryW.categoryName = productWrapper.categoryName;
                        categoryW.link = '/' + productWrapper.categoryId;
                        categoryW.fields = JSON.parse(JSON.stringify(productWrapper.fields));
                        categoryW.fields.splice(0, this.productFields.length);
                        categoryW.fields.forEach(field => {
                            if (field.isNumber) {
                                field.fieldValue = 0;
                            } else {
                                field.fieldValue = '';
                            }
                        })
                        categoryWMap[productWrapper.categoryId] = categoryW;
                    }
                    categoryWMap[productWrapper.categoryId].prodList.push(productWrapper);
                }
            }
        }
        if (!this.isBloc) {
            this.productDetailedData = Object.values(categoryWMap);
            this.fillCategoryTotalFields();
        }
        setTimeout(() => {
            this.changeHeight();
        }, 500);
        console.log('productDetailedData >>> ' + JSON.stringify(this.productDetailedData))
    }

    @track grandtTotalFields = [];

    // category Total For the screen Compare detail
    fillCategoryTotalFields() {
        this.grandtTotalFields = [];
        for (let categoryW of this.productDetailedData) {
            if (this.grandtTotalFields.length == 0) {
                this.grandtTotalFields = JSON.parse(JSON.stringify(categoryW.fields));
            }
            for (let productW of categoryW.prodList) {
                for (let fieldIndex = 0; fieldIndex < categoryW.fields.length; fieldIndex++) {
                    let prodFieldIndex = fieldIndex + this.productFields.length;
                    if (productW.fields[prodFieldIndex].isNumber) {
                        categoryW.fields[fieldIndex].fieldValue += productW.fields[prodFieldIndex].fieldValue;
                        this.grandtTotalFields[fieldIndex].fieldValue += productW.fields[prodFieldIndex].fieldValue;
                    }
                }
            }
        }
    }

    // global Total For the screen Compare Bloc
    fillTotal() {
        this.grandtTotalFields = [];
        if (this.records.length > 0) {
            for (let scopeValue of this.records[0].scopeValues) {
                if (this.grandtTotalFields.length == 0) {
                    this.grandtTotalFields = JSON.parse(JSON.stringify(scopeValue.fields));
                    this.grandtTotalFields.forEach(field => {
                        field.fieldValue = 0;
                    })
                }
                for (let fieldIndex = 0; fieldIndex < scopeValue.fields.length; fieldIndex++) {
                    this.grandtTotalFields[fieldIndex].fieldValue += scopeValue.fields[fieldIndex].fieldValue;
                }
            }
        }
        this.grandtTotalFields.forEach(totalField => {
            totalField.key = totalField.asId + '' + totalField.fieldName;
        })
    }

    setnumberOfFixedColumns() {
        let height = 0;
        let scopeHeader = this.template.querySelector('.scopeHeaderClass');
        let totalHeight = this.template.querySelector('.total')?.offsetHeight;
        if (scopeHeader.closest('.firstDiv')) {
            height = scopeHeader?.offsetHeight;
        } else {
            let mainFields = this.template.querySelector('.mainFieldsWidth');
            height = scopeHeader?.offsetHeight + mainFields?.offsetHeight;
        }
        // Sticky / Fixed columns for both Tables
        ['.main-table', '.product-table'].forEach(selector => {
            let table = this.template.querySelector(selector);
            if (!table) return;
            let isMainTable = selector === '.main-table';
            let tableTrs = table.rows;
            let nbOfFixedColumnsDefault = isMainTable ? 2 : 3;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                let left = 0;
                let nbOfFixedColumns = nbOfFixedColumnsDefault;
                if (tableTrs[index].classList?.contains('total') || tableTrs[index].classList?.contains('category') || index == 0) {
                    if (tableTrs[index].classList?.contains('total') || tableTrs[index].classList?.contains('category')) {
                        tableTrs[index].style.position = 'sticky';
                        tableTrs[index].style.zIndex = 5;
                        tableTrs[index].style.top = tableTrs[index].classList?.contains('total') ? height + 'px' : height + totalHeight + 'px';
                    }
                    nbOfFixedColumns = 1;
                } else {
                    nbOfFixedColumns = nbOfFixedColumnsDefault;
                }
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if ((isMainTable ? index != 1 : true) && index2 < nbOfFixedColumns) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = isMainTable ? (index == 0 ? 5 : 3) : (index == 0 || index == 1 ? 5 : 3);
                        left += childrens[index2].offsetWidth;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                    } else {
                        break;
                    }
                }
            }
            let firstHeader = tableTrs[0]?.children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = index2 == 0 ? 5 : 4;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
            let secondHeader = tableTrs[1]?.children;
            for (let index2 = 0; secondHeader && index2 < secondHeader.length; index2++) {
                secondHeader[index2].style.position = 'sticky';
                secondHeader[index2].style.top = tableTrs[0].offsetHeight + 'px';
                secondHeader[index2].style.zIndex = isMainTable ? 4 : index2 < nbOfFixedColumnsDefault ? 5 : 4;
                secondHeader[index2].style.backgroundColor = secondHeader[index2].style.backgroundColor ? secondHeader[index2].style.backgroundColor : '';
            }
        });
    }

    changeHeight = () => {
        let body = this.template.querySelector('.main-panel');
        let header = this.template.querySelector('.header');
        if (body && header) {
            let headerHeight = header.getBoundingClientRect().height;
            //Set table Height
            this.template.querySelector('.main-panel').style.height = window.innerHeight - headerHeight - (4 * 45) + 'px';
            // Set First Table Height
            if (this.template.querySelector('.firstDiv')) {
                this.template.querySelector('.firstDiv').style.height = ((window.innerHeight - headerHeight - (4 * 45)) / (this.showDetailedData ? 2 : 1)) + 'px';
            }
            // Set second Table Height
            if (this.template.querySelector('.secondDiv')) {
                this.template.querySelector('.secondDiv').style.height = ((window.innerHeight - headerHeight - (4 * 45)) / (this.isBloc ? 2 : 1)) + 'px';
            }
        }
    };

}