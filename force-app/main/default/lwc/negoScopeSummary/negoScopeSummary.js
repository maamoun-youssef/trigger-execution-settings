import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getPicklistValuesByRecordType, getObjectInfo } from 'lightning/uiObjectInfoApi';
// Services
import getData from '@salesforce/apex/NegoScopeSummaryCmpCtrl.getData';
// Custom Objects
import NEGOSCOPE_OBJECT from '@salesforce/schema/NegoScope__c';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import PG_OBJECT from '@salesforce/schema/PG__c';
// Custom Fields
import IncludeAllHEs__c from '@salesforce/schema/NegoScope__c.IncludeAllHEs__c';
import IncludeAllBrands__c from '@salesforce/schema/NegoScope__c.IncludeAllBrands__c';
import IncludeNewBrands__c from '@salesforce/schema/NegoScope__c.IncludeNewBrands__c';
import IncludeAllProducts__c from '@salesforce/schema/NegoScope__c.IncludeAllProducts__c';
import IncludeNewProducts__c from '@salesforce/schema/NegoScope__c.IncludeNewProducts__c';
import Hierarchy__c from '@salesforce/schema/NSHE__c.Hierarchy__c';
import HierarchyParent__c from '@salesforce/schema/Hierarchy__c.HierarchyParent__c';
import Level__c from '@salesforce/schema/Hierarchy__c.Level__c';
import Code__c from '@salesforce/schema/Hierarchy__c.Code__c';
import Brand__c from '@salesforce/schema/NSBRA__c.Brand__c';
// Custom Labels
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_No from "@salesforce/label/c.LBL_No";
import LBL_NS_Summary_Included_HE from "@salesforce/label/c.LBL_NS_Summary_Included_HE";
import LBL_NS_Summary_Excluded_HE from "@salesforce/label/c.LBL_NS_Summary_Excluded_HE";
import LBL_NS_Summary_Selected_Brands from "@salesforce/label/c.LBL_NS_Summary_Selected_Brands";
import LBL_NS_Summary_Product_Attributes from "@salesforce/label/c.LBL_NS_Summary_Product_Attributes";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_NS_Summary_Title from "@salesforce/label/c.LBL_NS_Summary_Title";
import LBL_NS_Summary_All_HEs_Included from "@salesforce/label/c.LBL_NS_Summary_All_HEs_Included";
import LBL_NS_Summary_All_Brands_Included from "@salesforce/label/c.LBL_NS_Summary_All_Brands_Included";
import LBL_NS_Summary_Null_Field from "@salesforce/label/c.LBL_NS_Summary_Null_Field";
import LBL_PA_ISNULL from '@salesforce/label/c.LBL_PA_ISNULL';
import LBL_PA_ISBLANK from '@salesforce/label/c.LBL_PA_ISBLANK';
import LBL_PA_IS_NOT_NULL from '@salesforce/label/c.LBL_PA_IS_NOT_NULL';
import LBL_PA_IS_NOT_BLANK from '@salesforce/label/c.LBL_PA_IS_NOT_BLANK';
import LBL_PA_EQUALS from '@salesforce/label/c.LBL_PA_EQUALS';
import LBL_PA_NOT_EQUALS from '@salesforce/label/c.LBL_PA_NOT_EQUALS';
import LBL_PA_CONTAINS from '@salesforce/label/c.LBL_PA_CONTAINS';
import LBL_PA_DOESNT_CONTAIN from '@salesforce/label/c.LBL_PA_DOESNT_CONTAIN';
import LBL_NS_Summary_Excluded_Products from '@salesforce/label/c.LBL_NS_Summary_Excluded_Products';
import LBL_NS_Summary_Included_Products from '@salesforce/label/c.LBL_NS_Summary_Included_Products';
import LBL_NS_Summary_Product_Info from '@salesforce/label/c.LBL_NS_Summary_Product_Info';
const Hierarchy__r = Hierarchy__c.fieldApiName.replace(/__c$/, '__r');
const HierarchyParent__r = HierarchyParent__c.fieldApiName.replace(/__c$/, '__r');
const Brand__r = Brand__c.fieldApiName.replace(/__c$/, '__r');


const NEGOSCOPE_API_NAMES = {
    IncludeAllHEs__c: IncludeAllHEs__c.fieldApiName,
    IncludeAllBrands__c: IncludeAllBrands__c.fieldApiName,
    IncludeNewBrands__c: IncludeNewBrands__c.fieldApiName,
    IncludeAllProducts__c: IncludeAllProducts__c.fieldApiName,
    IncludeNewProducts__c: IncludeNewProducts__c.fieldApiName,
    Hierarchy__c: Hierarchy__c.fieldApiName,
    HierarchyParent__c: HierarchyParent__c.fieldApiName,
    Level__c: Level__c.fieldApiName,
    Code__c: Code__c.fieldApiName,
    Brand__c: Brand__c.fieldApiName
}

export default class NegoScopeSummary extends LightningElement {
    @api recordId;
    Label = {
        LBL_No,
        LBL_Yes,
        LBL_NS_Summary_Included_HE,
        LBL_NS_Summary_Excluded_HE,
        LBL_NS_Summary_Selected_Brands,
        LBL_NS_Summary_Product_Attributes,
        LBL_No_Item_To_Display,
        LBL_NS_Summary_Title,
        LBL_NS_Summary_All_HEs_Included,
        LBL_NS_Summary_All_Brands_Included,
        LBL_NS_Summary_Null_Field,
        LBL_NS_Summary_Excluded_Products: LBL_NS_Summary_Excluded_Products,
        LBL_NS_Summary_Included_Products: LBL_NS_Summary_Included_Products,
        LBL_NS_Summary_Product_Info,
    };
    @track includedCategories = [];
    @track hasIncludedCategories = false;
    @track excludedCategories = [];
    @track hasExcludedCategories = false;
    @track brands = [];
    @track hasBrands = false;
    @track productAttributes = [];
    @track hasProductAttributes = false;
    @track includeAllHEs = false;
    @track includeAllBrands = false;
    @track includeNewBrands = false;
    @track includeAllProducts = false;
    @track includeNewProducts = false;
    @track includeAllHEsLabel;
    @track IncludeAllBrandsLabel;
    @track IncludeNewBrandsLabel;
    @track IncludeAllProductsLabel;
    @track IncludeNewProductsLabel;
    @track excludedPGsFromFilter;
    @track includedPGsHorsFilter;
    negoscopeLabel;
    productLabel;
    pgLabel;
    negoscopeInfo;
    negoscopeFieldsLabelMap = {};
    @wire(getObjectInfo, { objectApiName: NEGOSCOPE_OBJECT }) wiredNegoScopeInfo({ data, error }) {
        if (data) {
            this.negoscopeInfo = data;
            this.negoscopeLabel = data.label;
            for (let field of Object.values(data.fields)) {
                this.negoscopeFieldsLabelMap[field.apiName] = field.label;
            }
            //SET UP LABELS
            this.includeAllHEsLabel = this.negoscopeFieldsLabelMap[NEGOSCOPE_API_NAMES.IncludeAllHEs__c];
            this.IncludeAllBrandsLabel = this.negoscopeFieldsLabelMap[NEGOSCOPE_API_NAMES.IncludeAllBrands__c];
            this.IncludeNewBrandsLabel = this.negoscopeFieldsLabelMap[NEGOSCOPE_API_NAMES.IncludeNewBrands__c];
            this.IncludeAllProductsLabel = this.negoscopeFieldsLabelMap[NEGOSCOPE_API_NAMES.IncludeAllProducts__c];
            this.IncludeNewProductsLabel = this.negoscopeFieldsLabelMap[NEGOSCOPE_API_NAMES.IncludeNewProducts__c];
            this.wireIsDone.negoscopeInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
        }
    }
    productInfo;
    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT }) wiredProductInfo({ data, error }) {
        if (data) {
            this.productInfo = data;
            this.productLabel = data.label;
            this.wireIsDone.productInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
        }
    }
    pgInfo;
    @wire(getObjectInfo, { objectApiName: PG_OBJECT }) wiredPGInfo({ data, error }) {
        if (data) {
            this.pgInfo = data;
            this.pgLabel = data.label;
            this.wireIsDone.pgInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
        }
    }
    @track wireIsDone = {
        negoscopeInfo: false,
        productInfo: false,
        pgInfo: false,
    }

    checkIfWireIsDone() {
        if (this.wireIsDone.negoscopeInfo && this.wireIsDone.productInfo && this.wireIsDone.pgInfo) {
            this.loadNegoScopeSummary();
        }
    }
    get operationsMap() {
        return {
            'isnull': LBL_PA_ISNULL,
            'isnotnull': LBL_PA_IS_NOT_NULL,
            'isblank': LBL_PA_ISBLANK,
            'isnotblank': LBL_PA_IS_NOT_BLANK,
            'equals': LBL_PA_EQUALS,
            'notequals': LBL_PA_NOT_EQUALS,
            'contains': LBL_PA_CONTAINS,
            'notcontains': LBL_PA_DOESNT_CONTAIN
        };
    }

    connectedCallback() { }

    loadNegoScopeSummary() {
        let self = this;
        let recordId = this.recordId;
        getData({ recordId: recordId }).then(result => {
            let data = JSON.parse(result);
            let productAttributeReferenceValuesMap = {};
            if (data?.productAttributeReferenceValuesMap) {
                productAttributeReferenceValuesMap = JSON.parse(data.productAttributeReferenceValuesMap);
            }
            if (data?.includedCategories) {
                let sortMap = {};
                data.includedCategories.forEach(item => {
                    item.hierarchyName = item[Hierarchy__r].Name;
                    item.hierarchyCode = item[Hierarchy__r][Code__c.fieldApiName];
                    item.hierarchyDisplayName = item[Hierarchy__r].Name + ' - ' + item[Hierarchy__r][Code__c.fieldApiName];
                    item.url = '/' + item[Hierarchy__c.fieldApiName];
                    item.path = [];
                    sortMap[item[Hierarchy__r][Level__c.fieldApiName]] = sortMap[item[Hierarchy__r][Level__c.fieldApiName]] || {
                        level: item[Hierarchy__r][Level__c.fieldApiName],
                        items: []
                    };
                    if (item[Hierarchy__r] && item[Hierarchy__r][Level__c.fieldApiName] != 0) {
                        if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r] && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r]
                            && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r]) {
                            item.path.push({
                                name: item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r].Name,
                                url: '/' + item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r].Id
                            });
                        }
                        if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r] && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r]) {
                            item.path.push({
                                name: item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r].Name,
                                url: '/' + item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r].Id
                            });
                        }
                        if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r]) {
                            item.path.push({
                                name: item[Hierarchy__r][HierarchyParent__r].Name,
                                url: '/' + item[Hierarchy__r][HierarchyParent__r].Id
                            });
                        }
                    }
                    item.path.forEach((it, index) => {
                        it.isLast = index == item.path.length - 1;
                    });
                    item.isMultiLevels = false;
                    if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r] && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r]
                        && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r]
                        && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r]) {
                        item.isMultiLevels = true;
                    }
                    //item.isMultiLevels = item.Hierarchy__r?.HierarchyParent__r?.HierarchyParent__r?.HierarchyParent__r?.HierarchyParent__r?.Id ? true : false;
                    sortMap[item[Hierarchy__r][Level__c.fieldApiName]].items.push(item);
                });
                self.includedCategories = Object.keys(sortMap).sort().map(key => sortMap[key]);
            }
            if (data?.excludedCategories) {
                let sortMap = {};
                data.excludedCategories.forEach(item => {
                    item.hierarchyName = item[Hierarchy__r].Name;
                    item.hierarchyCode = item[Hierarchy__r][Code__c.fieldApiName];
                    item.hierarchyDisplayName = item[Hierarchy__r].Name + ' - ' + item[Hierarchy__r][Code__c.fieldApiName];
                    item.url = '/' + item[Hierarchy__c.fieldApiName];
                    item.path = [];
                    sortMap[item[Hierarchy__r][Level__c.fieldApiName]] = sortMap[item[Hierarchy__r][Level__c.fieldApiName]] || {
                        level: item[Hierarchy__r][Level__c.fieldApiName],
                        items: []
                    };
                    if (item[Hierarchy__r] && item[Hierarchy__r][Level__c.fieldApiName] != 0) {
                        if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r] && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r]
                            && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r]) {
                            item.path.push({
                                name: item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r].Name,
                                url: '/' + item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r].Id
                            });
                        }
                        if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r] && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r]) {
                            item.path.push({
                                name: item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r].Name,
                                url: '/' + item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r].Id
                            });
                        }
                        if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r]) {
                            item.path.push({
                                name: item[Hierarchy__r][HierarchyParent__r].Name,
                                url: '/' + item[Hierarchy__r][HierarchyParent__r].Id
                            });
                        }
                    }
                    item.path.forEach((it, index) => {
                        it.isLast = index == item.path.length - 1;
                    });
                    item.isMultiLevels = false;
                    if (item[Hierarchy__r] && item[Hierarchy__r][HierarchyParent__r] && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r]
                        && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r]
                        && item[Hierarchy__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r][HierarchyParent__r]) {
                        item.isMultiLevels = true;
                    }
                    sortMap[item[Hierarchy__r][Level__c.fieldApiName]].items.push(item);
                });
                self.excludedCategories = Object.keys(sortMap).sort().map(key => sortMap[key]);
            }
            if (data?.brands) {
                self.brands = data.brands.map(item => {
                    item.brandName = item[Brand__r].Name;
                    item.url = '/' + item[Brand__c.fieldApiName];
                    return item;
                });
            }
            let negoScope;
            if (data?.negoscope) {
                negoScope = data.negoscope;
                this.includeAllHEs = negoScope[IncludeAllHEs__c.fieldApiName];
                this.includeAllBrands = negoScope[IncludeAllBrands__c.fieldApiName];
                this.includeNewBrands = negoScope[IncludeNewBrands__c.fieldApiName];
                this.includeAllProducts = negoScope[IncludeAllProducts__c.fieldApiName];
                this.includeNewProducts = negoScope[IncludeNewProducts__c.fieldApiName];
            }
            if (data?.productAttributes) {
                let index = 0;
                data.productAttributes.forEach(item => {
                    if (item.productField) {
                        item.isReference = (item.isPGField ? this.pgInfo?.fields[item.productField]?.reference : this.productInfo?.fields[item.productField]?.reference);
                        item.labelToDisplay = ((item.isPGField ? this.pgLabel : this.productLabel) + ' : ' +
                            item.productLabel + ' ' +
                            (item.operation ? this.operationsMap[item.operation.toLowerCase()].toLowerCase() + ' ' : '') +
                            (item.isField && item.nsField ?
                                this.negoscopeLabel + ' : ' + this.negoscopeFieldsLabelMap[item.nsField] + ' (' + (negoScope[item.nsField] == undefined ? this.Label.LBL_NS_Summary_Null_Field : this.negoscopeInfo?.fields[item.nsField].reference ? negoScope[item.nsField.replace("__c", "__r")].Name : negoScope[item.nsField]) + ')'
                                : (item.isReference ? productAttributeReferenceValuesMap.hasOwnProperty(item.fieldValue) ? productAttributeReferenceValuesMap[item.fieldValue] : '' : item.fieldValue)));
                        item.index = index;
                        index++;
                        self.productAttributes.push(item);
                    }
                });
            }
            if (data?.excludedPGsFromFilter) {
                this.excludedPGsFromFilter = data?.excludedPGsFromFilter;
                this.Label.LBL_NS_Summary_Excluded_Products = this.Label.LBL_NS_Summary_Excluded_Products.replace('{0}', data?.excludedPGsFromFilter);
            }
            if (data?.includedPGsHorsFilter) {
                this.includedPGsHorsFilter = data?.includedPGsHorsFilter;
                this.Label.LBL_NS_Summary_Included_Products = this.Label.LBL_NS_Summary_Included_Products.replace('{0}', data?.includedPGsHorsFilter);
            }
            self.hasIncludedCategories = self.includedCategories?.length ? true : false;
            self.hasExcludedCategories = self.excludedCategories?.length ? true : false;
            self.hasBrands = self.brands?.length ? true : false;
            self.hasProductAttributes = self.productAttributes?.length ? true : false;
        });
    }
}