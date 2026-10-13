/**
* @author ULiT
* @date 04-03-2024
* @description Component for duplicating contract
*******************************************************************************************************************************************
*/
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { loadStyle } from "lightning/platformResourceLoader";
//APEX
import getData from '@salesforce/apex/DuplicateContractCmpCtrl.getData';
import validateTariffConditions from '@salesforce/apex/DuplicateContractCmpCtrl.validateTariffConditions';
import duplicateContract from '@salesforce/apex/DuplicateContractCmpCtrl.duplicateContract';
import checkBatchRunning from '@salesforce/apex/DuplicateContractCmpCtrl.checkBatchRunning';
import getApexLogId from '@salesforce/apex/DuplicateContractCmpCtrl.getApexLogId';
import synchroAdvancedContracts from '@salesforce/apex/DuplicateContractCmpCtrl.synchroAdvancedContracts';
import initContractSellIn from '@salesforce/apex/DuplicateContractCmpCtrl.initContractSellIn';
// OBJECT FIELDS
//CONTRACT
import OBJ_Contract__c from '@salesforce/schema/Contract__c';
import Contract_Number__c from '@salesforce/schema/Contract__c.Contract_Number__c';
import Contract_Commercial_BDate__c from '@salesforce/schema/Contract__c.Contract_Commercial_BDate__c';
import Contract_Commercial_EDate__c from '@salesforce/schema/Contract__c.Contract_Commercial_EDate__c';
import Supplier_Nego_Scope__c from '@salesforce/schema/Contract__c.Supplier_Nego_Scope__c';
import Supplier__c from '@salesforce/schema/Contract__c.Supplier__c';
import RecordTypeId from '@salesforce/schema/Contract__c.RecordTypeId';
import BusinessUnitContract__c from '@salesforce/schema/Contract__c.BusinessUnitContract__c';
import Reference_Year__c from '@salesforce/schema/Contract__c.Reference_Year__c';
//SUPPLIER
import OBJ_Supplier__c from '@salesforce/schema/Supplier__c';
import Code__c from '@salesforce/schema/Supplier__c.Code__c';
//CONTRACT DISCOUNT
import OBJ_Contract_Discount__c from '@salesforce/schema/Contract_Discount__c';
import Condition_Type__c from '@salesforce/schema/Contract_Discount__c.Condition_Type__c';
import Disc_BDate__c from '@salesforce/schema/Contract_Discount__c.Disc_BDate__c';
import Disc_EDate__c from '@salesforce/schema/Contract_Discount__c.Disc_EDate__c';
import Value_per__c from '@salesforce/schema/Contract_Discount__c.Value_per__c';
import Value_amt__c from '@salesforce/schema/Contract_Discount__c.Value_amt__c';
import unit_amount__c from '@salesforce/schema/Contract_Discount__c.unit_amount__c';
import Unit_Amount_Type__c from '@salesforce/schema/Contract_Discount__c.Unit_Amount_Type__c';
import BusinessUnitScope__c from '@salesforce/schema/Contract_Discount__c.BusinessUnitScope__c';
import Product_Scope__c from '@salesforce/schema/Contract_Discount__c.Product_Scope__c';
import is_duplicable__c from '@salesforce/schema/Contract_Discount__c.is_duplicable__c';
import Is_Duplicable_PE__c from '@salesforce/schema/Contract_Discount__c.Is_Duplicable_PE__c';
import Disc_BDate_Y1__c from '@salesforce/schema/Contract_Discount__c.Disc_BDate_Y1__c';
import Disc_EDate_Y1__c from '@salesforce/schema/Contract_Discount__c.Disc_EDate_Y1__c';
import Value_amt_Y1__c from '@salesforce/schema/Contract_Discount__c.Value_amt_Y1__c';
//POL_COM_CONDITION
import OBJ_Pol_Com_Condition__c from '@salesforce/schema/Pol_Com_Condition__c';
import Capture_Discount_Product_Level__c from '@salesforce/schema/Pol_Com_Condition__c.Capture_Discount_Product_Level__c';
//NEGOSCOPE
import OBJ_NegoScope__c from '@salesforce/schema/NegoScope__c';
import Status__c from '@salesforce/schema/NegoScope__c.Status__c';
import NS_Code__c from '@salesforce/schema/NegoScope__c.NS_Code__c';
//BU
import OBJ_BusinessUnit__c from '@salesforce/schema/BusinessUnit__c';
//LABELS
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Success from "@salesforce/label/c.LBL_Success";
//NEW LABELS
import LBL_Batch_Is_Running from "@salesforce/label/c.LBL_Batch_Is_Running";
import LBL_Batch_Finished from "@salesforce/label/c.LBL_Batch_Finished";
import LBL_Open_Log from "@salesforce/label/c.LBL_Open_Log";
import LBL_Duplicate_Contarct from "@salesforce/label/c.LBL_Duplicate_Contarct";
import LBL_Invalid_Dates from "@salesforce/label/c.LBL_Invalid_Dates";
import MSG_Contract_Duplicated_Successfully from "@salesforce/label/c.MSG_Contract_Duplicated_Successfully";
import MSG_PE_And_Signed_Exist from "@salesforce/label/c.MSG_PE_And_Signed_Exist";
import MSG_Contract_Exist_Same_Period from "@salesforce/label/c.MSG_Contract_Exist_Same_Period";
import MSG_Is_Duplicable_False from "@salesforce/label/c.MSG_Is_Duplicable_False";
import MSG_Is_Duplicable_PE_False from "@salesforce/label/c.MSG_Is_Duplicable_PE_False";
import MSG_Contract_Can_Not_Be_Duplicated from "@salesforce/label/c.MSG_Contract_Can_Not_Be_Duplicated";
import MSG_Signed_Exist_First_Jan from "@salesforce/label/c.MSG_Signed_Exist_First_Jan";
import MSG_EDate_Do_Not_Match from "@salesforce/label/c.MSG_EDate_Do_Not_Match";
import MSG_BU_Not_Open from "@salesforce/label/c.MSG_BU_Not_Open";
import MSG_NS_Not_Active from "@salesforce/label/c.MSG_NS_Not_Active";
import MSG_Open_Contract from "@salesforce/label/c.MSG_Open_Contract";
import LBL_Synchro from "@salesforce/label/c.LBL_Synchro";
import MSG_Invalid_Type_For_Contract from "@salesforce/label/c.MSG_Invalid_Type_For_Contract";
const API_NAMES = {
    Contract__c: {
        objectApiName: OBJ_Contract__c.objectApiName,
        Contract_Number__c: Contract_Number__c.fieldApiName,
        Contract_Commercial_BDate__c: Contract_Commercial_BDate__c.fieldApiName,
        Contract_Commercial_EDate__c: Contract_Commercial_EDate__c.fieldApiName,
        Supplier_Nego_Scope__c: Supplier_Nego_Scope__c.fieldApiName,
        Supplier_Nego_Scope__r: Supplier_Nego_Scope__c.fieldApiName.replace(/__c$/, '__r'),
        Supplier__c: Supplier__c.fieldApiName,
        Supplier__r: Supplier__c.fieldApiName.replace(/__c$/, '__r'),
        RecordTypeId: RecordTypeId.fieldApiName,
        BusinessUnitContract__c: BusinessUnitContract__c.fieldApiName,
        BusinessUnitContract__r: BusinessUnitContract__c.fieldApiName.replace(/__c$/, '__r'),
        Reference_Year__c: Reference_Year__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
    },
    Supplier__c: {
        objectApiName: OBJ_Supplier__c.objectApiName,
        Code__c: Code__c.fieldApiName,
    },
    Contract_Discount__c: {
        objectApiName: OBJ_Contract_Discount__c.objectApiName,
        Condition_Type__c: Condition_Type__c.fieldApiName,
        Condition_Type__r: Condition_Type__c.fieldApiName.replace(/__c$/, '__r'),
        Disc_BDate__c: Disc_BDate__c.fieldApiName,
        Disc_EDate__c: Disc_EDate__c.fieldApiName,
        Value_per__c: Value_per__c.fieldApiName,
        Value_amt__c: Value_amt__c.fieldApiName,
        unit_amount__c: unit_amount__c.fieldApiName,
        Unit_Amount_Type__c: Unit_Amount_Type__c.fieldApiName,
        BusinessUnitScope__c: BusinessUnitScope__c.fieldApiName,
        BusinessUnitScope__r: BusinessUnitScope__c.fieldApiName.replace(/__c$/, '__r'),
        Product_Scope__c: Product_Scope__c.fieldApiName,
        Product_Scope__r: Product_Scope__c.fieldApiName.replace(/__c$/, '__r'),
        is_duplicable__c: is_duplicable__c.fieldApiName,
        Is_Duplicable_PE__c: Is_Duplicable_PE__c.fieldApiName,
        Disc_BDate_Y1__c: Disc_BDate_Y1__c.fieldApiName,
        Disc_EDate_Y1__c: Disc_EDate_Y1__c.fieldApiName,
        Value_amt__c: Value_amt__c.fieldApiName,
        Value_amt_Y1__c: Value_amt_Y1__c.fieldApiName,
    },
    Pol_Com_Condition__c: {
        objectApiName: OBJ_Pol_Com_Condition__c.objectApiName,
        Capture_Discount_Product_Level__c: Capture_Discount_Product_Level__c.fieldApiName,
    },
    NegoScope__c: {
        objectApiName: OBJ_NegoScope__c.objectApiName,
        Status__c: Status__c.fieldApiName,
        NS_Code__c: NS_Code__c.fieldApiName,
    },
    BusinessUnit__c: {
        objectApiName: OBJ_BusinessUnit__c.objectApiName,
        Status__c: Status__c.fieldApiName,
    },
}
const formatDates = (date) => {
    date.setHours(date.getHours() - date.getTimezoneOffset() / 60);
    return date.toISOString().split('T')[0];
}
export default class DuplicateContract extends LightningElement {
    //APIS
    @api recordId;
    @api displayFromPopup = false;
    //BOOLEANS
    isLoading = true;
    isPageLoading = false;
    isPeriodExtension;
    batchRunning = false;
    isSigned;
    isObjective;
    isTable2Loading = false;
    noData = false;
    conditionsNotMet = false;
    signedExist = false;
    peExist = false;
    objectiveExist = false;
    toBeSignedExist = false;
    savePopUp = false;
    currentStatusMSG = '';
    //STRINGS
    @track inputBdate;
    @track inputEdate;
    @track conditionerrorMessage;
    //LISTS
    @track sourceContractDiscountsList = [];
    @track targetContractDiscountsList = [];
    //OBJECTS
    @track sourceContractRecord;
    @track sourceContract = {};
    @track targetContract = {};
    @track targetContractDuplications = {};
    @track targetContractRTs = {};
    @track pickListValues = {};
    @track discountPercentScale;
    //LABELS
    labels = {
        LBL_Save,
        LBL_Cancel,
        LBL_Batch_Is_Running,
        LBL_Batch_Finished,
        LBL_Open_Log,
        LBL_Duplicate_Contarct,
        LBL_Invalid_Dates,
        MSG_Contract_Duplicated_Successfully,
        LBL_Error,
        LBL_Success,
        MSG_PE_And_Signed_Exist,
        MSG_Is_Duplicable_False,
        MSG_Is_Duplicable_PE_False,
        MSG_BU_Not_Open,
        MSG_NS_Not_Active,
        MSG_EDate_Do_Not_Match,
        MSG_Contract_Can_Not_Be_Duplicated,
        MSG_Contract_Exist_Same_Period,
        MSG_Signed_Exist_First_Jan,
        MSG_Open_Contract,
        LBL_Synchro,
        MSG_Invalid_Type_For_Contract,
    };
    //GETTERS
    get signedContractBeginsOnFirstDay() {
        return this.signedContractN1 && this.signedContractN1[API_NAMES.Contract__c.Contract_Commercial_BDate__c].endsWith('-01-01');
    }
    get saveDisabled() {
        return this.batchRunning || this.noData || this.isLoading || this.conditionsNotMet;
    }
    @track recordTypeOptions = [];
    get minDate() {
        let refYear_N_1 = +this.sourceContract[API_NAMES.Contract__c.Reference_Year__c] + 1;
        if (this.isPeriodExtension) {
            return refYear_N_1 + '-01-01';
        } else if (this.peContractN1 && (this.targetContract.recordTypeDeveloperName == 'Simulation' || this.targetContract.recordTypeDeveloperName == 'To_Be_Signed' || this.targetContract.recordTypeDeveloperName == 'Signed')) {
            let bdate = new Date(this.peContractN1[API_NAMES.Contract__c.Contract_Commercial_EDate__c]);
            bdate.setDate(bdate.getDate() + 1);
            return bdate.toISOString().split('T')[0];
        } else {
            let sourceBdateMonth = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]).getMonth() + 1;
            let sourceBdateDay = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]).getDate();
            return refYear_N_1 + '-' + (sourceBdateMonth < 10 ? '0' + sourceBdateMonth : sourceBdateMonth) + '-' + (sourceBdateDay < 10 ? '0' + sourceBdateDay : sourceBdateDay);
        }
    }
    get maxDate() {
        let refYear_N_1 = +this.sourceContract[API_NAMES.Contract__c.Reference_Year__c] + 1;
        if (this.isPeriodExtension) {
            if (this.signedContractN1) {
                let edate = new Date(this.signedContractN1[API_NAMES.Contract__c.Contract_Commercial_EDate__c]);
                edate.setDate(edate.getDate() - 1);
                return edate.toISOString().split('T')[0];
            } else {
                let edate = new Date(refYear_N_1, 2, 0);
                let edateDay = edate.getDate();
                let edateMonth = edate.getMonth() + 1;
                return refYear_N_1 + '-' + (edateMonth < 10 ? '0' + edateMonth : edateMonth) + '-' + (edateDay < 10 ? '0' + edateDay : edateDay);
            }
        } else {
            if (this.peContractN1 && (this.targetContract.recordTypeDeveloperName == 'Simulation' || this.targetContract.recordTypeDeveloperName == 'To_Be_Signed' || this.targetContract.recordTypeDeveloperName == 'Signed')) {
                return ((+this.sourceContract[API_NAMES.Contract__c.Reference_Year__c]) + 1) + '-12-31';
            } else {
                let sourceEdateDay = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]).getDate();
                let sourceEdateMonth = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]).getMonth() + 1;
                return refYear_N_1 + '-' + (sourceEdateMonth < 10 ? '0' + sourceEdateMonth : sourceEdateMonth) + '-' + (sourceEdateDay < 10 ? '0' + sourceEdateDay : sourceEdateDay);
            }
        }
    }
    get hasErrorMessage() {
        return this.noData || this.conditionsNotMet;
    }
    get errorMessage() {
        if (this.noData) {
            return MSG_Contract_Can_Not_Be_Duplicated;
        }
        if (this.conditionsNotMet) {
            return this.conditionerrorMessage;
        }
        if (this.signedContractBeginsOnFirstDay) {
            return MSG_Signed_Exist_First_Jan;
        }
        return '';
    }
    get dateInputsDisplayed() {
        return (this.isSigned && !this.signedExist) || (this.isPeriodExtension && !this.peExist) || (this.isObjective && !this.objectiveExist) || (this.isToBeSigned && !this.toBeSignedExist) || this.isSimulation;
    }
    //LIFECYCLE
    connectedCallback() {
        try {
            addEventListener('resize', this.setPageSize);
            Promise.all([
                loadStyle(this, negOptimGlobalCSS),
            ]).then(() => {
                console.log('loading style success')
            }).catch(error => {
                console.log('error loading style >> ' + error)
            });
            this.loadData();
        } catch (error) {
            console.error(error);
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    renderedCallback() {
        try {
            setTimeout(() => {
                this.setPageSize()
            }, 200);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.loading = true;
        }
    }
    //LOAD
    loadData() {
        console.log('loadData');
        getData({
            recordId: this.recordId
        }).then(result => {
            if (result == null) {
                this.noData = true;
                this.isLoading = false;
                return;
            }
            this.afterLoad(result);
        }).catch(error => {
            this.isLoading = false;
            this.showNotification(LBL_Error, error, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        });
    }
    afterLoad(result) {
        let parsedResult = JSON.parse(result);
        this.pickListValues = parsedResult.captureProductLevelPicklistMap;
        this.discountPercentScale = parsedResult.discountPercentScale;
        // Fill labels
        let fieldLabels = parsedResult.fieldLabelsMap;
        this.labels['LBL_Contract_Supplier_Code'] = fieldLabels[API_NAMES.Supplier__c.Code__c];
        this.labels['LBL_Contract'] = fieldLabels[API_NAMES.Contract__c.objectApiName];
        this.labels['LBL_Contract_Supplier'] = fieldLabels[API_NAMES.Contract__c.Supplier__c];
        this.labels['LBL_Contract_NS'] = fieldLabels[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
        this.labels['LBL_Contract_Number'] = fieldLabels[API_NAMES.Contract__c.Contract_Number__c];
        this.labels['LBL_Contract_Commercial_BDate'] = fieldLabels[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
        this.labels['LBL_Contract_Commercial_EDate'] = fieldLabels[API_NAMES.Contract__c.Contract_Commercial_EDate__c];
        this.labels['LBL_Contract_BU'] = fieldLabels[API_NAMES.Contract__c.BusinessUnitContract__c];
        this.labels['LBL_RecordTypeId'] = fieldLabels[API_NAMES.Contract__c.RecordTypeId];
        this.labels['LBL_Contract_Status'] = fieldLabels[API_NAMES.Contract__c.Status__c];
        this.labels['LBL_Condition_Type'] = fieldLabels[API_NAMES.Contract_Discount__c.Condition_Type__c];
        this.labels['LBL_Condition_Bdate'] = fieldLabels[API_NAMES.Contract_Discount__c.Disc_BDate__c];
        this.labels['LBL_Condition_Edate'] = fieldLabels[API_NAMES.Contract_Discount__c.Disc_EDate__c];
        this.labels['LBL_Condition_Percent'] = fieldLabels[API_NAMES.Contract_Discount__c.Value_per__c];
        this.labels['LBL_Condition_Amount'] = fieldLabels[API_NAMES.Contract_Discount__c.Value_amt__c];
        this.labels['LBL_Condition_Unit_Amount'] = fieldLabels[API_NAMES.Contract_Discount__c.unit_amount__c];
        this.labels['LBL_Condition_Unit_Amount_Type'] = fieldLabels[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c];
        this.labels['LBL_Condition_BU'] = fieldLabels[API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
        this.labels['LBL_Condition_NS'] = fieldLabels[API_NAMES.Contract_Discount__c.Product_Scope__c];
        this.labels['LBL_Capture_Discount_Product_Level'] = fieldLabels[API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c];
        this.isLoading = false;
        this.isPageLoading = false;
        // Populate sourceContract
        this.sourceContract = parsedResult.sourceContract;
        this.sourceContractRecord = JSON.parse(JSON.stringify(parsedResult.sourceContract));
        //Fill Target RTs
        this.targetContractDuplications = parsedResult.targetContractDuplications;
        this.targetContractRTs = parsedResult.targetContractRTs;
        this.recordTypeOptions = [];
        for (let [key, value] of Object.entries(this.targetContractRTs)) {
            this.targetContract.recordTypeDeveloperName = key;
            this.recordTypeOptions.push({ label: value, value: key });
        }
        this.sourceContract.supplierLink = '/' + this.sourceContract[API_NAMES.Contract__c.Supplier__c];
        this.sourceContract.nsLink = '/' + this.sourceContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
        this.sourceContract.supplier = this.sourceContract[API_NAMES.Contract__c.Supplier__r];
        this.sourceContract.supplierCode = this.sourceContract[API_NAMES.Contract__c.Supplier__r][API_NAMES.Supplier__c.Code__c];
        this.sourceContract.supplierNS = this.sourceContract[API_NAMES.Contract__c.Supplier_Nego_Scope__r];
        this.sourceContract.supplierNSRecordType = this.sourceContract?.supplierNS?.RecordType?.DeveloperName;
        this.sourceContract.supplierNSCode = this.sourceContract[API_NAMES.Contract__c.Supplier_Nego_Scope__r][API_NAMES.NegoScope__c.NS_Code__c];
        this.sourceContract.contractNumber = this.sourceContract[API_NAMES.Contract__c.Contract_Number__c];
        this.sourceContract.contractBU = this.sourceContract[API_NAMES.Contract__c.BusinessUnitContract__r];
        this.sourceContract.contractBuLink = '/' + this.sourceContract[API_NAMES.Contract__c.BusinessUnitContract__c];
        this.sourceContract.commercialBDate = this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
        this.sourceContract.commercialEDate = this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c];
        this.sourceContract.status = this.sourceContract[API_NAMES.Contract__c.Status__c];
        this.peContractN1 = parsedResult.peContractN1;
        this.signedContractN1 = parsedResult.signedContractN1;
        this.objectiveContractN1 = parsedResult.objectiveContractN1;
        this.toBeSignedContractN1 = parsedResult.toBeSignedContractN1;
        this.setDefaultDates(this.targetContract.recordTypeDeveloperName == 'Period_Extension');
        // Populate sourceContractDiscountsList
        this.sourceContractDiscountsList = parsedResult.contractDiscountsList;
        this.sourceContractDiscountsList.forEach(element => {
            element.conditionType = element[API_NAMES.Contract_Discount__c.Condition_Type__r];
            element.conditionLink = '/' + element[API_NAMES.Contract_Discount__c.Condition_Type__c];
            element.discBDate = element[API_NAMES.Contract_Discount__c.Disc_BDate__c];
            element.discEDate = element[API_NAMES.Contract_Discount__c.Disc_EDate__c];
            element.percent = element[API_NAMES.Contract_Discount__c.Value_per__c];
            element.valueAmount = element[API_NAMES.Contract_Discount__c.Value_amt__c];
            element.unitAmount = element[API_NAMES.Contract_Discount__c.unit_amount__c];
            element.unitAmountType = element[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c];
            element.buScope = element[API_NAMES.Contract_Discount__c.BusinessUnitScope__r];
            element.buLink = '/' + element[API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
            element.productScope = element[API_NAMES.Contract_Discount__c.Product_Scope__r];
            element.nsLink = '/' + element[API_NAMES.Contract_Discount__c.Product_Scope__c];
            element.isPromoDisc = element[API_NAMES.Contract_Discount__c.Condition_Type__c] && ['Mandatory', 'Optional', 'From CPD Only'].includes(element[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c]);
            element.captureProductLevelMessage = element.isPromoDisc ? this.labels.LBL_Capture_Discount_Product_Level + ': ' + this.pickListValues[element[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c]] : '';
        });
        this.populateTargetDiscounts();
        if (parsedResult.errorMessage) {
            this.conditionsNotMet = true;
            this.conditionerrorMessage = parsedResult.errorMessage;
        }
    }
    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            this.mainContainer = mainContainer;
            let pageBodyDiv = this.template.querySelector(".pageBody");
            let divs = this.template.querySelectorAll(".pageHeader1, .pageHeader2, .slds-notify_container");
            let height = mainContainer.offsetHeight;
            divs.forEach(it => height -= it.offsetHeight);
            pageBodyDiv.style.height = height + "px";
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    setDefaultDates(isPE) {
        let refYear_N_1 = +this.sourceContract[API_NAMES.Contract__c.Reference_Year__c] + 1;
        let sourceBdateDay = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]).getDate();
        let sourceEdateDay = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]).getDate();
        let sourceBdateMonth = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]).getMonth();
        let sourceEdateMonth = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]).getMonth();
        let sourceBdateYear = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]).getUTCFullYear();
        let sourceEdateYear = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]).getUTCFullYear();
        if (isPE) {
            this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] = new Date(refYear_N_1, 0, 1);
            if (this.signedContractN1) {
                let edate = new Date(this.signedContractN1[API_NAMES.Contract__c.Contract_Commercial_BDate__c]);
                edate.setDate(edate.getDate() - 1);
                this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = edate;
            } else {
                this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = new Date(refYear_N_1, 2, 0);
            }
            this.isPeriodExtension = true;
        } else if (['Simulation', 'Target', 'Safe_Balance', 'Proposal'].includes(this.sourceContract?.RecordType?.DeveloperName) || this.targetContract.recordTypeDeveloperName === 'Nego_Base') {
            this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] = new Date(sourceBdateYear, sourceBdateMonth, sourceBdateDay);
            this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = new Date(sourceEdateYear, sourceEdateMonth, sourceEdateDay);
            this.isPeriodExtension = false;
        } else {
            if (this.peContractN1 && (this.targetContract.recordTypeDeveloperName == 'Simulation' || this.targetContract.recordTypeDeveloperName == 'To_Be_Signed' || this.targetContract.recordTypeDeveloperName == 'Signed')) {
                let bdate = new Date(this.peContractN1[API_NAMES.Contract__c.Contract_Commercial_EDate__c]);
                bdate.setDate(bdate.getDate() + 1);
                this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] = bdate;
                if (sourceBdateYear != sourceEdateYear) {
                    this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = new Date(refYear_N_1 + 1, 11, 31);
                } else {
                    this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = new Date(refYear_N_1, 11, 31);
                }
            } else {
                this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] = new Date(refYear_N_1, sourceBdateMonth, sourceBdateDay);
                if (sourceBdateYear != sourceEdateYear) {
                    this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = new Date(refYear_N_1 + 1, sourceEdateMonth, sourceEdateDay);
                } else {
                    this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = new Date(refYear_N_1, sourceEdateMonth, sourceEdateDay);
                }
            }
            this.isPeriodExtension = false;
        }
        this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] = formatDates(this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]);
        this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = formatDates(this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]);
        this.targetContract.commercialBDate = this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
        this.targetContract.commercialEDate = this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c];
        this.isSigned = this.targetContract.recordTypeDeveloperName == 'Signed';
        this.isToBeSigned = this.targetContract.recordTypeDeveloperName == 'To_Be_Signed';
        this.isPeriodExtension = this.targetContract.recordTypeDeveloperName == 'Period_Extension';
        this.isObjective = this.targetContract.recordTypeDeveloperName == 'Objective';
        this.isSimulation = this.targetContract.recordTypeDeveloperName == 'Simulation';
    }
    populateTargetDiscounts() {
        let refYear_N_1 = +this.sourceContract[API_NAMES.Contract__c.Reference_Year__c] + 1;
        this.targetContractDiscountsList = JSON.parse(JSON.stringify(this.sourceContractDiscountsList));
        this.targetContractDiscountsList.forEach(element => {
            element.isDuplicable = true;
            // element.isDuplicable = !this.isPeriodExtension ? element[API_NAMES.Contract_Discount__c.is_duplicable__c] : element[API_NAMES.Contract_Discount__c.Is_Duplicable_PE__c];
            if ((!this.isPeriodExtension && !element[API_NAMES.Contract_Discount__c.is_duplicable__c]) || (this.isPeriodExtension && !element[API_NAMES.Contract_Discount__c.Is_Duplicable_PE__c])) {
                element.isDuplicable = false;
                element.message = !this.isPeriodExtension ? MSG_Is_Duplicable_False : MSG_Is_Duplicable_PE_False;
                return;
            }
            if (element[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] != this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]) {
                element.isDuplicable = false;
                element.message = MSG_EDate_Do_Not_Match;
                return;
            }
            if (element[API_NAMES.Contract_Discount__c.Product_Scope__r] && element[API_NAMES.Contract_Discount__c.Product_Scope__r][API_NAMES.NegoScope__c.Status__c] != 'Active') {
                element.isDuplicable = false;
                element.message = MSG_NS_Not_Active;
                return;
            }
            if (element[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] && element[API_NAMES.Contract_Discount__c.BusinessUnitScope__r][API_NAMES.BusinessUnit__c.Status__c] != 'Open') {
                element.isDuplicable = false;
                element.message = MSG_BU_Not_Open;
                return;
            }
            let discBdateY1 = new Date(element[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c]);
            let discBDateY1N1 = new Date(new Date(element[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c]).setFullYear(refYear_N_1));
            let discEdateY1 = new Date(element[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c]);
            let targetBdate = new Date(this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]);
            let targetEdate = new Date(this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]);
            let sourceBdate = new Date(this.sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]);
            let sourceDaysDiff = (discEdateY1.getTime() - discBdateY1.getTime()) / (1000 * 60 * 60 * 24) + 1;
            if (discBdateY1.getTime() == sourceBdate.getTime()) {
                element[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
            } else if (targetBdate < discBDateY1N1 && discBDateY1N1 < targetEdate) {
                element[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = formatDates(discBDateY1N1);
            } else if (discBdateY1 < targetEdate) {
                element[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
            }
            element[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c];
            element[API_NAMES.Contract_Discount__c.Disc_BDate__c] = element[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c];
            element[API_NAMES.Contract_Discount__c.Disc_EDate__c] = element[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c];
            let targetDaysDiff = (targetEdate.getTime() - new Date(element[API_NAMES.Contract_Discount__c.Disc_BDate__c]).getTime()) / (1000 * 60 * 60 * 24) + 1;
            element[API_NAMES.Contract_Discount__c.Value_amt__c] = (element[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] * targetDaysDiff) / sourceDaysDiff;
            element.discBDate = element[API_NAMES.Contract_Discount__c.Disc_BDate__c];
            element.discEDate = element[API_NAMES.Contract_Discount__c.Disc_EDate__c];
            element.valueAmount = element[API_NAMES.Contract_Discount__c.Value_amt__c];
        });
        this.validateTariffConditions();
    }

    validateTariffConditions() {
        //if (this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] <= this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]) {
        let targetStatus = this.targetContractDuplications[this.targetContract.recordTypeDeveloperName];
        validateTariffConditions({
            sourceContractRecordJSON: JSON.stringify(this.sourceContractRecord),
            buId: this.sourceContract[API_NAMES.Contract__c.BusinessUnitContract__c],
            nsId: this.sourceContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c],
            year: this.sourceContract[API_NAMES.Contract__c.Reference_Year__c],
            commercialBeginDate: this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c],
            commercialEndDate: this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c],
            recordTypeDeveloperName: this.targetContract.recordTypeDeveloperName,
            targetStatus: targetStatus
        }).then(result => {
            let validTariffConditionMap = JSON.parse(result);
            this.targetContractDiscountsList.forEach(element => {
                if (validTariffConditionMap && !Object.keys(validTariffConditionMap).includes(element[API_NAMES.Contract_Discount__c.Condition_Type__c])) {
                    element.isDuplicable = false;
                    element.message = MSG_Invalid_Type_For_Contract;
                }
            });
            this.isTable2Loading = false;
        }).catch(error => {
            this.isTable2Loading = false;
            this.showNotification(LBL_Error, error, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        });
        //}
    }
    //EVENT HANDLERS
    handleChangeDate(event) {
        let value = event.target.value;
        let field = event.target.dataset.field;
        this.targetContract[API_NAMES.Contract__c[field]] = value;
        this.populateTargetDiscounts();
    }
    handleRecordTypeChange(event) {
        this.peExist = false;
        this.signedExist = false;
        this.objectiveExist = false;
        this.toBeSignedExist = false;
        let value = event.target.value;
        this.isSigned = value == 'Signed';
        this.isToBeSigned = value == 'To_Be_Signed';
        this.isPeriodExtension = value == 'Period_Extension';
        this.isObjective = value == 'Objective';
        this.isSimulation = value == 'Simulation';
        this.targetContract.recordTypeDeveloperName = value;
        this.isTable2Loading = true;
        this.setDefaultDates(value == 'Period_Extension');
        this.populateTargetDiscounts();
    }
    @api
    handleSave() {
        if (this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] <= this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]) {
            this.savePopUp = true;
            this.currentStatusMSG = this.labels.LBL_Save;
            this.isPageLoading = true;
            let targetStatus = this.targetContractDuplications[this.targetContract.recordTypeDeveloperName];
            duplicateContract({
                recordId: this.recordId,
                buId: this.sourceContract[API_NAMES.Contract__c.BusinessUnitContract__c],
                nsId: this.sourceContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c],
                year: this.sourceContract[API_NAMES.Contract__c.Reference_Year__c],
                commercialBeginDate: this.targetContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c],
                commercialEndDate: this.targetContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c],
                recordTypeDeveloperName: this.targetContract.recordTypeDeveloperName,
                targetStatus: targetStatus
            }).then(result => {
                result = JSON.parse(result);
                console.log('result >>> ' + JSON.stringify(result));
                if (result.errors) {
                    this.savePopUp = false;
                    let contractIdwithError;
                    let contractName;
                    let errors = [];
                    result?.errors?.forEach(_error => {
                        if (_error.includes(MSG_Contract_Exist_Same_Period)) {
                            contractName = _error.replace(`FIELD_CUSTOM_VALIDATION_EXCEPTION - ${MSG_Contract_Exist_Same_Period} - (`, '');
                            contractIdwithError = contractName.substr(0, 18);
                            contractName = contractName.substr(19, contractName.length - 2);
                        } else {
                            errors.push(_error);
                        }
                    });
                    if (contractIdwithError && contractName) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: `${MSG_Contract_Exist_Same_Period}`,
                            message: "{0}",
                            variant: 'error',
                            mode: 'sticky',
                            messageData: [
                                {
                                    url: '/' + contractIdwithError,
                                    label: contractName
                                }
                            ]
                        }));
                    } else if (errors.length > 0) {
                        this.showNotification(LBL_Error, result?.errors?.join('\n'), 'error');
                    }
                    this.isLoading = false;
                    this.isPageLoading = false;
                    return;
                }
                console.log('result.contractId >>> ' + result.contractId);
                console.log('result.contractName >>> ' + result.contractName);
                if (result.contractId && result.contractName) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: MSG_Contract_Duplicated_Successfully,
                        message: "{0}",
                        variant: 'success',
                        mode: 'sticky',
                        messageData: [
                            {
                                url: '/' + result.contractId,
                                label: result.contractName,
                            }
                        ]
                    }));
                    window.open('/' + result.contractId, '_blank');
                }
                const isAdvancedNS = this.sourceContract.supplierNSRecordType === 'Advanced';
                if (result.contractId) {
                    if (isAdvancedNS) {
                        this.synchroAdvancedContracts(result.contractId)
                    } else {
                        this.initContractSellIn(result.contractId)
                    }
                } else {
                    this.closeSavePopup();
                    this.isLoading = true;
                    this.loadData();
                }
            }).catch(error => {
                this.isPageLoading = false;
                this.closeSavePopup();
                this.showNotification(LBL_Error, error, 'error');
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
        } else {
            this.showNotification(LBL_Error, LBL_Invalid_Dates, 'error');
        }
    }
    handleCancel() {
        window.open('/' + this.recordId, '_self');
    }
    isBatchRunning(jobId) {
        checkBatchRunning({
            jobId: jobId
        }).then((result) => {
            if (result) {
                setTimeout(() => {
                    this.isBatchRunning(jobId);
                }, 5000);
                return;
            }
            getApexLogId({
                jobId: jobId,
                buId: this.sourceContract[API_NAMES.Contract__c.BusinessUnitContract__c],
                nsId: this.sourceContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c],
                year: this.sourceContract[API_NAMES.Contract__c.Reference_Year__c],
                recordTypeDeveloperName: this.targetContract.recordTypeDeveloperName
            }).then((result) => {
                this.batchRunning = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: LBL_Batch_Finished,
                    message: "{0}",
                    variant: 'success',
                    mode: 'sticky',
                    messageData: [
                        {
                            url: '/' + result['apexJobId'],
                            label: LBL_Open_Log
                        }
                    ]
                }));
                window.open('/' + result['contractId'], '_blank');
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        });
    }

    synchroAdvancedContracts(contractId) {
        this.currentStatusMSG = this.labels.LBL_Synchro;
        synchroAdvancedContracts({ contractId: contractId }).then((batchId) => {
            if (batchId != null) {
                let nIntervId = setInterval(() => {
                    checkBatchRunning({ jobId: batchId }).then(result => {
                        if (!result) {
                            // Batch finished – close the popup
                            this.closeSavePopup();
                            this.isLoading = true;
                            this.loadData();
                            clearInterval(nIntervId);
                        }
                    });
                }, 2000);
            } else {
                // Nothing to poll (not enqueued / already handled) – close gracefully
                this.closeSavePopup();
                return;
            }
        }).catch((error) => {
            this.closeSavePopup();
            console.error(error);
            this.showNotification(LBL_Error, error, 'error');
        });
    }

    initContractSellIn(contractId) {
        this.currentStatusMSG = 'Init';
        initContractSellIn({ contractId: contractId }).then((batchId) => {
            if (batchId != null) {
                let nIntervId = setInterval(() => {
                    checkBatchRunning({ jobId: batchId }).then(result => {
                        if (!result) {
                            // Batch finished – close the popup
                            this.closeSavePopup();
                            this.isLoading = true;
                            this.loadData();
                            clearInterval(nIntervId);
                        }
                    });
                }, 2000);
            } else {
                // Nothing to poll (not enqueued / already handled) – close gracefully
                this.closeSavePopup();
                return;
            }
        }).catch((error) => {
            this.closeSavePopup();
            console.error(error);
            this.showNotification(LBL_Error, error, 'error');
        });
    }

    closeSavePopup() {
        this.savePopUp = false;
        this.currentStatusMSG = '';
    }
}