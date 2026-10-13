// import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import initData from '@salesforce/apex/AssortmentChannelBudgetCtrl.initData';
import loadData from '@salesforce/apex/AssortmentChannelBudgetCtrl.loadData';
import processRestForExcel from '@salesforce/apex/AssortmentChannelBudgetCtrl.processRestForExcel';

import LBL_Error from "@salesforce/label/c.LBL_Error";

import BusinessUnitTarget__c from '@salesforce/schema/Assortment__c.BusinessUnitTarget__c';
import LongName__c from '@salesforce/schema/Assortment__c.LongName__c';
import Status__c from '@salesforce/schema/Assortment__c.Status__c';
import Product__c from '@salesforce/schema/AssortmentDetail__c.Product__c';
import Assortment__c from '@salesforce/schema/AssortmentDetail__c.Assortment__c';
import Hierarchy__c from '@salesforce/schema/AssortmentDetail__c.Hierarchy__c';
import WDChannelBaseBudget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget__c';
import BusinessUnitCluster__c from '@salesforce/schema/AssortmentDetail__c.BusinessUnitCluster__c';
import WDChannelBaseNegoL4L_P1__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseNegoL4L_P1__c';
import WDChannelBaseTarget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget__c';
import WDChannelBasePanel_P1__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBasePanel_P1__c';
import WDChannelBaseBudget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget_NegoL4LP1Gap__c';
import PNChannelBaseBudget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.PNChannelBaseBudget_NegoL4LP1Gap__c';
import WDChannelBaseTarget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget_NegoL4LP1Gap__c';
import Year__c from '@salesforce/schema/Assortment__c.Year__c';
import Market_Introduction_Date__c from '@salesforce/schema/Product2.Market_Introduction_Date__c';
import IsInnovation__c from '@salesforce/schema/Product2.IsInnovation__c';
import Market_End_of_Life_Date__c from '@salesforce/schema/Product2.Market_End_of_Life_Date__c';

const numberTypes = ['DOUBLE', 'INTEGER', 'PERCENT', 'LONG', 'CURRENCY'];
const variables = {
    loadingData: false,
    initResult: null,
    prefix: null,
    subTotalsMap: {},
    picklistValuesMap: {},
    allFields: [],
    currentAssortment: null,
    channelBU: {},
    assortmentLongName: null,
    fixedColumnsOptions: [],
    mainFields: [],
    budgetFieldsList: [],
    ASDFields: {},
    negoFieldsList: [],
    isSendEmail: false,
    isExportExcel: false,
    tableLoading: false,
    filters: {
        buTarget: [],
        categories: [],
        productGTIN: '',
        brand: '',
        priority: '',
    },
    pageNumber: 1,
    pageSize: '25',
    resultsW: [],
    targetAssortmentMap: new Map(),
    buTargetList: [],
    buTargetOptions: [],
    pageCount: 0,
    categoryWList: [],
    dataList: {},
    changesMap: {},
    showFileGenerationBar: false,
    rowCounter: 0,
    isBudgetDone: false,
    isNegoDone: false,
    isTargetDone: false,
    nbOfFixedColumns: '0',
    recordId: null,
    self: null
};

//Export excel only
   
const initDataJs = (self, recordId) => {
    variables.loadingData = true;
    variables.recordId = recordId;
    variables.self = self;
    initData({
        assortmentId: variables.recordId
    }).then((res) => {
        try {
            variables.initResult = JSON.parse(res);
            variables.prefix = variables.initResult.prefix || '';
            variables.subTotalsMap = variables.initResult.subTotalsMap;
            variables.picklistValuesMap = variables.initResult.picklistValuesMap;
            variables.allFields = variables.initResult.allFields;
            variables.currentAssortment = variables.initResult.budgetAssortment;
            let url = '/lightning/r/BusinessUnit__c/' + variables.currentAssortment[BusinessUnitTarget__c.fieldApiName] + '/view';
            variables.channelBU = { Name: variables.currentAssortment[BusinessUnitTarget__c.fieldApiName.replace('__c', '__r')].Name, url: url, style: 'background-color: #14b3bb;color:white;' }
            variables.assortmentLongName = variables.currentAssortment[LongName__c.fieldApiName];
            variables.mainFields = [];
            if (variables.initResult.mainFields) {
                variables.fixedColumnsOptions.push({ value: '0', label: '0' })
                let index = 0;
                for (let field of variables.initResult.mainFields) {
                    variables.mainFields.push({
                        Name: field.fieldName,
                        label: field.fieldLabel,
                        stringFieldType: field.stringFieldType,
                        class: index == variables.initResult.mainFields.length - 1 ? ' separator ' : '',
                        style: 'background-color: #267a7c;color:white;',
                        widthStyle: field.widthStyle,
                        width: field.width != null && field.width != 'undefined' ? field.width.replace('px', '') : '25'
                    });
                    index++;
                    variables.fixedColumnsOptions.push({ value: index + '', label: index + '' })
                }
            }
            if (variables.initResult.budgetASDFields) {
                let index = 0;
                for (let field of variables.initResult.budgetAssAPIFields) {
                    variables.budgetFieldsList.push({
                        Name: field,
                        label: variables.initResult.budgetASDFields[field],
                        stringFieldType: variables.ASDFields[field].dataType.toUpperCase(),
                        class: 'fieldLabelClass slds-truncate ' + (index == variables.initResult.budgetAssAPIFields.length - 1 ? ' separator ' : ''),
                        style: 'background-color: #14b3bb;color:white;',
                        width: '25',
                        isNumber: numberTypes.includes(variables.ASDFields[field].dataType.toUpperCase()),
                        scale: variables.ASDFields[field].scale
                    });
                    index++;
                }
            }
            if (variables.initResult.negoASDFields) {
                let index = 0;
                for (let field of variables.initResult.negoAssAPIFields) {
                    variables.negoFieldsList.push({
                        Name: field,
                        label: variables.initResult.negoASDFields[field],
                        stringFieldType: variables.ASDFields[field].dataType.toUpperCase(),
                        class: 'fieldLabelClass slds-truncate' + (index == variables.initResult.negoAssAPIFields.length - 1 ? ' separator ' : ''),
                        index: index,
                        style: 'background-color: #85DBDB;color:white;',
                        width: '25',
                        isNumber: numberTypes.includes(variables.ASDFields[field].dataType.toUpperCase(),),
                        scale: variables.ASDFields[field].scale
                    });
                    index++;
                }
            }
            loadDataJs(true);
            if (variables.isSendEmail) {
                // toggleEmailModal();
            } else if (variables.isExportExcel) {
                exportExcel();
            }
        } catch (error) {
            console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
            showNotification(LBL_Error, error.message ? error.message : error.body?.message, 'error');

        }
    }).catch(error => {
        variables.tableLoading = false;
        showNotification(LBL_Error, error.message ? error.message : error.body?.message, 'error');
        console.error(error);
        console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
    });
}

const loadDataJs = (firstLoad) => {
    variables.loadingData = true;
    variables.tableLoading = true;
    loadData({
        currentAssJSON: JSON.stringify(variables.currentAssortment),
        negoAssIds: variables.initResult.negoAssIds,
        filtersSerialized: JSON.stringify(variables.filters),
        allFields: variables.allFields,
        pageNumber: variables.pageNumber,
        pageSize: variables.pageSize,
        allProductsList: variables.initResult.productIdSet
    }).then((res) => {
        variables.resultsW = JSON.parse(res);
        if (firstLoad == true) {
            if (variables.resultsW.targetASDList) {
                for (let targetAsd of variables.resultsW.targetASDList) {
                    variables.targetAssortmentMap.set(targetAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName], targetAsd[Assortment__c.fieldApiName]);
                }
            }
            if (variables.initResult.assTargetList) {
                for (let buTarget of variables.initResult.assTargetList) {
                    let assUrl = '/apex/' + variables.prefix + 'NegoptimNavigator?c__componentName=' + (variables.prefix ? variables.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + variables.targetAssortmentMap.get(buTarget.Id);
                    variables.buTargetList.push({ Name: buTarget.Name, Id: buTarget.Id, url: '/' + buTarget.Id, class: variables.targetAssortmentMap.get(buTarget.Id) == undefined ? 'imgOpacity' : '', assUrl: assUrl, style: 'background-color: #85DBDB;color:white;', isDisplayed: true, hasTarget: variables.targetAssortmentMap.get(buTarget.Id) == undefined ? false : true });
                    variables.buTargetOptions.push({ value: buTarget.Id, label: buTarget.Name });
                    variables.filters.buTarget.push(buTarget.Id);
                }
            }
        }
        variables.buTargetList.forEach(bu => {
            bu.isDisplayed = variables.filters.buTarget.includes(bu.Id);
        })
        variables.pageCount = Math.ceil((variables.resultsW.numberOfRecords / variables.pageSize));
        variables.categoryWList = [];
        variables.categoryWList = buildData();
        console.log("variables.categoryWList >>>", JSON.stringify(variables.categoryWList));
        variables.loadingData = false;
        variables.tableLoading = false;
    }).catch(error => {
        variables.tableLoading = false;
        showNotification(LBL_Error, error.message ? error.message : error.body?.message, 'error');
        console.error(error);
        console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
    });
}

const buildData = () => {
    variables.dataList = {};
    let negoAsdMap = {};
    for (let negoAsd of variables.resultsW.negoASDList) {
        negoAsdMap[negoAsd[Product__c.fieldApiName] + negoAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = negoAsd;
    }
    let targetAsdMap = {};
    for (let targetAsd of variables.resultsW.targetASDList) {
        targetAsdMap[targetAsd[Product__c.fieldApiName] + targetAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = targetAsd;
    }
    for (let budgetAsd of variables.resultsW.budgetASDList) {
        let categoryId = budgetAsd[Hierarchy__c.fieldApiName];
        if (!variables.dataList[categoryId]) {
            let categoryW = {
                categoryId: categoryId,
                categoryName: budgetAsd[Hierarchy__c.fieldApiName.replace('__c', '__r')]?.Name,
                categoryURL: '/' + categoryId,
                categoryStyle: 'background-color:#595959;',
                productList: [],
                subTotalRow: []
            }
            variables.dataList[categoryId] = categoryW;
        }
        variables.dataList[categoryId].productList.push(buildProdRow(budgetAsd, negoAsdMap, targetAsdMap));
    }
    for (let categoryId of Object.keys(variables.dataList)) {
        variables.dataList[categoryId].subTotalRow = calculateSubTotal(categoryId);
    }
    return Object.values(variables.dataList);
}

const buildProdRow = (budgetASD, negoAsdMap, targetAsdMap) => {
    let prodRow = {
        Id: budgetASD.Id,
        mainFields: [],
        budgetFields: [],
        negoFields: []
    };
    for (let field of variables.mainFields) {
        let fieldw = {
            isInput: false,
            fieldName: field.Name,
            fieldValue: '',
            isRef: field.Name == Product__c.fieldApiName || field.stringFieldType == 'REFERENCE',
            url: '',
            fieldClass: field.class,
            fieldStyle: field.widthStyle + 'white-space:inherit;background-color:white;',
            fgColor: '',
            linkStyle: '',
        }
        let fieldValues = field.Name.split('.');
        for (let index = 0; index < fieldValues.length; index++) {
            let item = index == 0 ? budgetASD : fieldw.fieldValue;
            if (index == fieldValues.length - 1 && field.stringFieldType == 'REFERENCE') {
                fieldw.fieldValue = item[fieldValues[index].replace('__c', '__r')]?.Name;
                fieldw.url = '/' + item[fieldValues[index]];
            } else {
                fieldw.fieldValue = item[fieldValues[index]];
            }
        }
        if (field.stringFieldType == "PICKLIST") {
            fieldw.fieldValue = variables.picklistValuesMap[field.Name][fieldw.fieldValue];
        }

        if (field.Name == Product__c.fieldApiName) {
            let product = budgetASD[Product__c.fieldApiName.replace('__c', '__r')];
            if (product[Market_Introduction_Date__c.fieldApiName]) {
                if ((product[IsInnovation__c.fieldApiName] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[Market_Introduction_Date__c.fieldApiName]).getFullYear()) < variables.currentAssortment[Year__c.fieldApiName])) {
                    fieldw.linkStyle = 'color:' + variables.resultsW.INNO_INTRO_DATE_LESS_N + ';';
                }
                if ((product[IsInnovation__c.fieldApiName] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[Market_Introduction_Date__c.fieldApiName]).getFullYear()) >= variables.currentAssortment[Year__c.fieldApiName])) {
                    fieldw.linkStyle = 'color:' + variables.resultsW.INNO_INTRO_DATE_GREATER_N + ';';
                }
            }
            if (product[Market_End_of_Life_Date__c.fieldApiName]) {
                if ((new Date(product[Market_End_of_Life_Date__c.fieldApiName]).getFullYear()) < variables.currentAssortment[Year__c.fieldApiName]) {
                    fieldw.linkStyle = 'color:' + variables.resultsW.STOP_DATE_LESS_N + ';';
                }
                if ((new Date(product[Market_End_of_Life_Date__c.fieldApiName]).getFullYear()) >= variables.currentAssortment[Year__c.fieldApiName]) {
                    fieldw.linkStyle = 'color:' + variables.resultsW.STOP_DATE_GREATER_N + ';';
                }
            }
        }
        prodRow.mainFields.push(fieldw);
    }
    for (let field of variables.budgetFieldsList) {
        let fieldw = {
            budgetASDId: budgetASD.Id,
            isInput: variables.currentAssortment && variables.currentAssortment[Status__c.fieldApiName] != 'Validate' && field.Name == WDChannelBaseBudget__c.fieldApiName,
            fieldName: field.Name,
            isRef: field.stringFieldType == 'REFERENCE',
            fieldValue: field.stringFieldType == 'REFERENCE' ? (budgetASD[field.Name.replace('__c', '__r')] ? budgetASD[field.Name.replace('__c', '__r')].Name : '') : budgetASD[field.Name],
            url: field.stringFieldType == 'REFERENCE' ? '/' + budgetASD[field.Name] : '',
            fieldClass: field.class,
            isNumber: numberTypes.includes(field.stringFieldType),
            fieldStyle: (numberTypes.includes(field.stringFieldType) ? 'text-align:right;' : '') + (field.Name == WDChannelBaseBudget__c.fieldApiName ? 'width:80px;min-width:80px;max-width:80px;' : ''),
            scale: field.scale,
            step: field.scale / 100
        }
        if (field.Name == WDChannelBaseNegoL4L_P1__c.fieldApiName
            || field.Name == WDChannelBasePanel_P1__c.fieldApiName
            || field.Name == WDChannelBaseBudget__c.fieldApiName
            || field.Name == WDChannelBaseBudget_NegoL4LP1Gap__c.fieldApiName) {
            fieldw.fieldStyle += 'background-color:#DEF3EE;';
            fieldw.fgColor = 'DEF3EE;';
        } else if (field.Name == PNChannelBaseBudget_NegoL4LP1Gap__c.fieldApiName) {
            fieldw.fieldStyle += 'background-color:#DDEBF7;';
            fieldw.fgColor = 'DDEBF7';
        } else {
            fieldw.fieldStyle += 'background-color:white;';
        }
        if (variables.changesMap[budgetASD.Id] != null && variables.changesMap[budgetASD.Id].hasOwnProperty(field.Name)) {
            fieldw.fieldValue = variables.changesMap[budgetASD.Id][field.Name];
        }
        prodRow.budgetFields.push(fieldw);
    }
    for (let orgaBu of variables.buTargetList) {
        if (orgaBu.isDisplayed) {
            let product = budgetASD[Product__c.fieldApiName.replace('__c', '__r')];

            let negoAss = negoAsdMap[product.Id + orgaBu.Id];
            let targetAss = targetAsdMap[product.Id + orgaBu.Id];
            for (let field of variables.negoFieldsList) {
                if (field.Name == WDChannelBaseTarget_NegoL4LP1Gap__c.fieldApiName
                    || field.Name == WDChannelBaseTarget__c.fieldApiName) {
                    let fieldw = {
                        isInput: false,
                        fieldName: field.Name,
                        buId: orgaBu.Id,
                        isRef: false,
                        fieldValue: targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] == 'Validate' ? targetAss[field.Name] : '',
                        fieldClass: field.class,
                        isNumber: numberTypes.includes(field.stringFieldType),
                        fieldStyle: (numberTypes.includes(field.stringFieldType) ? 'text-align:right;' : 'text-align:center;') + 'background-color:white;',
                        isTargetHachured: targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] != 'Validate',
                        scale: field.scale
                    }
                    prodRow.negoFields.push(fieldw);
                } else {
                    let fieldw = {
                        isInput: false,
                        fieldName: field.Name,
                        buId: orgaBu.Id,
                        isRef: false,
                        fieldValue: negoAss ? (field.stringFieldType == 'REFERENCE' ? (negoAss[field.Name.replace('__c', '__r')] ? negoAss[field.Name.replace('__c', '__r')].Name : '') : negoAss[field.Name]) : 0,
                        url: field.stringFieldType == 'REFERENCE' && negoAss ? '/' + negoAss[field.Name] : '',
                        fieldClass: field.class,
                        isNumber: numberTypes.includes(field.stringFieldType),
                        fieldStyle: (numberTypes.includes(field.stringFieldType) ? 'text-align:right;' : 'text-align:center;'),
                        isHachured: negoAss ? false : true,
                        scale: field.scale
                    }
                    if (field.Name == BusinessUnitCluster__c.fieldApiName) {
                        fieldw.fieldStyle += 'background-color:#DDEBF7;';
                        fieldw.fgColor = 'DDEBF7';
                        if (targetAss != {} && targetAss != undefined && targetAss[BusinessUnitCluster__c.fieldApiName] && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] == 'Validate' && negoAss != {} && negoAss != undefined && negoAss[BusinessUnitCluster__c.fieldApiName] != targetAss[BusinessUnitCluster__c.fieldApiName]) {
                            fieldw.fieldValue += '→ ' + targetAss[BusinessUnitCluster__c.fieldApiName.replace('__c', '__r')].Name;
                        }
                    } else if (field.Name == WDChannelBaseNegoL4L_P1__c.fieldApiName) {
                        fieldw.fieldStyle += 'background-color:#DEF3EE;';
                        fieldw.fgColor = 'DEF3EE;';
                    } else {
                        fieldw.fieldStyle += 'background-color:white;';
                    }
                    prodRow.negoFields.push(fieldw);
                }
            }
        }
    }
    return prodRow;
}

const calculateSubTotal = (categoryId) => {
    let subTotalRow = [];
    let fieldIndex = 0;
    for (let budgetField of variables.budgetFieldsList) {
        let subTotal = {
            value: null,
            scale: null,
            class: fieldIndex == variables.budgetFieldsList.length - 1 ? 'subTotalRow separator' : 'subTotalRow'
        }
        let key = Object.keys(variables.subTotalsMap).find(k => k.includes(categoryId) && variables.buTargetList.every(item => !k.includes(item.Id)));
        if (budgetField.isNumber && key) {
            subTotal.value = variables.subTotalsMap[key][budgetField.Name];
        }
        subTotalRow.push(subTotal)
        fieldIndex++;
    }
    for (let bu of variables.buTargetList) {
        if (bu.isDisplayed) {
            fieldIndex = 0;
            for (let negoField of variables.negoFieldsList) {
                fieldIndex++;
                let subTotal = {
                    value: null,
                    scale: null,
                    class: fieldIndex == variables.negoFieldsList.length - 1 ? 'subTotalRow separator' : 'subTotalRow'
                }
                let key = categoryId + '-' + bu.Id;
                if (negoField.isNumber && variables.subTotalsMap.hasOwnProperty(key)) {
                    subTotal.value = variables.subTotalsMap[key][negoField.Name]
                }
                subTotalRow.push(subTotal)
                fieldIndex++;
            }
        }
    }
    return subTotalRow;
}

const exportExcel = () => {
    variables.showFileGenerationBar = true;
    try {
        variables.tableLoading = true;
        variables.resultsW = [];
        variables.resultsW.budgetASDList = [];
        variables.resultsW.negoASDList = [];
        variables.resultsW.targetASDList = [];
        processBudgetDetails();
        processNegoDetails();
        processTargetDetails();

    } catch (error) {
        console.log('%c' + error.message, 'color : red');
        console.log('%c' + error.body?.message, 'color : red');
        showNotification('', error.message, 'error');
    }
}

const processBudgetDetails = () => {
    processRestForExcel({
        currentAssortmentJSON: JSON.stringify(variables.currentAssortment),
        queryType: 'budget',
        negoAssIds: variables.initResult.negoAssIds,
        restURL: null
    }).then((result) => {
        try {
            let parsedResult = JSON.parse(result);
            variables.rowCounter = 0;
            if (parsedResult.error != null) {
                showNotification('', parsedResult.error, 'error');
                return;
            }
            if (parsedResult.hasOwnProperty('done')) {
                if (parsedResult.asdList) {
                    variables.resultsW.budgetASDList.push(...parsedResult.asdList);
                    variables.rowCounter += parsedResult.asdList.length;
                }
                if (parsedResult.done) {
                    variables.showFileGenerationBar = false;
                    variables.isBudgetDone = true;
                    buildExcel();
                } else {
                    excelLoadMore(parsedResult.nextRecordsUrl, variables.resultsW.budgetASDList, variables.isBudgetDone);
                }
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            showNotification('', error.message, 'error');
        }
    }).catch((error) => {
        console.log('%c' + error.message, 'color : red');
        console.log('%c' + error.body?.message, 'color : red');
        showNotification('', error.message, 'error');
    });
}

const processNegoDetails = () => {
    processRestForExcel({
        currentAssortmentJSON: JSON.stringify(variables.currentAssortment),
        queryType: 'nego',
        negoAssIds: variables.initResult.negoAssIds,
        restURL: null
    }).then((result) => {
        try {
            let parsedResult = JSON.parse(result);
            variables.rowCounter = 0;
            if (parsedResult.error != null) {
                showNotification('', parsedResult.error, 'error');
                return;
            }
            if (parsedResult.hasOwnProperty('done')) {
                if (parsedResult.asdList) {
                    variables.resultsW.negoASDList.push(...parsedResult.asdList);
                    variables.rowCounter += parsedResult.asdList.length;
                }
                if (parsedResult.done) {
                    variables.showFileGenerationBar = false;
                    variables.isNegoDone = true;
                    buildExcel();
                } else {
                    excelLoadMore(parsedResult.nextRecordsUrl, variables.resultsW.negoASDList, variables.isNegoDone);
                }
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            showNotification('', error.message, 'error');
        }
    }).catch((error) => {
        console.log('%c' + error.message, 'color : red');
        console.log('%c' + error.body?.message, 'color : red');
        showNotification('', error.message, 'error');
    });
}

const processTargetDetails = () => {
    processRestForExcel({
        currentAssortmentJSON: JSON.stringify(variables.currentAssortment),
        queryType: 'target',
        negoAssIds: variables.initResult.negoAssIds,
        restURL: null
    }).then((result) => {
        try {
            let parsedResult = JSON.parse(result);
            variables.rowCounter = 0;
            if (parsedResult.error != null) {
                showNotification('', parsedResult.error, 'error');
                return;
            }
            if (parsedResult.hasOwnProperty('done')) {
                if (parsedResult.asdList) {
                    variables.resultsW.targetASDList.push(...parsedResult.asdList);
                    variables.rowCounter += parsedResult.asdList.length;
                }
                if (parsedResult.done) {
                    variables.showFileGenerationBar = false;
                    variables.isTargetDone = true;
                    buildExcel();
                } else {
                    excelLoadMore(parsedResult.nextRecordsUrl, variables.resultsW.targetASDList, variables.isTargetDone);
                }
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            showNotification('', error.message, 'error');
        }
    }).catch((error) => {
        console.log('%c' + error.message, 'color : red');
        console.log('%c' + error.body?.message, 'color : red');
        showNotification('', error.message, 'error');
    });
}

const buildExcel = () => {
    if (variables.isBudgetDone && variables.isNegoDone && variables.isTargetDone) {
        let dataToExport = buildData();
        variables.loadingData = false;
        try {
            const workbook = new ExcelJS.Workbook();
            workbook.properties.date1904 = true;
            workbook.calcProperties.fullCalcOnLoad = true;
            const worksheet = workbook.addWorksheet(variables.assortmentLongName, { properties: { tabColor: { argb: 'worksheet' } } });
            let rowCounter = 1;
            const headerRow1 = worksheet.getRow(rowCounter);
            const header1Values = [];
            const colWidthStyle = [];
            for (let prodField of variables.mainFields) {
                header1Values.push(prodField.label);
                colWidthStyle.push(prodField.width);
            }
            header1Values.push(variables.channelBU.Name);
            for (let budgetIndex = 0; budgetIndex < variables.budgetFieldsList.length - 1; budgetIndex++) {
                header1Values.push(' ');
            }
            for (let buTarget of variables.buTargetList) {
                if (buTarget.isDisplayed) {
                    header1Values.push(buTarget.Name);
                    for (let negoIndex = 0; negoIndex < variables.negoFieldsList.length - 1; negoIndex++) {
                        header1Values.push(' ');
                    }
                }
            }
            headerRow1.values = header1Values;
            rowCounter++;
            let prodfieldLength = variables.mainFields.length;
            let self = variables;
            let separatorIndexes = [];
            headerRow1.eachCell(function (cell, colNumber) {
                let isLastMainField = colNumber == prodfieldLength;
                let isChannelBU = self.channelBU.Name === cell.value;
                let isInBuTargetList = self.buTargetList.some(field => field.Name === cell.value);
                if (isLastMainField) {
                    separatorIndexes.push(colNumber);
                }
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: colNumber < prodfieldLength + 1 ? '267a7c' : '14b3bb' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: 'FFFFFF' },
                }
                cell.border = {
                    top: { style: 'thin', color: { argb: 'E6E6E6' } },
                    left: { style: 'thin', color: { argb: 'E6E6E6' } },
                    bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                    right: { style: isLastMainField || isChannelBU || isInBuTargetList ? 'thick' : 'thin', color: { argb: isLastMainField || isChannelBU || isInBuTargetList ? '000000' : 'E6E6E6' } }
                };
                cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center', };
            });
            const headerRow2 = worksheet.getRow(rowCounter);
            let emptyCellsNb = [];
            for (let index = 0; index < variables.mainFields.length; index++) {
                emptyCellsNb.push('  ');
            }
            let excelNegoFields = [];
            variables.buTargetList.forEach(buTarget => {
                if (buTarget.isDisplayed) {
                    excelNegoFields.push(...variables.negoFieldsList);
                }
            });
            const header2Values = [...emptyCellsNb, ...variables.budgetFieldsList.map(budgetField => budgetField.label), ...excelNegoFields.map(negoField => negoField.label)];
            headerRow2.values = header2Values;
            colWidthStyle.push(...variables.budgetFieldsList.map(budgetField => budgetField.width));
            colWidthStyle.push(...excelNegoFields.map(negoField => negoField.width));
            rowCounter++;
            headerRow2.eachCell(function (cell, colNumber) {
                let isLastBudgetField = self.budgetFieldsList[self.budgetFieldsList.length - 1].label == cell.value;
                let isLastNegoField = self.negoFieldsList[self.negoFieldsList.length - 1].label == cell.value;
                if (isLastBudgetField || isLastNegoField) {
                    separatorIndexes.push(colNumber);
                }
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: '14b3bb' },
                };
                cell.font = {
                    'bold': true,
                    color: { argb: 'FFFFFF' },
                }
                cell.border = {
                    top: { style: 'thin', color: { argb: 'E6E6E6' } },
                    left: { style: 'thin', color: { argb: 'E6E6E6' } },
                    bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                    right: { style: isLastBudgetField || isLastNegoField ? 'thick' : 'thin', color: { argb: isLastBudgetField || isLastNegoField ? '000000' : 'E6E6E6' } }
                };
                cell.alignment = {
                    wrapText: true,
                    vertical: 'middle',
                    horizontal: 'center'
                };
            });
            // merge by start row, start column, end row, end column
            // rowspan Product Fields
            for (let prodIndex in variables.mainFields) {
                let index = parseInt(prodIndex) + 1;
                worksheet.mergeCells(1, index, 2, index);
            }
            // colspan Channel
            worksheet.mergeCells(1, variables.mainFields.length + 1, 1, variables.mainFields.length + variables.budgetFieldsList.length);
            // colspan BU Target
            for (let buIndex in variables.buTargetList) {
                worksheet.mergeCells(1, variables.mainFields.length + variables.budgetFieldsList.length + (parseInt(buIndex) * variables.negoFieldsList.length) + 1, 1, variables.mainFields.length + variables.budgetFieldsList.length + ((parseInt(buIndex) + 1) * variables.negoFieldsList.length));
            }
            for (let cat of dataToExport) {
                let catsubTotalLine = worksheet.getRow(rowCounter);
                rowCounter++;
                let catsubTotalValues = [cat.categoryName == null ? '  ' : cat.categoryName];
                for (let index = 0; index < variables.nbOfFixedColumns - 1; index++) {
                    catsubTotalValues.push(' ');
                }
                let categoryColspan = variables.mainFields.length - (variables.nbOfFixedColumns == 0 ? 1 : variables.nbOfFixedColumns);
                for (let index = 0; index < categoryColspan; index++) {
                    catsubTotalValues.push(' ');
                }
                for (let subTotalVal of cat.subTotalRow) {
                    if (subTotalVal != '-') {
                        catsubTotalValues.push(subTotalVal.value ?? ' ');
                    } else {
                        catsubTotalValues.push(' ');
                    }
                }
                catsubTotalLine.values = catsubTotalValues;
                catsubTotalLine.eachCell(function (cell, colNumber) {
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: '595959' },
                    };
                    cell.font = {
                        'bold': true,
                        color: { argb: 'FFFFFF' },
                    }
                    cell.border = {
                        top: { style: 'thin', color: { argb: 'E6E6E6' } },
                        left: { style: 'thin', color: { argb: 'E6E6E6' } },
                        bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                        right: { style: separatorIndexes.includes(colNumber) ? 'thick' : 'thin', color: { argb: separatorIndexes.includes(colNumber) ? '000000' : 'E6E6E6' } }
                    };
                });
                for (let prod of cat.productList) {
                    let rowLine = worksheet.getRow(rowCounter);
                    let rowValues = [];
                    let style = [];
                    let index = 1;
                    for (let prodField of prod.mainFields) {
                        rowValues.push(prodField.fieldValue);
                        style.push({});
                        index++;
                    }
                    for (let budgetField of prod.budgetFields) {
                        rowValues.push(budgetField.fieldValue);
                        style.push({ fgColor: budgetField.fgColor, horizAlign: budgetField.isNumber ? 'right' : '' });
                        index++;
                    }
                    for (let negoField of prod.negoFields) {
                        rowValues.push(negoField.fieldValue ?? ' ');
                        style.push({ fgColor: negoField.fgColor, horizAlign: negoField.isNumber ? 'right' : 'center' });
                        index++;
                    }
                    rowLine.values = rowValues;
                    rowLine.eachCell({ includeEmpty: true }, function (cell, colNumber) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: style[colNumber - 1].fgColor },
                        };
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'E6E6E6' } },
                            left: { style: 'thin', color: { argb: 'E6E6E6' } },
                            bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                            right: { style: separatorIndexes.includes(colNumber) ? 'thick' : 'thin', color: { argb: separatorIndexes.includes(colNumber) ? '000000' : 'E6E6E6' } }
                        };
                        cell.alignment = {
                            wrapText: true,
                            vertical: 'middle',
                            horizontal: style[colNumber - 1].horizAlign
                        };
                    });
                    rowCounter++;
                }
            }
            for (let index in colWidthStyle) {
                let colIndex = parseInt(index) + 1;
                worksheet.getColumn(colIndex).width = colWidthStyle[index];
            }
            worksheet._rows[0]._cells.forEach(cell => {
                cell.protection = { locked: true, lockText: false };
            });
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement("a");
                document.body.appendChild(a);
                a.style = "display: none";
                let base64Bin = result.toString('base64');
                if (variables.isSendEmail) {
                    // handleSend(base64Bin);
                } else {
                    a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
                    a.download = variables.currentAssortment.Name + '.xlsx'; //File name Here
                    a.click();
                    if (variables.isExportExcel) {
                        window.close();
                    }
                    variables.loadingtable = false;
                }
            });
        } catch (error) {
            variables.loadingtable = false;
            console.log('error > ' + error);
        }
    } else {
        console.log('NOT DONE');
    }
}

const excelLoadMore = (nextRecordsUrl, detailList, isDone) => {
    processRestForExcel({
        restURL: nextRecordsUrl,
    }).then((result) => {
        if (result) {
            let parsedResult = JSON.parse(result)
            try {
                if (parsedResult.hasOwnProperty('done')) {
                    if (parsedResult.asdList) {
                        detailList.push(...parsedResult.asdList);
                        variables.rowCounter += parsedResult.asdList.length;
                    }
                    if (parsedResult.done) {
                        variables.showFileGenerationBar = false;
                        isDone = true;
                        buildExcel();
                    } else {
                        excelLoadMore(parsedResult.nextRecordsUrl);
                    }
                }
            } catch (error) {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                showNotification('', error.message, 'error');
            }
        }
    });
}

// const handleSend = (excelBlob) => {
//     if (this.selectedId != '') {
//         sendEmail({
//             emailTo: this.targetAddress,
//             Name: variables.currentAssortment.Name,
//             emailCc: this.cc,
//             emailBcc: this.bcc,
//             emailSubject: this.subject,
//             emailBody: this.body,
//             excelBlob: excelBlob,
//             recordId: this.recordId,
//             assortmentName: 'assortmentTest'
//         }).then(result => {
//             console.log('result: ' + result)
//             window.close()
//         })
//         .catch(error => {
//             console.error(error); // Handle error
//         });
//     }
// }

const showNotification = (title, message, variant, mode) => {
    let evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
    });
    variables.self.dispatchEvent(evt);
}

export { initDataJs, loadDataJs, exportExcel, showNotification, variables };