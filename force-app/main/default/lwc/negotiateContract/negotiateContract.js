import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import unlockContract from "@salesforce/apex/NegotiateContractCmpController.unlockContract";
import saveContractData from "@salesforce/apex/NegotiateContractCmpController.saveContractData";
import validatePeriodExtension from "@salesforce/apex/NegotiateContractCmpController.validatePeriodExtension";
import fakeSaveContractDiscountData from "@salesforce/apex/NegotiateContractCmpController.fakeSaveContractDiscountData";
import getContractData from "@salesforce/apex/NegotiateContractCmpController.getContractData";
import calculateIndex from "@salesforce/apex/NegotiateContractCmpController.calculateIndex";
import calculateIndexAndSave from "@salesforce/apex/NegotiateContractCmpController.calculateIndexAndSave";
import generateContractSimulationName from "@salesforce/apex/NegotiateContractCmpController.generateContractSimulationName";
import createContract from "@salesforce/apex/NegotiateContractCmpController.createContract";
import getObjectLabels from "@salesforce/apex/NegotiateCmpController.getObjectLabels";
import performNSSearch from "@salesforce/apex/NegotiateContractCmpController.performNSSearch";
import performBUSearch from "@salesforce/apex/NegotiateContractCmpController.performBUSearch";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOCALE from '@salesforce/i18n/locale';
import { Labels, ContractServiceHelper, checkConditionEmpty, parseDecimalOnly, API_NAMES, setNegotiateConditionFields, reachProgressiveSlab } from "c/contractServices";
import { CurrentPageReference } from 'lightning/navigation';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubSub';
import canUserModifyAll from '@salesforce/userPermission/ModifyAllData';
const SEARCH_TIME_OUT = 500;
const LOADING_TIME_OUT = 1000;
const SUCCESS_VARIANT = 'success';
const CALCULATE_INDEX_TIMEOUT = 400;
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';
const globalMethods = {
    _fireEvent: (pageref, eventName, details) => {
    },
    _registerListener: (eventName, callback, cmpInstance) => {
    },
};
const _fireEvent = (pageref, eventName, details) => {
    globalMethods._fireEvent(pageref, eventName, details);
};
const _registerListener = (eventName, callback, cmpInstance) => {
    globalMethods._registerListener(eventName, callback, cmpInstance);
}
const convertToFloat = (number) => {
    if (number || number == 0) {
        let group;
        let decimal;
        new Intl.NumberFormat(LOCALE, {}).formatToParts(1000000.200888).filter(it => {
            if (it.type == 'group') {
                group = it.value;
            }
            if (it.type == 'decimal') {
                decimal = it.value;
            }
        });
        number = number.replace(/\s/gi, '');
        number = number.replace(new RegExp(`[${group}]`, 'gi'), '');
        number = number.replace(new RegExp(decimal == '.' ? '[\.]' : decimal, 'gi'), '.');
        return number;
    } else {
        return '';
    }
}
export default class NegotiateContract extends LightningElement {
    @api nonce;
    @api postSigned;
    API_NAMES = API_NAMES;
    @track lockedByApprovalProcess = false;
    @track LoadingMap = {};
    @track Loading = true;
    @track loadingTimeOut;
    @track showWarningMessagePeWillBeDeleted = false;
    @api lockedActions;
    @track loadingLockedActions = true;
    @api contractRTN1Settings;
    @api slabsMethodMap;
    @api hasIndexTarget;
    @wire(CurrentPageReference) pageRef;
    @track Labels = Labels;
    @track helpText = {};
    @api showIndexes;
    @api translation;
    @track depreciationRateClass;
    @track riseRateClass;
    get canUserModifyAll() {
        return canUserModifyAll;
    }
    get detailPopupFields() {
        let translation = this.translation;
        let res = [
            API_NAMES.Contract_Discount__c.Rank__c,
            API_NAMES.Contract_Discount__c.Product_Scope__c,
            API_NAMES.Contract_Discount__c.Base_TO_Nego__c,
            API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c,
            API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
            API_NAMES.Contract_Discount__c.Disc_BDate__c,
            API_NAMES.Contract_Discount__c.Disc_EDate__c,
            API_NAMES.Contract_Discount__c.BusinessUnitScope__c,
            API_NAMES.Contract_Discount__c.commercial_reference__c,
        ].filter(fieldApiName =>
            translation
            && translation.hasOwnProperty(API_NAMES.Contract_Discount__c.objectApiName)
            && translation[API_NAMES.Contract_Discount__c.objectApiName].hasOwnProperty(fieldApiName)
        ).map(fieldApiName => {
            return {
                fieldApiName: fieldApiName,
                label: translation[API_NAMES.Contract_Discount__c.objectApiName][fieldApiName],
                isRequired: fieldApiName == API_NAMES.Contract_Discount__c.Rank__c,
                isInput: fieldApiName != API_NAMES.Contract_Discount__c.commercial_reference__c,
                class: fieldApiName == API_NAMES.Contract_Discount__c.Rank__c ? 'rankPicker' : '',
            };
        });
        return res;
    }
    popupfields = [
        API_NAMES.Contract_Discount__c.Rank__c,
        API_NAMES.Contract_Discount__c.Product_Scope__c,
        API_NAMES.Contract_Discount__c.Base_TO_Nego__c,
        API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c,
        API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
        API_NAMES.Contract_Discount__c.BusinessUnitScope__c,
        API_NAMES.Contract_Discount__c.Disc_BDate__c,
        API_NAMES.Contract_Discount__c.Disc_EDate__c,
        API_NAMES.Contract_Discount__c.Value_per__c,
        API_NAMES.Contract_Discount__c.Value_amt__c,
        API_NAMES.Contract_Discount__c.unit_amount__c,
        API_NAMES.Contract_Discount__c.Unit_Amount_Type__c,
        API_NAMES.Contract_Discount__c.commercial_reference__c,
    ];
    @api contractId;
    @api hasTopNotSimulation;
    @api hasPe;
    @api hasPeSigned;
    get linkContractName() { return '/' + this.contractId; }
    @api populateRefIndexEvent;
    @api negoYear;
    @api availablePePolComs;
    @api isLast;
    @track res = {};
    @api hasAnyInternational;
    @track showSlabsCurrency;
    @track showSlabsUnitType;
    @track simulationNumber;
    @track postSimulationNumber;
    @track depreciationRate;
    @track riseRate;
    @track purchase;
    @track quantity;
    @track dateContract;
    @track contractName;
    @track readOnly = true;
    @track wrapperCondition;
    @track grouppingResult;
    @track contractRecordTypeDeveloperNameToLabelMap;
    @track arraysCondtion = [];
    @track changesMap = {};
    @track hasOnTop;
    @track ontopBdate;
    @track ontopEdate;
    @track ptBdate;
    @track ptEdate;
    @track confirmSetOnTop = false;
    @track contractFieldsScaleStepMap = {
        'riseRate': {
            scale: 0,
            step: '0'
        },
        'depreciationRate': {
            scale: 0,
            step: '0'
        },
        'qty': {
            scale: 0,
            step: '0'
        },
        'to': {
            scale: 0,
            step: '0'
        },
    };
    @wire(getObjectInfo, { objectApiName: API_NAMES.Contract__c.objectApiName }) contractInfo({ error, data }) {
        if (data) {

            // Rise Rate
            let step = '.';
            this.contractFieldsScaleStepMap['riseRate'].scale = data.fields[API_NAMES.Contract__c.Rise_Rate__c].scale;
            step = '.';
            for (let i = 0; i < this.contractFieldsScaleStepMap['riseRate'].scale; i++) {
                step += i == this.contractFieldsScaleStepMap['riseRate'].scale - 1 ? '1' : '0';
            }
            this.contractFieldsScaleStepMap['riseRate'].step = step;

            // Depreciation Rate
            this.contractFieldsScaleStepMap['depreciationRate'].scale = data.fields[API_NAMES.Contract__c.Depreciation_Rate__c].scale;
            step = '.';
            for (let i = 0; i < this.contractFieldsScaleStepMap['depreciationRate'].scale; i++) {
                step += i == this.contractFieldsScaleStepMap['depreciationRate'].scale - 1 ? '1' : '0';
            }
            this.contractFieldsScaleStepMap['depreciationRate'].step = step;
            // Qty
            this.contractFieldsScaleStepMap['qty'].scale = data.fields[API_NAMES.Contract__c.Qty1__c].scale;
            step = '.';
            for (let i = 0; i < this.contractFieldsScaleStepMap['qty'].scale; i++) {
                step += i == this.contractFieldsScaleStepMap['qty'].scale - 1 ? '1' : '0';
            }
            this.contractFieldsScaleStepMap['qty'].step = step;
            //TO
            this.contractFieldsScaleStepMap['to'].scale = data.fields[API_NAMES.Contract__c.TO1__c].scale;
            step = '.';
            for (let i = 0; i < this.contractFieldsScaleStepMap['to'].scale; i++) {
                step += i == this.contractFieldsScaleStepMap['to'].scale - 1 ? '1' : '0';
            }
            this.contractFieldsScaleStepMap['to'].step = step;
        } else {
            console.log(error);
        }
    }
    get newContractRecordTypeOptions() {
        let contractRTN1Settings = this.contractRTN1Settings;
        let createSimulFromNegoBaseLabel = this.createSimulFromNegoBaseLabel;
        let createSimulFromSafeBalanceLabel = this.createSimulFromSafeBalanceLabel;
        let createSafeBalanceFromSafeBalanceLabel = this.createSafeBalanceFromSafeBalanceLabel;
        let createSimulFromSimulLabel = this.createSimulFromSimulLabel;
        let createPostNegoSimulFromSignedLabel = this.createPostNegoSimulFromSignedLabel;
        let createSafeBalanceFromSimulLabel = this.createSafeBalanceFromSimulLabel;
        let createSafeBalanceFromNegoBaseLabel = this.createSafeBalanceFromNegoBaseLabel;
        let duplicateNegoBasetoPE = this.duplicateNegoBasetoPE;
        let duplicateSafeBalanceToPE = this.duplicateSafeBalanceToPE;
        let contractRecordTypeDeveloperNameToLabelMap = this.contractRecordTypeDeveloperNameToLabelMap;
        let options = [];
        if (this.isNegoBase && !this.isNegoYear) {
            if (contractRTN1Settings.includes('Simulation')) {
                options.push({ value: 'Simulation', label: createSimulFromNegoBaseLabel });
            }
            if (contractRTN1Settings.includes('Safe_Balance')) {
                options.push({ value: 'Safe_Balance', label: createSafeBalanceFromNegoBaseLabel });
            }
            let ontopBdate;
            if (this.ontopBdate) {
                ontopBdate = new Date(this.ontopBdate);
                ontopBdate.setUTCMilliseconds(0);
                ontopBdate.setUTCMinutes(0);
                ontopBdate.setUTCSeconds(0);
                ontopBdate.setUTCHours(0);
            }
            if (!this.hasPe && (!ontopBdate || (ontopBdate.toGMTString() != new Date(Date.parse(this.negoYear + '-01-01')).toGMTString())) && contractRTN1Settings.includes('Period_Extension')) {
                options.push({ value: 'Period_Extension', label: duplicateNegoBasetoPE });
            }
        }
        if (this.isSafeBalance) {
            if (contractRTN1Settings.includes('Simulation')) {
                options.push({ value: 'Simulation', label: createSimulFromSafeBalanceLabel });
            }
            if (contractRTN1Settings.includes('Safe_Balance')) {
                options.push({ value: 'Safe_Balance', label: createSafeBalanceFromSafeBalanceLabel });
            }
            let ontopBdate;
            if (this.ontopBdate) {
                ontopBdate = new Date(this.ontopBdate);
                ontopBdate.setUTCMilliseconds(0);
                ontopBdate.setUTCMinutes(0);
                ontopBdate.setUTCSeconds(0);
                ontopBdate.setUTCHours(0);
            }
            if (!this.hasPe && (!ontopBdate || (ontopBdate.toGMTString() != new Date(Date.parse(this.negoYear + '-01-01')).toGMTString())) && contractRTN1Settings.includes('Period_Extension')) {
                options.push({ value: 'Period_Extension', label: duplicateSafeBalanceToPE });
            }
        }
        if (this.isSimulation) {
            if (contractRTN1Settings.includes('Simulation')) {
                options.push({ value: 'Simulation', label: createSimulFromSimulLabel });
            }
            if (contractRTN1Settings.includes('Safe_Balance')) {
                options.push({ value: 'Safe_Balance', label: createSafeBalanceFromSimulLabel });
            }
        }
        if (this.isSigned) {
            if (contractRTN1Settings.includes('PostNego_Simulation')) {
                options.push({ value: 'PostNego_Simulation', label: createPostNegoSimulFromSignedLabel });
            }
        }
        return options.filter(rt => contractRecordTypeDeveloperNameToLabelMap && contractRecordTypeDeveloperNameToLabelMap[rt.value] ? true : false);
    }
    get isNegoYear() { return (this?.contract?.hasOwnProperty(API_NAMES.Contract__c.Contract_BDate__c) && this?.contract[API_NAMES.Contract__c.Contract_BDate__c] ? new Date(this.contract[API_NAMES.Contract__c.Contract_BDate__c]).getUTCFullYear() == this.negoYear : false) };
    get isSimulation() { return (this?.contract?.RecordType?.DeveloperName == 'Simulation') };
    get isSigned() { return (this?.contract?.RecordType?.DeveloperName == 'Signed') };
    get isSafeBalance() { return (this?.contract?.RecordType?.DeveloperName == 'Safe_Balance') };
    get isSimulationOrisSafeBalance() { return this.isSimulation || this.isSafeBalance };
    // get isSimulationOrisSigned() { return this.isSimulation || this.isSigned };
    get isPE() { return (this?.contract?.RecordType?.DeveloperName == 'Period_Extension') };
    get isNegoBase() { return (this?.contract?.RecordType?.DeveloperName == 'Nego_Base') };
    get isRefNegoBase() {
        let contract = this.contract;
        let negoYear = this.negoYear;
        let bDate = contract ? new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]) : null;
        return contract && contract.RecordType ? (contract.RecordType.DeveloperName == 'Nego_Base') && (bDate.getFullYear() < negoYear) : false
    };
    get isNegoBaseInitNegoYear() {
        let contract = this.contract;
        let negoYear = this.negoYear;
        let bDate = contract ? new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]) : null;
        return contract && contract.RecordType ? (contract.RecordType.DeveloperName == 'Nego_Base_Init') && (bDate.getFullYear() == negoYear) : false
    };
    get isLandingNegoYear() {
        let contract = this.contract;
        let negoYear = this.negoYear;
        let bDate = contract ? new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]) : null;
        return contract && contract.RecordType ? (contract.RecordType.DeveloperName == 'Landing') && (bDate.getFullYear() == negoYear) : false
    };
    get isNegoBaseNegoYear() {
        let contract = this.contract;
        let negoYear = this.negoYear;
        let bDate = contract ? new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]) : null;
        return contract && contract.RecordType ? (contract.RecordType.DeveloperName == 'Nego_Base') && (bDate.getFullYear() == negoYear) : false
    };
    get isPENegoYear() {
        let contract = this.contract;
        let negoYear = this.negoYear;
        let bDate = contract ? new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]) : null;
        return contract && contract.RecordType ? (contract.RecordType.DeveloperName == 'Period_Extension') && (bDate.getFullYear() == negoYear) : false
    };
    get isOnTopNegoYear() {
        let contract = this.contract;
        let negoYear = this.negoYear;
        let bDate = contract ? new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]) : null;
        return contract && contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] ? (bDate.getFullYear() == negoYear) : false
    };
    get isNegoBaseInit() { return (this?.contract?.RecordType?.DeveloperName == 'Nego_Base_Init') };
    get isAvailableForClone() { return this.cloneLabel ? true : false; };
    get isAvailableForDelete() { return !this.readOnly && (this.isSimulation || this.isSafeBalance) };
    @track isOnTopSimulation;
    @api get isTopOrPe() {
        return !this.readOnly && (this.isPE || this.isOnTopSimulation);
    }
    @api isLockedByAprovalProcess;
    @api currentUrl;
    @track isLocked;
    @track isSelected;
    @track isEditConditionModelOpen = false;
    @track rankPending;
    @api contract;
    @api wIndex = {};
    @track validTariffConditionMap = {};
    @api getValidTariffConditionMap() {
        return this.validTariffConditionMap;
    }
    @track hasChanges = false;
    @track hasContractChanges = false;
    @api get hasChangesToSave() {
        return this.hasContractChanges;
    }
    @track currentCondition;
    @track diffQty;
    @track diffTO;
    @track gapQty;
    @track gapQtyStyle;
    @track gapSBQty;
    @track gapSBTO;
    @track gapTO;
    @track gapTOStyle;
    get currentConditionPopupfieldsWrappers() {
        let validTariffConditionMap = this.validTariffConditionMap;
        let readOnly = this.readOnly;
        let contract = this.contract;
        let isPE = this.isPE;
        let isSimulation = this.isSimulation;
        let condition = this.currentCondition;
        let userProfileId = this.userProfileId;
        condition = setNegotiateConditionFields(condition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, userProfileId);
        return this.popupfields.map(fieldApiName => {
            return {
                fieldApiName: fieldApiName,
                value: condition && condition[fieldApiName] ? condition[fieldApiName] : '',
                isInput: fieldApiName != API_NAMES.Contract_Discount__c.commercial_reference__c,
                isSearchNS: fieldApiName == API_NAMES.Contract_Discount__c.Product_Scope__c,
                isSearchBU: fieldApiName == API_NAMES.Contract_Discount__c.BusinessUnitScope__c,
                get disabled() {
                    let disableRespect = (condition.respectScope
                        && (fieldApiName == API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c
                            || fieldApiName == API_NAMES.Contract_Discount__c.Base_TO_Nego__c
                            || fieldApiName == API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c));
                    let disableNotRespect = (fieldApiName == API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c
                        && !(!condition.respectScope
                            && condition[API_NAMES.Contract_Discount__c.Disc_BDate__c] != contract[API_NAMES.Contract__c.Contract_BDate__c]
                            && condition[API_NAMES.Contract_Discount__c.Product_Scope__c] != contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c]
                            && (contract.RecordType.DeveloperName == 'Simulation' || contract.RecordType.DeveloperName == 'To_Be_Signed' || contract.RecordType.DeveloperName == 'Signed')));
                    return disableRespect || disableNotRespect;
                },
                show: (fieldApiName != API_NAMES.Contract_Discount__c.Value_amt__c
                    && fieldApiName != API_NAMES.Contract_Discount__c.Value_per__c
                    && fieldApiName != API_NAMES.Contract_Discount__c.unit_amount__c
                    && fieldApiName != API_NAMES.Contract_Discount__c.Unit_Amount_Type__c)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c && condition.enablePercentage)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.Value_amt__c && condition.enableAmt)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.unit_amount__c && condition.enableUnitAmt)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c && condition.enableUnitAmt) ? true : false,
                isDiscPercent: fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c
            }
        });
    }
    renderedCallback() {
        if (this.isRefNegoBase) {
            let cloneIcon = this.template.querySelector(`[data-id="cloneIcon"]`);
            if (cloneIcon) {
                if (cloneIcon.getBoundingClientRect().top && cloneIcon.getBoundingClientRect().left) {
                    _fireEvent(this.pageRef, 'ref_contract_clone_icon', {
                        top: cloneIcon.getBoundingClientRect().top,
                        left: cloneIcon.getBoundingClientRect().left,
                    });
                }
            }
        }
    }
    get refCurrentConditionPopupfieldsWrappers() {
        let validTariffConditionMap = this.validTariffConditionMap;
        let readOnly = this.readOnly;
        let contract = this.contract;
        let isPE = this.isPE;
        let isSimulation = this.isSimulation;
        let condition = this.refCurrentCondition;
        let userProfileId = this.userProfileId;
        condition = setNegotiateConditionFields(condition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, userProfileId);
        return this.popupfields.map(fieldApiName => {
            return {
                fieldApiName: fieldApiName,
                value: condition && condition.Id && condition[fieldApiName] ? condition[fieldApiName] : '',
                isInput: fieldApiName != API_NAMES.Contract_Discount__c.commercial_reference__c,
                show: (fieldApiName != API_NAMES.Contract_Discount__c.Value_amt__c
                    && fieldApiName != API_NAMES.Contract_Discount__c.Value_per__c
                    && fieldApiName != API_NAMES.Contract_Discount__c.unit_amount__c
                    && fieldApiName != API_NAMES.Contract_Discount__c.Unit_Amount_Type__c)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c && condition.enablePercentage)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.Value_amt__c && condition.enableAmt)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.unit_amount__c && condition.enableUnitAmt)
                    || (fieldApiName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c && condition.enableUnitAmt) ? true : false,
                isDiscPercent: fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c
            }
        });
    }
    @track nsPopUp = {
        selectedDataName: '',
        dataList: [],
        filteredDataList: [],
        displayDataList: false,
        hideDataList(event) {
            let self = this;
            setTimeout(() => {
                self.nsPopUp.displayDataList = false;
            }, 500);
        },
        handleChange(event) {
            let self = this;
            let nsId = this.contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
            let supplierId = this.contract[API_NAMES.Contract__c.Supplier__c];
            let searchString = event?.detail?.value;
            if (!searchString) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__c] = '';
                if (!this.currentCondition.hasOwnProperty(API_NAMES.Contract_Discount__c.Product_Scope__r)) {
                    this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__r] = { attributes: { type: API_NAMES.NegoScope__c.objectApiName }, Id: '' };
                }
                this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__r].Name = '';
            }
            if (this.nsPopUp.dataList.length == 0) {
                performNSSearch({ nsId: nsId, supplierId: supplierId, searchString: searchString }).then(result => {
                    let data = JSON.parse(result);
                    self.nsPopUp.dataList = data.map(item => {
                        let newItem = {
                            Id: item.Id,
                            Name: item.Name,
                        };
                        return newItem;
                    });
                    if (searchString) {
                        self.nsPopUp.filteredDataList = self.nsPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                    } else {
                        self.nsPopUp.filteredDataList = self.nsPopUp.dataList.map(item => item);
                    }
                    self.nsPopUp.displayDataList = true;
                });
            } else {
                if (searchString) {
                    self.nsPopUp.filteredDataList = self.nsPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                } else {
                    self.nsPopUp.filteredDataList = self.nsPopUp.dataList.map(item => item);
                }
                this.nsPopUp.displayDataList = true;
            }
        },
        showDataList(event) {
            let self = this;
            let nsId = this.contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
            let supplierId = this.contract[API_NAMES.Contract__c.Supplier__c];
            let searchString = event?.detail?.value;
            if (this.nsPopUp.dataList.length == 0) {
                performNSSearch({ nsId: nsId, supplierId: supplierId, searchString: searchString }).then(result => {
                    let data = JSON.parse(result);
                    self.nsPopUp.dataList = data.map(item => {
                        let newItem = {
                            Id: item.Id,
                            Name: item.Name,
                        };
                        return newItem;
                    });
                    if (searchString) {
                        self.nsPopUp.filteredDataList = self.nsPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                    } else {
                        self.nsPopUp.filteredDataList = self.nsPopUp.dataList.map(item => item);
                    }
                    self.nsPopUp.displayDataList = true;
                });
            } else {
                if (searchString) {
                    self.nsPopUp.filteredDataList = self.nsPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                } else {
                    self.nsPopUp.filteredDataList = self.nsPopUp.dataList.map(item => item);
                }
                this.nsPopUp.displayDataList = true;
            }
        },
        setCurrentItem(event) {
            let Id = event.target.dataset.id;
            let Name = event.target.dataset.name;
            this.nsPopUp.selectedDataName = '';
            setTimeout(() => {
                this.nsPopUp.selectedDataName = Name;
            }, 200);
            this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__c] = Id;
            if (!this.currentCondition.hasOwnProperty(API_NAMES.Contract_Discount__c.Product_Scope__r)) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__r] = { attributes: { type: API_NAMES.NegoScope__c.objectApiName }, Id: Id };
            }
            this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__r].Name = Name;
        },
    }
    @track buPopUp = {
        selectedDataName: '',
        dataList: [],
        filteredDataList: [],
        displayDataList: false,
        hideDataList(event) {
            let self = this;
            setTimeout(() => {
                self.buPopUp.displayDataList = false;
            }, 200);
        },
        handleChange(event) {
            let self = this;
            let buId = this.contract[API_NAMES.Contract__c.BusinessUnitContract__c];
            let searchString = event?.detail?.value;
            if (!searchString) {
                this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = '';
                if (!this.currentCondition.hasOwnProperty(API_NAMES.Contract_Discount__c.BusinessUnitScope__r)) {
                    this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = { attributes: { type: API_NAMES.BusinessUnit__c.objectApiName }, Id: '' };
                }
                this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name = '';
            }
            if (this.buPopUp.dataList.length == 0) {
                performBUSearch({ buId: buId, searchString: searchString }).then(result => {
                    let data = JSON.parse(result);
                    self.buPopUp.dataList = data.map(item => {
                        let newItem = {
                            Id: item.Id,
                            Name: item.Name,
                        };
                        return newItem;
                    });
                    if (searchString) {
                        self.buPopUp.filteredDataList = self.buPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                    } else {
                        self.buPopUp.filteredDataList = self.buPopUp.dataList.map(item => item);
                    }
                    self.buPopUp.displayDataList = true;
                });
            } else {
                if (searchString) {
                    self.buPopUp.filteredDataList = self.buPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                } else {
                    self.buPopUp.filteredDataList = self.buPopUp.dataList.map(item => item);
                }
                this.buPopUp.displayDataList = true;
            }
        },
        showDataList(event) {
            let self = this;
            let buId = this.contract[API_NAMES.Contract__c.BusinessUnitContract__c];
            let searchString = event?.detail?.value;
            if (this.buPopUp.dataList.length == 0) {
                performBUSearch({ buId: buId, searchString: searchString }).then(result => {
                    let data = JSON.parse(result);
                    self.buPopUp.dataList = data.map(item => {
                        let newItem = {
                            Id: item.Id,
                            Name: item.Name,
                        };
                        return newItem;
                    });
                    if (searchString) {
                        self.buPopUp.filteredDataList = self.buPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                    } else {
                        self.buPopUp.filteredDataList = self.buPopUp.dataList.map(item => item);
                    }
                    self.buPopUp.displayDataList = true;
                });
            } else {
                if (searchString) {
                    self.buPopUp.filteredDataList = self.buPopUp.dataList.filter(item => item.Name.toLocaleLowerCase().trim().includes(searchString.toLocaleLowerCase().trim()));
                } else {
                    self.buPopUp.filteredDataList = self.buPopUp.dataList.map(item => item);
                }
                this.buPopUp.displayDataList = true;
            }
        },
        setCurrentItem(event) {
            let Id = event.target.dataset.id;
            let Name = event.target.dataset.name;
            this.buPopUp.selectedDataName = '';
            setTimeout(() => {
                this.buPopUp.selectedDataName = Name;
            }, 200);
            this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = Id;
            if (!this.currentCondition.hasOwnProperty(API_NAMES.Contract_Discount__c.BusinessUnitScope__r)) {
                this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = { attributes: { type: API_NAMES.BusinessUnit__c.objectApiName }, Id: Id };
            }
            this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name = Name;
        },
    }
    @track currentMapKey;
    @track indexesClass = 'slds-hide';
    @track popupColClass = 'slds-col slds-size_1-of-2';
    @track createSimulFromNegoBaseLabel;
    @track createSafeBalanceFromNegoBaseLabel;
    @track createSimulFromSafeBalanceLabel;
    @track createSafeBalanceFromSafeBalanceLabel;
    @track createSafeBalanceFromSimulLabel;
    @track createSimulFromSimulLabel;
    @track createPostNegoSimulFromSignedLabel;
    @track duplicateNegoBasetoPE;
    @track duplicateSafeBalanceToPE;
    @track discountPercentScale;
    @track executiveSummaryUrl;
    openExecutiveSummary(event) {
        _fireEvent(this.pageRef, 'openExecutiveSummary', this.executiveSummaryUrl);
    }
    get cloneRTs() {
        let recordTypes = [];
        if (this.isNegoBase && !this.isNegoYear) {
            if (this.contractRTN1Settings.includes('Simulation')) {
                recordTypes.push('Simulation');
            }
            if (this.contractRTN1Settings.includes('Safe_Balance')) {
                recordTypes.push('Safe_Balance');
            }
            if (!this.hasPe && this.contractRTN1Settings.includes('Period_Extension')) {
                recordTypes.push('Period_Extension');
            }
        }
        if (this.isSimulation && this.isNegoYear) {
            if (this.contractRTN1Settings.includes('Simulation')) {
                recordTypes.push('Simulation');
            }
            if (this.contractRTN1Settings.includes('Safe_Balance')) {
                recordTypes.push('Safe_Balance');
            }
        }
        if (this.isSafeBalance && this.isNegoYear) {
            if (this.contractRTN1Settings.includes('Simulation')) {
                recordTypes.push('Simulation');
            }
            if (this.contractRTN1Settings.includes('Safe_Balance')) {
                recordTypes.push('Safe_Balance');
            }
            if (!this.hasPe && this.contractRTN1Settings.includes('Period_Extension')) {
                recordTypes.push('Period_Extension');
            }
        }
        if (this.isSigned) {
            if (this.contractRTN1Settings.includes('PostNego_Simulation')) {
                recordTypes.push('PostNego_Simulation');
            }
        }
        return recordTypes;
    }
    get cloneLabels() {
        let labels = [];
        if (this.isNegoBase && !this.isNegoYear) {
            if (this.contractRTN1Settings.includes('Simulation')) {
                labels.push(this.createSimulFromNegoBaseLabel);
            }
            if (this.contractRTN1Settings.includes('Safe_Balance')) {
                labels.push(this.createSafeBalanceFromNegoBaseLabel);
            }
            if (!this.hasPe && this.contractRTN1Settings.includes('Period_Extension')) {
                labels.push(this.duplicateNegoBasetoPE);
            }
        }
        if (this.isSimulation && this.isNegoYear) {
            if (this.contractRTN1Settings.includes('Simulation')) {
                labels.push(this.createSimulFromSimulLabel);
            }
            if (this.contractRTN1Settings.includes('Safe_Balance')) {
                labels.push(this.createSafeBalanceFromSimulLabel);
            }
        }
        if (this.isSafeBalance && this.isNegoYear) {
            if (this.contractRTN1Settings.includes('Simulation')) {
                labels.push(this.createSimulFromSafeBalanceLabel);
            }
            if (this.contractRTN1Settings.includes('Safe_Balance')) {
                labels.push(this.createSafeBalanceFromSafeBalanceLabel);
            }
            if (!this.hasPe && this.contractRTN1Settings.includes('Period_Extension')) {
                labels.push(this.duplicateSafeBalanceToPE);
            }
        }
        if (this.isSigned) {
            if (this.contractRTN1Settings.includes('PostNego_Simulation')) {
                labels.push(this.createPostNegoSimulFromSignedLabel);
            }
        }
        return labels;
    }
    get cloneLabel() {
        return this.cloneLabels.join(' / ');
    }
    @api isReadOnly() {
        return this.readOnly;
    }
    @track iseditContractOpen = false;
    @track isRevalidatePTOpen = false;
    @track continueEditContract = false;
    @track wasEditContractForm = false;
    @track wasEditTopForm = false;
    @track continueEditContract = false;
    @track validatePT = false;
    @track isDeleteContractOpen = false;
    @track contractBeginDate;
    @track contractEndDate;
    @track mainContractSimulationName;
    @track contractSimulationName;
    @track isTotalToRecalcAfterDateChange;
    @track isFixCondRecalcAfterDateChange;
    addIndexTargetCondition(event) {
        _fireEvent(this.pageRef, 'addIndexTargetCondition', this.contract);
    }
    openDeletePopup(event) {
        this.isDeleteContractOpen = true;
    }
    confirmDeletePopup(event) {
        let contractId = this.contract.Id;
        _fireEvent(this.pageRef, 'deletecontract', {
            detail: {
                contractId: contractId,
            },
        });
        this.isDeleteContractOpen = false;
    }
    closeDeletePopup(event) {
        this.isDeleteContractOpen = false;
    }
    unlockContract(event) {
        _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'unlockContract' });
        let self = this;
        let contractId = this.contract.Id;
        unlockContract({ contractId }).then(isLocked => {
            if (isLocked) {
                self.isLocked = true;
            } else {
                self.isLocked = false;
                self.isLockedByAprovalProcess = false;
                _fireEvent(self.pageRef, 'lockedByApprovalProcess', { isActive: false });
            }
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'unlockContract' });
        }).catch(error => {
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'unlockContract' });
        });
    }
    openeditContract(event) {
        this.showWarningMessagePeWillBeDeleted = false;
        this.iseditContractOpen = true;
        this.contractBeginDate = this.contract[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
        this.contractEndDate = this.contract[API_NAMES.Contract__c.Contract_Commercial_EDate__c];
        this.contractSimulationName = this.contract.Name;
        this.isTotalToRecalcAfterDateChange = this.contract[API_NAMES.Contract__c.Is_TotalTo_Recalc_AfterDateChange__c];
        this.isFixCondRecalcAfterDateChange = this.contract[API_NAMES.Contract__c.Is_FixCond_Recalc_AfterDateChange__c];
    }
    closeeditContract(event) {
        this.iseditContractOpen = false;
        //this.contractEndDate = undefined;
        this.isRevalidatePTOpen = false;
        this.continueEditContract = false;
        this.validatePT = false;
    }
    confirmrevalidatept(event) {
        this.isRevalidatePTOpen = false;
        this.validatePT = true;
        if (this.wasEditContractForm) {
            this.continueEditContract = true;
            this.wasEditContractForm = false;
            this.confirmeditContract(event);
        } else if (this.wasEditTopForm) {
            this.continueTopContract = true;
            this.wasEditTopForm = false;
            this.setOnTop(event);
        }
    }
    closerevalidatept(event) {
        this.isRevalidatePTOpen = false;
        this.validatePT = false;
        if (this.wasEditContractForm) {
            this.continueEditContract = true;
            this.wasEditContractForm = false;
            this.confirmeditContract(event);
        } else if (this.wasEditTopForm) {
            this.continueTopContract = true;
            this.wasEditTopForm = false;
            this.setOnTop(event);
        }
    }
    confirmeditContract(event) {
        try {
            let contract = this.contract;
            this.iseditContractOpen = false;
            let oldBeginDateIsNotFirst = new Date(contract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]).toGMTString() != new Date(this.negoYear + '-01-01').toGMTString();
            let newBeginDateIsNotFirst = new Date(this.contractBeginDate).toGMTString() != new Date(this.negoYear + '-01-01').toGMTString();
            if (contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && !this.continueEditContract && oldBeginDateIsNotFirst && newBeginDateIsNotFirst && this.hasPeSigned) {
                this.isRevalidatePTOpen = true;
                this.wasEditContractForm = true;
            } else {
                let invalidDates = false;
                // validate new contract dates
                if (new Date(this.contractBeginDate) > new Date(this.contractEndDate)) {
                    invalidDates = true;
                    self.dispatchEvent(new ShowToastEvent({
                        title: Labels.LBL_Error,
                        message: Labels.LBL_Invalid_Dates,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                }
                if (invalidDates) {
                    _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'confirmeditContract' });
                    return;
                }
                let self = this;
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: true, fname: 'confirmeditContract' });
                let beginDateChanged = false, endDateChanged;
                if (this.hasContractChanges) {
                    beginDateChanged = contract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] != this.contractBeginDate;
                    contract[API_NAMES.Contract__c.Contract_Commercial_BDate__c] = this.contractBeginDate;
                    contract[API_NAMES.Contract__c.Contract_BDate__c] = this.contractBeginDate;
                    endDateChanged = contract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] != this.contractEndDate;
                    contract[API_NAMES.Contract__c.Contract_Commercial_EDate__c] = this.contractEndDate;
                    contract[API_NAMES.Contract__c.Contract_EDate__c] = this.contractEndDate;
                    contract.Name = this.contractSimulationName;
                    contract[API_NAMES.Contract__c.Is_TotalTo_Recalc_AfterDateChange__c] = this.isTotalToRecalcAfterDateChange;
                    contract[API_NAMES.Contract__c.Is_FixCond_Recalc_AfterDateChange__c] = this.isFixCondRecalcAfterDateChange;
                    this.save().then(result => {
                        let dmlResults = JSON.parse(result);
                        if (dmlResults.isSuccess) {
                            self.contractBeginDate = undefined;
                            self.contractEndDate = undefined;
                            self.contractSimulationName = undefined;
                            self.isTotalToRecalcAfterDateChange = undefined;
                            self.isFixCondRecalcAfterDateChange = undefined;
                            if (this.validatePT) {
                                _fireEvent(self.pageRef, 'RevalidatePT', {});
                            }
                            if (beginDateChanged || endDateChanged) {
                                _fireEvent(self.pageRef, 'reorderContracts', { contract: contract });
                            }
                            _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'confirmeditContract' });
                            if (!this.validatePT && (self.isPE || self.isOnTopSimulation)) {
                                _fireEvent(self.pageRef, 'consolidateContracts');
                                // _fireEvent(self.pageRef, 'requireConso');
                            }
                            let negotiateIndexesCmp = self.template.querySelector('[data-id="negotiate-indexes-cmp"]');
                            if (negotiateIndexesCmp && negotiateIndexesCmp.recalculate) {
                                negotiateIndexesCmp.recalculate();
                            }
                        } else {
                            if (dmlResults.errors) {
                                let errorMessages = dmlResults.errors.filter((item, index) => index == dmlResults.errors.indexOf(item));
                                if (errorMessages && errorMessages.length) {
                                    self.dispatchEvent(new ShowToastEvent({
                                        title: Labels.LBL_Error,
                                        message: errorMessages.join('\n'),
                                        variant: ERROR_VARIANT,
                                        mode: STICKY_VARIANT
                                    }));
                                }
                                _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'confirmeditContract' });
                                let beginDate = new Date(self.contract[API_NAMES.Contract__c.Contract_BDate__c]);
                                if (self.hasPe) {
                                    self.showPTMessage = beginDate.toGMTString() == new Date(self.negoYear + '-01-01').toGMTString();
                                }
                                self.iseditContractOpen = true;
                            }
                        }
                        self.showWarningMessagePeWillBeDeleted = false;
                    }).catch(error => {
                        console.error(error);
                        self.showWarningMessagePeWillBeDeleted = false;
                        self.iseditContractOpen = true;
                        _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'confirmeditContract' });
                    });
                }
            }
        } catch (error) {
            console.error('ERROR::: ' + error);
        }
    }
    handleEditContractChange(event) {
        this.hasContractChanges = true;
        if (event.target.dataset.fieldName == 'contractBeginDate' || event.target.dataset.fieldName == 'contractEndDate' || event.target.dataset.fieldName == 'contractSimulationName') {
            this[event.target.dataset.fieldName] = event.detail.value;
        } else {
            this[event.target.dataset.fieldName] = event.detail.checked;
        }
        if (event.target.dataset.fieldName == 'contractBeginDate' && this.isOnTopSimulation && this.hasPe && !this.isSetSimulationDataBeforeCreateNewModalOpen) {
            let newDate = new Date(event.detail.value);
            newDate.setUTCMilliseconds(0);
            newDate.setUTCMinutes(0);
            newDate.setUTCSeconds(0);
            newDate.setUTCHours(0);
            if (newDate.toGMTString() == new Date(this.negoYear + '-01-01').toGMTString()) {
                this.showWarningMessagePeWillBeDeleted = true;
            } else {
                this.showWarningMessagePeWillBeDeleted = false;
            }
        }
    }
    cancelSetOnTop(event) {
        this.confirmSetOnTop = false;
    }
    setOnTop(event) {
        let beginDate = new Date(this.contract[API_NAMES.Contract__c.Contract_BDate__c]);
        let endDate = new Date(this.contract[API_NAMES.Contract__c.Contract_EDate__c]);
        if (!this.confirmSetOnTop && !this.continueTopContract) {
            if (this.hasPe) {
                this.showPTMessage = beginDate.toGMTString() == new Date(this.negoYear + '-01-01').toGMTString();
            }
            if (this.ontopBdate) {
                let ontopBdate;
                if (this.ontopBdate) {
                    ontopBdate = new Date(this.ontopBdate);
                    ontopBdate.setUTCMilliseconds(0);
                    ontopBdate.setUTCMinutes(0);
                    ontopBdate.setUTCSeconds(0);
                    ontopBdate.setUTCHours(0);
                }
                let bbeginDate = new Date(beginDate);
                bbeginDate.setUTCMilliseconds(0);
                bbeginDate.setUTCMinutes(0);
                bbeginDate.setUTCSeconds(0);
                bbeginDate.setUTCHours(0);
                this.showOnTopMessage = bbeginDate.toGMTString() != ontopBdate.toGMTString();
            }
            this.confirmSetOnTop = true;
            return;
        }
        this.confirmSetOnTop = false;
        let oldBeginDateIsNotFirst = beginDate.toGMTString() != new Date(this.negoYear + '-01-01').toGMTString();
        let newBeginDateIsNotFirst = new Date(this.ontopBdate).toGMTString() != new Date(this.negoYear + '-01-01').toGMTString();
        if (!this.continueTopContract && oldBeginDateIsNotFirst && newBeginDateIsNotFirst && this.hasPeSigned) {
            this.isRevalidatePTOpen = true;
            this.wasEditTopForm = true;
        } else {
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'setOnTop' });
            let self = this;
            this.contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] = true;
            this.hasContractChanges = true;
            this.save().then(result => {
                let dmlResults = JSON.parse(result);
                if (dmlResults.isSuccess) {
                    self.isOnTopSimulation = true;
                    self.hasContractChanges = false;
                    if (this.validatePT) {
                        _fireEvent(self.pageRef, 'RevalidatePT', {});
                    }
                    _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'setOnTop' });
                    _fireEvent(this.pageRef, 'handleNewOnTop', { beginDate, endDate });
                    _fireEvent(this.pageRef, 'consolidateContracts');
                    // if (!this.validatePT) {
                    // _fireEvent(this.pageRef, 'requireConso');
                    // }
                } else {
                    self.hasContractChanges = true;
                    if (dmlResults.errors) {
                        let errorMessages = dmlResults.errors.filter((item, index) => index == dmlResults.errors.indexOf(item));
                        self.dispatchEvent(new ShowToastEvent({
                            title: Labels.LBL_Error,
                            message: errorMessages.join('\n'),
                            variant: ERROR_VARIANT,
                            mode: STICKY_VARIANT
                        }));
                        _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'setOnTop' });
                    }
                    _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'setOnTop' });
                }
            }).catch(error => {
                self.dispatchEvent(new ShowToastEvent({
                    title: Labels.LBL_Error,
                    message: error,
                    variant: ERROR_VARIANT,
                    mode: STICKY_VARIANT
                }));
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'setOnTop' });
            });
        }
    }
    @track isNewContractModelOpen = false;
    @track isSetSimulationDataBeforeCreateNewModalOpen = false;
    @track selectedNewContractDeveloperName = '';
    openNewContractModel(event) {
        this.isNewContractModelOpen = true;
    }
    closeNewContractModel(event) {
        this.isNewContractModelOpen = false;
        this.selectedNewContractDeveloperName = undefined;
    }
    confirmNewContractModel(event) {
        this.createNewContract(event);
    }
    handleNewContractDeveloperNameChange(event) {
        this.selectedNewContractDeveloperName = event.detail.value || event.target.value;
    }
    closeSetSimulationDataBeforeCreateNewModal(event) {
        this.isSetSimulationDataBeforeCreateNewModalOpen = false;
        this.contractBeginDate = undefined;
        this.contractEndDate = undefined;
        this.contractSimulationName = undefined;
        this.isTotalToRecalcAfterDateChange = undefined;
        this.isFixCondRecalcAfterDateChange = undefined;
    }
    createNewContract(event) {
        try {
            let self = this;
            this.showWarningMessagePeWillBeDeleted = false;
            _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: true, fname: 'createNewContract' });
            let nsId = this.contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
            let hasOnTop = this.hasOnTop;
            let isRefNegoBase = this.isRefNegoBase;
            let negoYear = this.negoYear;
            let refNegoBase = this.refContract;
            let contractPE = this.contractPE;
            let sourceContract = JSON.parse(JSON.stringify(this.contract));
            let refDiscountsList = [];
            let arraysCondtion = this.arraysCondtion;
            let blockingDups = [];
            for (let index of arraysCondtion) {
                for (let negodiscount of index.negodiscounts) {
                    for (let conditionIndex in negodiscount.conditions) {
                        let condition = negodiscount.conditions[conditionIndex];
                        if (isRefNegoBase && !checkConditionEmpty(condition) && condition[API_NAMES.Contract_Discount__c.Condition_Type__r] && condition[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Original_Name__c]) {
                            let eDate = new Date(condition[API_NAMES.Contract_Discount__c.Disc_EDate__c]);
                            if (eDate.getDate() == 31 && eDate.getMonth() + 1 == 12) {
                                blockingDups.push({
                                    sourceName: condition[API_NAMES.Contract_Discount__c.Condition_Type__r].Name,
                                    targetName: condition[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Original_Name__c],
                                });
                            }
                        }
                        refDiscountsList.push(condition);
                    }
                }
            }
            let targetContractRTDeveloperName = this.cloneRTs && this.cloneRTs.length ? this.cloneRTs[0] : 'Simulation';
            // if (this.isSimulation) {
            //     targetContractRTDeveloperName = 'Simulation';
            // }
            // if (this.isNegoBase) {
            //     targetContractRTDeveloperName = 'Simulation';
            //     if (!this.selectedNewContractDeveloperName) {
            //         this.isNewContractModelOpen = true;
            //         _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'createNewContract' });
            //         return;
            //     } else {
            //         targetContractRTDeveloperName = this.selectedNewContractDeveloperName;
            //     }
            // }
            // if (this.isSafeBalance) {
            //     targetContractRTDeveloperName = 'Simulation';
            //     if (!this.selectedNewContractDeveloperName) {
            //         this.isNewContractModelOpen = true;
            //         _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'createNewContract' });
            //         return;
            //     } else {
            //         targetContractRTDeveloperName = this.selectedNewContractDeveloperName;
            //     }
            // }
            if (this.cloneLabels && this.cloneLabels.length > 1) {
                if (!this.selectedNewContractDeveloperName) {
                    this.isNewContractModelOpen = true;
                    _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'createNewContract' });
                    return;
                } else {
                    targetContractRTDeveloperName = this.selectedNewContractDeveloperName;
                }
                if ((targetContractRTDeveloperName == 'Simulation' || targetContractRTDeveloperName == 'Safe_Balance') && blockingDups && blockingDups.length) {
                    let errMsgs = blockingDups.map(it => Labels.MSG_Error_Replace_Condition.replace(/\{0\}/gi, it.sourceName).replace(/\{1\}/gi, it.targetName));
                    errMsgs = errMsgs.filter((item, index) => { return index == errMsgs.indexOf(item); });
                    this.dispatchEvent(new ShowToastEvent({
                        message: errMsgs.join('\n'),
                        variant: WARNING_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                    _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'createNewContract' });
                    this.isNewContractModelOpen = false;
                    this.isSetSimulationDataBeforeCreateNewModalOpen = false;
                    this.selectedNewContractDeveloperName = undefined;
                    return;
                }
            }
            let contractCommercialBDate = new Date(sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c]);
            let contractCommercialEDate = new Date(sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c]);
            if ((targetContractRTDeveloperName == 'Simulation' || targetContractRTDeveloperName == 'Safe_Balance') && !this.isSetSimulationDataBeforeCreateNewModalOpen) {
                this.contractBeginDate = sourceContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c].replace(contractCommercialBDate.getUTCFullYear(), this.negoYear);
                if (contractCommercialBDate.getUTCFullYear() == contractCommercialEDate.getUTCFullYear()) {
                    this.contractEndDate = sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c].replace(contractCommercialEDate.getUTCFullYear(), this.negoYear);
                } else {
                    let nextNegoYear = parseInt(this.negoYear) + 1;
                    this.contractEndDate = sourceContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c].replace(contractCommercialEDate.getUTCFullYear(), nextNegoYear);
                }
                let simulationNumber = this.simulationNumber || 0;
                generateContractSimulationName({
                    createcontractwrapper_JSON: JSON.stringify({
                        sourceContract: sourceContract,
                        targetContractRTDeveloperName: targetContractRTDeveloperName,
                        simulationNumber: simulationNumber,
                    })
                }).then(result => {
                    this.contractSimulationName = result;
                    this.mainContractSimulationName = result;
                }).catch(error => {
                    console.error(error);
                    let msg = error;
                    if (error.body) {
                        msg = error.body.message;
                        if (error.body.message.includes('UNABLE_TO_LOCK_ROW')) {
                            msg = Labels.MSG_Error_Lock;
                        }
                    } else {
                        msg = error;
                        if (error.message && error.message.includes('UNABLE_TO_LOCK_ROW')) {
                            msg = Labels.MSG_Error_Lock;
                        }
                    }
                    self.dispatchEvent(new ShowToastEvent({
                        title: Labels.LBL_Error,
                        message: msg,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                });
                // this.contractSimulationName = (splittedContractName.length >= 2 ? splittedContractName[0].trim() + ' - ' + splittedContractName[1].trim() : sourceContract.Name) + ' - ' + this.negoYear + '- Simulation';
                // this.mainContractSimulationName = this.contractSimulationName;
                this.isTotalToRecalcAfterDateChange = sourceContract[API_NAMES.Contract__c.Is_TotalTo_Recalc_AfterDateChange__c];
                this.isFixCondRecalcAfterDateChange = sourceContract[API_NAMES.Contract__c.Is_FixCond_Recalc_AfterDateChange__c];
                this.isSetSimulationDataBeforeCreateNewModalOpen = true;
                _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'createNewContract' });
                return;
            }
            let beginDate = sourceContract[API_NAMES.Contract__c.Contract_BDate__c];
            let endDate = sourceContract[API_NAMES.Contract__c.Contract_EDate__c];
            let bDate = new Date(sourceContract[API_NAMES.Contract__c.Contract_BDate__c]);
            let eDate = new Date(sourceContract[API_NAMES.Contract__c.Contract_EDate__c]);
            let contractName = 'new Contract';
            if ((targetContractRTDeveloperName == 'Simulation' || targetContractRTDeveloperName == 'Safe_Balance') && this.isSetSimulationDataBeforeCreateNewModalOpen) {
                if (this.mainContractSimulationName != this.contractSimulationName) {
                    contractName = this.contractSimulationName;
                }
                bDate = new Date(this.contractBeginDate);
                beginDate = negoYear + '-' + (bDate.getUTCMonth() + 1) + '-' + bDate.getUTCDate();
                eDate = new Date(this.contractEndDate);
                endDate = eDate.getUTCFullYear() + '-' + (eDate.getUTCMonth() + 1) + '-' + eDate.getUTCDate();
                sourceContract[API_NAMES.Contract__c.Is_TotalTo_Recalc_AfterDateChange__c] = this.isTotalToRecalcAfterDateChange;
                sourceContract[API_NAMES.Contract__c.Is_FixCond_Recalc_AfterDateChange__c] = this.isFixCondRecalcAfterDateChange;
                this.isSetSimulationDataBeforeCreateNewModalOpen = false;
                this.contractBeginDate = undefined;
                this.contractEndDate = undefined;
                this.contractSimulationName = undefined;
                this.isTotalToRecalcAfterDateChange = undefined;
                this.isFixCondRecalcAfterDateChange = undefined;
            } else {
                endDate = negoYear + '-' + (eDate.getUTCMonth() + 1) + '-' + eDate.getUTCDate();
            }
            // validate contract dates
            let invalidDates = false;
            if (bDate > eDate) {
                invalidDates = true;
                self.dispatchEvent(new ShowToastEvent({
                    title: Labels.LBL_Error,
                    message: Labels.LBL_Invalid_Dates,
                    variant: ERROR_VARIANT,
                    mode: STICKY_VARIANT
                }));
            }
            if (invalidDates) {
                _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'createNewContract' });
                return;
            }
            if (targetContractRTDeveloperName == 'Period_Extension') {
                if (this.ontopBdate) {
                    let ontopBdate;
                    if (this.ontopBdate) {
                        ontopBdate = new Date(this.ontopBdate);
                        ontopBdate.setUTCMilliseconds(0);
                        ontopBdate.setUTCMinutes(0);
                        ontopBdate.setUTCSeconds(0);
                        ontopBdate.setUTCHours(0);
                    }
                    eDate = ontopBdate;
                    eDate.setDate(eDate.getDate() - 1);
                } else {
                    eDate = new Date(negoYear + '-02-28');
                    eDate.setDate(eDate.getDate() + 1);
                    if (eDate.getUTCMonth() == 2) {
                        eDate.setDate(eDate.getDate() - 1);
                    }
                }
                bDate = new Date(negoYear + '-01-01');
                endDate = negoYear + '-' + (eDate.getUTCMonth() + 1) + '-' + eDate.getUTCDate();
            }
            // if (bDate.getFullYear() < negoYear) {
            beginDate = negoYear + '-' + (bDate.getUTCMonth() + 1) + '-' + bDate.getUTCDate();
            //endDate = negoYear + '-' + (eDate.getUTCMonth() + 1) + '-' + eDate.getUTCDate();
            // }
            let simulationNumber = this.simulationNumber || 0;
            let postSimulationNumber = this.postSimulationNumber || 0;
            let refContractBUId = this.refContractBUId;
            let refContractSourceBUId = this.refContractSourceBUId;
            this.isNewContractModelOpen = false;
            this.selectedNewContractDeveloperName = undefined;
            if (targetContractRTDeveloperName == 'Period_Extension') {
                _fireEvent(this.pageRef, 'lockLoadingLockedActions');
            }
            createContract({
                createcontractwrapper_JSON: JSON.stringify({
                    nsId: nsId,
                    negoYear: negoYear,
                    refNegoBase: refNegoBase,
                    contractPE: contractPE,
                    sourceContract: sourceContract,
                    refDiscountsList: refDiscountsList,
                    targetContractRTDeveloperName: targetContractRTDeveloperName,
                    contractName: contractName,
                    beginDate: beginDate,
                    endDate: endDate,
                    simulationNumber: simulationNumber,
                    postSimulationNumber: postSimulationNumber,
                    refContractBUId: refContractBUId,
                    refContractSourceBUId: refContractSourceBUId,
                })
            }).then(result => {
                if (targetContractRTDeveloperName == 'Period_Extension') {
                    _fireEvent(self.pageRef, 'updateHasPe');
                }
                _fireEvent(self.pageRef, 'triggerContractLoading' + (self.contractId || 0), { isLoading: false, fname: 'createNewContract' });
                _fireEvent(self.pageRef, 'handleNewContract', JSON.parse(result));
                if (hasOnTop && targetContractRTDeveloperName == 'Period_Extension') {
                    _fireEvent(self.pageRef, 'consolidateContracts');
                    // _fireEvent(self.pageRef, 'requireConso');
                }
            }).catch(error => {
                console.error(error);
                let msg = error;
                if (error.body) {
                    msg = error.body.message;
                    if (error.body.message.includes('UNABLE_TO_LOCK_ROW')) {
                        msg = Labels.MSG_Error_Lock;
                    }
                } else {
                    msg = error;
                    if (error.message && error.message.includes('UNABLE_TO_LOCK_ROW')) {
                        msg = Labels.MSG_Error_Lock;
                    }
                }
                self.dispatchEvent(new ShowToastEvent({
                    title: Labels.LBL_Error,
                    message: msg,
                    variant: ERROR_VARIANT,
                    mode: STICKY_VARIANT
                }));
                if (targetContractRTDeveloperName == 'Period_Extension') {
                    _fireEvent(self.pageRef, 'unlockLoadingLockedActions');
                }
                _fireEvent(self.pageRef, 'triggerContractLoading' + (self.contractId || 0), { isLoading: false, fname: 'createNewContract' });
            });
        } catch (error) {
            console.error('ERROR: ' + error);
        }
    }
    openEditConditionModel(event) {
        this.hasChanges = true;
        _fireEvent(this.pageRef, 'hasChanges', {});
        let isPE = this.isPE;
        let contract = this.contract;
        let isSimulation = this.isSimulation;
        let validTariffConditionMap = this.validTariffConditionMap;
        let readOnly = this.readOnly;
        let userProfileId = this.userProfileId;
        let index = event.target.dataset.rowindex;
        let negotiateIndex = event.target.dataset.index;
        let negotiateType = event.target.dataset.negotiatetype;
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                this.mapKey = negotiateIndex + '-' + negotiateType + '-' + index;
                this.oldCondition = negoType.conditions[index];
                this.currentCondition = JSON.parse(JSON.stringify(negoType.conditions[index]));
                this.currentCondition = setNegotiateConditionFields(this.currentCondition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, negoType, userProfileId);
                this.nsPopUp.selectedDataName = this.currentCondition[API_NAMES.Contract_Discount__c.Product_Scope__r]?.Name;
                this.buPopUp.selectedDataName = this.currentCondition[API_NAMES.Contract_Discount__c.BusinessUnitScope__r]?.Name;
            }
        }
        if (this.refArraysCondtion) {
            let refNegoIndex = this.refArraysCondtion.find(item => item.key == negotiateIndex);
            if (refNegoIndex) {
                let refnegoType = refNegoIndex.negodiscounts.find(item => item.key == negotiateType);
                if (refnegoType && refnegoType.conditions && refnegoType.conditions.length > index) {
                    this.refCurrentCondition = JSON.parse(JSON.stringify(refnegoType.conditions[index]));
                    this.refCurrentCondition = setNegotiateConditionFields(this.refCurrentCondition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, refnegoType, userProfileId);
                }
            }
        }
        this.popupColClass = 'slds-col' + (this.refCurrentCondition ? ' slds-size_1-of-2' : ' slds-size_1-of-1');
        // to open modal set isEditConditionModelOpen tarck value as true
        this.isEditConditionModelOpen = true;
    }
    openEditSlabsConditionModel(event) {
        this.hasChanges = true;
        _fireEvent(this.pageRef, 'hasChanges', {});
        let isPE = this.isPE;
        let contract = this.contract;
        let validTariffConditionMap = this.validTariffConditionMap;
        let readOnly = this.readOnly;
        let userProfileId = this.userProfileId;
        let isSimulation = this.isSimulation;
        let index = event.target.dataset.rowindex;
        let negotiateIndex = event.target.dataset.index;
        let negotiateType = event.target.dataset.negotiatetype;
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                this.mapKey = negotiateIndex + '-' + negotiateType + '-' + index;
                this.oldCondition = negoType.conditions[index];
                let currentCondition = JSON.parse(JSON.stringify(negoType.conditions[index]));
                currentCondition = setNegotiateConditionFields(currentCondition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, negoType, userProfileId);
                currentCondition.slabs = [];
                for (let slabIndex = 1; slabIndex <= 10; slabIndex++) {
                    currentCondition.slabs.push({
                        fields: [
                            { fieldApiName: API_NAMES.Contract_Discount__c['Slab_' + slabIndex + '__c'], value: currentCondition[API_NAMES.Contract_Discount__c['Slab_' + slabIndex + '__c']] },
                            { fieldApiName: API_NAMES.Contract_Discount__c['slab_per_' + slabIndex + '__c'], value: currentCondition[API_NAMES.Contract_Discount__c['slab_per_' + slabIndex + '__c']] },
                            { fieldApiName: API_NAMES.Contract_Discount__c['Slab_Val_' + slabIndex + '__c'], value: currentCondition[API_NAMES.Contract_Discount__c['Slab_Val_' + slabIndex + '__c']] },
                        ],
                        index: slabIndex,
                        isSelected: slabIndex == currentCondition[API_NAMES.Contract_Discount__c.slab_target__c],
                    });
                }
                this.showSlabsCurrency = currentCondition[API_NAMES.Contract_Discount__c.slab_calc_method__c] ? currentCondition[API_NAMES.Contract_Discount__c.slab_calc_method__c].toLocaleLowerCase().includes('to') : false;
                this.showSlabsUnitType = currentCondition[API_NAMES.Contract_Discount__c.slab_calc_method__c] ? currentCondition[API_NAMES.Contract_Discount__c.slab_calc_method__c].toLocaleLowerCase().includes('qty') : false;
                this.currentCondition = currentCondition;
            }
        }
        // to open modal set isEditSlabsConditionModelOpen tarck value as true
        this.isEditSlabsConditionModelOpen = true;
    }
    closeEditConditionModel() {
        this.mapKey = undefined;
        this.oldCondition = undefined;
        this.currentCondition = undefined;
        this.refCurrentCondition = undefined;
        this.isEditConditionModelOpen = false;
        this.popupColClass = 'slds-col slds-size_1-of-2';
    }
    closeEditSlabsConditionModel() {
        this.mapKey = undefined;
        this.oldCondition = undefined;
        this.currentCondition = undefined;
        this.refCurrentCondition = undefined;
        this.isEditSlabsConditionModelOpen = false;
    }
    @track fakesaveLoading = false;
    submitEditConditionChanged() {
        let contractId = this.contractId;
        let changesMap = this.changesMap;
        let mapKey = this.mapKey;
        let self = this;
        this.fakesaveLoading = true;
        let oldCondition = this.oldCondition;
        let _oldCondition = { ...this.oldCondition };
        let currentCondition = this.currentCondition;
        let missingValues = true;
        Object.keys(currentCondition).forEach(key => {
            try {
                if (_oldCondition[key] != currentCondition[key]) {
                    _oldCondition[key] = currentCondition[key];
                    if (currentCondition[API_NAMES.Contract_Discount__c.Value_per__c]
                        || currentCondition[API_NAMES.Contract_Discount__c.Value_amt__c]
                        || currentCondition[API_NAMES.Contract_Discount__c.unit_amount__c]) {
                        missingValues = false;
                    }
                }
            } catch (error) { }
        });
        if (missingValues) {
            this.dispatchEvent(new ShowToastEvent({
                message: Labels.MSG_Missing_Remuneration,
                variant: ERROR_VARIANT,
            }));
            self.fakesaveLoading = false;
        } else {
            _fireEvent(this.pageRef, 'fakesave_' + contractId, {
                condition: _oldCondition,
                errorCallback: () => {
                    self.fakesaveLoading = false;
                },
                successCallback: () => {
                    self.fakesaveLoading = false;
                    Object.keys(currentCondition).forEach(key => {
                        try {
                            if (oldCondition[key] != currentCondition[key]) {
                                oldCondition[key] = currentCondition[key];
                            }
                        } catch (error) {
                        }
                    });
                    changesMap[mapKey] = oldCondition;
                    oldCondition.detailPopupFields = this.detailPopupFields.map(item => {
                        let newItem = { ...item };
                        newItem.value = oldCondition[item.fieldApiName];
                        newItem.hasValue = oldCondition[item.fieldApiName] ? true : false;
                        return newItem;
                    });
                    self.mapKey = undefined;
                    self.oldCondition = undefined;
                    self.currentCondition = undefined;
                    self.refCurrentCondition = undefined;
                    self.isEditConditionModelOpen = false;
                    self.popupColClass = 'slds-col slds-size_1-of-2';
                    if (self.calculateIndex) {
                        clearTimeout(self.calculateIndexTimeOut);
                        self.calculateIndexTimeOut = setTimeout(() => {
                            self.calculateIndex();
                        }, CALCULATE_INDEX_TIMEOUT);
                    }
                },
            });
        }
    }
    submitEditSlabsConditionChanged() {
        let contractId = this.contractId;
        let mapKey = this.mapKey;
        let changesMap = this.changesMap;
        let self = this;
        delete this.currentCondition.slabs;
        let oldCondition = { ...this.oldCondition };
        let currentCondition = this.currentCondition;
        let contract = this.contract;
        currentCondition = reachProgressiveSlab(currentCondition, contract);
        Object.keys(currentCondition).forEach(key => {
            try {
                if (oldCondition[key] != currentCondition[key]) {
                    oldCondition[key] = currentCondition[key];
                }
            } catch (error) {
            }
        });
        oldCondition.detailPopupFields = this.detailPopupFields.map(item => {
            let newItem = { ...item };
            newItem.value = oldCondition[item.fieldApiName];
            newItem.hasValue = oldCondition[item.fieldApiName] ? true : false;
            return newItem;
        });
        _fireEvent(this.pageRef, 'fakesave_' + contractId, {
            condition: oldCondition,
            successCallback: () => {
                self.oldCondition = oldCondition;
                changesMap[mapKey] = self.oldCondition;
                self.mapKey = undefined;
                self.oldCondition = undefined;
                self.currentCondition = undefined;
                self.refCurrentCondition = undefined;
                self.isEditSlabsConditionModelOpen = false;
                if (self.calculateIndex) {
                    clearTimeout(self.calculateIndexTimeOut);
                    self.calculateIndexTimeOut = setTimeout(() => {
                        self.calculateIndex();
                    }, CALCULATE_INDEX_TIMEOUT);
                }
            },
        });
    }
    handleEditConditionValueChange(event) {
        let contract = this.contract;
        if (event?.target?.dataset?.fieldApiName) {
            this.currentCondition[event.target.dataset.fieldApiName] = event.target.value;
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Disc_BDate__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = event.target.value;
            }
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Disc_EDate__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = event.target.value;
            }
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = event.target.value;
            }
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Value_amt__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = event.target.value;
            }
            if (this.currentCondition.respectScope) {
                let baseTo = 0;
                [
                    API_NAMES.Contract__c.TO1__c,
                    API_NAMES.Contract__c.TO2__c,
                    API_NAMES.Contract__c.TO3__c,
                    API_NAMES.Contract__c.TO4__c,
                    API_NAMES.Contract__c.TO5__c,
                    API_NAMES.Contract__c.TO6__c,
                    API_NAMES.Contract__c.TO7__c,
                    API_NAMES.Contract__c.TO8__c,
                    API_NAMES.Contract__c.TO9__c,
                    API_NAMES.Contract__c.TO10__c,
                    API_NAMES.Contract__c.TO11__c,
                    API_NAMES.Contract__c.TO12__c,
                ].forEach(keyField => {
                    baseTo += contract[keyField] || 0;
                });
                if (this.currentCondition[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] != baseTo) {
                    this.currentCondition[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = baseTo;
                }
                let qty = 0;
                [
                    API_NAMES.Contract__c.Qty1__c,
                    API_NAMES.Contract__c.Qty2__c,
                    API_NAMES.Contract__c.Qty3__c,
                    API_NAMES.Contract__c.Qty4__c,
                    API_NAMES.Contract__c.Qty5__c,
                    API_NAMES.Contract__c.Qty6__c,
                    API_NAMES.Contract__c.Qty7__c,
                    API_NAMES.Contract__c.Qty8__c,
                    API_NAMES.Contract__c.Qty9__c,
                    API_NAMES.Contract__c.Qty10__c,
                    API_NAMES.Contract__c.Qty11__c,
                    API_NAMES.Contract__c.Qty12__c,
                ].forEach(keyField => {
                    qty += contract[keyField] || 0;
                });
                if (this.currentCondition[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] != qty) {
                    this.currentCondition[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = qty;
                }
            }
        }
    }
    get slabsMethodOptions() {
        let slabsMethodMap = this.slabsMethodMap;
        return (this.currentCondition[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Conditional_Slab_Method__c] || '').split(';').map(methodAPI => ({ value: methodAPI, label: slabsMethodMap[methodAPI] || methodAPI })).sort((item1, item2) => item1.label.localeCompare(item2.label));
    }
    handleEditSlabsConditionValueChange(event) {
        if (event?.target?.dataset?.fieldApiName) {
            if (event?.target?.dataset?.index) {
                this.currentCondition[event?.target?.dataset?.fieldApiName] = event.target.value;
                let slab = this.currentCondition.slabs.find(slab => slab.index == event?.target?.dataset?.index);
                if (slab) {
                    slab.fields.forEach(field => {
                        if (field.fieldApiName == event?.target?.dataset?.fieldApiName) {
                            field.value = event.target.value;
                        }
                    })
                }
            } else {
                this.currentCondition[event?.target?.dataset?.fieldApiName] = event.target.value;
                if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.slab_calc_method__c) {
                    this.showSlabsCurrency = event.target.value.toLocaleLowerCase().includes('to');
                    this.showSlabsUnitType = event.target.value.toLocaleLowerCase().includes('qty');
                }
            }
        }
    }
    handleEditSlabsConditionSelect(event) {
        this.currentCondition.slabs.forEach(slab => slab.isSelected = (slab.index == event?.target?.dataset?.index));
        this.currentCondition[API_NAMES.Contract_Discount__c.slab_target__c] = event?.target?.dataset?.index;
    }
    handleDetailEditConditionValueChange(event) {
        let contract = this.contract;
        if (event?.target?.dataset?.fieldApiName) {
            this.currentCondition[event.target.dataset.fieldApiName] = event.target.value;
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Disc_BDate__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = event.target.value;
            }
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Disc_EDate__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = event.target.value;
            }
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = event.target.value;
            }
            if (event?.target?.dataset?.fieldApiName == API_NAMES.Contract_Discount__c.Value_amt__c) {
                this.currentCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = event.target.value;
            }
            if (this.currentCondition.respectScope) {
                let baseTo = 0;
                [
                    API_NAMES.Contract__c.TO1__c,
                    API_NAMES.Contract__c.TO2__c,
                    API_NAMES.Contract__c.TO3__c,
                    API_NAMES.Contract__c.TO4__c,
                    API_NAMES.Contract__c.TO5__c,
                    API_NAMES.Contract__c.TO6__c,
                    API_NAMES.Contract__c.TO7__c,
                    API_NAMES.Contract__c.TO8__c,
                    API_NAMES.Contract__c.TO9__c,
                    API_NAMES.Contract__c.TO10__c,
                    API_NAMES.Contract__c.TO11__c,
                    API_NAMES.Contract__c.TO12__c,
                ].forEach(keyField => {
                    baseTo += contract[keyField] || 0;
                });
                if (this.currentCondition[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] != baseTo) {
                    this.currentCondition[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = baseTo;
                }
                let qty = 0;
                [
                    API_NAMES.Contract__c.Qty1__c,
                    API_NAMES.Contract__c.Qty2__c,
                    API_NAMES.Contract__c.Qty3__c,
                    API_NAMES.Contract__c.Qty4__c,
                    API_NAMES.Contract__c.Qty5__c,
                    API_NAMES.Contract__c.Qty6__c,
                    API_NAMES.Contract__c.Qty7__c,
                    API_NAMES.Contract__c.Qty8__c,
                    API_NAMES.Contract__c.Qty9__c,
                    API_NAMES.Contract__c.Qty10__c,
                    API_NAMES.Contract__c.Qty11__c,
                    API_NAMES.Contract__c.Qty12__c,
                ].forEach(keyField => {
                    qty += contract[keyField] || 0;
                });
                if (this.currentCondition[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] != qty) {
                    this.currentCondition[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = qty;
                }
            }
        }
    }
    get headerClass() {
        if (this.isOnTopSimulation) {
            return 'conditionTable_On_Top';
        } else {
            return 'conditionTable_' + (this.contract?.RecordType?.DeveloperName ? this.contract?.RecordType?.DeveloperName.replace(/_/g, '-').toLocaleLowerCase() : '');
        }
    }
    // toggleShowEdit(event) {
    // let isLast = this.isLast;
    // let detailPopupFields = this.detailPopupFields;
    // let index = event.target.dataset.rowindex;
    // let negotiateIndex = event.target.dataset.index;
    // let negotiateType = event.target.dataset.negotiatetype;
    // let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
    // if (negoIndex) {
    // let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
    // if (negoType && negoType.conditions && negoType.conditions.length > index) {
    // negoType.conditions[index].detailPopupFields = detailPopupFields.map(item => {
    // let newItem = { ...item };
    // newItem.value = negoType.conditions[index][item.fieldApiName];
    // newItem.hasValue = negoType.conditions[index][item.fieldApiName] ? true : false;
    // return newItem;
    // });
    // negoType.conditions[index].hideInfo = true;
    // negoType.conditions[index].passedFirstLoad = true;
    // if (!isLast) {
    // negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_left-top';
    // negoType.conditions[index].popOverStyle = 'position: absolute; top: -20px; left: 125px;';
    // } else {
    // negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_right-top';
    // negoType.conditions[index].popOverStyle = 'position: absolute; top: -20px; left: -295px;';
    // }
    // }
    // }
    // }
    // toggleShowInfo(event) {
    // // let isLast = this.isLast;
    // let index = event.target.dataset.rowindex;
    // let negotiateIndex = event.target.dataset.index;
    // let negotiateType = event.target.dataset.negotiatetype;
    // let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
    // if (negoIndex) {
    // let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
    // if (negoType && negoType.conditions && negoType.conditions.length > index) {
    // negoType.conditions[index].hideInfo = false;
    // if (!isLast) {
    // negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_left-top slds-hide';
    // negoType.conditions[index].popOverStyle = 'position: absolute; top: -20px; left: 125px;';
    // } else {
    // negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_right-top slds-hide';
    // negoType.conditions[index].popOverStyle = 'position: absolute; top: -20px; left: -295px;';
    // }
    // delete negoType.conditions[index].detailPopupFields;
    // }
    // }
    // }
    toggleShowEdit(event) {
        let isLast = this.isLast;
        let detailPopupFields = this.detailPopupFields;
        let index = event.target.dataset.rowindex;
        let negotiateIndex = event.target.dataset.index;
        let negotiateType = event.target.dataset.negotiatetype;
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                negoType.conditions[index].detailPopupFields = detailPopupFields.map(item => {
                    let newItem = { ...item };
                    newItem.value = negoType.conditions[index][item.fieldApiName];
                    newItem.hasValue = negoType.conditions[index][item.fieldApiName] ? true : false;
                    return newItem;
                });
                negoType.conditions[index].hideInfo = true;
                negoType.conditions[index].passedFirstLoad = true;
                let deleteIcon = this.template.querySelector(".delete-icon");
                if (!isLast) {
                    negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_bottom-left ';
                    negoType.conditions[index].popOverStyle = 'position: absolute;bottom: calc(0.5rem + 100%);right:' + ((deleteIcon != null) ? -250 : -277) + 'px;background:white;border-left:none;border-right:none;';
                } else {
                    negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_bottom-right ';
                    negoType.conditions[index].popOverStyle = 'position: absolute;bottom: calc(0.5rem + 100%);right:' + ((deleteIcon != null) ? 20 : 5) + 'px;background:white;border-left:none;border-right:none;';
                }
            }
        }
    }
    toggleShowInfo(event) {
        let isLast = this.isLast;
        let index = event.target.dataset.rowindex;
        let negotiateIndex = event.target.dataset.index;
        let negotiateType = event.target.dataset.negotiatetype;
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                negoType.conditions[index].hideInfo = false;
                let deleteIcon = this.template.querySelector(".delete-icon");
                if (!isLast) {
                    negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_bottom-left slds-hide';
                    negoType.conditions[index].popOverStyle = 'position: absolute;bottom: calc(0.5rem + 100%);right:' + ((deleteIcon != null) ? -250 : -277) + 'px;background:white;border-left:none;border-right:none;';
                } else {
                    negoType.conditions[index].popOverClass = 'force-read-only-style slds-popover slds-popover_panel slds-nubbin_bottom-right slds-hide';
                    negoType.conditions[index].popOverStyle = 'position: absolute;bottom: calc(0.5rem + 100%);right:' + ((deleteIcon != null) ? 20 : 5) + 'px;background:white;border-left:none;border-right:none;';
                }
                delete negoType.conditions[index].detailPopupFields;
            }
        }
    }
    disconnectedCallback() {
        // unsubscribe from inputChangeEvent event
        unregisterAllListeners(this);
    }
    blockSubmit(event) {
        if (event.keyCode == 13) {
            event.preventDefault();
            return false;
        }
    }
    connectedCallback() {
        globalMethods._fireEvent = (pageref, eventName, details) => {
            fireEvent(pageref, eventName + '_' + this.nonce, details);
        }
        globalMethods._registerListener = (eventName, callback, cmpInstance) => {
            registerListener(eventName + '_' + this.nonce, callback, cmpInstance);
        }
        _registerListener('unlockLoadingLockedActions', () => {
            this.loadingLockedActions = false;
        }, this);
        _registerListener('resetContractChanges', () => {
            let recordedChange = Object.keys(this.changesMap).length || this.hasContractChanges || this.hasChanges ? true : false;
            this.changesMap = {};
            this.hasContractChanges = false;
            this.hasChanges = false;
            if (recordedChange) {
                this._refreshData(true);
            }
        }, this);
        _registerListener('lockLoadingLockedActions', () => {
            this.loadingLockedActions = true;
        }, this);
        let processFakeSave;
        let contractId = this.contractId;
        _registerListener('fakesave_' + contractId, ({ condition, successCallback, errorCallback }) => {
            try {
                clearTimeout(processFakeSave);
            } catch (error) {
            }
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'fakesave_' + contractId });
            let c_condition = { ...condition };
            delete c_condition.detailPopupFields;
            delete c_condition.Condition_Type;
            delete c_condition.contract;
            delete c_condition.popOverClass;
            delete c_condition.hideInfo;
            delete c_condition.class;
            delete c_condition.isDisplayed;
            processFakeSave = setTimeout(() => {
                fakeSaveContractDiscountData({ contractDiscounts_JSON: JSON.stringify([c_condition]) }).then(result => {
                    let dmlResults = JSON.parse(result);
                    if (!dmlResults.isSuccess) {
                        if (dmlResults.errors) {
                            let errorMessages = dmlResults.errors.filter((item, index) => index == dmlResults.errors.indexOf(item));
                            let msg = errorMessages.join('\n');
                            msg = msg.includes('UNABLE_TO_LOCK_ROW') ? Labels.MSG_Error_Lock : msg;
                            this.dispatchEvent(new ShowToastEvent({
                                message: msg,
                                variant: ERROR_VARIANT,
                                mode: STICKY_VARIANT
                            }));
                        }
                        if (errorCallback) {
                            errorCallback();
                        }
                    } else if (successCallback) {
                        successCallback();
                    }
                    _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'fakesave_' + contractId });
                }).catch(error => {
                    _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'fakesave_' + contractId });
                    console.error(error);
                });
            }, 200);
        }, this);
        _registerListener('refresh_walkthrought_position', () => {
            if (this.isRefNegoBase) {
                let cloneIcon = this.template.querySelector(`[data-id="cloneIcon"]`);
                if (cloneIcon) {
                    if (cloneIcon.getBoundingClientRect().top && cloneIcon.getBoundingClientRect().left) {
                        _fireEvent(this.pageRef, 'ref_contract_clone_icon', {
                            top: cloneIcon.getBoundingClientRect().top,
                            left: cloneIcon.getBoundingClientRect().left,
                        });
                    }
                }
            }
        }, this);
        _registerListener('updateHasPEOnRefresh', ({ hasPe }) => {
            this.hasPe = hasPe;
        }, this);
        _registerListener('updateHasPESignedOnRefresh', ({ hasPeSigned }) => {
            this.hasPeSigned = hasPeSigned;
        }, this);
        _registerListener('triggerContractLoading' + (this.contractId || 0), ({ isLoading, fname }) => {
            if (fname && isLoading) {
                this.LoadingMap[fname] = isLoading;
            }
            if (isLoading) {
                clearTimeout(this.loadingTimeOut);
                this.Loading = isLoading;
            } else {
                delete this.LoadingMap[fname];
                clearTimeout(this.loadingTimeOut);
                this.loadingTimeOut = setTimeout(() => {
                    this.Loading = Object.keys(this.LoadingMap).length != 0;
                }, LOADING_TIME_OUT);
            }
        }, this);
        _registerListener('refreshAfterConso', () => {
            if (this.isNegoBaseInitNegoYear
                || this.isLandingNegoYear
                || this.isNegoBaseNegoYear) {
                this._refreshData(true);
            }
            if (this.isPENegoYear || this.isOnTopNegoYear) {
                let contractId = this.contractId;
                _fireEvent(this.pageRef, 'triggerContractLoading' + (contractId || 0), { isLoading: true, fname: 'refreshAfterConso' });
                calculateIndexAndSave({ contractId: contractId }).then(result => {
                    _fireEvent(this.pageRef, 'triggerContractLoading' + (contractId || 0), { isLoading: false, fname: 'refreshAfterConso' });
                    this._refreshData(true);
                }).catch(error => {
                    _fireEvent(this.pageRef, 'triggerContractLoading' + (contractId || 0), { isLoading: false, fname: 'refreshAfterConso' });
                });
            }
        }, this);
        _registerListener('calculateAllIndexes', () => {
            if (this.calculateIndex) {
                let self = this;
                clearTimeout(this.calculateIndexTimeOut);
                this.calculateIndexTimeOut = setTimeout(() => {
                    self.calculateIndex();
                }, CALCULATE_INDEX_TIMEOUT);
            }
        }, this);
        _registerListener('setNegoPlanFromContracts', ({ riseRateDiff, depreciationRiseRateDiff }) => {
            this.riseRateDiff = riseRateDiff;
            this.depreciationRiseRateDiff = depreciationRiseRateDiff;
            this.depreciationRateClass = '';
            if (!isNaN(this.depreciationRiseRateDiff)) {
                this.depreciationRateClass = this.depreciationRiseRateDiff != (this.contract[API_NAMES.Contract__c.Depreciation_Rate__c] || 0) ? 'has-error-rate' : '';
            }
            this.riseRateClass = '';
            if (!isNaN(this.riseRateDiff)) {
                this.riseRateClass = this.riseRateDiff != (this.contract[API_NAMES.Contract__c.Rise_Rate__c] || 0) ? 'has-error-rate' : '';
            }
        }, this);
        _registerListener('setOnTopDatesFromContracts', ({ bDate, eDate }) => {
            this.ontopBdate = bDate;
            this.ontopEdate = eDate;
        }, this);
        _registerListener('setPTDatesFromContracts', ({ bDate, eDate }) => {
            this.ptBdate = bDate;
            this.ptEdate = eDate;
        }, this);
        _registerListener('RevalidatePT', ({ }) => {
            if (this.contract.RecordType.DeveloperName == 'Period_Extension') {
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: true, fname: 'RevalidatePT' });
                validatePeriodExtension({ ptContractId: this.contract.Id }).then((result) => {
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'RevalidatePT' });
                    _fireEvent(self.pageRef, 'consolidateContracts');
                    // _fireEvent(self.pageRef, 'requireConso');
                    let dmlResults = JSON.parse(result);
                    if (dmlResults.errors) {
                        let errorMessages = dmlResults.errors.filter((item, index) => index == dmlResults.errors.indexOf(item));
                        if (errorMessages && errorMessages.length) {
                            self.dispatchEvent(new ShowToastEvent({
                                title: Labels.LBL_Error,
                                message: errorMessages.join('\n'),
                                variant: ERROR_VARIANT,
                                mode: STICKY_VARIANT
                            }));
                        }
                    }
                }).catch(error => {
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'RevalidatePT' });
                    console.error(error);
                    let msg = error;
                    if (error.body) {
                        msg = error.body.message;
                        if (error.body.message.includes('UNABLE_TO_LOCK_ROW')) {
                            msg = Labels.MSG_Error_Lock;
                        }
                    } else {
                        msg = error;
                        if (error.message && error.message.includes('UNABLE_TO_LOCK_ROW')) {
                            msg = Labels.MSG_Error_Lock;
                        }
                    }
                    self.dispatchEvent(new ShowToastEvent({
                        title: Labels.LBL_Error,
                        message: msg,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                });
            }
        }, this);
        _registerListener('setRefToQtyDurationFromContracts', ({ refTO, refQty, refDuration }) => {
            this.refTO = refTO;
            this.refQty = refQty;
            this.refDuration = refDuration;
            _fireEvent(this.pageRef, 'calculateGap', {});
        }, this);
        _registerListener('setSafeBalanceToQtyDurationFromContracts', ({ safeBalanceTO, safeBalanceQty, safeBalanceDuration }) => {
            this.safeBalanceTO = safeBalanceTO;
            this.safeBalanceQty = safeBalanceQty;
            this.safeBalanceDuration = safeBalanceDuration;
            _fireEvent(this.pageRef, 'calculateGap', {});
        }, this);
        _registerListener('setNegoPlan', ({ riseRateDiff, depreciationRiseRateDiff }) => {
            this.riseRateDiff = riseRateDiff;
            this.depreciationRiseRateDiff = depreciationRiseRateDiff;
            this.depreciationRateClass = '';
            if (!isNaN(this.depreciationRiseRateDiff)) {
                this.depreciationRateClass = this.depreciationRiseRateDiff != (this.contract[API_NAMES.Contract__c.Depreciation_Rate__c] || 0) ? 'has-error-rate' : '';
            }
            this.riseRateClass = '';
            if (!isNaN(this.riseRateDiff)) {
                this.riseRateClass = this.riseRateDiff != (this.contract[API_NAMES.Contract__c.Rise_Rate__c] || 0) ? 'has-error-rate' : '';
            }
        }, this);
        _registerListener('lockedByApprovalProcess', ({ isActive }) => {
            this.lockedByApprovalProcess = isActive;
            this.lockedActions |= this.lockedByApprovalProcess;
        }, this);
        _registerListener('updateHasPe', () => {
            this.hasPe = true;
        }, this);
        _registerListener('updateHasPESigned', () => {
            this.hasPeSigned = true;
        }, this);
        _registerListener('calculate_index_done_' + this.contractId, (wIndex) => {
            this.wIndex = wIndex;
            let grouppedConditions = this.arraysCondtion;
            for (let index of grouppedConditions) {
                let currentIndex = wIndex.values.find(item => item.indexName == index.key);
                if (currentIndex) {
                    index.percent = currentIndex.IndexPerc;
                    index.computedAmount = currentIndex.Computed;
                    index.indexVal = currentIndex.Index;
                }
            }
        }, this);
        _registerListener('setRefNegoBaseIndex1', negoBaseRefIndex1 => {
            if (this.negoBaseRefIndex1 != negoBaseRefIndex1) {
                this.negoBaseRefIndex1 = negoBaseRefIndex1;
                _fireEvent(this.pageRef, 'recalculateFolding', {});
            }
        }, this);
        _registerListener('calculateGap', () => {
            {
                if (this.refTO) {
                    //difference between current contract and nego base
                    this.diffTO = (this.purchase - this.refTO) / this.refTO;
                    let prorataRefValue = this.refDuration && this.duration ? this.refTO / this.refDuration * this.duration : 0;
                    this.gapTO = prorataRefValue ? (this.purchase - prorataRefValue) / prorataRefValue : 0;
                } else {
                    this.diffTO = 0;
                    this.gapTO = 0;
                }
                if (this.safeBalanceTO) {
                    if (!this.isSafeBalance) {
                        //difference between current contract and safe balance
                        let prorataSBValue = this.safeBalanceDuration && this.duration ? this.safeBalanceTO / this.safeBalanceDuration * this.duration : 0;
                        this.gapSBTO = prorataSBValue ? (this.purchase - prorataSBValue) / prorataSBValue : 0;
                    } else {
                        this.gapSBTO = 0;
                    }
                } else {
                    this.gapSBTO = 0;
                }
                if (this.readOnly) {
                    this.diffTO = 0;
                    this.gapTO = 0;
                    this.gapSBTO = 0;
                }
                // this.gapTOStyle = this.diffTO ? (this.diffTO < 0 ? 'color: red;' : 'color: green;') + ' !important' : 'visibility: hidden!important;';
                // this.gapTOStyle = (this.diffTO < 0 ? 'color: red;' : 'color: green;') + ' !important';
                this.gapTOStyle = !this.diffTO || isNaN(this.safeBalanceTO) ? 'visibility: hidden;' : (this.diffTO < 0 ? 'color: red;' : 'color: green;') + ' !important';
                // this.gapSBTOStyle = this.gapSBTO ? 'color:#A167F4 !important;' : 'visibility: hidden!important;';
                // this.gapSBTOStyle = 'color:#A167F4 !important;';
                this.gapSBTOStyle = !this.gapSBTO ? 'visibility: hidden;' : 'color:#A167F4 !important;';
            }
            {
                if (this.refQty) {
                    //difference between current contract and nego base
                    this.diffQty = (this.quantity - this.refQty) / this.refQty;
                    let prorataRefValue = this.refDuration && this.duration ? this.refQty / this.refDuration * this.duration : 0;
                    this.gapQty = prorataRefValue ? (this.quantity - prorataRefValue) / prorataRefValue : 0;
                } else {
                    this.diffQty = 0;
                    this.gapQty = 0;
                }
                if (this.safeBalanceQty) {
                    if (!this.isSafeBalance) {
                        //difference between current contract and safe balance
                        let prorataSBValue = this.safeBalanceDuration && this.duration ? this.safeBalanceQty / this.safeBalanceDuration * this.duration : 0;
                        this.gapSBQty = prorataSBValue ? (this.quantity - prorataSBValue) / prorataSBValue : 0;
                    } else {
                        this.gapSBQty = 0;
                    }
                } else {
                    this.gapSBQty = 0;
                }
                if (this.readOnly) {
                    this.diffQty = 0;
                    this.gapQty = 0;
                    this.gapSBQty = 0;
                }
                // this.gapQtyStyle = this.diffQty ? (this.diffQty < 0 ? 'color: red;' : 'color: green;') + ' !important' : 'visibility: hidden!important;';
                // this.gapQtyStyle = (this.diffQty < 0 ? 'color: red;' : 'color: green;') + ' !important';
                this.gapQtyStyle = !this.diffQty || isNaN(this.safeBalanceQty) ? 'visibility: hidden;' : (this.diffQty < 0 ? 'color: red;' : 'color: green;') + ' !important';
                // this.gapSBQtyStyle = this.gapSBQty ? 'color:#A167F4 !important;' : 'visibility: hidden!important;';
                // this.gapSBQtyStyle = 'color:#A167F4 !important;';
                this.gapSBQtyStyle = !this.gapSBQty ? 'visibility: hidden;' : 'color:#A167F4 !important;';
            }
            this.depreciationRateClass = '';
            if (!isNaN(this.depreciationRiseRateDiff)) {
                this.depreciationRateClass = this.depreciationRiseRateDiff != (this.contract[API_NAMES.Contract__c.Depreciation_Rate__c] || 0) ? 'has-error-rate' : '';
            }
            this.riseRateClass = '';
            if (!isNaN(this.riseRateDiff)) {
                this.riseRateClass = this.riseRateDiff != (this.contract[API_NAMES.Contract__c.Rise_Rate__c] || 0) ? 'has-error-rate' : '';
            }
        }, this);
        _registerListener('setRefToQtyDuration', ({ refTO, refQty, refDuration }) => {
            this.refTO = refTO;
            this.refQty = refQty;
            this.refDuration = refDuration;
            _fireEvent(this.pageRef, 'calculateGap', {});
        }, this);
        _registerListener('setSafeBalanceToQtyDuration', ({ safeBalanceTO, safeBalanceQty, safeBalanceDuration }) => {
            this.safeBalanceTO = safeBalanceTO;
            this.safeBalanceQty = safeBalanceQty;
            this.safeBalanceDuration = safeBalanceDuration;
            _fireEvent(this.pageRef, 'calculateGap', {});
        }, this);
        _registerListener('setOnTopDates', ({ bDate, eDate }) => {
            this.hasOnTop = true;
            this.ontopBdate = bDate;
            this.ontopEdate = eDate;
            // if (!this.readOnly && this.isPE) {
            //     this._refreshData(true);
            // }
        }, this);
        _registerListener('setPTDates', ({ bDate, eDate }) => {
            this.ptBdate = bDate;
            this.ptEdate = eDate;
        }, this);
        _registerListener('setSafeBalanceIndex1', safeBalanceIndex1 => {
            if (this.safeBalanceIndex1 != safeBalanceIndex1) {
                this.safeBalanceIndex1 = safeBalanceIndex1;
                _fireEvent(this.pageRef, 'recalculateFolding', {});
            }
        }, this);
        _registerListener('recalculateFolding', () => {
            let changesMap = this.changesMap;
            if (this.isSimulation && !this.readOnly && this.hasAnyInternational) {
                // A = contractNegoBaseRef.Index1__c
                let negoBaseRefIndex1 = this.negoBaseRefIndex1 || 0;
                // B = contractSafeBalanceRef.Index1__c
                let safeBalanceIndex1 = this.safeBalanceIndex1 || 0;
                let grouppedConditions = this.arraysCondtion;
                for (let index of grouppedConditions) {
                    let previousNegodiscount;
                    for (let negodiscount of index.negodiscounts) {
                        for (let conditionIndex in negodiscount.conditions) {
                            let condition = negodiscount.conditions[conditionIndex];
                            if (previousNegodiscount && previousNegodiscount.hasInternational && condition[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Is_Folding_Discount__c] && condition[API_NAMES.Contract_Discount__c.Status__c] != 'Deleted') {
                                let ytdInternational = previousNegodiscount.index || 0;
                                let percent = 0;
                                if (negoBaseRefIndex1 && safeBalanceIndex1) {
                                    // C / ((100 - (100 * ((A - B) / A))) / 100) - C
                                    // baisse2Net = 100 * ((A - B) / A)
                                    let baisse2Net = negoBaseRefIndex1 != 0 ? 100 * ((negoBaseRefIndex1 - safeBalanceIndex1) / negoBaseRefIndex1) : 0;
                                    // coef = (100 - baisse2Net) / 100
                                    let coef = (100 - baisse2Net) / 100;
                                    // tauxInternationalApresFolding = C / coef
                                    let tauxInternationalApresFolding = coef != 0 ? ytdInternational / coef : 0;
                                    // percent = tauxInternationalApresFolding - C
                                    percent = tauxInternationalApresFolding - ytdInternational;
                                }
                                if (condition[API_NAMES.Contract_Discount__c.Value_per__c] != percent || condition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] != percent) {
                                    let mapKey = index.key + '-' + negodiscount.key + '-' + conditionIndex;
                                    if (condition[API_NAMES.Contract_Discount__c.Status__c] != 'Deleted') {
                                        condition[API_NAMES.Contract_Discount__c.Value_per__c] = percent;
                                        condition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = percent;
                                        changesMap[mapKey] = condition;
                                        this.hasChanges = true;
                                        _fireEvent(this.pageRef, 'hasChanges', {});
                                    }
                                }
                            }
                        }
                        previousNegodiscount = negodiscount;
                    }
                }
            }
        }, this);
        if (this.showIndexes) {
            this.indexesClass = '';
        } else {
            this.indexesClass = 'slds-hide';
        }
        this.readOnly = true;
        let self = this;
        getObjectLabels().then(result => {
            let data = JSON.parse(result);
            let translation = data.labelsMap;
            let helpText = data.helpTextMap;
            self.Labels.LBL_Is_OnTop_Simulation = translation[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Is_OnTop_Simulation__c];
            self.Labels.LBL_Conditional_Slab_Method = translation[API_NAMES.Pol_Com_Condition__c.objectApiName][API_NAMES.Pol_Com_Condition__c.Conditional_Slab_Method__c];
            self.Labels.LBL_slab_calc_method = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.slab_calc_method__c];
            self.Labels.LBL_Rise_Rate = translation[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Rise_Rate__c];
            self.Labels.LBL_Depreciation_Rise_Rate = translation[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Depreciation_Rate__c];
            self.Labels.LBL_QTY = translation[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Total_Qty__c];
            self.Labels.LBL_TO = translation[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Total_TO__c];
            self.Labels.LBL_Index_val__c = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.Index_val__c];
            self.Labels.LBL_Index_perc__c = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.Index_perc__c];
            self.Labels.LBL_Total_TO_Tariff_Nego__c = translation[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Total_TO_Tariff_Nego__c];
            self.Labels.BusinessUnitScope__c = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
            self.Labels.Product_Scope__c = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.Product_Scope__c];
            self.helpText.BusinessUnitScope__c = helpText[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
            self.helpText.Product_Scope__c = helpText[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.Product_Scope__c];
        });
        this._refreshData(true);
    }
    @api refreshData() {
        this._refreshData(true);
    }

    get discPercentStep() {
        if (this.discountPercentScale) {
            let step = '.';
            for (let i = 0; i < this.discountPercentScale; i++) {
                if (i == this.discountPercentScale - 1) {
                    step += '1';
                    break;
                }
                step += '0';
            }
            return step;
        }
    }
    _refreshData(notifyParent) {
        let contractId = this.contractId;
        let self = this;
        self.isRevalidatePTOpen = false;
        self.continueEditContract = false;
        getContractData({ contractId: contractId }).then((result) => {
            let negotiateIndexesCmp = self.template.querySelector('[data-id="negotiate-indexes-cmp"]');
            if (negotiateIndexesCmp && negotiateIndexesCmp.recalculate) {
                negotiateIndexesCmp.recalculate();
            }
            let grouppingResult = {};
            let contractDataWrapper = JSON.parse(result);
            self.validTariffConditionMap = contractDataWrapper.validTariffConditionMap;
            self.userProfileId = contractDataWrapper.userProfileId;
            self.isLocked = contractDataWrapper.isLockedByAprovalProcess;
            self.isLockedByAprovalProcess = contractDataWrapper.isLockedByAprovalProcess;
            if (self.isLockedByAprovalProcess) {
                _fireEvent(self.pageRef, 'lockedByApprovalProcess', { isActive: true });
            }
            _fireEvent(self.pageRef, 'toggleRTLegend', contractDataWrapper.contract.RecordType.DeveloperName);
            self.contractName = contractDataWrapper.contract.Name;
            self.contract = contractDataWrapper.contract;
            self.isOnTopSimulation = contractDataWrapper.contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c];
            self.duration = contractDataWrapper.contract[API_NAMES.Contract__c.Duration__c];
            self.purchase = contractDataWrapper.contract[API_NAMES.Contract__c.TO1__c] || '';
            self.quantity = contractDataWrapper.contract[API_NAMES.Contract__c.Qty1__c] || '';
            self.riseRate = contractDataWrapper.contract[API_NAMES.Contract__c.Rise_Rate__c] || '';
            self.depreciationRate = contractDataWrapper.contract[API_NAMES.Contract__c.Depreciation_Rate__c] || '';
            self.createSimulFromNegoBaseLabel = contractDataWrapper.createSimulFromNegoBaseLabel;
            self.createSafeBalanceFromNegoBaseLabel = contractDataWrapper.createSafeBalanceFromNegoBaseLabel;
            self.createSimulFromSafeBalanceLabel = contractDataWrapper.createSimulFromSafeBalanceLabel;
            self.createSafeBalanceFromSafeBalanceLabel = contractDataWrapper.createSafeBalanceFromSafeBalanceLabel;
            self.createSimulFromSimulLabel = contractDataWrapper.createSimulFromSimulLabel;
            self.createPostNegoSimulFromSignedLabel = contractDataWrapper.createPostNegoSimulFromSignedLabel;
            self.createSafeBalanceFromSimulLabel = contractDataWrapper.createSafeBalanceFromSimulLabel;
            self.duplicateNegoBasetoPE = contractDataWrapper.duplicateNegoBasetoPE;
            self.duplicateSafeBalanceToPE = contractDataWrapper.duplicateSafeBalanceToPE;
            self.contractRecordTypeDeveloperNameToLabelMap = contractDataWrapper.contractRecordTypeDeveloperNameToLabelMap;
            self.sBusinessType = contractDataWrapper.sBusinessType;
            self.discountPercentScale = contractDataWrapper.discountPercentScale;
            self.isCPG = contractDataWrapper.sBusinessType == 'CPG';
            let bDate = new Date(contractDataWrapper.contract[API_NAMES.Contract__c.Contract_BDate__c]);
            let eDate = new Date(contractDataWrapper.contract[API_NAMES.Contract__c.Contract_EDate__c]);
            let status = contractDataWrapper.contract[API_NAMES.Contract__c.Status__c];
            let isSignedPE = (bDate.getUTCFullYear() == self.negoYear && contractDataWrapper.contract.RecordType.DeveloperName == 'Period_Extension' && status == 'Signed');
            self.dateContract = ' ('
                + (bDate.getUTCDate() < 10 ? '0' + bDate.getUTCDate() : bDate.getUTCDate())
                + '/'
                + (bDate.getUTCMonth() + 1 < 10 ? '0' + (bDate.getUTCMonth() + 1) : bDate.getUTCMonth() + 1)
                + (bDate.getUTCFullYear() != eDate.getUTCFullYear() ? '/' + bDate.getUTCFullYear() : '')
                + '-'
                + (eDate.getUTCDate() < 10 ? '0' + eDate.getUTCDate() : eDate.getUTCDate())
                + '/'
                + (eDate.getUTCMonth() + 1 < 10 ? '0' + (eDate.getUTCMonth() + 1) : eDate.getUTCMonth() + 1)
                + (bDate.getUTCFullYear() != eDate.getUTCFullYear() ? '/' + eDate.getUTCFullYear() : '')
                + ')';
            if (bDate.getUTCFullYear() == self.negoYear && ((self.isSimulation || self.isSigned) && self.isOnTopSimulation)) {
                self.executiveSummaryUrl = contractDataWrapper.executiveSummaryUrl + '&backUrl=' + encodeURIComponent(self.currentUrl);
            }
            if (bDate.getUTCFullYear() == self.negoYear && self.isOnTopSimulation) {
                _fireEvent(self.pageRef, 'setOnTopDates', { bDate, eDate });
            }
            if (bDate.getUTCFullYear() == self.negoYear && contractDataWrapper.contract.RecordType.DeveloperName == 'Period_Extension') {
                _fireEvent(self.pageRef, 'setPTDates', { bDate, eDate });
            }
            if (isSignedPE) {
                _fireEvent(self.pageRef, 'updateHasPESigned', {});
            }
            if (bDate.getUTCFullYear() < self.negoYear && contractDataWrapper.contract.RecordType.DeveloperName == 'Nego_Base') {
                _fireEvent(self.pageRef, 'checkRefNegoBase', { contract: contractDataWrapper.contract });
            }
            if (bDate.getUTCFullYear() < self.negoYear && contractDataWrapper.contract.RecordType.DeveloperName == 'Nego_Base') {
                _fireEvent(self.pageRef, 'setRefToQtyDuration', { refTO: contractDataWrapper.contract[API_NAMES.Contract__c.Total_TO__c], refQty: contractDataWrapper.contract[API_NAMES.Contract__c.Total_Qty__c], refDuration: contractDataWrapper.contract[API_NAMES.Contract__c.Duration__c] });
            }
            if (bDate.getUTCFullYear() == self.negoYear && contractDataWrapper.contract.RecordType.DeveloperName == 'Safe_Balance') {
                _fireEvent(self.pageRef, 'setSafeBalanceToQtyDuration', { safeBalanceTO: contractDataWrapper.contract[API_NAMES.Contract__c.Total_TO__c], safeBalanceQty: contractDataWrapper.contract[API_NAMES.Contract__c.Total_Qty__c], safeBalanceDuration: contractDataWrapper.contract[API_NAMES.Contract__c.Duration__c] });
            }
            self.readOnly = isSignedPE || bDate.getUTCFullYear() < self.negoYear || ['Nego_Base_Exit', 'Nego_Base_Init'].includes(contractDataWrapper.contract.RecordType.DeveloperName);
            contractDataWrapper.discounts.forEach(item => {
                item[API_NAMES.Contract_Discount__c.Contract__r] = contractDataWrapper.contract;
                let index = item[API_NAMES.Contract_Discount__c.Index__c];
                let negoDiscountType = item[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
                if (!grouppingResult.hasOwnProperty(index)) {
                    grouppingResult[index] = {};
                }
                if (!grouppingResult[index].hasOwnProperty(negoDiscountType)) {
                    grouppingResult[index][negoDiscountType] = [];
                }
                grouppingResult[index][negoDiscountType].push(item);
            });
            self.grouppingResult = grouppingResult;
            if (notifyParent) {
                const readyEvent = new CustomEvent('childready', {
                    detail: {
                        value: grouppingResult,
                        contractId: contractId,
                        userProfileId: self.userProfileId,
                        validTariffConditionMap: contractDataWrapper.validTariffConditionMap,
                    },
                });
                if (self.dispatchEvent) {
                    self.dispatchEvent(readyEvent);
                } else {
                    console.error('event not available .... ');
                }
                _fireEvent(self.pageRef, 'triggerContractLoading' + (self.contractId || 0), { isLoading: true, fname: 'getContractData' });
                _fireEvent(self.pageRef, 'calculateGap', {});
                _fireEvent(self.pageRef, 'refreshList', {});
            } else {
                self._rePopulateConditions();
            }
        });
    }
    @api populateConditions(grouppedConditions) {
        return this._populateConditions(grouppedConditions);
    }
    _populateConditions(grouppedConditions) {
        _fireEvent(this.pageRef, 'calculateGap', {});
        let readOnly = this.readOnly;
        let validTariffConditionMap = this.validTariffConditionMap;
        let isPE = this.isPE;
        let isSimulation = this.isSimulation;
        let contract = this.contract;
        let contractId = this.contractId;
        let wIndex = this.wIndex;
        let userProfileId = this.userProfileId;
        let grouppingResult = {};
        try {
            grouppingResult = JSON.parse(JSON.stringify(this.grouppingResult));
            for (let index of grouppedConditions) {
                Object.defineProperty(index, 'rowClass', {
                    get: function () { return this.isExpanded ? '' : 'slds-hide'; }
                });
                for (let negodiscount of index.negodiscounts) {
                    Object.defineProperty(negodiscount, 'rowClass', {
                        get: function () { return this.isExpanded && index.isExpanded ? '' : 'slds-hide'; }
                    });
                    if (!negodiscount.hasOwnProperty('hasInternational')) {
                        Object.defineProperty(negodiscount, 'hasInternational', {
                            get: function () { return this.conditions.some(item => item[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Is_International_Discount__c]); }
                        });
                    }
                    if (!negodiscount.hasOwnProperty('indexPer')) {
                        Object.defineProperty(negodiscount, 'indexPer', {
                            get: function () { let sum = 0; this.conditions.forEach(item => sum += (item[API_NAMES.Contract_Discount__c.Index_perc__c] ? item[API_NAMES.Contract_Discount__c.Index_perc__c] : 0)); return sum; }
                        });
                    }
                    if (!negodiscount.hasOwnProperty('computedAmount')) {
                        Object.defineProperty(negodiscount, 'computedAmount', {
                            get: function () { let sum = 0; this.conditions.forEach(item => sum += (item[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] ? item[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] : 0)); return sum; }
                        });
                    }
                    for (let tarifConditionIndex = 0; tarifConditionIndex < negodiscount.conditions.length; tarifConditionIndex++) {
                        try {
                            // let tarifConditionPes = negodiscount.conditions[tarifConditionIndex].peConditions || [negodiscount.conditions[tarifConditionIndex].condition];
                            let tarifCondition = negodiscount.conditions[tarifConditionIndex].condition;
                            let tarifConditionId = tarifCondition.Id;
                            let gCondition;
                            let gIndex;
                            let gNegodiscount;
                            for (let kIndex in grouppingResult) {
                                for (let kNegodiscount in grouppingResult[kIndex]) {
                                    for (let condition of grouppingResult[kIndex][kNegodiscount]) {
                                        if (condition[API_NAMES.Contract_Discount__c.Condition_Type__c] == tarifConditionId
/*|| (tarifConditionPes
&& tarifConditionPes.some(_tariffpe => condition[API_NAMES.Contract_Discount__c.Condition_Type__c] == _tariffpe.Id))*/) {
                                            gCondition = condition;
                                            gIndex = kIndex;
                                            gNegodiscount = kNegodiscount;
                                        }
                                        if (gCondition) {
                                            break;
                                        }
                                    }
                                    if (gCondition) {
                                        break;
                                    }
                                }
                                if (gCondition) {
                                    break;
                                }
                            }
                            if (gCondition) {
                                negodiscount.conditions[tarifConditionIndex] = gCondition;
                                grouppingResult[gIndex][gNegodiscount] = grouppingResult[gIndex][gNegodiscount].filter(item => item.Id != gCondition.Id);
                            } else {
                                let newItem = {
                                    SObjectType: API_NAMES.Contract_Discount__c.objectApiName,
                                };
                                newItem[API_NAMES.Contract_Discount__c.Contract__c] = contractId;
                                newItem[API_NAMES.Contract_Discount__c.Contract__r] = this.contract;
                                newItem[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = this.contract[API_NAMES.Contract__c.Total_Qty__c];
                                newItem[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = this.contract[API_NAMES.Contract__c.Total_TO__c];
                                newItem[API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c] = this.contract[API_NAMES.Contract__c.Total_TO_Nego_YearBase__c];
                                newItem[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = this.contract[API_NAMES.Contract__c.BusinessUnitContract__c];
                                newItem[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = this.contract[API_NAMES.Contract__c.BusinessUnitContract__r];
                                newItem[API_NAMES.Contract_Discount__c.Product_Scope__c] = this.contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
                                newItem[API_NAMES.Contract_Discount__c.Product_Scope__r] = this.contract[API_NAMES.Contract__c.Supplier_Nego_Scope__r];
                                // let bDate = new Date();
                                // let cbDate = new Date(this.contract[API_NAMES.Contract__c.Contract_BDate__c]);
                                // let ceDate = new Date(this.contract[API_NAMES.Contract__c.Contract_EDate__c]);
                                // if (bDate.getTime() < cbDate) {
                                //     bDate = cbDate;
                                // } else if (bDate.getTime() > ceDate) {
                                //     bDate = ceDate;
                                // }
                                // newItem[API_NAMES.Contract_Discount__c.Disc_BDate__c] = bDate.getFullYear() + '-' + (bDate.getUTCMonth() + 1 < 10 ? '0' + bDate.getUTCMonth() + 1 : bDate.getUTCMonth() + 1) + '-' + (bDate.getUTCDate() < 10 ? '0' + bDate.getUTCDate() : bDate.getUTCDate());
                                newItem[API_NAMES.Contract_Discount__c.Disc_BDate__c] = this.contract[API_NAMES.Contract__c.Contract_BDate__c];
                                newItem[API_NAMES.Contract_Discount__c.Disc_EDate__c] = this.contract[API_NAMES.Contract__c.Contract_EDate__c];
                                newItem[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = newItem[API_NAMES.Contract_Discount__c.Disc_BDate__c];
                                newItem[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = newItem[API_NAMES.Contract_Discount__c.Disc_EDate__c];
                                /*if (this?.contract?.RecordType?.DeveloperName == 'Period_Extension') {
                                let tarifConditionPe = tarifConditionPes[tarifConditionPes.length - 1];
                                let tarifConditionPeId = tarifConditionPe?.Id;
                                newItem[API_NAMES.Contract_Discount__c.Condition_Type__c] = tarifConditionPeId;
                                newItem[API_NAMES.Contract_Discount__c.Condition_Type__r] = tarifConditionPe;
                                newItem[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c] = tarifConditionPe[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
                                } else {*/
                                newItem[API_NAMES.Contract_Discount__c.Condition_Type__c] = tarifConditionId;
                                newItem[API_NAMES.Contract_Discount__c.Condition_Type__r] = tarifCondition;
                                newItem[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c] = tarifCondition[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
                                /*}*/
                                newItem[API_NAMES.Contract_Discount__c.Index__c] = index.key;
                                negodiscount.conditions[tarifConditionIndex] = newItem;
                            }
                            let currentCondition = negodiscount.conditions[tarifConditionIndex];
                            currentCondition[API_NAMES.Contract_Discount__c.Is_Tariff_Condition__c] = tarifCondition[API_NAMES.Contract_Discount__c.Is_Tariff_Condition__c];
                            currentCondition.hideInfo = false;
                            currentCondition.popOverClass = 'slds-popover slds-popover_panel slds-nubbin_left-top force-read-only-style slds-hide';
                            currentCondition = setNegotiateConditionFields(currentCondition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, negodiscount, userProfileId);
                        } catch (error) {
                            console.error(error);
                        }
                    }
                    this.hasAnyInternational = this.hasAnyInternational || negodiscount.hasInternational;
                }
            }
            if (wIndex && wIndex.values) {
                for (let index of grouppedConditions) {
                    let currentIndex = wIndex.values.find(item => item.indexName == index.key);
                    if (currentIndex) {
                        index.percent = currentIndex.IndexPerc;
                        index.computedAmount = currentIndex.Computed;
                        index.indexVal = currentIndex.Index;
                    }
                }
                let negotiateIndexesCmp = this.template.querySelector('[data-id="negotiate-indexes-cmp"]');
                if (negotiateIndexesCmp && negotiateIndexesCmp.setCalculation) {
                    negotiateIndexesCmp.setCalculation(JSON.stringify(wIndex));
                }
            }
            this.arraysCondtion = grouppedConditions.map(item => item);
        } catch (error) {
        }
        _fireEvent(this.pageRef, 'triggerContractLoading' + (this.contractId || 0), { isLoading: false, fname: 'getContractData' });
        _fireEvent(this.pageRef, 'refreshList', {});
        return this.arraysCondtion;
    }
    _rePopulateConditions() {
        let validTariffConditionMap = this.validTariffConditionMap;
        let readOnly = this.readOnly;
        let isPE = this.isPE;
        let isSimulation = this.isSimulation;
        let contract = this.contract;
        let arraysCondtion = this.arraysCondtion;
        let userProfileId = this.userProfileId;
        let changesMap = this.changesMap;
        let grouppingResult = JSON.parse(JSON.stringify(this.grouppingResult));
        for (let index of arraysCondtion) {
            // if (!index.hasOwnProperty('rowClass')) {
            Object.defineProperty(index, 'rowClass', {
                get: function () { return this.isExpanded ? '' : 'slds-hide'; }
            });
            // }
            for (let negodiscount of index.negodiscounts) {
                // if (!negodiscount.hasOwnProperty('rowClass')) {
                Object.defineProperty(negodiscount, 'rowClass', {
                    get: function () { return this.isExpanded && index.isExpanded ? '' : 'slds-hide'; }
                });
                if (!negodiscount.hasOwnProperty('hasInternational')) {
                    Object.defineProperty(negodiscount, 'hasInternational', {
                        get: function () { return this.conditions.some(item => item[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Is_International_Discount__c]); }
                    });
                }
                // }
                for (let conditionIndex in negodiscount.conditions) {
                    let condition = negodiscount.conditions[conditionIndex];
                    let conditionId = condition.Id;
                    let tarifConditionId = condition[API_NAMES.Contract_Discount__c.Condition_Type__c];
                    let mapKey = index.key + '-' + negodiscount.key + '-' + conditionIndex;
                    if (grouppingResult.hasOwnProperty(index.key) && grouppingResult[index.key].hasOwnProperty(negodiscount.key) && grouppingResult[index.key][negodiscount.key].some(condition => condition[API_NAMES.Contract_Discount__c.Condition_Type__c] == tarifConditionId)) {
                        let availabeCondition = conditionId ? grouppingResult[index.key][negodiscount.key].find(_condition => _condition.Id == conditionId) : undefined;
                        if (availabeCondition) {
                            availabeCondition = grouppingResult[index.key][negodiscount.key].find(_condition => _condition[API_NAMES.Contract_Discount__c.Condition_Type__c] == tarifConditionId);
                        }
                        if (availabeCondition) {
                            negodiscount.conditions[conditionIndex] = availabeCondition;
                            grouppingResult[index.key][negodiscount.key] = grouppingResult[index.key][negodiscount.key].filter(item => item.Id != availabeCondition.Id);
                            // changesMap[mapKey] = undefined;
                        }
                    }
                    let currentCondition = negodiscount.conditions[conditionIndex];
                    currentCondition.hideInfo = false;
                    currentCondition.popOverClass = 'slds-popover slds-popover_panel slds-nubbin_left-top force-read-only-style slds-hide';
                    currentCondition = setNegotiateConditionFields(currentCondition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, negodiscount, userProfileId);
                }
                this.hasAnyInternational = this.hasAnyInternational || negodiscount.hasInternational;
            }
        }
        this.arraysCondtion = this.arraysCondtion.map(item => item);
        if (this.calculateIndex) {
            let self = this;
            clearTimeout(this.calculateIndexTimeOut);
            this.calculateIndexTimeOut = setTimeout(() => {
                self.calculateIndex();
            }, CALCULATE_INDEX_TIMEOUT);
        }
    }
    recalculateFolding() {
        if (this.isSimulation && !this.readOnly) {
            // A = contractNegoBaseRef.Index1__c
            let negoBaseRefIndex1 = this.negoBaseRefIndex1 || 0;
            // B = contractSafeBalanceRef.Index1__c
            let safeBalanceIndex1 = this.safeBalanceIndex1 || 0;
            let grouppedConditions = this.arraysCondtion;
            for (let index of grouppedConditions) {
                let previousNegodiscount;
                for (let negodiscount of index.negodiscounts) {
                    for (let condition of negodiscount.conditions) {
                        if (previousNegodiscount && previousNegodiscount.hasInternational && condition[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Is_Folding_Discount__c]) {
                            let ytdInternational = previousNegodiscount.index || 0;
                            let percent = 0;
                            if (negoBaseRefIndex1 && safeBalanceIndex1) {
                                // C / ((100 - (100 * ((A - B) / A))) / 100) - C
                                // baisse2Net = 100 * ((A - B) / A)
                                let baisse2Net = negoBaseRefIndex1 != 0 ? 100 * ((negoBaseRefIndex1 - safeBalanceIndex1) / negoBaseRefIndex1) : 0;
                                // coef = (100 - baisse2Net) / 100
                                let coef = (100 - baisse2Net) / 100;
                                // tauxInternationalApresFolding = C / coef
                                let tauxInternationalApresFolding = coef != 0 ? ytdInternational / coef : 0;
                                // percent = tauxInternationalApresFolding - C
                                percent = tauxInternationalApresFolding - ytdInternational;
                            }
                            condition[API_NAMES.Contract_Discount__c.Value_per__c] = percent;
                            condition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = percent;
                        }
                    }
                    previousNegodiscount = negodiscount;
                }
            }
        }
    }
    calculateIndexTimeOut;
    handleContractFieldChange(event) {
        let self = this;
        let contract = this.contract;
        let negoYear = this.negoYear;
        let value = event.target.value == '' ? null : event.target.value;
        let fieldApiName = event.target.dataset.fieldApiName;
        let field = event.target.dataset.field;
        if (contract[fieldApiName] != value) {
            this.hasContractChanges = true;
            window.clearTimeout(this.calculateIndexTimeOut);
            contract[fieldApiName] = value;
            this[field] = value;
            this.depreciationRateClass = '';
            if (!isNaN(this.depreciationRiseRateDiff)) {
                this.depreciationRateClass = this.depreciationRiseRateDiff != (this.contract[API_NAMES.Contract__c.Depreciation_Rate__c] || 0) ? 'has-error-rate' : '';
            }
            this.riseRateClass = '';
            if (!isNaN(this.riseRateDiff)) {
                this.riseRateClass = this.riseRateDiff != (this.contract[API_NAMES.Contract__c.Rise_Rate__c] || 0) ? 'has-error-rate' : '';
            }
            if (new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getUTCFullYear() == negoYear && contract.RecordType.DeveloperName == 'Safe_Balance') {
                _fireEvent(this.pageRef, 'setSafeBalanceToQtyDuration', { safeBalanceTO: contract[API_NAMES.Contract__c.TO1__c], safeBalanceQty: contract[API_NAMES.Contract__c.Qty1__c], safeBalanceDuration: contract[API_NAMES.Contract__c.Duration__c] });
            } else {
                _fireEvent(this.pageRef, 'calculateGap', {});
            }
            this.calculateIndexTimeOut = setTimeout(() => {
                self.calculateIndex();
            }, CALCULATE_INDEX_TIMEOUT);
        }
    }
    calculateIndex() {
        // this._calculateIndex();
        this._calculateIndex2();
    }
    _calculateIndex() {
        let contract = this.contract;
        let grouppedConditions = this.arraysCondtion;
        let conditions = [];
        for (let index of grouppedConditions) {
            for (let negodiscount of index.negodiscounts) {
                for (let tarifConditionIndex = 0; tarifConditionIndex < negodiscount.conditions.length; tarifConditionIndex++) {
                    conditions.push(negodiscount.conditions[tarifConditionIndex])
                }
            }
        }
        let indexServices = new ContractServiceHelper(contract, conditions);
        let negotiateIndexesCmp = this.template.querySelector('[data-id="negotiate-indexes-cmp"]');
        if (negotiateIndexesCmp && negotiateIndexesCmp.setCalculation) {
            negotiateIndexesCmp.setCalculation(JSON.stringify({
                key: contract.Id,
                contractName: contract.name,
                riseRate: contract[API_NAMES.Contract__c.Rise_Rate__c],
                depresiationRate: contract[API_NAMES.Contract__c.Depreciation_Rate__c],
                totalToTariffNego: contract[API_NAMES.Contract__c.Total_TO_Tariff_Nego__c],
                values: indexServices.calculateContractIndex2(true),
                baseIndex: indexServices.getContractBaseIndex(),
            }));
        }
    }
    _calculateIndex2() {
        if (this.contract.RecordType.DeveloperName == 'Signed_Copy' || this.contract.RecordType.DeveloperName == 'Nego_Base_Exit') {
            return;
        }
        let contract = this.contract;
        _fireEvent(this.pageRef, 'triggerContractLoading' + (contract.Id || 0), { isLoading: true, fname: contract.Id + '_calculateIndex2' });
        let self = this;
        let negoYear = this.negoYear;
        let bDate = new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]);
        let isRefNegoBase = contract && contract.RecordType ? (contract.RecordType.DeveloperName == 'Nego_Base') && (bDate.getFullYear() < negoYear) : false;
        let grouppedConditions = this.arraysCondtion;
        let _conditions = [];
        let conditions = [];
        for (let index of grouppedConditions) {
            for (let negodiscount of index.negodiscounts) {
                for (let tarifConditionIndex = 0; tarifConditionIndex < negodiscount.conditions.length; tarifConditionIndex++) {
                    _conditions.push(negodiscount.conditions[tarifConditionIndex]);
                    let condition = { ...negodiscount.conditions[tarifConditionIndex] };
                    delete condition.detailPopupFields;
                    delete condition.Condition_Type;
                    delete condition.contract;
                    delete condition.popOverClass;
                    delete condition.hideInfo;
                    delete condition.class;
                    delete condition.isDisplayed;
                    conditions.push(condition);
                }
            }
        }
        calculateIndex({
            contract_JSON: JSON.stringify(contract),
            discounts_JSON: JSON.stringify(conditions),
        }).then(result => {
            let wrapper = JSON.parse(result);
            let wIndex = wrapper.wIndex;
            let wConditions = wrapper.discounts;
            let wContract = wrapper.contract;
            self.wIndex = wIndex;
            [
                API_NAMES.Contract__c.Index1__c,
                API_NAMES.Contract__c.Index2__c,
                API_NAMES.Contract__c.Index3__c,
                API_NAMES.Contract__c.Index4__c,
                API_NAMES.Contract__c.Index5__c,
                API_NAMES.Contract__c.Index6__c,
                API_NAMES.Contract__c.Index7__c,
                API_NAMES.Contract__c.Index1_V2__c,
                API_NAMES.Contract__c.Index2_V2__c,
                API_NAMES.Contract__c.Index3_V2__c,
                API_NAMES.Contract__c.Index4_V2__c,
                API_NAMES.Contract__c.Index5_V2__c,
                API_NAMES.Contract__c.Index6_V2__c,
                API_NAMES.Contract__c.Index7_V2__c,
                API_NAMES.Contract__c.Index1_perc__c,
                API_NAMES.Contract__c.Index2_perc__c,
                API_NAMES.Contract__c.Index3_perc__c,
                API_NAMES.Contract__c.Index4_perc__c,
                API_NAMES.Contract__c.Index5_perc__c,
                API_NAMES.Contract__c.Index6_perc__c,
                API_NAMES.Contract__c.Index7_perc__c,
                API_NAMES.Contract__c.Total_TO_Tariff_Nego__c,
                API_NAMES.Contract__c.Rise_Rate__c,
                API_NAMES.Contract__c.Depreciation_Rate__c,
                API_NAMES.Contract__c.Rise_Rate_YE__c,
                API_NAMES.Contract__c.Depreciation_Rate_YE__c,
            ].forEach(fieldApiName => {
                if (contract[fieldApiName] !== wContract[fieldApiName]) {
                    self.hasContractChanges = true;
                    contract[fieldApiName] = wContract[fieldApiName];
                }
            });
            for (let index of grouppedConditions) {
                let currentIndex = wIndex.values.find(item => item.indexName == index.key);
                if (currentIndex) {
                    index.percent = currentIndex.IndexPerc;
                    index.computedAmount = currentIndex.Computed;
                    index.indexVal = currentIndex.Index;
                }
            }
            wConditions.forEach((item, index) => {
                let negotiateIndex = _conditions[index][API_NAMES.Contract_Discount__c.Index__c];
                let negotiateType = _conditions[index][API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
                let filteredIndex = grouppedConditions.find(item => item.key == negotiateIndex);
                let mapKey = undefined;
                if (filteredIndex) {
                    let filteredNegodiscount = filteredIndex.negodiscounts.find(item => item.key == negotiateType);
                    if (filteredNegodiscount) {
                        mapKey = negotiateIndex + '-' + negotiateType + '-' + filteredNegodiscount.conditions.indexOf(_conditions[index]);
                    }
                }
                [
                    API_NAMES.Contract_Discount__c.Display_Order__c,
                    API_NAMES.Contract_Discount__c.Index_val__c,
                    API_NAMES.Contract_Discount__c.Index_perc__c,
                    API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c,
                    API_NAMES.Contract_Discount__c.Base_TO_Tariff_Nego__c,
                    API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
                ].forEach(fieldApiName => {
                    if (_conditions[index][fieldApiName] != item[fieldApiName]) {
                        _conditions[index][fieldApiName] = item[fieldApiName];
                        self.hasChanges = true;
                        self.changesMap[mapKey] = _conditions[index];
                        _fireEvent(self.pageRef, 'hasChanges', {});
                    }
                });
            });
            let negotiateIndexesCmp = self.template.querySelector('[data-id="negotiate-indexes-cmp"]');
            if (negotiateIndexesCmp && negotiateIndexesCmp.setCalculation) {
                negotiateIndexesCmp.setCalculation(JSON.stringify(wIndex));
            }
            if (isRefNegoBase) {
                const populateRefIndexEvent = new CustomEvent(self.populateRefIndexEvent, {
                    detail: {
                        wIndex: JSON.stringify(wIndex),
                    },
                });
                if (self.dispatchEvent) {
                    self.dispatchEvent(populateRefIndexEvent);
                } else {
                    console.error('event not available .... ');
                }
            }
            _fireEvent(self.pageRef, 'calculateGap', {});
            _fireEvent(self.pageRef, 'recalculateFolding', {});
            _fireEvent(self.pageRef, 'triggerContractLoading' + (contract.Id || 0), { isLoading: false, fname: contract.Id + '_calculateIndex2' });
        });
    }
    @api getConditions() {
        return this.arraysCondtion;
    }
    @api populateRefConditions(refContract, contractPE, refArraysCondtion, simulationNumber, postSimulationNumber, refContractBUId, refContractSourceBUId) {
        this._populateRefConditions(refContract, contractPE, refArraysCondtion, simulationNumber, postSimulationNumber, refContractBUId, refContractSourceBUId);
    }
    _populateRefConditions(refContract, contractPE, refArraysCondtion, simulationNumber, postSimulationNumber, refContractBUId, refContractSourceBUId) {
        this.refArraysCondtion = refArraysCondtion;
        this.refContract = refContract;
        this.contractPE = contractPE;
        this.simulationNumber = simulationNumber;
        this.postSimulationNumber = postSimulationNumber;
        this.refContractBUId = refContractBUId;
        this.refContractSourceBUId = refContractSourceBUId;
    }
    @api populateNewConditions(newCondition) {
        this._populateNewConditions(newCondition);
    }
    _populateNewConditions(newCondition) {
        let contractId = this.contractId;
        let self = this;
        let negotiateIndex = newCondition[API_NAMES.Contract_Discount__c.Index__c];
        let negotiateType = newCondition[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
        let arraysCondtion = this.arraysCondtion;
        let readOnly = this.readOnly;
        let userProfileId = this.userProfileId;
        let validTariffConditionMap = this.validTariffConditionMap;
        let isPE = this.isPE;
        let isSimulation = this.isSimulation;
        let contract = this.contract;
        let filteredIndex = arraysCondtion.find(item => item.key == negotiateIndex);
        if (filteredIndex) {
            let filteredNegodiscount = filteredIndex.negodiscounts.find(item => item.key == negotiateType);
            if (filteredNegodiscount) {
                let mapKey = negotiateIndex + '-' + negotiateType + '-' + filteredNegodiscount.conditions.length;
                filteredNegodiscount.conditions.push(newCondition);
                newCondition.hideInfo = false;
                newCondition.popOverClass = 'slds-popover slds-popover_panel slds-nubbin_left-top force-read-only-style slds-hide';
                newCondition = setNegotiateConditionFields(newCondition, contract, readOnly, isSimulation, isPE, validTariffConditionMap, filteredNegodiscount, userProfileId);
                if (newCondition[API_NAMES.Contract_Discount__c.Value_amt__c]
                    || newCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c]
                    || newCondition[API_NAMES.Contract_Discount__c.Value_per__c]
                    || newCondition[API_NAMES.Contract_Discount__c.Value_per_Y1__c]
                    || newCondition[API_NAMES.Contract_Discount__c.unit_amount__c]
                    || newCondition[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c]) {
                    this.hasChanges = true;
                    _fireEvent(this.pageRef, 'hasChanges', {});
                    this.changesMap[mapKey] = newCondition;
                    _fireEvent(this.pageRef, 'fakesave_' + contractId, {
                        condition: newCondition,
                        successCallback: () => {
                            if (self.calculateIndex) {
                                clearTimeout(self.calculateIndexTimeOut);
                                self.calculateIndexTimeOut = setTimeout(() => {
                                    self.calculateIndex();
                                }, CALCULATE_INDEX_TIMEOUT);
                            }
                        },
                    });
                }
            }
        }
    }
    genericHandleValueChange(event) {
        let changesMap = this.changesMap;
        let contractId = this.contractId;
        let self = this;
        this.hasChanges = true;
        _fireEvent(this.pageRef, 'hasChanges', {});
        let value = event.target.value;
        let fieldApiName = event.target.dataset.fieldApiName;
        let index = event.target.dataset.rowindex;
        let negotiateIndex = event.target.dataset.index;
        let negotiateType = event.target.dataset.negotiatetype;
        let mapKey = negotiateIndex + '-' + negotiateType + '-' + index;
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                let currentCondition = negoType.conditions[index];
                currentCondition[fieldApiName] = value;
                if (fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c) {
                    currentCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = currentCondition[API_NAMES.Contract_Discount__c.Value_per__c];
                }
                if (fieldApiName == API_NAMES.Contract_Discount__c.Value_amt__c) {
                    currentCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = currentCondition[API_NAMES.Contract_Discount__c.Value_amt__c];
                }
                if (fieldApiName == API_NAMES.Contract_Discount__c.Disc_BDate__c) {
                    currentCondition[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = event.target.value;
                }
                if (fieldApiName == API_NAMES.Contract_Discount__c.Disc_EDate__c) {
                    currentCondition[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = event.target.value;
                }
                _fireEvent(this.pageRef, 'fakesave_' + contractId, {
                    condition: currentCondition,
                    successCallback: () => {
                        changesMap[mapKey] = currentCondition;
                        if (self.calculateIndex) {
                            clearTimeout(self.calculateIndexTimeOut);
                            self.calculateIndexTimeOut = setTimeout(() => {
                                self.calculateIndex();
                            }, CALCULATE_INDEX_TIMEOUT);
                        }
                    },
                });
            }
        }
    }
    @api updateShowIndexes(showIndexes) {
        this.showIndexes = showIndexes;
        if (showIndexes) {
            this.indexesClass = '';
        } else {
            this.indexesClass = 'slds-hide';
        }
    }
    @api save() {
        return new Promise((resolve, reject) => {
            let hasChanges = this.hasChanges;
            let hasContractChanges = this.hasContractChanges;
            let discounts = Object.values(this.changesMap).map(item => {
                let newItem = { ...item };
                delete newItem.detailPopupFields;
                delete newItem.Condition_Type;
                delete newItem.contract;
                delete newItem.popOverClass;
                delete newItem.hideInfo;
                delete newItem.class;
                delete newItem.isDisplayed;
                return newItem;
            });
            let contract = { ...this.contract };
            delete contract[API_NAMES.Contract__c.Status__c];
            let contractDataWrapper = { contract: contract, discounts: discounts };
            if (hasContractChanges || (hasChanges && discounts.length)) {
                let isTopOrPe = this.isTopOrPe;
                saveContractData({ contractDataWrapperJSON: JSON.stringify(contractDataWrapper) }).then(result => {
                    let contractsSaveResult = JSON.parse(result);
                    contractsSaveResult.isTopOrPe = isTopOrPe;
                    if (!contractsSaveResult.errors.some(i => i.includes('UNABLE_TO_LOCK_ROW'))) {
                        this.changesMap = {};
                        this.hasContractChanges = false;
                        this.hasChanges = false;
                        this._refreshData(true);
                    }
                    resolve(JSON.stringify(contractsSaveResult));
                }).catch(error => {
                    console.error(error);
                    if (error.body) {
                        if (error.body.message.includes('UNABLE_TO_LOCK_ROW')) {
                            resolve(JSON.stringify({
                                isTopOrPe: isTopOrPe,
                                errors: [error.body.message],
                                isSuccess: false,
                                isEmpty: false,
                            }));
                        }
                    } else {
                        if (error.message && error.message.includes('UNABLE_TO_LOCK_ROW')) {
                            msg = Labels.MSG_Error_Lock;
                            resolve(JSON.stringify({
                                isTopOrPe: isTopOrPe,
                                errors: [error.message],
                                isSuccess: false,
                                isEmpty: false,
                            }));
                        }
                    }
                    reject(error);
                });
            } else {
                resolve(JSON.stringify({ isEmpty: true, isSuccess: true, errors: [] }));
            }
        });
    }
    @api toggleExpension(isExpanded, index, negodiscount) {
        this._toggleExpension(isExpanded, index, negodiscount);
    }
    _toggleExpension(isExpanded, index, negodiscount) {
        let filteredIndex = this.arraysCondtion.find(item => item.key == index);
        if (filteredIndex) {
            if (negodiscount) {
                let filteredNegodiscount = filteredIndex.negodiscounts.find(item => item.key == negodiscount);
                if (filteredNegodiscount) {
                    filteredNegodiscount.isExpanded = isExpanded;
                }
            } else {
                filteredIndex.isExpanded = isExpanded;
            }
            this.arraysCondtion = this.arraysCondtion.map(item => item);
        }
    }
    @api contractAll() {
        this._contractAll();
    }
    _contractAll() {
        this.arraysCondtion.forEach(item => {
            item.negodiscounts.forEach(item2 => {
                item2.isExpanded = false;
            });
            item.isExpanded = false;
        });
        this.arraysCondtion = this.arraysCondtion.map(item => item);
    }
    @api expandAll() {
        this._expandAll();
    }
    _expandAll() {
        this.arraysCondtion.forEach(item => {
            item.negodiscounts.forEach(item2 => {
                item2.isExpanded = true;
            });
            item.isExpanded = true;
        });
        this.arraysCondtion = this.arraysCondtion.map(item => item);
    }
    @api removeSpecificCondition(index, negoDiscountType, cIndex) {
        this._removeSpecificCondition(index, negoDiscountType, cIndex);
    }
    _removeSpecificCondition(negotiateIndex, negotiateType, index) {
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                let currentCondition = negoType.conditions[index];
                let oldDeleteStatus = currentCondition.deleted;
                currentCondition.deleted = true;
                if (oldDeleteStatus != currentCondition.deleted) {
                    negoType.conditions = negoType.conditions.map(item => item);
                }
            }
        }
    }
    @api updateHasDisplayedContractData(index, negoDiscountType, cIndex, hasDataOnContractsNotHidden) {
        this._updateHasDisplayedContractData(index, negoDiscountType, cIndex, hasDataOnContractsNotHidden);
    }
    _updateHasDisplayedContractData(negotiateIndex, negotiateType, index, hasDataOnContractsNotHidden) {
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                let currentCondition = negoType.conditions[index];
                let oldhasDataOnContractsNotHidden = currentCondition.hasDataOnContractsNotHidden;
                currentCondition.hasDataOnContractsNotHidden = hasDataOnContractsNotHidden;
                if (oldhasDataOnContractsNotHidden != currentCondition.hasDataOnContractsNotHidden) {
                    negoType.conditions = negoType.conditions.map(item => item);
                }
            }
        }
    }
    deleteHandler(event) {
        // let contractId = this.contractId;
        let self = this;
        this.hasChanges = true;
        _fireEvent(this.pageRef, 'hasChanges', {});
        let index = event.target.dataset.rowindex;
        let negotiateIndex = event.target.dataset.index;
        let negotiateType = event.target.dataset.negotiatetype;
        let mapKey = negotiateIndex + '-' + negotiateType + '-' + index;
        let negoIndex = this.arraysCondtion.find(item => item.key == negotiateIndex);
        if (negoIndex) {
            let negoType = negoIndex.negodiscounts.find(item => item.key == negotiateType);
            if (negoType && negoType.conditions && negoType.conditions.length > index) {
                let currentCondition = negoType.conditions[index];
                currentCondition[API_NAMES.Contract_Discount__c.Value_amt__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Value_per__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.unit_amount__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c] = null;
                // currentCondition[API_NAMES.Contract_Discount__c.Rank__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Display_Order__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Index_val__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Index_perc__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Base_TO_Tariff_Nego__c] = null;
                currentCondition[API_NAMES.Contract_Discount__c.Status__c] = 'Deleted';
                this.changesMap[mapKey] = currentCondition;
                if (!currentCondition.Id) {
                    delete this.changesMap[mapKey];
                }
                // console.log('deleteHandler >>>> ', 'fakesave');
                // _fireEvent(this.pageRef, 'fakesave_' + contractId, {
                //     condition: currentCondition,
                //     successCallback: () => {
                //         if (self.calculateIndex) {
                //             clearTimeout(self.calculateIndexTimeOut);
                //             self.calculateIndexTimeOut = setTimeout(() => {
                //                 self.calculateIndex();
                //             }, CALCULATE_INDEX_TIMEOUT);
                //         }
                //         _fireEvent(self.pageRef, 'refreshList', {});
                //     },
                // });
                if (self.calculateIndex) {
                    clearTimeout(self.calculateIndexTimeOut);
                    self.calculateIndexTimeOut = setTimeout(() => {
                        self.calculateIndex();
                    }, CALCULATE_INDEX_TIMEOUT);
                }
                _fireEvent(self.pageRef, 'refreshList', {});
            }
        }
    }
}