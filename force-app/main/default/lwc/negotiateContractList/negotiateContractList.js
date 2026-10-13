import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { Labels, API_NAMES, checkConditionEmpty } from "c/contractServices";
import { CurrentPageReference } from 'lightning/navigation';
import getObjectLabels from "@salesforce/apex/NegotiateCmpController.getObjectLabels";
import fakeSaveContractDiscountData from "@salesforce/apex/NegotiateContractCmpController.fakeSaveContractDiscountData";
import populateFields from "@salesforce/apex/NegotiateContractCmpController.populateFields";
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubSub';
const SEARCH_TIME_OUT = 500;
const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
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
export default class NegotiateContracts extends LightningElement {
    @api nonce;
    @api postSigned;
    API_NAMES = API_NAMES;
    @track lockedByApprovalProcess = false;
    @api lockedActions;
    @track loadingLockedActions = true;
    @api contractRTN1Settings;
    @wire(CurrentPageReference) pageRef;
    fields = {
        Rank__c: API_NAMES.Contract_Discount__c.Rank__c,
    }
    @api get hasAnyInternational() {
        let contractIds = this.contractIds;
        return contractIds.some(contractId => {
            let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
            return contractCmp && contractCmp.hasAnyInternational;
        });
    }
    @api get hasChangesToSave() {
        let children = this.template.querySelectorAll('c-negotiate-contract')
        let hasChangesToSave = false;
        for (let i = 0; i < children.length; i++) {
            hasChangesToSave |= children[i].hasChangesToSave;
        }
        return hasChangesToSave;
    }
    @api translation;
    @api hasTopNotSimulation;
    @api hasPe;
    @api hasPeSigned;
    @track contractIds = [];
    @api negoDiscountTypeLabelsMap;
    @api indexLabelsMap;
    @api slabsMethodMap;
    @track contracts;
    @track containerStyle;
    @track populatedFoldings = {};
    @api readyEvent;
    @api negoYear;
    @api availablePolComs;
    @api currentUrl;
    @track availablePePolComs;
    @api missingFoldings = {};
    @api headerHeight;
    @track Labels = Labels;
    conditionsGroupping = {};
    addConditionGroupping = {};
    groupingProcessedContractIds = {};
    validTariffConditionMap = {};
    @track allowedTariffs = {};
    @track grouppedConditions = [];
    @track indexesClass = 'slds-hide';
    @track showIndexes = true;
    @track refContract = {};
    @track toggleMap = {};
    @track ontopBdate;
    @track ontopEdate;
    @track refTO;
    @track refQty;
    @track refDuration;
    @track safeBalanceTO;
    @track safeBalanceQty;
    @track safeBalanceDuration;
    @track riseRateDiff;
    @track depreciationRiseRateDiff;
    @track requireRank = false;
    @track addConditionModal = {
        Loading: false,
        isOpen: false,
        index: '',
        negodiscount: '',
        availablenewTariffs: [],
        get availablenewTariffsOptions() {
            return this.availablenewTariffs.map(item => {
                return { value: item.Id, label: item.Name };
            }).sort((i1, i2) => i1.label.localeCompare(i2.label));
        },
        currentCondition: undefined,
        currentConditions: [],
        fields: [],
        submit(event) {
            let self = this;
            this.addConditionModal.Loading = true;
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'addConditionModal_submit' });
            try {
                let requireRank = this.requireRank;
                let missingFoldings = this.missingFoldings;
                let conditionsGroupping = this.conditionsGroupping;
                let availablePePolComs = this.availablePePolComs;
                let grouppedConditions = this.grouppedConditions;
                let availablenewTariffs = this.addConditionModal.availablenewTariffs;
                let index = this.addConditionModal.index;
                let negodiscount = this.addConditionModal.negodiscount;
                let fields = this.addConditionModal.fields;
                let conditionPicker = this.template.querySelector('.conditionPicker');
                let rankPicker = this.template.querySelector('.rankPicker');
                if (conditionPicker && conditionPicker.reportValidity() && ((requireRank && rankPicker && rankPicker.reportValidity()) || !requireRank)) {
                    if (this.addConditionModal.currentConditions.every(item => !item.isDisplayed)) {
                        this.dispatchEvent(new ShowToastEvent({
                            // title: Labels.LBL_Info,
                            message: Labels.MSG_Invalid_Condition,
                            variant: INFO_VARIANT,
                        }));
                        self.addConditionModal.isOpen = false;
                        self.addConditionModal.availablenewTariffs = [];
                        self.addConditionModal.index = '';
                        self.addConditionModal.negodiscount = '';
                        self.addConditionModal.currentConditions = [];
                        self.addConditionModal.Loading = false;
                        _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'addConditionModal_submit' });
                        _fireEvent(self.pageRef, 'recalculateFolding', {});
                    } else if (this.addConditionModal.currentConditions.some(item => fields.some(field => item[field.value]))) {
                        let tariffId = conditionPicker.value;
                        delete missingFoldings[tariffId];
                        let tariff = availablenewTariffs.find(item => item.Id == tariffId);
                        let currentConditions = this.addConditionModal.currentConditions;
                        let _currentConditions = [];
                        currentConditions.forEach(item => {
                            let c_condition = { ...item };
                            delete c_condition.addConditionPopUpFields;
                            delete c_condition.detailPopupFields;
                            delete c_condition.Condition_Type;
                            delete c_condition.contract;
                            delete c_condition.popOverClass;
                            delete c_condition.hideInfo;
                            delete c_condition.class;
                            delete c_condition.isDisplayed;
                            if (item.isDisplayed) {
                                _currentConditions.push(c_condition);
                            }
                        });
                        let errorMessages = [];
                        let continueProcessing = () => {
                            if (errorMessages && errorMessages.length) {
                                self.dispatchEvent(new ShowToastEvent({
                                    // title: Labels.LBL_Error,
                                    message: errorMessages.join('\n'),
                                    variant: ERROR_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            } else {
                                conditionsGroupping[index][negodiscount][conditionPicker.value].val++;
                                conditionsGroupping[index][negodiscount][conditionPicker.value].peVal++;
                                let filteredIndex = grouppedConditions.find(item => item.key == index);
                                if (filteredIndex) {
                                    let filteredNegodiscount = filteredIndex.negodiscounts.find(item => item.key == negodiscount);
                                    if (filteredNegodiscount) {
                                        let lastIndex = 0;
                                        let tIndex = 0;
                                        filteredNegodiscount.conditions.forEach((item, index) => {
                                            if (item.condition.Id == conditionPicker.value) {
                                                tIndex++;
                                                lastIndex = index;
                                            }
                                        });
                                        filteredNegodiscount.conditions.push({
                                            Name: tariff.Name + (tIndex != 0 ? '(' + tIndex + ')' : ''),
                                            condition: tariff,
                                            hasDataOnContractsNotHidden: true,
                                            peConditions: availablePePolComs[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]],
                                            get cell1Class() {
                                                let classes = [
                                                    '_slds-p-right_none',
                                                    'slds-tree__item',
                                                ];
                                                if (this.condition[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                                                    classes.push('preclosed-cell');
                                                }
                                                return classes.join(' ');
                                            },
                                            get cell2Class() {
                                                let classes = [
                                                    'condition-cell',
                                                ];
                                                if (this.condition[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                                                    classes.push('preclosed-cell');
                                                }
                                                return classes.join(' ');
                                            },
                                            get rowClass() {
                                                return (filteredNegodiscount && filteredNegodiscount.rowClass ? filteredNegodiscount.rowClass : '') + (this.deleted || !this.hasDataOnContractsNotHidden ? ' slds-hide' : '');
                                            },
                                        });
                                    }
                                }
                                currentConditions.forEach(condition => {
                                    delete condition.addConditionPopUpFields;
                                    let contractCmp = self.template.querySelector(`[data-id="` + condition[API_NAMES.Contract_Discount__c.Contract__c] + `"]`);
                                    if (contractCmp && contractCmp.populateNewConditions) {
                                        contractCmp.populateNewConditions(condition);
                                    }
                                });
                                let refContract = self.refContract;
                                let contractPE = self.contractPE;
                                let simulationNumber = self.simulationNumber;
                                let postSimulationNumber = self.postSimulationNumber;
                                let refContractBUId = self.refContractBUId;
                                let refContractSourceBUId = self.refContractSourceBUId;
                                let refContractConditions = [];
                                if (refContract && refContract.Id) {
                                    let contractCmp = self.template.querySelector(`[data-id="` + refContract.Id + `"]`);
                                    if (contractCmp && contractCmp.getConditions) {
                                        refContractConditions = contractCmp.getConditions();
                                    }
                                }
                                JSON.parse(JSON.stringify(self.contractIds)).forEach(contractId => {
                                    let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
                                    if (contractCmp && contractCmp.populateRefConditions) {
                                        contractCmp.populateRefConditions(refContract, contractPE, refContractConditions, simulationNumber, postSimulationNumber, refContractBUId, refContractSourceBUId);
                                    }
                                });
                                self.addConditionModal.isOpen = false;
                                self.addConditionModal.availablenewTariffs = [];
                                self.addConditionModal.index = '';
                                self.addConditionModal.negodiscount = '';
                                self.addConditionModal.currentConditions = [];
                                self.addConditionModal.Loading = false;
                                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'addConditionModal_submit' });
                                _fireEvent(self.pageRef, 'recalculateFolding', {});
                                _fireEvent(self.pageRef, 'refreshList', {});
                            }
                            self.addConditionModal.Loading = false;
                            _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'addConditionModal_submit' });
                            _fireEvent(self.pageRef, 'refreshList', {});
                        };
                        // processFakeSaveItem();
                        // let processFakeSaveItem = () => {
                        //     let _fakeSaveCondition = _currentConditions.shift();
                        //     if (_fakeSaveCondition) {
                        //         fakeSaveContractDiscountData({ contractDiscounts_JSON: JSON.stringify([_fakeSaveCondition]) }).then(result => {
                        //             let dmlResults = JSON.parse(result);
                        //             if (!dmlResults.isSuccess) {
                        //                 if (dmlResults.errors) {
                        //                     errorMessage = [...errorMessage, ...dmlResults.errors.filter((itemError, index) => index == dmlResults.errors.indexOf(itemError))];
                        //                 }
                        //             }
                        //             processFakeSaveItem();
                        //         }).catch(err => {
                        //             console.log(`🚀 -----------------------------------------------------------------------------------------------🚀`);
                        //             console.log(`🚀 ~ file: negotiateContracts.js ~ line 235 ~ NegotiateContracts ~ fakeSaves.forEach ~ err`, err);
                        //             console.log(`🚀 -----------------------------------------------------------------------------------------------🚀`);
                        //             errorMessage.push(err);
                        //             processFakeSaveItem();
                        //         });
                        //     } else {
                        //         continueProcessing();
                        //     }
                        // }
                        if (_currentConditions && _currentConditions.length) {
                            fakeSaveContractDiscountData({ contractDiscounts_JSON: JSON.stringify(_currentConditions) }).then(result => {
                                let dmlResults = JSON.parse(result);
                                if (!dmlResults.isSuccess) {
                                    if (dmlResults.errors) {
                                        errorMessages = [...errorMessages, ...dmlResults.errors.filter((itemError, index) => index == dmlResults.errors.indexOf(itemError))];
                                    }
                                }
                                continueProcessing();
                            }).catch(err => {
                                console.log(`🚀 -----------------------------------------------------------------------------------------------🚀`);
                                console.log(`🚀 ~ file: negotiateContracts.js ~ line 235 ~ NegotiateContracts ~ fakeSaves.forEach ~ err`, err);
                                console.log(`🚀 -----------------------------------------------------------------------------------------------🚀`);
                                errorMessages.push(err);
                                continueProcessing();
                            });
                        } else {
                            continueProcessing();
                        }
                    } else {
                        if (!this.addConditionModal.currentConditions.some(item => [
                            API_NAMES.Contract_Discount__c.Value_per__c,
                            API_NAMES.Contract_Discount__c.Value_amt__c,
                            API_NAMES.Contract_Discount__c.unit_amount__c,
                        ].some(keyField => item[keyField]))) {
                            this.dispatchEvent(new ShowToastEvent({
                                message: Labels.MSG_Missing_Remuneration,
                                variant: ERROR_VARIANT,
                            }));
                            self.addConditionModal.Loading = false;
                            _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'addConditionModal_submit' });
                            _fireEvent(self.pageRef, 'refreshList', {});
                        }
                    }
                } else {
                    self.addConditionModal.Loading = false;
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'addConditionModal_submit' });
                    _fireEvent(self.pageRef, 'refreshList', {});
                }
            } catch (error) {
                console.error(error);
            }
        },
        close(event) {
            this.addConditionModal.isOpen = false;
            this.addConditionModal.availablenewTariffs = [];
            this.addConditionModal.index = '';
            this.addConditionModal.negodiscount = '';
            this.addConditionModal.rankValue = '';
        },
        handleFocusOut(event) {
            let self = this;
            let itemIndex = event?.target?.dataset?.itemIndex;
            let fieldApiName = event?.target?.dataset?.fieldApiName;
            let currentConditions = this.addConditionModal.currentConditions;
            if (fieldApiName && currentConditions.length > itemIndex) {
                let currentCondition = currentConditions[itemIndex];
                self.populateFields(currentCondition, currentCondition[API_NAMES.Contract_Discount__c.Condition_Type__r], true);
            }
        },
        handleConditionValueChange(event) {
            let itemIndex = event?.target?.dataset?.itemIndex;
            let fieldApiName = event?.target?.dataset?.fieldApiName;
            let currentConditions = this.addConditionModal.currentConditions;
            if (fieldApiName && currentConditions.length > itemIndex) {
                let currentCondition = currentConditions[itemIndex];
                currentCondition[fieldApiName] = event.target.value;
                currentCondition.addConditionPopUpFields.forEach(field => {
                    if (field.fieldApiName == fieldApiName) {
                        field.fieldValue = event.target.value;
                    }
                });
                if (fieldApiName == API_NAMES.Contract_Discount__c.Value_per__c) {
                    currentCondition[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = event.target.value;
                }
                if (fieldApiName == API_NAMES.Contract_Discount__c.Value_amt__c) {
                    currentCondition[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = event.target.value;
                }
            }
        },
        handleTariffChange(event) {
            let self = this;
            let validTariffConditionMap = this.validTariffConditionMap;
            let availablePePolComs = this.availablePePolComs;
            let tariffId = event.detail.value;
            let tariff = this.addConditionModal.availablenewTariffs.find(item => item.Id == tariffId);
            let contracts = this.contracts;
            let template = this.template;
            if (tariff) {
                // this.requireRank = tariff[API_NAMES.Pol_Com_Condition__c.Index__c] == 'Index1' || tariff[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c];
                this.requireRank = false;
                this.addConditionModal.currentConditions.forEach(item => {
                    let _tariff = tariff;
                    let contractCmp = template.querySelector(`[data-id="` + item[API_NAMES.Contract_Discount__c.Contract__c] + `"]`);
                    let isDisplayed = true;
                    if (contractCmp && contractCmp.isReadOnly) {
                        let currentContractStyle = contracts.find(con => con.contractId == item[API_NAMES.Contract_Discount__c.Contract__c]);
                        isDisplayed &= !contractCmp.isReadOnly();
                        if (currentContractStyle) {
                            isDisplayed &= currentContractStyle.colclass && !currentContractStyle.colclass.includes('slds-hide') ? true : false;
                        }
                    } else {
                        isDisplayed = false;
                    }
                    item.isDisplayed = isDisplayed;
                    if (_tariff[API_NAMES.Pol_Com_Condition__c.Is_Yearly_Condition__c]) {
                        if (item[API_NAMES.Contract_Discount__c.Contract__r].RecordType.DeveloperName != 'Period_Extension') {
                            item.isDisplayed = true && !item.isReadOnlyContract;
                        } else {
                            item.isDisplayed = false && !item.isReadOnlyContract;
                        }
                    }
                    if (_tariff[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                        if (item[API_NAMES.Contract_Discount__c.Contract__r].RecordType.DeveloperName == 'Simulation') {
                            item.isDisplayed = false && !item.isReadOnlyContract;
                        } else {
                            item.isDisplayed = true && !item.isReadOnlyContract;
                        }
                    }
                    if (item[API_NAMES.Contract_Discount__c.Contract__r].RecordType.DeveloperName == 'Period_Extension' && availablePePolComs.hasOwnProperty(_tariff.Id)) {
                        let bdate = new Date(item[API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.Contract_BDate__c]);
                        let edate = new Date(item[API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.Contract_EDate__c]);
                        let peTariff = availablePePolComs[_tariff.Id].find(ptTariff => {
                            if (_tariff.Id != ptTariff.Id) {
                                let tbdate = ptTariff[API_NAMES.Pol_Com_Condition__c.Status_BDate__c] ? new Date(ptTariff[API_NAMES.Pol_Com_Condition__c.Status_BDate__c]) : undefined;
                                let tedate = ptTariff[API_NAMES.Pol_Com_Condition__c.Status_EDate__c] ? new Date(ptTariff[API_NAMES.Pol_Com_Condition__c.Status_EDate__c]) : undefined;
                                let condition_status = ptTariff[API_NAMES.Pol_Com_Condition__c.Condition_Status__c];
                                if (condition_status == 'Open') {
                                    return tbdate.getTime() <= edate.getTime();
                                }
                                if (!['Simulation', 'Signed', 'To_Be_Signed'].includes(item[API_NAMES.Contract_Discount__c.Contract__r].RecordType.DeveloperName) && condition_status == 'PreClosed') {
                                    return tbdate.getTime() <= edate.getTime();
                                }
                                if (condition_status == 'Close') {
                                    (tbdate.getTime() >= bdate.getTime() && tbdate.getTime() <= edate.getTime())
                                    return (tbdate.getTime() >= bdate.getTime() && tbdate.getTime() <= edate.getTime())
                                        || (tedate.getTime() >= bdate.getTime() && tedate.getTime() <= edate.getTime())
                                        || (tbdate.getTime() <= bdate.getTime() && tedate.getTime() >= edate.getTime());
                                }
                            }
                            return false;
                        });
                        if (peTariff) {
                            _tariff = peTariff;
                        }
                        // _tariff = availablePePolComs[_tariff.Id][availablePePolComs[_tariff.Id].length - 1];
                    }
                    item[API_NAMES.Contract_Discount__c.Condition_Type__c] = _tariff.Id;
                    item[API_NAMES.Contract_Discount__c.Condition_Type__r] = _tariff;
                    item[API_NAMES.Contract_Discount__c.t_SetPopulateDefaultValuesInTrigger__c] = false;
                    self.populateFields(item, _tariff, false);
                    this.addConditionModal.rankValue = item[API_NAMES.Contract_Discount__c.Rank__c];
                    if (_tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/%/gi) ? false : true) {
                        item[API_NAMES.Contract_Discount__c.Value_per__c] = null;
                        item[API_NAMES.Contract_Discount__c.Value_per_Y1__c] = null;
                    }
                    if (_tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[F]/gi) ? false : true) {
                        item[API_NAMES.Contract_Discount__c.Value_amt__c] = null;
                        item[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] = null;
                    }
                    if (_tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[U]/gi) ? false : true) {
                        item[API_NAMES.Contract_Discount__c.unit_amount__c] = null;
                        item[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c] = null;
                    }
                    try {
                        item.isDisplayed &= validTariffConditionMap[item[API_NAMES.Contract_Discount__c.Contract__c]] && validTariffConditionMap[item[API_NAMES.Contract_Discount__c.Contract__c]][_tariff.Id] ? true : false;
                    } catch (error) {
                        console.log(error);
                    }
                    item.addConditionPopUpFields = [
                        { fieldName: API_NAMES.Contract_Discount__c.Value_per__c, label: '%', fieldValue: item[API_NAMES.Contract_Discount__c.Value_per__c] || '' },
                        { fieldName: API_NAMES.Contract_Discount__c.Value_amt__c, label: Labels.Amount, fieldValue: item[API_NAMES.Contract_Discount__c.Value_amt__c] || '' },
                        { fieldName: API_NAMES.Contract_Discount__c.unit_amount__c, label: Labels.LBL_unit_amount__c, fieldValue: item[API_NAMES.Contract_Discount__c.unit_amount__c] || '' },
                        { fieldName: API_NAMES.Contract_Discount__c.Unit_Amount_Type__c, label: Labels.LBL_Unit_Amount_Type__c, fieldValue: item[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c] || '' },
                    ].filter(field => {
                        if (tariff) {
                            return ((field.fieldName == API_NAMES.Contract_Discount__c.Value_per__c) && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/%/gi) ? true : false)
                                || ((field.fieldName == API_NAMES.Contract_Discount__c.unit_amount__c) && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[U]/gi) ? true : false)
                                || ((field.fieldName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c) && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[U]/gi) ? true : false)
                                || ((field.fieldName == API_NAMES.Contract_Discount__c.Value_amt__c) && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[F]/gi) ? true : false);
                        } else {
                            return false;
                        }
                    });
                    // item.isDisplayed &= validTariffConditionMap[item[API_NAMES.Contract_Discount__c.Contract__c]] && validTariffConditionMap[item[API_NAMES.Contract_Discount__c.Contract__c]][_tariff.Id] ? true : false;
                });
                this.addConditionModal.currentConditions = this.addConditionModal.currentConditions.map(item => item);
            }
            this.addConditionModal.fields = [
                { value: API_NAMES.Contract_Discount__c.Value_per__c, label: '%' },
                { value: API_NAMES.Contract_Discount__c.Value_amt__c, label: Labels.Amount },
                { value: API_NAMES.Contract_Discount__c.unit_amount__c, label: Labels.LBL_unit_amount__c },
                { value: API_NAMES.Contract_Discount__c.Unit_Amount_Type__c, label: Labels.LBL_Unit_Amount_Type__c },
            ].filter(field => {
                if (tariff) {
                    return (field.value == API_NAMES.Contract_Discount__c.Value_per__c && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/%/gi) ? true : false)
                        || (field.value == API_NAMES.Contract_Discount__c.unit_amount__c && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[U]/gi) ? true : false)
                        || (field.value == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[U]/gi) ? true : false)
                        || (field.value == API_NAMES.Contract_Discount__c.Value_amt__c && tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c] && tariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c].match(/[F]/gi) ? true : false);
                } else {
                    return false;
                }
            });
        },
        handleRankChange(event) {
            let rank = event.detail.value;
            this.addConditionModal.rankValue = rank;
            this.addConditionModal.currentConditions.forEach(item => {
                if (item.isDisplayed) {
                    item[API_NAMES.Contract_Discount__c.Rank__c] = rank;
                }
            });
        },
        addCondition(event) {
            let contracts = this.contracts;
            let negoDiscountTypeLabelsMap = this.negoDiscountTypeLabelsMap;
            let indexLabelsMap = this.indexLabelsMap;
            let self = this;
            let addConditionGroupping = this.addConditionGroupping;
            let index = event.target.dataset.index;
            let negodiscount = event.target.dataset.negodiscount;
            let contractIds = this.contractIds;
            let userProfileId = this.userProfileId;
            let availablenewTariffs = Object.values(addConditionGroupping[index][negodiscount]).map(item => item.condition).filter(item => {
                try {
                    return (contractIds.some(contractId => {
                        let currentContractStyle = contracts.find(con => con.contractId == contractId);
                        let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
                        if (contractCmp && contractCmp.getValidTariffConditionMap && contractCmp.isReadOnly) {
                            return !contractCmp.isReadOnly() && contractCmp.getValidTariffConditionMap()[item.Id] && currentContractStyle.colclass && !currentContractStyle.colclass.includes('slds-hide') ? true : false;
                        }
                        return false;
                    }) && !item[API_NAMES.Pol_Com_Condition__c.Parent_Condition__c]) && (!item?.RecordTypeId || item?.RecordType?.DeveloperName == 'Main_Term')
                        && (!item[API_NAMES.Pol_Com_Condition__c.LimitUsage_ToProfile__c] || item[API_NAMES.Pol_Com_Condition__c.LimitUsage_ToProfile__c].includes(userProfileId));
                } catch (error) {
                    console.log(`🚀 -----------------------------------------------------------------------------------------------------🚀`);
                    console.log(`🚀 ~ file: negotiateContracts.js ~ line 330 ~ NegotiateContracts ~ availablenewTariffs ~ error`, error);
                    console.log(`🚀 -----------------------------------------------------------------------------------------------------🚀`);
                }
                return false;
            });
            if (!availablenewTariffs.length) {
                this.dispatchEvent(new ShowToastEvent({
                    // title: Labels.LBL_Info,
                    message: Labels.MSG_No_Available_Pol_Com,
                    variant: INFO_VARIANT,
                }));
                return;
            }
            this.addConditionModal.availablenewTariffs = availablenewTariffs;
            this.addConditionModal.index = index;
            this.addConditionModal.negodiscount = negodiscount;
            this.addConditionModal.indexLabel = indexLabelsMap[index] || index;
            this.addConditionModal.negodiscountLabel = negoDiscountTypeLabelsMap[negodiscount] || negodiscount;
            let currentConditions = [];
            let hasContractsNegoYear = false;
            contractIds.forEach(contractId => {
                let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
                if (contractCmp && contractCmp.isReadOnly && contractCmp.contract) {
                    let currentContractStyle = contracts.find(con => con.contractId == contractId);
                    let contract = contractCmp.contract;
                    let cellClass = contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] ? 'cell_On_Top' : 'cell_' + contract.RecordType.DeveloperName.replace(/_/g, '-').toLocaleLowerCase();
                    let isDisplayed = !contractCmp.isReadOnly();
                    if (currentContractStyle) {
                        isDisplayed &= currentContractStyle.colclass && !currentContractStyle.colclass.includes('slds-hide') ? true : false;
                    }
                    hasContractsNegoYear = hasContractsNegoYear || isDisplayed;
                    let newItem = {
                        SObjectType: API_NAMES.Contract_Discount__c.objectApiName,
                        isDisplayed: isDisplayed,
                        isReadOnlyContract: contractCmp.isReadOnly(),
                        class: cellClass,
                        get contract() {
                            return this[API_NAMES.Contract_Discount__c.Contract__r];
                        },
                    };
                    newItem[API_NAMES.Contract_Discount__c.Contract__c] = contractId;
                    newItem[API_NAMES.Contract_Discount__c.Contract__r] = contract;
                    newItem[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = contract[API_NAMES.Contract__c.BusinessUnitContract__c];
                    newItem[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = contract[API_NAMES.Contract__c.BusinessUnitContract__r];
                    newItem[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = contract[API_NAMES.Contract__c.Total_Qty__c];
                    newItem[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = contract[API_NAMES.Contract__c.Total_TO__c];
                    newItem[API_NAMES.Contract_Discount__c.Product_Scope__c] = contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
                    newItem[API_NAMES.Contract_Discount__c.Product_Scope__r] = contract[API_NAMES.Contract__c.Supplier_Nego_Scope__r];
                    newItem[API_NAMES.Contract_Discount__c.Disc_BDate__c] = contract[API_NAMES.Contract__c.Contract_BDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_EDate__c] = contract[API_NAMES.Contract__c.Contract_EDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = contract[API_NAMES.Contract__c.Contract_BDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = contract[API_NAMES.Contract__c.Contract_EDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Condition_Type__c] = '';
                    newItem[API_NAMES.Contract_Discount__c.Condition_Type__r] = '';
                    newItem[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c] = negodiscount;
                    newItem[API_NAMES.Contract_Discount__c.Index__c] = index;
                    currentConditions.push(newItem);
                }
            });
            this.addConditionModal.currentConditions = currentConditions;
            this.addConditionModal.fields = [];
            if (hasContractsNegoYear) {
                this.addConditionModal.isOpen = true;
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    // title: Labels.LBL_Info,
                    message: Labels.MSG_No_Available_Contracts_On_Nego_Year,
                    variant: INFO_VARIANT,
                }));
            }
        }
    }
    populateFields(item, _tariff, onlyInvoiceFields) {
        let discount = JSON.parse(JSON.stringify(item));
        delete discount.addConditionPopUpFields;
        delete discount.detailPopupFields;
        delete discount.Condition_Type;
        delete discount.contract;
        delete discount.popOverClass;
        delete discount.hideInfo;
        delete discount.class;
        delete discount.isDisplayed;
        populateFields({
            DiscountJSON: JSON.stringify(discount),
            tarrifConditionJSON: JSON.stringify(_tariff),
            onlyInvoiceFields: onlyInvoiceFields,
        }).then((result) => {
            discount = JSON.parse(result);
            for (let field of Object.keys(discount)) {
                item[field] = discount[field];
            }
        }).catch((error) => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({
                // title: Labels.LBL_Error,
                message: error?.body?.message || error?.message || error,
                variant: ERROR_VARIANT,
                mode: STICKY_VARIANT
            }));
        });
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
    renderedCallback() {
        _fireEvent(this.pageRef, 'refresh_walkthrought_position', {});
        this.changeHeight();
    }

    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        globalMethods._fireEvent = (pageref, eventName, details) => {
            fireEvent(pageref, eventName + '_' + this.nonce, details);
        }
        globalMethods._registerListener = (eventName, callback, cmpInstance) => {
            registerListener(eventName + '_' + this.nonce, callback, cmpInstance);
        }
        let self = this;
        _registerListener('unlockLoadingLockedActions', () => {
            this.loadingLockedActions = false;
        }, this);
        getObjectLabels().then(result => {
            let data = JSON.parse(result);
            let translation = data.labelsMap;
            self.Labels.LBL_unit_amount__c = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.unit_amount__c];
            self.Labels.LBL_Unit_Amount_Type__c = translation[API_NAMES.Contract_Discount__c.objectApiName][API_NAMES.Contract_Discount__c.Unit_Amount_Type__c];
        });
        let refreshList;
        _registerListener('refreshList', () => {
            try { clearTimeout(refreshList); } catch (error) { console.log(error); }
            refreshList = setTimeout(() => {
                try {
                    let checkMap = {};
                    let grouppedConditions = self.grouppedConditions;
                    let contractIds = self.contractIds;
                    let template = self.template;
                    let isContractHiddenMap = {};
                    self.contracts.forEach(item => isContractHiddenMap[item.contractId] = item.colclass && item.colclass.includes('slds-hide') ? true : false);
                    contractIds.forEach(contractId => {
                        let contractCmp = template.querySelector(`[data-id="` + contractId + `"]`);
                        if (contractCmp && contractCmp.getConditions) {
                            checkMap[contractId] = JSON.parse(JSON.stringify(contractCmp.getConditions()));
                        }
                    });
                    for (let ccIndex in grouppedConditions) {
                        let keyIndex = grouppedConditions[ccIndex].key;
                        for (let ccNegoDiscountType in grouppedConditions[ccIndex].negodiscounts) {
                            let keyNegoDiscountType = grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].key;
                            for (let cConditionIndex in grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].conditions) {
                                let c_condition = grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].conditions[cConditionIndex];
                                if (Object.keys(checkMap).every(contractId => {
                                    try {
                                        if (checkMap[contractId]) {
                                            let v1 = Object.values(checkMap[contractId]).find(item => item.key == keyIndex);
                                            // let v1 = checkMap[contractId][ccIndex];
                                            if (v1?.negodiscounts) {
                                                let v2 = Object.values(v1?.negodiscounts).find(item => item.key == keyNegoDiscountType);
                                                if (v2?.conditions) {
                                                    let v3 = v2?.conditions[cConditionIndex];
                                                    return checkConditionEmpty(v3);
                                                } else {
                                                    console.log('out scope >keyNegoDiscountType> not found', keyNegoDiscountType);
                                                }
                                            } else {
                                                console.log('out scope >keyIndex> not found', keyIndex);
                                            }
                                        } else {
                                            console.log('out scope >contractId> not found', contractId);
                                        }
                                    } catch (errorr) {
                                        console.log(errorr);
                                    }
                                    return true;
                                })) {
                                    contractIds.forEach(contractId => {
                                        let contractCmp = template.querySelector(`[data-id="` + contractId + `"]`);
                                        if (contractCmp && contractCmp.removeSpecificCondition) {
                                            contractCmp.removeSpecificCondition(grouppedConditions[ccIndex].key, grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].key, cConditionIndex);
                                        }
                                    });
                                    c_condition.deleted = true;
                                }
                                if (Object.keys(checkMap).every(contractId => {
                                    try {
                                        if (checkMap[contractId]) {
                                            let v1 = Object.values(checkMap[contractId]).find(item => item.key == keyIndex);
                                            // let v1 = checkMap[contractId][ccIndex];
                                            if (v1?.negodiscounts) {
                                                let v2 = Object.values(v1?.negodiscounts).find(item => item.key == keyNegoDiscountType);
                                                if (v2?.conditions) {
                                                    let v3 = v2?.conditions[cConditionIndex];
                                                    return checkConditionEmpty(v3) || isContractHiddenMap[contractId];
                                                } else {
                                                    console.log('out scope >keyNegoDiscountType> not found', keyNegoDiscountType);
                                                }
                                            } else {
                                                console.log('out scope >keyIndex> not found', keyIndex);
                                            }
                                        } else {
                                            console.log('out scope >contractId> not found', contractId);
                                        }
                                    } catch (errorr) {
                                        console.log(errorr);
                                    }
                                    return true;
                                })) {
                                    contractIds.forEach(contractId => {
                                        let contractCmp = template.querySelector(`[data-id="` + contractId + `"]`);
                                        if (contractCmp && contractCmp.updateHasDisplayedContractData) {
                                            contractCmp.updateHasDisplayedContractData(grouppedConditions[ccIndex].key, grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].key, cConditionIndex, false);
                                        }
                                    });
                                    c_condition.hasDataOnContractsNotHidden = false;
                                } else {
                                    contractIds.forEach(contractId => {
                                        let contractCmp = template.querySelector(`[data-id="` + contractId + `"]`);
                                        if (contractCmp && contractCmp.updateHasDisplayedContractData) {
                                            contractCmp.updateHasDisplayedContractData(grouppedConditions[ccIndex].key, grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].key, cConditionIndex, true);
                                        }
                                    });
                                    c_condition.hasDataOnContractsNotHidden = true;
                                }
                            }
                            grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].conditions = grouppedConditions[ccIndex].negodiscounts[ccNegoDiscountType].conditions.map(item => item);
                        }
                    }
                } catch (errorrr) {
                    console.log(`🚀 ------------------------------------------------------------------------------------------------------------🚀`);
                    console.log(`🚀 ~ file: negotiateContracts.js ~ line 671 ~ NegotiateContracts ~ refreshList=setTimeout ~ errorrr`, errorrr);
                    console.log(`🚀 ------------------------------------------------------------------------------------------------------------🚀`);
                }
            }, 300);
        }, this);
        _registerListener('updateHasPEOnRefresh', ({ hasPe }) => {
            this.hasPe = hasPe;
        }, this);
        _registerListener('updateHasPESignedOnRefresh', ({ hasPeSigned }) => {
            this.hasPeSigned = hasPeSigned;
        }, this);
        _registerListener('setOnTopDates', ({ bDate, eDate }) => {
            this.onTopBDate = bDate;
            this.onTopEDate = eDate;
        }, this);
        _registerListener('setPTDates', ({ bDate, eDate }) => {
            this.ptBdate = bDate;
            this.ptEdate = eDate;
        }, this);
        _registerListener('setRefToQtyDuration', ({ refTO, refQty, refDuration }) => {
            this.refTO = refTO;
            this.refQty = refQty;
            this.refDuration = refDuration;
        }, this);
        _registerListener('setSafeBalanceToQtyDuration', ({ safeBalanceTO, safeBalanceQty, safeBalanceDuration }) => {
            this.safeBalanceTO = safeBalanceTO;
            this.safeBalanceQty = safeBalanceQty;
            this.safeBalanceDuration = safeBalanceDuration;
        }, this);
        _registerListener('setNegoPlan', ({ riseRateDiff, depreciationRiseRateDiff }) => {
            this.riseRateDiff = riseRateDiff;
            this.depreciationRiseRateDiff = depreciationRiseRateDiff;
        }, this);
        let groupingProcessedContractIds = this.groupingProcessedContractIds;
        // this.contractIds.forEach(item => groupingProcessedContractIds[item] = false);
        this.availablePePolComs = {};
        _registerListener('registerContractId', ({ contractId }) => {
            if (contractId) {
                this.groupingProcessedContractIds[contractId] = false
                let contractIds = this.contractIds.filter(cId => cId != contractId);
                contractIds.push(contractId);
                this.contractIds = contractIds;
                this.contracts = contractIds.map((contractId, index) => {
                    let item = {
                        contractId: contractId,
                        colclass: 'slds-col' + (index != contractIds.length - 1 ? ' slds-p-right_small' : ''),
                        isLast: index == contractIds.length - 1
                    };
                    return item;
                });
            }
        }, this);
        _registerListener('lockedByApprovalProcess', ({ isActive }) => {
            this.lockedByApprovalProcess = isActive;
            this.lockedActions |= this.lockedByApprovalProcess;
        }, this);
        if (this.showIndexes) {
            this.indexesClass = '';
        } else {
            this.indexesClass = 'slds-hide';
        }
        _registerListener('handleNewOnTop', () => {
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: '_registerListener_handleNewOnTop' });
            let contractIds = this.contractIds;
            contractIds.forEach(contractId => {
                let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
                if (contractCmp && contractCmp.contract && contractCmp.contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && contractCmp.refreshData) {
                    contractCmp.refreshData();
                }
            });
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: '_registerListener_handleNewOnTop' });
        }, this);
        _registerListener('deletecontract', (event) => {
            let delContractId = new String(event.detail.contractId).valueOf();
            this.contractIds = this.contractIds.filter(contractId => contractId != delContractId);
            this.contracts = this.contracts.filter(item => item.Id != delContractId);
            let lastContract = this.contracts[this.contracts.length - 1];
            lastContract.colclass = lastContract.colclass.replace(/slds-p-right_small/gi, '');
        }, this);
        this.allowedTariffs = {};
        let allowedTariffs = this.allowedTariffs;
        if (!this.contractIds) {
            this.contractIds = [];
        }
        if (!this.contracts) {
            this.contracts = [];
        }
        let contractIds = this.contractIds;
        this.contracts = contractIds.map((contractId, index) => {
            let item = {
                contractId: contractId,
                colclass: 'slds-col' + (index != contractIds.length - 1 ? ' slds-p-right_small' : ''),
                isLast: index == contractIds.length - 1
            };
            return item;
        });
        let availablePolComs = this.availablePolComs;
        let availablePePolComs = this.availablePePolComs;
        let missingFoldings = this.missingFoldings;
        let conditionsGroupping = this.conditionsGroupping;
        let addConditionGroupping = this.addConditionGroupping;
        let toggleMap = this.toggleMap;
        if (availablePolComs) {
            Object.keys(availablePolComs.validTariffPEMap).forEach(Id => {
                let tariff = availablePolComs.validTariffPEMap[Id];
                if (availablePolComs.validTariffPEMapping.hasOwnProperty(tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c])) {
                    availablePePolComs[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]] = availablePolComs.validTariffPEMapping[(tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c])];
                }
            });
            Object.keys(availablePolComs.validTariffPEMapping).forEach(Id => {
                availablePePolComs[Id] = availablePolComs.validTariffPEMapping[Id];
            });
            Object.keys(availablePolComs).filter(validMapKey => validMapKey != 'validTariffPEMap').forEach(validMapKey => {
                let validMap = availablePolComs[validMapKey];
                if (validMapKey == 'validTariffNegoYearMap') {
                    Object.keys(validMap).forEach(Id => {
                        let tariff = validMap[Id];
                        if (tariff && tariff.Id) {
                            allowedTariffs[Id] = tariff;
                            if (tariff[API_NAMES.Pol_Com_Condition__c.Is_Folding_Discount__c]) {
                                missingFoldings[Id] = tariff;
                            }
                            if (!conditionsGroupping.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Index__c])) {
                                conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]] = {};
                            }
                            if (!conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]].hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c])) {
                                conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]] = {};
                            }
                            if (!conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]].hasOwnProperty(tariff.Id)) {
                                conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]][tariff.Id] = { val: 0, peVal: 0, condition: tariff, peConditions: availablePePolComs[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]] };
                            }
                            if (!addConditionGroupping.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Index__c])) {
                                addConditionGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]] = {};
                            }
                            if (!addConditionGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]].hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c])) {
                                addConditionGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]] = {};
                            }
                            if (!addConditionGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]].hasOwnProperty(tariff.Id)) {
                                addConditionGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]][tariff.Id] = { val: 0, peVal: 0, condition: tariff, peConditions: availablePePolComs[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]] };
                            }
                            if (!toggleMap.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Index__c])) {
                                toggleMap[tariff[API_NAMES.Contract_Discount__c.Index__c]] = { isExpanded: false, discountTypes: {} };
                            }
                            if (!toggleMap[tariff[API_NAMES.Contract_Discount__c.Index__c]].discountTypes.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c])) {
                                toggleMap[tariff[API_NAMES.Contract_Discount__c.Index__c]].discountTypes[tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]] = { isExpanded: false };
                            }
                        }
                    });
                } else {
                    if (validMapKey == 'validTariffPEMapping') {
                        let newValidMap = {};
                        Object.keys(validMap).forEach(Id => {
                            validMap[Id].forEach(item => {
                                newValidMap[item.Id] = item;
                            })
                        });
                        validMap = newValidMap;
                    }
                    Object.keys(validMap).forEach(Id => {
                        let tariff = validMap[Id];
                        if (tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]) {
                            tariff = availablePolComs.validTariffNegoYearMap[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]];
                        }
                        if (tariff && tariff.Id) {
                            allowedTariffs[Id] = tariff;
                            if (tariff[API_NAMES.Pol_Com_Condition__c.Is_Folding_Discount__c]) {
                                missingFoldings[Id] = tariff;
                            }
                            if (!conditionsGroupping.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Index__c])) {
                                conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]] = {};
                            }
                            if (!conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]].hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c])) {
                                conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]] = {};
                            }
                            if (!conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]].hasOwnProperty(tariff.Id)) {
                                conditionsGroupping[tariff[API_NAMES.Contract_Discount__c.Index__c]][tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]][tariff.Id] = { val: 0, peVal: 0, condition: tariff, peConditions: availablePePolComs[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]] };
                            }
                            if (!toggleMap.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Index__c])) {
                                toggleMap[tariff[API_NAMES.Contract_Discount__c.Index__c]] = { isExpanded: false, discountTypes: {} };
                            }
                            if (!toggleMap[tariff[API_NAMES.Contract_Discount__c.Index__c]].discountTypes.hasOwnProperty(tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c])) {
                                toggleMap[tariff[API_NAMES.Contract_Discount__c.Index__c]].discountTypes[tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]] = { isExpanded: false };
                            }
                        }
                    });
                }
            });
        }
    }
    @api generateFolding() {
        this._generateFolding();
        _fireEvent(this.pageRef, 'recalculateFolding', {});
    }
    _generateFolding() {
        let missingFoldings = Object.values(this.missingFoldings);
        let contractIds = this.contractIds;
        let conditionsGroupping = this.conditionsGroupping;
        let availablePePolComs = this.availablePePolComs;
        let grouppedConditions = this.grouppedConditions;
        let refContract = this.refContract;
        let refContractBUId = this.refContractBUId;
        let refContractSourceBUId = this.refContractSourceBUId;
        let refContractConditions = [];
        let contractPE = this.contractPE;
        let simulationNumber = this.simulationNumber;
        let postSimulationNumber = this.postSimulationNumber;
        for (let tariff of missingFoldings) {
            let currentConditions = [];
            for (let contractId of contractIds) {
                let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
                if (contractCmp && contractCmp.isReadOnly && contractCmp.contract) {
                    let contract = contractCmp.contract;
                    let newItem = {
                        SObjectType: API_NAMES.Contract_Discount__c.objectApiName,
                    };
                    newItem[API_NAMES.Contract_Discount__c.Contract__c] = contractId;
                    newItem[API_NAMES.Contract_Discount__c.Contract__r] = contract;
                    newItem[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = contract[API_NAMES.Contract__c.BusinessUnitContract__c];
                    newItem[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = contract[API_NAMES.Contract__c.BusinessUnitContract__r];
                    newItem[API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c] = contract[API_NAMES.Contract__c.Total_Qty__c];
                    newItem[API_NAMES.Contract_Discount__c.Base_TO_Nego__c] = contract[API_NAMES.Contract__c.Total_TO__c];
                    newItem[API_NAMES.Contract_Discount__c.Product_Scope__c] = contract[API_NAMES.Contract__c.Supplier_Nego_Scope__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_BDate__c] = contract[API_NAMES.Contract__c.Contract_BDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_EDate__c] = contract[API_NAMES.Contract__c.Contract_EDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] = contract[API_NAMES.Contract__c.Contract_BDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] = contract[API_NAMES.Contract__c.Contract_EDate__c];
                    newItem[API_NAMES.Contract_Discount__c.Condition_Type__c] = tariff.Id;
                    newItem[API_NAMES.Contract_Discount__c.Condition_Type__r] = tariff;
                    newItem[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c] = tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
                    newItem[API_NAMES.Contract_Discount__c.Index__c] = tariff[API_NAMES.Contract_Discount__c.Index__c];
                    currentConditions.push(newItem);
                }
            }
            let index = tariff[API_NAMES.Contract_Discount__c.Index__c];
            let negodiscount = tariff[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
            let tariffId = tariff.Id;
            delete missingFoldings[tariffId];
            conditionsGroupping[index][negodiscount][tariff.Id].val++;
            conditionsGroupping[index][negodiscount][tariff.Id].peVal++;
            let filteredIndex = grouppedConditions.find(item => item.key == index);
            if (filteredIndex) {
                let filteredNegodiscount = filteredIndex.negodiscounts.find(item => item.key == negodiscount);
                if (filteredNegodiscount) {
                    let tIndex = 0;
                    filteredNegodiscount.conditions.forEach((item, index) => {
                        if (item.condition.Id == tariff.Id) {
                            tIndex++;
                        }
                    });
                    filteredNegodiscount.conditions.push({
                        Name: tariff.Name + (tIndex != 0 ? '(' + tIndex + ')' : ''),
                        condition: tariff,
                        hasDataOnContractsNotHidden: true,
                        peConditions: availablePePolComs[tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]],
                        get cell1Class() {
                            let classes = [
                                '_slds-p-right_none',
                                'slds-tree__item',
                            ];
                            if (this.condition[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                                classes.push('preclosed-cell');
                            }
                            return classes.join(' ');
                        },
                        get cell2Class() {
                            let classes = [
                                'condition-cell',
                            ];
                            if (this.condition[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                                classes.push('preclosed-cell');
                            }
                            return classes.join(' ');
                        },
                        get rowClass() {
                            return (filteredNegodiscount && filteredNegodiscount.rowClass ? filteredNegodiscount.rowClass : '') + (this.deleted || !this.hasDataOnContractsNotHidden ? ' slds-hide' : '');
                        },
                    });
                }
            }
            for (let condition of currentConditions) {
                let contractCmp = this.template.querySelector(`[data-id="` + condition[API_NAMES.Contract_Discount__c.Contract__c] + `"]`);
                if (contractCmp && contractCmp.populateNewConditions) {
                    contractCmp.populateNewConditions(condition);
                }
            }
            if (refContract && refContract.Id) {
                let contractCmp = this.template.querySelector(`[data-id="` + refContract.Id + `"]`);
                if (contractCmp && contractCmp.getConditions) {
                    refContractConditions = contractCmp.getConditions();
                }
            }
            for (let contractId of contractIds) {
                let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
                if (contractCmp && contractCmp.populateRefConditions) {
                    contractCmp.populateRefConditions(refContract, contractPE, refContractConditions, simulationNumber, postSimulationNumber, refContractBUId, refContractSourceBUId);
                }
            }
            delete this.missingFoldings[tariff.Id];
        }
    }
    @api getContracts() {
        return this._getContracts();
    }
    _getContracts() {
        return this.contractIds.map(contractId => {
            let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
            if (contractCmp && contractCmp.isReadOnly) {
                return contractCmp.contract;
            }
        }).filter(item => item);
    }
    @api toggleContract(contractId, isShow) {
        this._toggleContract(contractId, isShow);
    }
    _toggleContract(contractId, isShow) {
        let contract = this.contracts.find(item => item.contractId == contractId);
        if (contract) {
            if (isShow) {
                contract.colclass = contract.colclass.replace(/slds-hide/gi, '');
            } else {
                contract.colclass = contract.colclass + ' slds-hide';
            }
        }
    }
    toggleIndexes(event) {
        let showIndexes = !this.showIndexes;
        this.showIndexes = showIndexes;
        if (this.showIndexes) {
            this.indexesClass = '';
        } else {
            this.indexesClass = 'slds-hide';
        }
        let contractIds = JSON.parse(JSON.stringify(this.contractIds));
        contractIds.forEach(contractId => {
            let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
            if (contractCmp && contractCmp.updateShowIndexes) {
                contractCmp.updateShowIndexes(showIndexes);
            }
        });
    }
    @api updateShowIndexes(showIndexes) {
        this.showIndexes = showIndexes;
        if (showIndexes) {
            this.indexesClass = '';
        } else {
            this.indexesClass = 'slds-hide';
        }
        let contractIds = JSON.parse(JSON.stringify(this.contractIds));
        contractIds.forEach(contractId => {
            let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
            if (contractCmp && contractCmp.updateShowIndexes) {
                contractCmp.updateShowIndexes(showIndexes);
            }
        });
    }
    @api save() {
        // let groupingProcessedContractIds = JSON.parse(JSON.stringify(this.groupingProcessedContractIds));
        let contractIds = JSON.parse(JSON.stringify(this.contractIds));
        // let doneContractIds = JSON.parse(JSON.stringify(this.contractIds));
        let resolveMap = {};
        contractIds.forEach(contractId => {
            resolveMap[contractId] = false;
        });
        let results = { isEmpty: true, isSuccess: true, isTopOrPe: false, errors: [] };
        return new Promise((resolve, reject) => {
            let processResolve = () => {
                if (Object.values(resolveMap).every(item => item)) {
                    // if (results.isSuccess) {
                    //     doneContractIds.forEach(item => groupingProcessedContractIds[item] = false);
                    //     this.groupingProcessedContractIds = groupingProcessedContractIds;
                    //     setTimeout(() => {
                    //         doneContractIds.forEach(contractId => {
                    //             let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
                    //             if (contractCmp && contractCmp.refreshData) {
                    //                 contractCmp.refreshData();
                    //             }
                    //         });
                    //     }, 20);
                    // }
                    resolve(JSON.stringify(results));
                } else {
                    popElement();
                }
            }
            let popElement = () => {
                let contractId = contractIds.shift();
                let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
                if (contractCmp && contractCmp.save) {
                    contractCmp.save().then(result => {
                        let currContractId = contractId;
                        let contractSaveResult = JSON.parse(result);
                        results.isEmpty &= contractSaveResult.hasOwnProperty('isEmpty') && contractSaveResult.isEmpty;
                        results.isSuccess &= contractSaveResult.isSuccess;
                        results.isTopOrPe |= contractSaveResult.isTopOrPe;
                        contractSaveResult.errors.forEach(err => results.errors.push(err));
                        resolveMap[currContractId] = true;
                        processResolve();
                    });
                } else {
                    delete resolveMap[contractId];
                    processResolve();
                }
            }
            processResolve();
            // contractIds.forEach(contractId => {
            //     let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
            //     if (contractCmp && contractCmp.save) {
            //         contractCmp.save().then(result => {
            //             let currContractId = contractId;
            //             let contractSaveResult = JSON.parse(result);
            //             results.isSuccess &= contractSaveResult.isSuccess;
            //             contractSaveResult.errors.forEach(err => results.errors.push(err));
            //             resolveMap[currContractId] = true;
            //             if (Object.values(resolveMap).every(item => item)) {
            //                 resolve(JSON.stringify(results));
            //             }
            //         });
            //     } else {
            //         delete resolveMap[contractId];
            //     }
            // });
        });
    }
    @api updateContractIds(contractIds_JSON) {
        let contractIds = JSON.parse(contractIds_JSON);
        this.contractIds = contractIds;
        let currentContracts = this.contracts;
        let groupingProcessedContractIds = this.groupingProcessedContractIds;
        this.contracts = contractIds.map((contractId, index) => {
            let currContract = currentContracts.find(item => item.contractId == contractId);
            let item = {
                contractId: contractId,
                colclass: 'slds-col',
                isLast: index == contractIds.length - 1
            };
            if (currContract) {
                item = currContract;
                groupingProcessedContractIds[contractId] = true;
            } else {
                groupingProcessedContractIds[contractId] = false;
            }
            item.colclass = item.colclass.replace(/slds-p-right_small/gi, '');
            if (index != contractIds.length - 1) {
                item.colclass = item.colclass + ' slds-p-right_small ';
            }
            return item;
        });
    }
    childReadyHandle(event) {
        // _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'childReadyHandle' });
        let self = this;
        let addConditionGroupping = this.addConditionGroupping;
        let validTariffConditionMap = this.validTariffConditionMap;
        let toggleMap = this.toggleMap;
        let negoDiscountTypeLabelsMap = this.negoDiscountTypeLabelsMap;
        let availablePePolComs = this.availablePePolComs;
        let indexLabelsMap = this.indexLabelsMap;
        let allowedTariffs = this.allowedTariffs;
        let missingFoldings = this.missingFoldings;
        let negoYear = this.negoYear;
        let contractIds = this.contractIds;
        let conditionsGroupping = this.conditionsGroupping;
        let contractGroupping = {};
        if (event && event.detail && event.detail.contractId) {
            let contractId = event.detail.contractId;
            this.groupingProcessedContractIds[contractId] = true;
            if (event && event.detail && event.detail.validTariffConditionMap) {
                validTariffConditionMap[contractId] = event.detail.validTariffConditionMap;
            }
        }
        if (event && event.detail && event.detail.userProfileId) {
            this.userProfileId = event.detail.userProfileId;
        }
        if (event && event.detail && event.detail.value) {
            let res = event.detail.value;
            for (let index of Object.keys(res)) {
                if (!contractGroupping.hasOwnProperty(index)) {
                    contractGroupping[index] = {};
                }
                if (!conditionsGroupping.hasOwnProperty(index)) {
                    conditionsGroupping[index] = {};
                }
                for (let negodiscountType of Object.keys(res[index])) {
                    if (!contractGroupping[index].hasOwnProperty(negodiscountType)) {
                        contractGroupping[index][negodiscountType] = {};
                    }
                    if (!conditionsGroupping[index].hasOwnProperty(negodiscountType)) {
                        conditionsGroupping[index][negodiscountType] = {};
                    }
                    for (let c of res[index][negodiscountType]) {
                        // if (allowedTariffs[c[API_NAMES.Contract_Discount__c.Condition_Type__c]] || allowedTariffs[c[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c]]) {
                        let tariff = c[API_NAMES.Contract_Discount__c.Condition_Type__r];
                        let tariffId = tariff.Id;
                        let tariffPes = availablePePolComs[tariffId] || [tariff];
                        let hasPeCond = false;
                        /*if (c[API_NAMES.Contract_Discount__c.Contract__r].RecordType.DeveloperName == 'Period_Extension') {
                            let replacementPEMapping = tariff[API_NAMES.Pol_Com_Condition__c.Duplication_Discount_Mapping__c];
                            if (replacementPEMapping && allowedTariffs[replacementPEMapping] && availablePePolComs[replacementPEMapping]) {
                                tariff = allowedTariffs[replacementPEMapping];
                                tariffId = tariff.Id;
                                tariffPes = availablePePolComs[replacementPEMapping];
                                hasPeCond = true;
                            }
                        }*/
                        let tIndex = tariff[API_NAMES.Pol_Com_Condition__c.Index__c];
                        if (tIndex) {
                            if (!contractGroupping.hasOwnProperty(tIndex)) {
                                contractGroupping[tIndex] = {};
                            }
                            if (!conditionsGroupping.hasOwnProperty(tIndex)) {
                                conditionsGroupping[tIndex] = {};
                            }
                        }
                        let tNegodiscountType = tariff[API_NAMES.Pol_Com_Condition__c.Nego_Discount_Type__c];
                        if (tIndex && tNegodiscountType) {
                            if (!contractGroupping[tIndex].hasOwnProperty(tNegodiscountType)) {
                                contractGroupping[tIndex][tNegodiscountType] = {};
                            }
                            if (!conditionsGroupping[tIndex].hasOwnProperty(tNegodiscountType)) {
                                conditionsGroupping[tIndex][tNegodiscountType] = {};
                            }
                        }
                        if (tIndex && tNegodiscountType && tariffId) {
                            if (tariff[API_NAMES.Pol_Com_Condition__c.Is_Folding_Discount__c]) {
                                delete missingFoldings[tariffId];
                            }
                            if (!contractGroupping[tIndex][tNegodiscountType].hasOwnProperty(tariffId)) {
                                contractGroupping[tIndex][tNegodiscountType][tariffId] = { val: 0, peVal: 0, condition: tariff, peConditions: tariffPes, hasDataOnContractsNotHidden: true };
                            }
                            if (!conditionsGroupping[tIndex][tNegodiscountType].hasOwnProperty(tariffId)) {
                                conditionsGroupping[tIndex][tNegodiscountType][tariffId] = { val: 0, peVal: 0, condition: tariff, peConditions: tariffPes, hasDataOnContractsNotHidden: true };
                            }
                            if (new Date(c[API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear && c[API_NAMES.Contract_Discount__c.Contract__r].RecordType.DeveloperName == 'Nego_Base' && isNaN(conditionsGroupping[tIndex][tNegodiscountType][tariffId].refDisplayOrder)) {
                                conditionsGroupping[tIndex][tNegodiscountType][tariffId].refDisplayOrder = c[API_NAMES.Contract_Discount__c.Display_Order__c];
                            }
                            if (c[API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.Is_OnTop_Simulation__c] && isNaN(conditionsGroupping[tIndex][tNegodiscountType][tariffId].ontopDisplayOrder)) {
                                conditionsGroupping[tIndex][tNegodiscountType][tariffId].ontopDisplayOrder = c[API_NAMES.Contract_Discount__c.Display_Order__c];
                            }
                            /*if (hasPeCond) {
                                contractGroupping[tIndex][tNegodiscountType][tariffId].peVal++;
                            } else {*/
                            contractGroupping[tIndex][tNegodiscountType][tariffId].val++;
                            /*}*/
                            if (contractGroupping[tIndex][tNegodiscountType][tariffId].val > conditionsGroupping[tIndex][tNegodiscountType][tariffId].val) {
                                conditionsGroupping[tIndex][tNegodiscountType][tariffId].val = contractGroupping[tIndex][tNegodiscountType][tariffId].val;
                            }
                            if (contractGroupping[tIndex][tNegodiscountType][tariffId].peVal > conditionsGroupping[tIndex][tNegodiscountType][tariffId].peVal) {
                                conditionsGroupping[tIndex][tNegodiscountType][tariffId] = contractGroupping[tIndex][tNegodiscountType][tariffId];
                            }
                        }
                    }
                }
            }
        }
        if (Object.values(this.groupingProcessedContractIds).every(item => item)) {
            let grouppedConditions = Object.keys(conditionsGroupping).sort((key1, key2) => key1.localeCompare(key2)).map(keyIndex => {
                if (!toggleMap.hasOwnProperty(keyIndex)) {
                    toggleMap[keyIndex] = { isExpanded: false, discountTypes: {} };
                }
                let item = {
                    key: keyIndex,
                    label: indexLabelsMap[keyIndex] || keyIndex,
                    isExpanded: toggleMap[keyIndex].isExpanded,
                    get rowClass() {
                        return this.isExpanded ? '' : 'slds-hide';
                    }
                };
                item.negodiscounts = Object.keys(conditionsGroupping[keyIndex]).map(keyNegoDiscountType => {
                    if (!toggleMap[keyIndex].discountTypes.hasOwnProperty(keyNegoDiscountType)) {
                        toggleMap[keyIndex].discountTypes[keyNegoDiscountType] = { isExpanded: false };
                    }
                    let availablenewTariffs = [];
                    if (addConditionGroupping && addConditionGroupping[keyIndex] && addConditionGroupping[keyIndex][keyNegoDiscountType]) {
                        availablenewTariffs = Object.values(addConditionGroupping[keyIndex][keyNegoDiscountType]).map(item => item.condition).filter(item => {
                            return !item[API_NAMES.Pol_Com_Condition__c.Parent_Condition__c] || !item?.RecordTypeId || item?.RecordType?.DeveloperName == 'Main_Term';
                        });
                    }
                    let negodiscountItem = {
                        key: keyNegoDiscountType,
                        hasAvailableNewConditions: availablenewTariffs.length ? true : false,
                        label: negoDiscountTypeLabelsMap[keyNegoDiscountType] || keyNegoDiscountType,
                        isExpanded: toggleMap[keyIndex].discountTypes[keyNegoDiscountType].isExpanded,
                        conditions: [],
                        get chevronStyle() {
                            return 'slds-p-right_xx-small' + (this.conditions && this.conditions.some(_cond => !_cond.deleted && _cond.hasDataOnContractsNotHidden) ? '' : ' slds-hidden');
                        },
                        get rowClass() {
                            return this.isExpanded && item.isExpanded ? '' : 'slds-hide';
                        },
                    };
                    Object.keys(conditionsGroupping[keyIndex][keyNegoDiscountType]).forEach(tarrifId => {
                        let refDisplayOrder = conditionsGroupping[keyIndex][keyNegoDiscountType][tarrifId].refDisplayOrder;
                        let ontopDisplayOrder = conditionsGroupping[keyIndex][keyNegoDiscountType][tarrifId].ontopDisplayOrder;
                        let cond = conditionsGroupping[keyIndex][keyNegoDiscountType][tarrifId].condition;
                        let maxVal = conditionsGroupping[keyIndex][keyNegoDiscountType][tarrifId].val;
                        let peVal = conditionsGroupping[keyIndex][keyNegoDiscountType][tarrifId].peVal;
                        if (maxVal < peVal) {
                            maxVal = peVal;
                        }
                        for (let tIndex = 0; tIndex < maxVal; tIndex++) {
                            negodiscountItem.conditions.push({
                                Name: cond.Name + (tIndex != 0 ? '(' + tIndex + ')' : ''),
                                deleted: false,
                                hasDataOnContractsNotHidden: true,
                                condition: cond,
                                peConditions: conditionsGroupping[keyIndex][keyNegoDiscountType][tarrifId].peConditions,
                                get cell1Class() {
                                    let classes = [
                                        '_slds-p-right_none',
                                        'slds-tree__item',
                                    ];
                                    if (this.condition[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                                        classes.push('preclosed-cell');
                                    }
                                    return classes.join(' ');
                                },
                                get cell2Class() {
                                    let classes = [
                                        'condition-cell',
                                    ];
                                    if (this.condition[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] == 'PreClosed') {
                                        classes.push('preclosed-cell');
                                    }
                                    return classes.join(' ');
                                },
                                refDisplayOrder: refDisplayOrder,
                                ontopDisplayOrder: ontopDisplayOrder,
                                get rowClass() {
                                    return (negodiscountItem && negodiscountItem.rowClass ? negodiscountItem.rowClass : '') + (this.deleted || !this.hasDataOnContractsNotHidden ? ' slds-hide' : '');
                                },
                            });
                        }
                    });
                    negodiscountItem.conditions = negodiscountItem.conditions.sort((item1, item2) => {
                        if (!isNaN(item1.ontopDisplayOrder) && !isNaN(item2.ontopDisplayOrder)) {
                            if (item1.ontopDisplayOrder - item2.ontopDisplayOrder == 0) {
                                return item1.Name.localeCompare(item2.Name);
                            }
                            return item1.ontopDisplayOrder - item2.ontopDisplayOrder;
                        } else if (!isNaN(item1.refDisplayOrder) && !isNaN(item2.refDisplayOrder)) {
                            if (item1.refDisplayOrder - item2.refDisplayOrder == 0) {
                                return item1.Name.localeCompare(item2.Name);
                            }
                            return item1.refDisplayOrder - item2.refDisplayOrder;
                        } else {
                            return item1.Name.localeCompare(item2.Name);
                        }
                    });
                    return negodiscountItem;
                }).sort((item1, item2) => {
                    let l1 = item1.label.replace(/[^0-9]/gi, '');
                    let l2 = item2.label.replace(/[^0-9]/gi, '');
                    let n1 = l1 ? new Number(l1) : NaN;
                    let n2 = l2 ? new Number(l2) : NaN;
                    if (!isNaN(n1) && !isNaN(n2)) {
                        return n1 - n2;
                    } else {
                        return item1.label.localeCompare(item2.label);
                    }
                });
                return item;
            });
            this.grouppedConditions = grouppedConditions;
            let refContractConditions = [];
            let refContract = null;
            let contractPE = null;
            let simulationNumber = 0;
            let postSimulationNumber = 0;
            let refContractBUId;
            let refContractSourceBUId;
            let promisesMap = {};
            let promises = contractIds.map(contractId => {
                promisesMap[contractId] = false;
                return new Promise((resolve, reject) => {
                    setTimeout(() => {
                        let contractCmp = this.template.querySelector(`[data-id="` + contractId + `"]`);
                        let contractConditions = [];
                        if (contractCmp && contractCmp.populateConditions) {
                            contractConditions = contractCmp.populateConditions(JSON.parse(JSON.stringify(grouppedConditions)), contractId);
                        }
                        if (contractCmp && contractCmp.contract) {
                            let contract = contractCmp.contract;
                            if (new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear && contract.RecordType.DeveloperName == 'Nego_Base') {
                                refContractConditions = contractConditions;
                                refContract = contract;
                                if (contract[API_NAMES.Contract__c.BusinessUnitContract__c]) {
                                    refContractBUId = contract[API_NAMES.Contract__c.BusinessUnitContract__c];
                                }
                                if (contract[API_NAMES.Contract__c.BusinessUnitSource__c]) {
                                    refContractSourceBUId = contract[API_NAMES.Contract__c.BusinessUnitSource__c];
                                }
                            }
                            if (new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear && contract.RecordType.DeveloperName == 'Pertiod_Extension') {
                                contractPE = contract;
                            }
                            if (new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear && contract.RecordType.DeveloperName == 'Simulation' && contract[API_NAMES.Contract__c.SimulationNumber__c] && simulationNumber < contract[API_NAMES.Contract__c.SimulationNumber__c]) {
                                simulationNumber = contract[API_NAMES.Contract__c.SimulationNumber__c];
                            }
                            if (new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear && contract.RecordType.DeveloperName == 'Safe_Balance' && contract[API_NAMES.Contract__c.SimulationNumber__c] && simulationNumber < contract[API_NAMES.Contract__c.SimulationNumber__c]) {
                                simulationNumber = contract[API_NAMES.Contract__c.SimulationNumber__c];
                            }
                            if (new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear && contract.RecordType.DeveloperName == 'PostNego_Simulation' && contract[API_NAMES.Contract__c.SimulationNumber__c] && postSimulationNumber < contract[API_NAMES.Contract__c.SimulationNumber__c]) {
                                postSimulationNumber = contract[API_NAMES.Contract__c.SimulationNumber__c];
                            }
                            if (!refContractBUId && contract[API_NAMES.Contract__c.BusinessUnitContract__c]) {
                                refContractBUId = contract[API_NAMES.Contract__c.BusinessUnitContract__c];
                            }
                            if (!refContractSourceBUId && contract[API_NAMES.Contract__c.BusinessUnitSource__c]) {
                                refContractSourceBUId = contract[API_NAMES.Contract__c.BusinessUnitSource__c];
                            }
                        }
                        resolve(contractId);
                    }, 10);
                });
            });
            let promiseCallBack = () => {
                self.refContract = refContract;
                self.contractPE = contractPE;
                self.simulationNumber = simulationNumber;
                self.postSimulationNumber = postSimulationNumber;
                self.refContractBUId = refContractBUId;
                self.refContractSourceBUId = refContractSourceBUId;
                contractIds.forEach(contractId => {
                    let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
                    if (contractCmp && contractCmp.populateRefConditions) {
                        contractCmp.populateRefConditions(refContract, contractPE, refContractConditions, simulationNumber, postSimulationNumber, refContractBUId, refContractSourceBUId);
                    }
                });
                _fireEvent(self.pageRef, 'reloadFilter', {});
                _fireEvent(self.pageRef, 'setOnTopDatesFromContracts', {
                    bDate: self.onTopBDate,
                    eDate: self.onTopEDate,
                });
                _fireEvent(self.pageRef, 'setPTDatesFromContracts', {
                    bDate: self.ptBdate,
                    eDate: self.ptEdate,
                });
                _fireEvent(self.pageRef, 'setNegoPlanFromContracts', {
                    riseRateDiff: self.riseRateDiff || 0,
                    depreciationRiseRateDiff: self.depreciationRiseRateDiff || 0,
                });
                _fireEvent(self.pageRef, 'setRefToQtyDurationFromContracts', {
                    refTO: self.refTO || 0,
                    refQty: self.refQty || 0,
                    refDuration: self.refDuration || 0,
                });
                _fireEvent(self.pageRef, 'setSafeBalanceToQtyDurationFromContracts', {
                    safeBalanceTO: self.safeBalanceTO || 0,
                    safeBalanceQty: self.safeBalanceQty || 0,
                    safeBalanceDuration: self.safeBalanceDuration || 0,
                });
                _fireEvent(self.pageRef, 'recalculateFolding', {});
                _fireEvent(self.pageRef, 'calculateGap', {});
                _fireEvent(self.pageRef, 'loadNextContract', {});
                _fireEvent(self.pageRef, 'refreshList', {});
                // _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'childReadyHandle' });
            }
            promises.forEach(prom => {
                prom.then((contractId) => {
                    promisesMap[contractId] = true;
                    if (Object.values(promisesMap).every(res => res)) {
                        promiseCallBack();
                    }
                });
            });
        }
    }
    toggleExpension(event) {
        let self = this;
        let contractIds = this.contractIds;
        let index = event.target.dataset.index;
        let negodiscount = event.target.dataset.negodiscount;
        let filteredIndex = this.grouppedConditions.find(item => item.key == index);
        if (filteredIndex) {
            if (negodiscount) {
                let filteredNegodiscount = filteredIndex.negodiscounts.find(item => item.key == negodiscount);
                if (filteredNegodiscount) {
                    filteredNegodiscount.isExpanded = !filteredNegodiscount.isExpanded;
                    this.toggleMap[filteredIndex.key].discountTypes[filteredNegodiscount.key].isExpanded = filteredNegodiscount.isExpanded;
                    contractIds.forEach(contractId => {
                        // setTimeout(() => {
                        let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
                        if (contractCmp && contractCmp.toggleExpension) {
                            contractCmp.toggleExpension(filteredNegodiscount.isExpanded, index, negodiscount);
                        }
                        // }, 10);
                    });
                }
            } else {
                filteredIndex.isExpanded = !filteredIndex.isExpanded;
                this.toggleMap[filteredIndex.key].isExpanded = filteredIndex.isExpanded;
                contractIds.forEach(contractId => {
                    // setTimeout(() => {
                    let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
                    if (contractCmp && contractCmp.toggleExpension) {
                        contractCmp.toggleExpension(filteredIndex.isExpanded, index, null);
                    }
                    // }, 10);
                });
            }
        }
    }
    contractAll(event) {
        let self = this;
        let toggleMap = this.toggleMap;
        let contractIds = this.contractIds;
        this.grouppedConditions.forEach(item => {
            toggleMap[item.key].isExpanded = true;
            item.negodiscounts.forEach(item2 => {
                toggleMap[item.key].discountTypes[item2.key].isExpanded = false;
                item2.isExpanded = false;
            });
            item.isExpanded = false;
        });
        contractIds.forEach(contractId => {
            // setTimeout(() => {
            let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
            if (contractCmp && contractCmp.contractAll) {
                contractCmp.contractAll();
            }
            // }, 10);
        });
    }
    expandAll(event) {
        let self = this;
        let toggleMap = this.toggleMap;
        let contractIds = this.contractIds;
        this.grouppedConditions.forEach(item => {
            toggleMap[item.key].isExpanded = true;
            item.negodiscounts.forEach(item2 => {
                toggleMap[item.key].discountTypes[item2.key].isExpanded = true;
                item2.isExpanded = true;
            });
            item.isExpanded = true;
        });
        contractIds.forEach(contractId => {
            // setTimeout(() => {
            let contractCmp = self.template.querySelector(`[data-id="` + contractId + `"]`);
            if (contractCmp && contractCmp.expandAll) {
                contractCmp.expandAll();
            }
            // }, 10);
        });
    }
    changeHeight = () => {
        let pageHeaderHeight = this.headerHeight || 0;
        let mainPanelHeight = window.innerHeight - pageHeaderHeight - 125;
        this.containerStyle = 'height:' + mainPanelHeight + 'px;';
    };
}