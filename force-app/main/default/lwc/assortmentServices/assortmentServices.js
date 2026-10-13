import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
import { loadScript } from 'lightning/platformResourceLoader';
import initData from '@salesforce/apex/AssortmentMatrixCtrl.initData';
import loadData from '@salesforce/apex/AssortmentMatrixCtrl.loadData';
import processRestForExcel from '@salesforce/apex/AssortmentMatrixCtrl.processRestForExcel';
import { ASD_API_NAMES, BU_API_NAMES, PROD_API_NAMES, AS_API_NAMES, labels, fieldsToColor} from './propreties.js';

let excelJsInitialized = false;
/**
 * Ensure ExcelJS is loaded once per session
 * @param {LightningElement} component - the LWC context for loadScript
 */
async function ensureExcelJS(component) {
    if (!excelJsInitialized) {
        await loadScript(component, ExcelJSURL);
        excelJsInitialized = true;
    }
}

/**
 * Initialize matrix data
 */
const initDataServices = (recordId, gridLayout) => {
    console.log("initDataServices recordID:", recordId);
    console.log("initDataServices layout:", gridLayout);
    return new Promise((resolve, reject) => {
        let wrapper = {
            mainData: {},
            categoryBUClustersMap: {},
            categoryBUCpltMap: {},
            categoryBUClustersRefMap: {},
            categoryBUCpltRefMap: {},
            assortmentLongName: '',
        }
        initData({ assortmentId: recordId, gridLayout: gridLayout }).then((result) => {
            console.log('result >>> ' + result)
            console.log('1 >>> ')
            wrapper.mainData = JSON.parse(result);
            console.log('2 >>> ')
            console.log('wrapper.mainData >>> ' + JSON.stringify(wrapper.mainData))
            // check the local Storage
            let selectedFields;
            if (localStorage.getItem('AssortmentMatrix' + wrapper.mainData.currentAssortment.RecordType.DeveloperName) != null) {
                selectedFields = JSON.parse(localStorage.getItem('AssortmentMatrix' + wrapper.mainData.currentAssortment.RecordType.DeveloperName));
            }
            wrapper.mainData.gridSettingsManager.GRID_FIELDS.forEach(field => {
                field.isShown = !selectedFields || (selectedFields && selectedFields.includes(field.fieldName));
            });
            for (let category of Object.keys(wrapper.mainData.categoryBUClustersMap)) {
                for (let strat of wrapper.mainData.categoryBUClustersMap[category]) {
                    let key = category + strat.clientCategory;
                    if (!wrapper.categoryBUClustersMap.hasOwnProperty(key)) {
                        wrapper.categoryBUClustersMap[key] = [];
                    }
                    wrapper.categoryBUClustersMap[key].push(strat);
                }
            }
            for (let category of Object.keys(wrapper.mainData.categoryBUCpltMap)) {
                for (let cplt of wrapper.mainData.categoryBUCpltMap[category]) {
                    let key = category + cplt.clientCategory;
                    if (!wrapper.categoryBUCpltMap.hasOwnProperty(key)) {
                        wrapper.categoryBUCpltMap[key] = [];
                    }
                    wrapper.categoryBUCpltMap[key].push(cplt);
                }
            }
            for (let category of Object.keys(wrapper.mainData.categoryBUClustersRefMap)) {
                for (let refStrat of wrapper.mainData.categoryBUClustersRefMap[category]) {
                    let key = category + refStrat.clientCategory;
                    if (!wrapper.categoryBUClustersRefMap.hasOwnProperty(key)) {
                        wrapper.categoryBUClustersRefMap[key] = [];
                    }
                    wrapper.categoryBUClustersRefMap[key].push(refStrat);
                }
            }
            for (let category of Object.keys(wrapper.mainData.categoryBUCpltRefMap)) {
                for (let refCplt of wrapper.mainData.categoryBUCpltRefMap[category]) {
                    let key = category + refCplt.clientCategory;
                    if (!wrapper.categoryBUCpltRefMap.hasOwnProperty(key)) {
                        wrapper.categoryBUCpltRefMap[key] = [];
                    }
                    wrapper.categoryBUCpltRefMap[key].push(refCplt);
                }
            }
            wrapper.assortmentLongName = wrapper.mainData.currentAssortment.LongName__c;
            console.log('AS_API_NAMES >>> ' + JSON.stringify(AS_API_NAMES))
            resolve(wrapper);
        }).catch(error => {
            console.error(error);
            reject(error);
            //this.showNotification('error', error?.body?.message || error?.message || error, 'error', 'sticky');
        });
    });
}

/**
 * Load detail rows for a given assortment
 * @param {string} recordId
 * @param {string} gridLayout
 * @returns {Promise<Object>} parsed row data
 */
function loadDataServices(recordId, gridLayout) {
    return loadData({ assortmentId: recordId, gridLayout })
        .then(raw => JSON.parse(raw))
        .catch(error => {
            console.error('loadDataServices error', error);
            throw error;
        });
}

function isDisabled(option, initialValue, currentValue, hasLastHistory, isValidDetail) {
    initialValue = initialValue == undefined || initialValue == null ? '' : initialValue;
    currentValue = currentValue == undefined || currentValue == null ? '' : currentValue;
    if (initialValue != currentValue) {
        if (option == initialValue || option == currentValue)
                return false;
            return true;
        }
        if (currentValue == option) {
            return false;
        }
        switch (initialValue) {
            case '':
                if (option == 'Opportunity') {
                    return false;
                }
                break;
            case 'Increase':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Decrease':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'New':
                if (option == 'Opportunity' || (option == '' && !hasLastHistory && !isValidDetail)) {
                    return false;
                }
                break;
            case 'Keep':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Delist':
                if (option == 'New') {
                    return false;
                }
                break;
            case 'Opportunity':
                if (option == 'Keep' || option == 'ProbablyDeleted' || option == 'Delist' || ((!hasLastHistory || isValidDetail) && option == 'New')) {
                    return false;
                }
                break;
            case 'ProbablyDeleted':
                if (option == 'Keep' || option == 'Delist') {
                    return false;
                }
                break;
        }
        return true;
    }

/**
 * Rebuilds exactly your matrix data (categories → rows → values)
 * so we can export it the same way both from Matrix and DirectAccess.
 */
function buildExportData(wrapper) {
  const {
    mainData,
    categoryBUClustersMap,
    categoryBUCpltMap,
    categoryBUClustersRefMap,
    categoryBUCpltRefMap,
    asdList,
    filters,
    nbOfStoresField,
  } = wrapper;

  // local state (mirrors `this.*` in LWC)
  let displayedFields        = [];
  let totalsMap              = {};
  let initTotalsMap          = {};
  let totalsList             = [];
  let subTotalsMap = {};
  let clusterTotalIndexes    = [];
  let cpltTotalIndexes       = [];
  let clusterRefTotalIndexes = [];
  let cpltRefTotalIndexes    = [];
  let productLifeStatusValues= [];
  let picklistColorsMap      = {};
  let ASDToUpdateMap         = {};    // unused for export
  const ASDPicklistValues      = mainData.gridSettingsManager.picklistValuesMap;
  let asdFullDataMap;

      function getSubTotalList(categoryId) {
        try {
            //GET NB OF STORES FOR EACH CLUSTER
            let clusterToStores = {};
            if (filters.includeNbOfStores) {
                if (mainData.categoryBUClustersMap && mainData.categoryBUClustersMap.hasOwnProperty(categoryId)) {
                    for (let strat of mainData.categoryBUClustersMap[categoryId]) {
                        clusterToStores['Strat' + strat.index] = strat.cluster[nbOfStoresField];
                    }
                }
                if (mainData.categoryBUCpltMap && mainData.categoryBUCpltMap.hasOwnProperty(categoryId)) {
                    for (let cplt of mainData.categoryBUCpltMap[categoryId]) {
                        clusterToStores['Cplt' + cplt.index] = cplt.cluster[nbOfStoresField];
                    }
                }
                if (mainData.categoryBUClustersRefMap && mainData.categoryBUClustersRefMap.hasOwnProperty(categoryId)) {
                    for (let strat of mainData.categoryBUClustersRefMap[categoryId]) {
                        clusterToStores['RefStrat' + strat.index] = strat.cluster[nbOfStoresField];
                    }
                }
                if (mainData.categoryBUCpltRefMap && mainData.categoryBUCpltRefMap.hasOwnProperty(categoryId)) {
                    for (let cplt of mainData.categoryBUCpltRefMap[categoryId]) {
                        clusterToStores['RefCplt' + cplt.index] = cplt.cluster[nbOfStoresField];
                    }
                }
            }
            let subTotalList = [];
            let categoryTotals = subTotalsMap[categoryId];
            for (let field of displayedFields) {
                if (field.isStrat || field.isCplt) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        key: 'SubTotal ' + categoryId + '' + field.fieldName,
                        isShown: field.isShown,
                        scale: 0,
                        value: 0,
                        class: 'categoryTd slds-text-align_center'
                    }
                    if (subTotalsMap && subTotalsMap.hasOwnProperty(categoryId) && categoryTotals.hasOwnProperty(field.fieldName)) {
                        fieldWrapper.value = (filters.includeAllStatuses ? categoryTotals[field.fieldName].valueofAllStatus : categoryTotals[field.fieldName].value);
                        if (filters.includeNbOfStores && clusterToStores.hasOwnProperty(field.fieldName)) {
                            fieldWrapper.value *= clusterToStores[field.fieldName];
                        }
                    } else {
                        fieldWrapper.value = 0
                    }
                    subTotalList.push(fieldWrapper)
                } else {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        key: 'SubTotal ' + categoryId + '' + field.fieldName,
                        scale: field.scale,
                        isShown: field.isShown,
                        value: null,
                        class: categoryTotals && categoryTotals.hasOwnProperty(field.fieldName) ? categoryTotals[field.fieldName].class : 'categoryTd'
                    }
                    if (subTotalsMap.hasOwnProperty(categoryId) && categoryTotals.hasOwnProperty(field.fieldName)) {
                        fieldWrapper.value = filters.includeAllStatuses ? categoryTotals[field.fieldName].valueofAllStatus : categoryTotals[field.fieldName].value;
                    } else if (field.isNumberField || field.isBoolean) {
                        fieldWrapper.value = 0
                    }
                    subTotalList.push(fieldWrapper)
                }
            }
            return subTotalList;
        } catch (error) {
            console.error('getSubTotalList', error);
                throw error;
        }
    }
    function buildRowData(asd, productLifeStatusField, historyList) {
        let status;
        try {
            status = asd[ASD_API_NAMES.Status__c] || '';
        } catch(e) {
            throw e;
        }
        let asdW = {
            Id: asd.Id,
            productId: asd[ASD_API_NAMES.Product__c],
            startDate: asd[ASD_API_NAMES.StartDate__c],
            lastValidProductLifeStatus: '',
            isNegoN1: !asd[ASD_API_NAMES.AssortmentDetailLHistory__c] && asd[ASD_API_NAMES.AssortmentDetailNegotiationRef__c],
            lastValidStratIndex: '',
            lastValidStratCount: 0,
            hasHistory: asd[ASD_API_NAMES.AssortmentDetailLHistory__c] != null || asd[ASD_API_NAMES.AssortmentDetailNegotiationRef__c] != null,
            //isValid: asd[ASD_API_NAMES.Status__c] == 'Validate',
            isValid: status === 'Validate',
            initialClientStatus: asd[ASD_API_NAMES.ProductLifeStatusAss__c],
            initialClusters: asd[ASD_API_NAMES.ProductCluster__c],
            values: [],
            historyList: [],
        }
        // if (asd[ASD_API_NAMES.Status__c] == 'Validate') {
        if (status === 'Validate') {
            asdW.lastValidProductLifeStatus = asd[ASD_API_NAMES.ProductLifeStatusAss__c];
            asdW.lastValidStratIndex = asd[ASD_API_NAMES.BusinessUnitCluster__c] ? parseInt(asd[ASD_API_NAMES.BusinessUnitCluster__c.replace('__c', '__r')][BU_API_NAMES.AssortmentStrat__c].replace('Strat', '').replace('Cplt', '')) : null;
        } else {
            let lastHistory = asd[ASD_API_NAMES.AssortmentDetailLHistory__c] ? asd[ASD_API_NAMES.AssortmentDetailLHistory__c.replace('__c', '__r')] : asd[ASD_API_NAMES.AssortmentDetailNegotiationRef__c.replace('__c', '__r')]
            asdW.lastValidProductLifeStatus = lastHistory ? lastHistory[ASD_API_NAMES.ProductLifeStatusAss__c] : null;
            asdW.lastValidStratIndex = lastHistory && lastHistory[ASD_API_NAMES.BusinessUnitCluster__c] ? parseInt(lastHistory[ASD_API_NAMES.BusinessUnitCluster__c.replace('__c', '__r')][BU_API_NAMES.AssortmentStrat__c]?.replace('Strat', '')?.replace('Cplt', '')) : null;
        }
        let index = 0;
        for (let field of mainData.gridSettingsManager.GRID_FIELDS) {
            try {
            if (field.isInputField && ASDToUpdateMap.hasOwnProperty(asd.Id)) {
                let obj = ASDToUpdateMap[asd.Id];
                if (obj.hasOwnProperty(field.fieldName)) {
                    asd[field.fieldName] = obj[field.fieldName];
                }
            }
            if (field.fieldName != ASD_API_NAMES.ProductCluster__c && field.fieldName != ASD_API_NAMES.ProductClusterASDNego__c) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    key: asd.Id + '' + field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isInputField: field.isInputField,
                    fieldType: field.fieldType,
                    isNumberField: field.isNumberField,
                    isReference: false,
                    isDate: false,
                    isPicklist: false,
                    isBoolean: false,
                    isText: false,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isShown: field.isShown,
                    style: field.style,
                    bgColor: field.bgColor ? field.bgColor.replace('#', '') : 'FFFFFF',
                    fieldValue: asd[field.fieldName],
                    picklistOptions: [],
                    scale: field.scale,
                    step: field.isInputField && field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                    linkStyle: '',
                    showInTotal: field.showInTotal,
                    isSwitch: false,
                    isStop: false,
                    isHLP: false,
                    class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                }
                if (field.fieldName == ASD_API_NAMES.Product__c) {
                    fieldWrapper.divClass = 'spaceBetween';
                    if (mainData.productsHavingASDHLP.includes(asd[ASD_API_NAMES.Product__c])) {
                        fieldWrapper.HLPClass = 'HLPSelected';
                    }
                }
                if (fieldWrapper.isHTMLFormatted) {
                    fieldWrapper.class += ' slds-align--absolute-center';
                }
                switch (field.fieldType) {
                    case 'REFERENCE':
                        fieldWrapper.isReference = true;
                        fieldWrapper.link = '/' + fieldWrapper.fieldValue;
                        fieldWrapper.fieldValue = asd[field.fieldName.replace('__c', '__r')]?.Name;
                        break;
                    case 'DATE':
                        fieldWrapper.isDate = true;
                        break;
                    case 'PICKLIST':
                        fieldWrapper.isPicklist = true;
                        const pickVals = mainData
                        .gridSettingsManager
                        .GRID_FIELDS
                        .find(f => f.fieldName === field.fieldName)
                        .pickListValues;
                        //for (let pickVal of ASDPicklistValues[field.fieldName].values) {
                        for (let pickVal of pickVals) {
                            if (field.fieldName != ASD_API_NAMES.Status__c || (field.fieldName == ASD_API_NAMES.Status__c && pickVal.value != 'PreviouslyValidate')) {
                                fieldWrapper.picklistOptions.push({
                                    label: pickVal.label,
                                    value: pickVal.value,
                                    key: asd.Id + '' + pickVal.value,
                                    isSelected: pickVal.value == fieldWrapper.fieldValue,
                                    isDisabled: field.fieldName == ASD_API_NAMES.ProductLifeStatusAss__c && isDisabled(pickVal.value, asd[ASD_API_NAMES.ProductLifeStatusAss__c], asd[ASD_API_NAMES.ProductLifeStatusAss__c], asdW.hasHistory, asdW.isValid)
                                })
                            }
                        }
                        fieldWrapper.picklistOptions.unshift({
                            label: labels.LBL_None_Picklist_Value,
                            value: '',
                            key: asd.Id + 'NULL',
                            isSelected: asd[field.fieldName] == '',
                            isDisabled: field.fieldName == ASD_API_NAMES.ProductLifeStatusAss__c && isDisabled('', asd[ASD_API_NAMES.ProductLifeStatusAss__c], asd[ASD_API_NAMES.ProductLifeStatusAss__c], asdW.hasHistory, asdW.isValid)
                        })
                        fieldWrapper.fieldOutputValue = mainData.gridSettingsManager.picklistValuesMap[field.fieldName][fieldWrapper.fieldValue] != null ? mainData.gridSettingsManager.picklistValuesMap[fieldWrapper.fieldName][fieldWrapper.fieldValue] : fieldWrapper.fieldValue;
                        break;
                    case 'BOOLEAN':
                        fieldWrapper.isBoolean = true;
                        fieldWrapper.divClass = 'slds-p-left--x-small';
                        break;
                    default:
                        fieldWrapper.isText = !fieldWrapper.isNumberField;
                }

                if (field.fieldName.includes('.')) {
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let item = index == 0 ? asd : fieldWrapper.fieldValue;
                        if (index == values.length - 1 && field.stringFieldType == 'REFERENCE') {
                            fieldWrapper.fieldValue = item[values[index].replace('__c', '__r')].Name;
                            fieldWrapper.link = '/' + item[values[index]];
                        } else {
                            fieldWrapper.fieldValue = item[values[index]];
                        }
                    }
                }
                if (fieldsToColor.includes(field.fieldName)) {
                    fieldWrapper.style += 'background-color:' + (picklistColorsMap ? picklistColorsMap[asd[ASD_API_NAMES.ProductLifeStatusAss__c]] : 'white') + ';';
                    fieldWrapper.bgColor = (picklistColorsMap ? picklistColorsMap[asd[ASD_API_NAMES.ProductLifeStatusAss__c]] : '#ffffff')?.replace('#', '');
                }
                fieldWrapper.class += fieldWrapper.isNumberField ? ' slds-text-align--right' : '';
                if (!field.widthStyle) {
                    fieldWrapper.style += 'min-width: 100px; max-width: 100px; width: 100px;';
                }
                let product = asd[ASD_API_NAMES.Product__c.replace('__c', '__r')];
                if (product.RecordType?.DeveloperName == 'Competitor' && !fieldsToColor.includes(field.fieldName)) {
                    fieldWrapper.style += 'background: #FFF7E8;';
                }
                if (field.fieldName == ASD_API_NAMES.Product__c) {
                    if (product[PROD_API_NAMES.Market_Introduction_Date__c]) {
                        if ((product[PROD_API_NAMES.IsInnovation__c] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[PROD_API_NAMES.Market_Introduction_Date__c]).getFullYear()) < mainData.currentAssortment[AS_API_NAMES.Year__c])) {
                            fieldWrapper.linkStyle = 'color:' + mainData.INNO_INTRO_DATE_LESS_N + ';';
                        }
                        if ((product[PROD_API_NAMES.IsInnovation__c] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[PROD_API_NAMES.Market_Introduction_Date__c]).getFullYear()) >= mainData.currentAssortment[AS_API_NAMES.Year__c])) {
                            fieldWrapper.linkStyle = 'color:' + mainData.INNO_INTRO_DATE_GREATER_N + ';';
                        }
                    }
                    if (product[PROD_API_NAMES.Market_End_of_Life_Date__c]) {
                        if ((new Date(product[PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) < mainData.currentAssortment[AS_API_NAMES.Year__c]) {
                            fieldWrapper.linkStyle = 'color:' + mainData.STOP_DATE_LESS_N + ';';
                        }
                        if ((new Date(product[PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) >= mainData.currentAssortment[AS_API_NAMES.Year__c]) {
                            fieldWrapper.linkStyle = 'color:' + mainData.STOP_DATE_GREATER_N + ';';
                        }
                    }
                    if (product[PROD_API_NAMES.Product_Reference_Type__c] == 'Switch'
                        && (!product[PROD_API_NAMES.Market_End_of_Life_Date__c] || (new Date(product[PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) > mainData.currentAssortment[AS_API_NAMES.Year__c])
                        && !asd[ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isSwitch = true;
                    }
                    if ((product[PROD_API_NAMES.Market_End_of_Life_Date__c] && (new Date(product[PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) <= mainData.currentAssortment[AS_API_NAMES.Year__c])
                        && !asd[ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isStop = true;
                    }
                    if (product[PROD_API_NAMES.Product_Reference_Type__c] == 'Reno'
                        && (!product[PROD_API_NAMES.Market_End_of_Life_Date__c] || (new Date(product[PROD_API_NAMES.Market_End_of_Life_Date__c]).getFullYear()) > mainData.currentAssortment[AS_API_NAMES.Year__c])
                        && !asd[ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isReno = true;
                    }
                    if (asd.RecordType.DeveloperName == 'Regular'
                        && mainData.productsHavingHLP.includes(asd[ASD_API_NAMES.Product__c])
                        && !asd[ASD_API_NAMES.Version__c]) {
                        fieldWrapper.isHLP = true;
                    }

                }
                asdW.values.push(fieldWrapper);
            } else if (field.fieldName == ASD_API_NAMES.ProductCluster__c) {
                let selectedStratValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Strat?.filter(item => item.value).map(item => item.index) : [];
                let selectedCpltValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Cplt?.filter(item => item.value).map(item => item.index) : [];
                let key = asd[ASD_API_NAMES.Hierarchy__c] + asd[ASD_API_NAMES.ClientCategory__c];
                let key2 = asd[ASD_API_NAMES.Hierarchy__c] + null;
                let stratList = categoryBUClustersMap.hasOwnProperty(key) ? categoryBUClustersMap[key] : [];
                if (stratList.length == 0) {
                    stratList = categoryBUClustersMap.hasOwnProperty(key2) ? categoryBUClustersMap[key2] : [];
                }
                let stratIndexList = stratList.map(strat => strat.index);
                for (let index of clusterTotalIndexes) {
                    let strat = stratIndexList.includes(index) ? stratList[stratIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'Strat' + strat.index,
                        key: asd.Id + 'Strat' + strat.index,
                        stratIndex: strat.index,
                        stratId: strat?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedStratValues.includes(strat.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !stratIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    fieldWrapper.style = 'background-color:' + (picklistColorsMap ? picklistColorsMap[asd[ASD_API_NAMES.ProductLifeStatusAss__c]] : 'white') + ';';
                    fieldWrapper.bgColor = (picklistColorsMap ? picklistColorsMap[asd[ASD_API_NAMES.ProductLifeStatusAss__c]] : '#ffffff')?.replace('#', '');
                    asdW.values.push(fieldWrapper);
                }
                let cpltList = categoryBUCpltMap.hasOwnProperty(key) ? categoryBUCpltMap[key] : [];
                if (cpltList.length == 0) {
                    cpltList = categoryBUCpltMap.hasOwnProperty(key2) ? categoryBUCpltMap[key2] : [];
                }
                let cpltIndexList = cpltList.map(cplt => cplt.index);
                for (let index of cpltTotalIndexes) {
                    let cplt = cpltIndexList.includes(index) ? cpltList[cpltIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'Cplt' + cplt.index,
                        key: asd.Id + 'Cplt' + cplt.index,
                        stratIndex: cplt.index,
                        stratId: cplt?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedCpltValues.includes(cplt.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !cpltIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    fieldWrapper.style = 'background-color:' + (picklistColorsMap ? picklistColorsMap[asd[ASD_API_NAMES.ProductLifeStatusAss__c]] : 'white') + ';';
                    fieldWrapper.bgColor = (picklistColorsMap ? picklistColorsMap[asd[ASD_API_NAMES.ProductLifeStatusAss__c]] : '#ffffff')?.replace('#', '');
                    asdW.values.push(fieldWrapper);
                }
                // calculate lastValidStratCount
                // if (asd[ASD_API_NAMES.Status__c] == 'Validate') {
                if (status === 'Validate') {
                    asdW.lastValidStratCount += selectedStratValues.length;
                } else {
                    let lastHistory = asd[ASD_API_NAMES.AssortmentDetailLHistory__c] ? asd[ASD_API_NAMES.AssortmentDetailLHistory__c.replace('__c', '__r')] : asd[ASD_API_NAMES.AssortmentDetailNegotiationRef__c.replace('__c', '__r')]
                    let selectedStratHistoValues = lastHistory && lastHistory[field.fieldName] ? JSON.parse(lastHistory[field.fieldName]).Strat?.filter(item => item.value).map(item => item.index) : [];
                    asdW.lastValidStratCount += selectedStratHistoValues.length;
                }
            } else if (field.fieldName == ASD_API_NAMES.ProductClusterASDNego__c && mainData.currentAssortment[ASD_API_NAMES.AssortmentNegotiationRef__c] != null) {
                let selectedRefStratValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Strat?.filter(item => item.value).map(item => item.index) : [];
                let selectedRefCpltValues = asd[field.fieldName] ? JSON.parse(asd[field.fieldName]).Cplt?.filter(item => item.value).map(item => item.index) : [];

                let key = asd[ASD_API_NAMES.Hierarchy__c] + asd[ASD_API_NAMES.ClientCategory__c];
                let key2 = asd[ASD_API_NAMES.Hierarchy__c] + null;
                let stratList = categoryBUClustersRefMap.hasOwnProperty(key) ? categoryBUClustersRefMap[key] : [];
                if (stratList.length == 0) {
                    stratList = categoryBUClustersRefMap.hasOwnProperty(key2) ? categoryBUClustersRefMap[key2] : [];
                }
                let stratIndexList = stratList.map(strat => strat.index);
                for (let index of clusterRefTotalIndexes) {
                    let strat = stratIndexList.includes(index) ? stratList[stratIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'RefStrat' + strat.index,
                        key: asd.Id + 'RefStrat' + strat.index,
                        stratIndex: strat.index,
                        stratId: strat?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedRefStratValues.includes(strat.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !stratIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    asdW.values.push(fieldWrapper);
                }
                let cpltList = categoryBUCpltRefMap.hasOwnProperty(key) ? categoryBUCpltRefMap[key] : [];
                if (cpltList.length == 0) {
                    cpltList = categoryBUCpltRefMap.hasOwnProperty(key2) ? categoryBUCpltRefMap[key2] : [];
                }
                let cpltIndexList = cpltList.map(cplt => cplt.index);
                for (let index of cpltRefTotalIndexes) {
                    let cplt = cpltIndexList.includes(index) ? cpltList[cpltIndexList.indexOf(index)] : '';
                    let fieldWrapper = {
                        fieldName: 'RefCplt' + cplt.index,
                        key: asd.Id + 'RefCplt' + cplt.index,
                        stratIndex: cplt.index,
                        stratId: cplt?.cluster?.Id,
                        isInputField: field.isInputField,
                        isStrat: true,
                        style: field.style,
                        isShown: field.isShown,
                        bgColor: '',
                        fieldValue: selectedRefCpltValues.includes(cplt.index),
                        class: 'slds-truncate' + (index == 0 ? ' slds-border--left' : '') + (asd[ASD_API_NAMES.Version__c] != null ? ' history' : ''),
                        isStratEmpty: !cpltIndexList.includes(index),
                    }
                    fieldWrapper.divClass = 'slds-p-left--x-small';
                    asdW.values.push(fieldWrapper);
                }
            }
            index++;
            } catch (innerErr) {
    throw innerErr;
  }
        }
        for (let history of historyList) {
            const detailRecord = history?.detail ?? history;
            asdW.historyList.push(buildRowData(detailRecord, productLifeStatusField, []));
        }
        return asdW;
    }

    function buildData(asdList) {
        let asdMap = {};
        let categoryWMap = {};
        let productLifeStatusField = mainData.gridSettingsManager.GRID_FIELDS.filter(item => item.fieldName == ASD_API_NAMES.ProductLifeStatusAss__c);
        if (productLifeStatusField.length > 0) {
            picklistColorsMap = productLifeStatusField[0].picklistColorsMap;
            if (productLifeStatusValues.length == 0) {
                for (let item of productLifeStatusField[0].pickListValues) {
                    productLifeStatusValues.push({ value: item.value, label: item.label, bgColor: (picklistColorsMap ? picklistColorsMap[item.value] : 'white;'), style: 'background-color:' + (picklistColorsMap ? picklistColorsMap[item.value] : 'white') + ';' })
                }
                productLifeStatusValues.unshift({ value: 'BLANK', label: labels.Blank, bgColor: 'white', style: 'background-color:white;' })
            }
        }
        let categoryIndex = 0;
        for (let item of asdList) {
            let categoryId = item.detail[ASD_API_NAMES.Hierarchy__c];
            let categW = {
                categoryId: categoryId,
                categoryIndex: categoryIndex,
                key: categoryId + '' + categoryIndex,
                categoryName: item.detail[ASD_API_NAMES.Hierarchy__c.replace('__c', '__r')].Name,
                link: '/' + categoryId,
                asdList: [],
                rowspan: 1,
                subTotalList: []
            }
            if (!categoryWMap.hasOwnProperty(categoryId)) {
                //BUILD DISPLAYED FIELDS
                // exist in boucle for of asdList => In Case that a new product is added to the assortment that didn't previously have an ASD, the Strat header should be rebuilt accordingly.
                if (displayedFields.length == 0) {
                    for (let field of mainData.gridSettingsManager.GRID_FIELDS) {
                        let emptyTotal = {
                            key: 'Total' + field.fieldName,
                            value: 0,
                            valueofAllStatus: null,
                            isValueUp: false,
                            isValueDown: false,
                            isValueofAllStatusUp: false,
                            isValueofAllStatusDown: false,
                            isShown: field.isShown,
                            class: 'categoryTd' + ((field.fieldType == 'BOOLEAN' || field.fieldName == ASD_API_NAMES.ProductCluster__c || field.fieldName == ASD_API_NAMES.ProductClusterASDNego__c) ? ' slds-text-align_center' : ' slds-text-align_right')
                        };
                        if (field.fieldName != ASD_API_NAMES.ProductCluster__c && field.fieldName != ASD_API_NAMES.ProductClusterASDNego__c) {
                            displayedFields.push({
                                fieldName: field.fieldName,
                                fieldLabel: field.fieldLabel.toUpperCase(),
                                isShown: field.isShown,
                                isNumberField: field.isNumberField,
                                isSortable: field.isSortable,
                                isReference: field.fieldType == 'REFERENCE',
                                isBoolean: field.fieldType == 'BOOLEAN',
                                sortedField: false,
                                scale: field.scale,
                                style: field.widthStyle + (field.headerStyle ? field.headerStyle.style : ''),
                                width: field.nonConditional && field.nonConditional.width ? field.nonConditional?.width.replace('px', '') / 4 : field.fieldLabel.toUpperCase().length * 2,
                                bgColor: field.bgColor.replace('#', '')
                            })
                            totalsList.push(totalsMap.hasOwnProperty(field.fieldName) ? totalsMap[field.fieldName] : emptyTotal);
                        } else if (field.fieldName == ASD_API_NAMES.ProductCluster__c) {
                            for (let key of Object.keys(mainData.categoryBUClustersMap)) {
                                for (let strat of mainData.categoryBUClustersMap[key]) {
                                    if (displayedFields.filter(field => field.fieldName == 'Strat' + strat.index)?.length == 0) {
                                        clusterTotalIndexes.push(strat.index);
                                        displayedFields.push({
                                            isStrat: true,
                                            isShown: field.isShown,
                                            fieldName: 'Strat' + strat.index,
                                            fieldLabel: strat.cluster.Name.toUpperCase(),
                                            isNumberField: field.isNumberField,
                                            style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''),
                                            width: '15', bgColor: field.bgColor.replace('#', '')
                                        })
                                        if (!totalsMap.hasOwnProperty('Strat' + strat.index)) {
                                            totalsMap['Strat' + strat.index] = emptyTotal;
                                            initTotalsMap['Strat' + strat.index] = { value: 0, valueofAllStatus: 0, scale: 0 };
                                        }
                                        totalsList.push(totalsMap.hasOwnProperty('Strat' + strat.index) ? totalsMap['Strat' + strat.index] : emptyTotal);
                                    }
                                }
                            }
                            for (let key of Object.keys(mainData.categoryBUCpltMap)) {
                                for (let cplt of mainData.categoryBUCpltMap[key]) {
                                    if (displayedFields.filter(field => field.fieldName == 'Cplt' + cplt.index)?.length == 0) {
                                        cpltTotalIndexes.push(cplt.index);
                                        displayedFields.push({
                                            isShown: field.isShown, isCplt: true, fieldName: 'Cplt' + cplt.index, fieldLabel: cplt.cluster.Name.toUpperCase(), isNumberField: field.isNumberField, style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''), width: '15', bgColor: field.bgColor.replace('#', '')
                                        })
                                        if (!totalsMap.hasOwnProperty('Cplt' + cplt.index)) {
                                            totalsMap['Cplt' + cplt.index] = emptyTotal;
                                            initTotalsMap['Cplt' + cplt.index] = { value: 0, valueofAllStatus: 0, scale: 0 };
                                        }
                                        totalsList.push(totalsMap.hasOwnProperty('Cplt' + cplt.index) ? totalsMap['Cplt' + cplt.index] : emptyTotal);
                                    }
                                }
                            }
                        } else if (field.fieldName == ASD_API_NAMES.ProductClusterASDNego__c && mainData.currentAssortment[ASD_API_NAMES.AssortmentNegotiationRef__c] != null) {
                            for (let key of Object.keys(mainData.categoryBUClustersRefMap)) {
                                for (let strat of mainData.categoryBUClustersRefMap[key]) {
                                    if (displayedFields.filter(field => field.fieldName == 'RefStrat' + strat.index)?.length == 0) {
                                        clusterRefTotalIndexes.push(strat.index);
                                        displayedFields.push({
                                            isStrat: true,
                                            fieldName: 'RefStrat' + strat.index,
                                            fieldLabel: strat.cluster.Name.toUpperCase(),
                                            isShown: field.isShown,
                                            isNumberField: field.isNumberField,
                                            style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''),
                                            width: '15', bgColor: field.bgColor.replace('#', '')
                                        })
                                        totalsList.push(totalsMap.hasOwnProperty('RefStrat' + strat.index) ? totalsMap['RefStrat' + strat.index] : emptyTotal);
                                    }
                                }
                            }
                            for (let key of Object.keys(mainData.categoryBUCpltRefMap)) {
                                for (let cplt of mainData.categoryBUCpltRefMap[key]) {
                                    if (displayedFields.filter(field => field.fieldName == 'RefCplt' + cplt.index)?.length == 0) {
                                        cpltRefTotalIndexes.push(cplt.index);
                                        displayedFields.push({
                                            isCplt: true,
                                            fieldName: 'RefCplt' + cplt.index,
                                            fieldLabel: cplt.cluster.Name.toUpperCase(),
                                            isNumberField: field.isNumberField,
                                            isShown: field.isShown,
                                            style: 'min-width: 50px; max-width: 50px; width: 50px;' + (field.headerStyle ? field.headerStyle.style : ''),
                                            width: '15',
                                            bgColor: field.bgColor.replace('#', '')
                                        })
                                        totalsList.push(totalsMap.hasOwnProperty('RefCplt' + cplt.index) ? totalsMap['RefCplt' + cplt.index] : emptyTotal);
                                    }
                                }
                            }
                        }
                    }
                }
                categW.subTotalList = getSubTotalList(categoryId);
                categoryWMap[categoryId] = categW;
                categoryIndex++;
            }
            categW = categoryWMap[categoryId];
            //categW.asdList.push(buildRowData(item.detail, productLifeStatusField[0], item.historyList));
            console.log('Critical Line!!!')
            categW.asdList.push(buildRowData(item.detail, productLifeStatusField[0], item.historyList));
            categW.rowspan += 1;
            if (filters.isShowHistory) {
                categW.rowspan += item.historyList.length;
            }
            categoryWMap[categoryId] = categW;
            asdMap[item.detail.Id] = item.detail;
        }
        asdFullDataMap = asdMap;
        return Object.values(categoryWMap);
    }
    return buildData(asdList);
}

async function exportExcelServices(component, recordId, recordType, fileName = 'export.xlsx') {
    try {
    // Ensure ExcelJS is loaded
    await ensureExcelJS(component);
    let apexArgs;
    if (recordType === 'ChannelBudget') {
      apexArgs = { assortmentId: recordId, isChannelBudget: true };
    } else {
      apexArgs = {
        assortmentId:     recordId,
        gridsettingsJSON: JSON.stringify(component.mainData.gridSettingsManager),
        restURL:          null
      };
    }
    // Call REST/Apex, parse, error-check
    const raw     = await processRestForExcel(apexArgs);
    const wrapper = JSON.parse(raw);
    // grab a few basic props so stringify won’t choke on the Proxy
    // … after parsing wrapper
    const rawFields = component.mainData.gridSettingsManager.GRID_FIELDS;
    // spread into a real array, then pick only the props you need
    const sampleFields = [...rawFields]
    .slice(0, 5)
    .map(f => ({
        fieldName:  f.fieldName,
        fieldLabel: f.fieldLabel,
        isShown:    f.isShown,
        style:      f.style,
        width:      f.width,
        fieldType:  f.fieldType
    }));
    if (wrapper.error) throw new Error(wrapper.error);
    if (!wrapper.asdList?.length) throw new Error('No rows returned from Apex');
    // Inject defaults for any missing detail fields
    wrapper.asdList.forEach(entry => {
      const detail = entry.detail;
      // if Status__c isn’t returned by Apex, default it to ''
      detail[ ASD_API_NAMES.Status__c ] = detail[ ASD_API_NAMES.Status__c ] ?? '';
    });
    // build out the minimal "wrapper" shape that buildExportData needs
    const exportWrapper = {
        mainData:                  component.mainData,
        categoryBUClustersMap:     component.categoryBUClustersMap,
        categoryBUCpltMap:         component.categoryBUCpltMap,
        categoryBUClustersRefMap:  component.categoryBUClustersRefMap,
        categoryBUCpltRefMap:      component.categoryBUCpltRefMap,
        picklistValuesMap:         component.mainData.gridSettingsManager.picklistValuesMap,
        asdList:                   wrapper.asdList,
        filters:                   component.filters,
        nbOfStoresField:           component.nbOfStoresField,
        ASD_API_NAMES, 
        BU_API_NAMES,
        PROD_API_NAMES,
        AS_API_NAMES,
        labels,
        fieldsToColor
    };
    const categories = buildExportData(exportWrapper);
    // Flatten every detail-row into one array
    const allRows = categories.reduce((acc, cat) => acc.concat(cat.asdList), []);
    // New workbook + sheet
    const workbook = new ExcelJS.Workbook();
    workbook.properties.date1904           = true;
    workbook.calcProperties.fullCalcOnLoad = true;
    const tabName = component.mainData.currentAssortment?.Name || recordType;
    const sheet   = workbook.addWorksheet(tabName, {
      properties: { tabColor: { argb: '0d807d' } }  // teal tab
    });
    // Build Excel columns:
    //    all visible GRID_FIELDS except the two raw cluster ones
    //    then H1…Hn for each Strat field
    //    then C1…Cm for each Cplt field
    const { ProductCluster__c, ProductClusterASDNego__c } = component.ASD_API_NAMES;
    const baseFields = component
      .mainData
      .gridSettingsManager
      .GRID_FIELDS
      .filter(f =>
        f.isShown &&
        f.fieldName !== ProductCluster__c &&
        f.fieldName !== ProductClusterASDNego__c
      );
    // start building columns
    const excelColumns = baseFields.map(f => {
      const pxMatch = /width:(\d+)px/.exec(f.style||'');
      return {
        header: f.fieldLabel,
        key:    f.fieldName,
        width:  pxMatch ? Number(pxMatch[1]) * 0.14 : (f.width || 20)
      };
    });
    // peek at the first row’s wrappers to see how many Strat/Cplt indexes we have
    const sample = allRows[0].values || [];
    // H-columns (Strat)
    sample
      .filter(v => v.isStrat && v.fieldName.startsWith('Strat'))
      .sort((a,b) => a.stratIndex - b.stratIndex)
      .forEach(v => {
        excelColumns.push({
          header: 'H' + (v.stratIndex + 1),
          key:    v.fieldName,
          width:  8
        });
      });
    // C-columns (Cplt)
    sample
      .filter(v => v.isStrat && v.fieldName.startsWith('Cplt'))
      .sort((a,b) => a.stratIndex - b.stratIndex)
      .forEach(v => {
        excelColumns.push({
          header: 'C' + (v.stratIndex + 1),
          key:    v.fieldName,
          width:  8
        });
      });

    sheet.columns = excelColumns;
    // Style HEADER row
    const headerRow = sheet.getRow(1);
    headerRow.height = 40;
    headerRow.eachCell(cell => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '0d807d' } };
      cell.font = { bold: true, color: { argb: 'FFFFFF' } };
      cell.border = {
        top:    { style: 'thin', color: { argb: 'E6E6E6' } },
        left:   { style: 'thin', color: { argb: 'E6E6E6' } },
        bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
        right:  { style: 'thin', color: { argb: 'E6E6E6' } }
      };
      cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center' };
    });
    // Add & style DATA rows
    allRows.forEach((r, rowIndex) => {
      // grey separator
      const sep = sheet.addRow([]);
      sep.height = 20;
      sheet.columns.forEach((_, c) => {
        sep.getCell(c+1).fill = {
          type: 'pattern', pattern: 'solid', fgColor: { argb: '595959' }
        };
      });
      // unwrap into the same column order
      const rowData = excelColumns.map(col => {
        const meta = r.values.find(v => v.fieldName === col.key) || {};
        return meta.fieldOutputValue != null
          ? meta.fieldOutputValue
          : (meta.fieldValue ?? '');
      });
      const dataRow = sheet.addRow(rowData);
      dataRow.height = 20;
      // style each cell
      dataRow.eachCell((cell, idx) => {
        const meta = r.values.find(v => v.fieldName === sheet.columns[idx-1].key) || {};
        const fillHex = (meta.bgColor || 'FFFFFF').replace('#','');
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: fillHex } };
        cell.border = {
          top:    { style: 'thin', color: { argb: 'E6E6E6' } },
          left:   { style: 'thin', color: { argb: 'E6E6E6' } },
          bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
          right:  { style: 'thin', color: { argb: 'E6E6E6' } }
        };
        const horiz = sheet.columns[idx-1].class?.includes('slds-text-align_center')
                    ? 'center'
                    : sheet.columns[idx-1].class?.includes('slds-text-align_right')
                      ? 'right'
                      : 'left';
        cell.alignment = { wrapText: true, vertical: 'middle', horizontal: horiz };
      });
    });
    // Serialize & trigger download
    const buf    = await workbook.xlsx.writeBuffer();
    const base64 = window.btoa(
      new Uint8Array(buf).reduce((s,b) => s + String.fromCharCode(b), '')
    );
    const uri    = `data:application/octet-stream;base64,${base64}`;
    const a      = document.createElement('a');
    a.href     = uri;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  } catch (error) {
    console.error('exportExcelServices error', error);
    component.dispatchEvent(
      new ShowToastEvent({
        title:   'Export Failed',
        message: error?.body?.message || error.message || 'Unknown error',
        variant: 'error',
        mode:    'sticky'
      })
    );
  }
}

export {
    initDataServices,
    loadDataServices,
    exportExcelServices,
    buildExportData
};