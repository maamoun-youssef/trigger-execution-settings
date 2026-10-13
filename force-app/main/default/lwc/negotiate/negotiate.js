import { LightningElement, track, wire, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getNegoScopes from "@salesforce/apex/NegotiateCmpController.getNegoScopes";
import getNegoScopesBySupplier from "@salesforce/apex/NegotiateCmpController.getNegoScopesBySupplier";
import getSuppliers from "@salesforce/apex/NegotiateCmpController.getSuppliers";
import getContracts from "@salesforce/apex/NegotiateCmpController.getContracts";
import getObjectLabels from "@salesforce/apex/NegotiateCmpController.getObjectLabels";
import consolidateContract from "@salesforce/apex/NegotiateCmpController.consolidateContract";
import deleteContract from "@salesforce/apex/NegotiateCmpController.deleteContract";
import synchroAdvancedContracts from "@salesforce/apex/NegotiateCmpController.synchroAdvancedContracts";
import checkBatchRunning from "@salesforce/apex/NegotiateCmpController.checkBatchRunning";
const SEARCH_TIME_OUT = 500;
const LOADING_TIME_OUT = 1000;
const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const INFO_VARIANT = 'info';
const STICKY_VARIANT = 'sticky';
import { Labels, NegoPlanWrapper, API_NAMES, generateNonce } from "c/contractServices";
import { loadStyle } from 'lightning/platformResourceLoader';
import negotiateSRURL from '@salesforce/resourceUrl/negotiate';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { LightningAlert } from 'lightning/alert';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubSub';
const nonce = generateNonce();
const _fireEvent = (pageref, eventName, details) => {
    fireEvent(pageref, eventName + '_' + nonce, details);
}
const _registerListener = (eventName, callback, cmpInstance) => {
    registerListener(eventName + '_' + nonce, callback, cmpInstance);
}
import canUserModifyAll from '@salesforce/userPermission/ModifyAllData';
export default class NegotiateLwc extends NavigationMixin(LightningElement) {
    API_NAMES = API_NAMES;
    get canUserModifyAll() {
        return canUserModifyAll;
    }
    @api negoyear;
    @api negoId;
    @api contractId;
    @api postSigned;
    @track currentStatusMSG;
    @track nonce = nonce;
    @track hasChanges = false;
    @track lockedByApprovalProcess = false;
    @track lockedActions;
    @track negoPlanTableLoading = false;
    @track savePopUp = false;
    get hasChangesToSave() {
        let negoPlanCmp = this.template.querySelector(`[data-id="negotiate-nego-plan-cmp"]`);
        let indexesCmp = this.template.querySelector(`[data-id="negotiate-indexes-cmp"]`);
        let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
        return contractsCmp?.hasChangesToSave || negoPlanCmp?.hasChangesToSave || indexesCmp?.hasChangesToSave;
    }
    pageRef;
    loadingTimeOut;
    // Injects the page reference that describes the current page
    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        let self = this;
        this.pageRef = pageRef;
        this.instance.pageRef = pageRef;
        // currentPageReference.state.c__supplier
        this.ready_setCurrentPageReference = true;
        if (pageRef.state.hasOwnProperty('c__negoyear') && pageRef.state.c__negoyear) {
            this.instance.negoYear = pageRef.state.c__negoyear;
        }
        if (pageRef.state.hasOwnProperty('c__negoId') && pageRef.state.c__negoId) {
            this.instance.selectedNegoScopeId = pageRef.state.c__negoId;
        }
        if (pageRef.state.hasOwnProperty('c__contractId') && pageRef.state.c__contractId) {
            this.instance.selectedContractId = pageRef.state.c__contractId;
            this.instance.backUrl = '/' + pageRef.state.c__contractId;
            this.instance.hasBackUrl = true;
        }
        let params = Object.keys(pageRef.state).map(key => {
            return key + '=' + pageRef.state[key];
        });
        this.instance.currentUrl = '/apex/NegoptimNavigator?' + ['c__componentName=Negoptim:negotiate', 'a__negoyear=' + (this.instance.negoYear || this.negoyear), 'a__negoId=' + (this.instance.selectedNegoScopeId || this.negoId), 'a__contractId=' + (this.instance.selectedContractId || this.contractId)].join('&');
        if (this.ready_setCurrentPageReference && this.ready_connectedCallback) {
            if (this.instance.selectedNegoScopeId) {
                this.instance.negoscope._setCurrentItem(this.instance).then(result => {
                    self.instance = result;
                    _fireEvent(self.pageRef, 'registerAllContractIds', {});
                });
            } else {
                this.instance.readyToDisplay = true;
            }
        }
    }
    @track Loading = false;
    @track LoadingMap = {};
    Events = {
        allcontractsloaded: 'allcontractsloaded',
    }
    Label = Labels;
    @track translation = {};
    @track contractRecordTypes = [];
    @track requireConso = false;
    @track consoRunning = false;
    @track instance = {
        self: undefined,
        executiveSummaryPopUp: {
            url: undefined,
            isOpen: false,
            buttonsFlag: true,
            cancel(event) {
                this.instance.executiveSummaryPopUp.url = undefined;
                this.instance.executiveSummaryPopUp.isOpen = false;
            },
            discardAndProceed(event) {
                let a = document.createElement('A');
                a.href = this.instance.executiveSummaryPopUp.url;
                a.target = '_blank';
                a.click();
                this.instance.executiveSummaryPopUp.url = undefined;
                this.instance.executiveSummaryPopUp.isOpen = false;
            },
        },
        unableToLockUnlockPopUp: {
            disableButton: false,
            isOpen: false,
            cancel(event) {
                this.instance.unableToLockUnlockPopUp.isOpen = false;
                this.instance.unableToLockUnlockPopUp.disableButton = false;
                _fireEvent(this.pageRef, 'resetContractChanges', {});
            },
        },
        hasData: false,
        template: {},
        get displayMenuItem() { return !this.lockedActions && this.menuItems && this.menuItems.length ? true : false },
        get menuItems() {
            let menuItems = [
                // { label: Labels.LBL_Executive_Summary, icon_Name: "utility:approval", section: 1, show: true },
                // { label: Labels.LBL_Executive_Summary_Top, icon_Name: "utility:approval", section: 1, show: true },
                // { label: data.createSimulFromNegoBaseLabel, icon_Name: "utility:add", section: 2, show: true },
                // { label: data.createSafeBalanceFromNegoBaseLabel, icon_Name: "utility:add", section: 2, show: true },
                // { label: data.createSimulFromSafeBalanceLabel, icon_Name: "utility:add", section: 2, show: true },
                // { label: data.createSimulFromSimulLabel, icon_Name: "utility:add", section: 2, show: true },
                // { label: data.duplicateNegoBasetoPE, icon_Name: "utility:multi_picklist", section: 3, show: true },
                // { label: Labels.LBL_Consolidate_Contracts, icon_Name: "utility:multi_picklist", section: 3, show: true, action: instance.consolidateContract },
                // { label: Labels.LBL_Generate_Folding, icon_Name: "utility:percent", section: 4, show: true },
            ];
            if (!this.lockedActions) {
                menuItems.push({ label: Labels.Calculate, icon_Name: "utility:number_input", section: 1, show: true, action: this.calculateAllIndexes });
                if (this.hasTop || this.hasPE) {
                    menuItems.push({ label: Labels.LBL_Consolidate_Contracts, icon_Name: "utility:multi_picklist", section: 3, show: true, action: this.consolidateContract });
                }
                let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
                if (contractsCmp && contractsCmp.missingFoldings && Object.keys(contractsCmp.missingFoldings).length && contractsCmp.hasAnyInternational) {
                    menuItems.push({ label: Labels.LBL_Generate_Folding, icon_Name: "utility:percent", section: 4, show: true, action: this.generateFolding });
                }
                let lastItem = menuItems.find(item => item.show);
                if (lastItem) {
                    let lastSection = lastItem.section;
                    menuItems.forEach(item => {
                        item.showDivider = item.section != lastSection && item.show;
                        if (item.show) {
                            lastSection = item.section;
                        }
                    });
                }
            }
            return menuItems;
        },
        hasPE: false,
        hasPeSigned: false,
        readyToDisplay: false,
        negoPlan: {
            oInstance: {},
            wrapper: new NegoPlanWrapper(),
        },
        showIndexes: true,
        showBrief: false,
        showSideBar: false,
        showHeader: true,
        isFullScreen: false,
        indexesClass: 'slds-hide',
        briefClass: 'slds-hide',
        Labels: {
            createSimulFromNegoBaseLabel: '',
            createSafeBalanceFromNegoBaseLabel: '',
            createSimulFromSafeBalanceLabel: '',
            createSimulFromSimulLabel: '',
            duplicateNegoBasetoPE: '',
            duplicateSafeBalanceToPE: '',
        },
        toggleIndexes(event) {
            this.instance.showIndexes = !this.instance.showIndexes;
            if (this.instance.showIndexes) {
                this.instance.indexesClass = '';
            } else {
                this.instance.indexesClass = 'slds-hide';
            }
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            if (contractsCmp && contractsCmp.updateShowIndexes) {
                contractsCmp.updateShowIndexes(this.instance.showIndexes);
            }
        },
        toggleBrief(event) {
            this.instance.showBrief = !this.instance.showBrief;
            if (this.instance.showBrief) {
                this.instance.briefClass = '';
            } else {
                this.instance.briefClass = 'slds-hide';
            }
        },
        toggleHeader(event) {
            this.instance.showHeader = !this.instance.showHeader;
        },
        toggleSideBar(event) {
            this.instance.showSideBar = !this.instance.showSideBar;
            let sideBar = this.template.querySelector('[data-id="side-bar"]');
            let contractsCmp = this.template.querySelector('[data-id="negotiate-contracts-cmp"]');
            if (sideBar && contractsCmp) {
                if (this.instance.showSideBar) {
                    sideBar.classList.add('slds-size_1-of-4');
                    sideBar.classList.remove('slds-hide');
                    contractsCmp.classList.add('slds-size_3-of-4');
                    contractsCmp.classList.remove('slds-size_full');
                } else {
                    sideBar.classList.remove('slds-size_1-of-4');
                    sideBar.classList.add('slds-hide');
                    contractsCmp.classList.remove('slds-size_3-of-4');
                    contractsCmp.classList.add('slds-size_full');
                }
            }
        },
        toggleFullScreen(event) {
            this.instance.isFullScreen = !this.instance.isFullScreen;
        },
        cancelSelectNegoscope() {
            this.instance.loadingSelection = true;
            this.instance.negoscope.data = [];
            this.instance.negoscope.hasSearchTerm = this.instance.supplier.searchTerm.length > 2;
            this.instance.negoscope.oInstance = {};
            this.instance.negoscope.searchTerm = '';
            this.instance.supplier.data = [];
            this.instance.supplier.displayNegoscopePopup = false;
            this.instance.supplier.hasSearchTerm = this.instance.supplier.searchTerm.length > 2;
            this.instance.supplier.negoscopes = [];
            this.instance.supplier.oInstance = {};
            this.instance.supplier.searchTerm = '';
        },
        save(event) {
            this.instance.executiveSummaryPopUp.buttonsFlag = false
            this.currentStatusMSG = Labels.LBL_Save;
            // this.instance.executiveSummaryPopUp.isOpen = false;
            this.instance.unableToLockUnlockPopUp.disableButton = true;
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'global_save' });
            let results = { isEmpty: true, isSuccess: true, errors: [] };
            let negoPlanCmp = this.template.querySelector(`[data-id="negotiate-nego-plan-cmp"]`);
            let indexesCmp = this.template.querySelector(`[data-id="negotiate-indexes-cmp"]`);
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            let savingMap = {};
            if (indexesCmp && indexesCmp.save) {
                savingMap.indexesCmp = indexesCmp;
            }
            if (contractsCmp && contractsCmp.save) {
                savingMap.contractsCmp = contractsCmp;
            }
            if (negoPlanCmp && negoPlanCmp.save) {
                savingMap.negoPlanCmp = negoPlanCmp;
            }
            let self = this;
            let anyOnTopOrPTSavedContract = false;
            let isAdvanced = false;
            let processSaveDone = () => {
                if (Object.keys(savingMap).length == 0) {
                    self.hasChanges = false;
                    self.instance.unableToLockUnlockPopUp.disableButton = false;
                    self.instance.unableToLockUnlockPopUp.isOpen = false;
                    let done = true;
                    if (results.isEmpty) {
                        self.dispatchEvent(new ShowToastEvent({
                            // title: Labels.LBL_Info,
                            message: Labels.MSG_No_Changes_To_Save,
                            variant: INFO_VARIANT
                        }));
                        if (self.instance.executiveSummaryPopUp.url) {
                            let a = document.createElement('A');
                            a.href = self.instance.executiveSummaryPopUp.url;
                            a.target = '_blank';
                            a.click();
                            self.instance.executiveSummaryPopUp.url = undefined;
                            self.instance.executiveSummaryPopUp.isOpen = false;
                        }
                    } else if (results.isSuccess) {
                        if (anyOnTopOrPTSavedContract) {
                            self.currentStatusMSG = Labels.LBL_Consolidate_Contracts;
                            _fireEvent(self.pageRef, 'consolidateContracts');
                            done = false;
                            // _fireEvent(self.pageRef, 'requireConso');
                        } else {
                            if (isAdvanced) {
                                _fireEvent(self.pageRef, 'synchroAdvancedContracts');
                                done = false;
                            }
                            if (self.instance.executiveSummaryPopUp.url) {
                                let a = document.createElement('A');
                                a.href = self.instance.executiveSummaryPopUp.url;
                                a.target = '_blank';
                                a.click();
                                self.instance.executiveSummaryPopUp.url = undefined;
                                self.instance.executiveSummaryPopUp.isOpen = false;
                            }
                        }
                    } else {
                        if (results && results.errors) {
                            let errorMessages = results.errors.filter((item, index) => index == results.errors.indexOf(item));
                            if (errorMessages.some(i => i.includes('UNABLE_TO_LOCK_ROW'))) {
                                // self.dispatchEvent(new ShowToastEvent({
                                //     message: Labels.MSG_Error_Lock,
                                //     variant: ERROR_VARIANT,
                                //     mode: STICKY_VARIANT
                                // }));
                                self.instance.unableToLockUnlockPopUp.disableButton = false;
                                self.instance.unableToLockUnlockPopUp.isOpen = true;
                            }
                            errorMessages = errorMessages.filter(i => !i.includes('UNABLE_TO_LOCK_ROW'));
                            let warningMessage = errorMessages.find(i => i.includes(Labels.MSG_Contract_Exist_Same_Period));
                            if (warningMessage) {
                                errorMessages = errorMessages.filter(i => i != warningMessage);
                                self.dispatchEvent(new ShowToastEvent({
                                    // title: Labels.LBL_Error,
                                    message: warningMessage,
                                    // variant: ERROR_VARIANT,
                                    variant: WARNING_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            }
                            self.dispatchEvent(new ShowToastEvent({
                                // title: Labels.LBL_Error,
                                message: errorMessages.join('\n'),
                                variant: ERROR_VARIANT,
                                // variant: WARNING_VARIANT,
                                mode: STICKY_VARIANT
                            }));
                        }
                        if (anyOnTopOrPTSavedContract) {
                            this.currentStatusMSG = Labels.LBL_Consolidate_Contracts;
                            _fireEvent(self.pageRef, 'consolidateContracts');
                            done = false;
                            // _fireEvent(self.pageRef, 'requireConso');
                        } else {
                            if (isAdvanced) {
                                _fireEvent(self.pageRef, 'synchroAdvancedContracts');
                                done = false;
                            }
                            if (self.instance.executiveSummaryPopUp.url) {
                                // window.open(window.location.origin + self.instance.executiveSummaryPopUp.url, '_blank');
                                let a = document.createElement('A');
                                a.href = self.instance.executiveSummaryPopUp.url;
                                a.target = '_blank';
                                a.click();
                                self.instance.executiveSummaryPopUp.url = undefined;
                                self.instance.executiveSummaryPopUp.isOpen = false;
                            }
                        }
                    }
                    if (done) {
                        self.savePopUp = false;
                    }
                }
            };
            if (indexesCmp && indexesCmp.save) {
                self.savePopUp = true;
                _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'process_indexesCmp' });
                indexesCmp.save();
                delete savingMap.indexesCmp;
                processSaveDone();
                _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'process_indexesCmp' });
            }
            if (contractsCmp && contractsCmp.save) {
                self.savePopUp = true;
                _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'process_contractsCmp' });
                contractsCmp.save().then(result => {
                    let contractsSaveResult = JSON.parse(result);
                    if (!anyOnTopOrPTSavedContract) {
                        anyOnTopOrPTSavedContract |= !contractsSaveResult.isEmpty && contractsSaveResult.isTopOrPe /* && !contractsSaveResult.errors.some(i => i.includes('UNABLE_TO_LOCK_ROW')) */;
                    }
                    if (!isAdvanced) {
                        isAdvanced |= !contractsSaveResult.isEmpty && contractsSaveResult.isAdvanced;
                    }
                    results.isEmpty &= contractsSaveResult.hasOwnProperty('isEmpty') && contractsSaveResult.isEmpty;
                    results.isSuccess &= contractsSaveResult.isSuccess;
                    // if (contractsSaveResult.isSuccess && contractsCmp.refreshData) {
                    //     contractsCmp.refreshData();
                    // }
                    contractsSaveResult.errors.forEach(err => results.errors.push(err));
                    delete savingMap.contractsCmp;
                    processSaveDone();
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'process_contractsCmp' });
                }).catch(error => {
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'process_contractsCmp' });
                    self.dispatchEvent(new ShowToastEvent({
                        // title: Labels.LBL_Error,
                        message: error,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                });
            }
            if (negoPlanCmp && negoPlanCmp.save) {
                self.savePopUp = true;
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: true, fname: 'process_negoPlanCmp' });
                self.negoPlanTableLoading = true;
                negoPlanCmp.save().then(result => {
                    self.negoPlanTableLoading = false;
                    let negoPlanSaveResult = JSON.parse(result);
                    results.isEmpty &= negoPlanSaveResult.hasOwnProperty('isEmpty') && negoPlanSaveResult.isEmpty;
                    results.isSuccess &= negoPlanSaveResult.isSuccess;
                    negoPlanSaveResult.errors.forEach(err => results.errors.push(err));
                    delete savingMap.negoPlanCmp;
                    processSaveDone();
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'process_negoPlanCmp' });
                }).catch(error => {
                    self.negoPlanTableLoading = false;
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'process_negoPlanCmp' });
                    self.dispatchEvent(new ShowToastEvent({
                        // title: Labels.LBL_Error,
                        message: error,
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                });
            }
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'global_save' });
        },
        selectedNegoScopeId: undefined,
        selectedSupplierId: undefined,
        loadingSelection: true,
        get negoYearOptions() {
            let currentYear = new Date().getFullYear();
            return [
                { label: "" + (currentYear - 2), value: "" + (currentYear - 2) },
                { label: "" + (currentYear - 1), value: "" + (currentYear - 1) },
                { label: "" + currentYear, value: "" + currentYear },
                { label: "" + (currentYear + 1), value: "" + (currentYear + 1) },
                { label: "" + (currentYear + 2), value: "" + (currentYear + 2) },
                { label: "" + (currentYear + 3), value: "" + (currentYear + 3) },
            ]
        },
        negoYear: (new Date().getFullYear() + 1).toString(),
        handleYearChange(event) {
            this.instance.negoYear = event.detail.value;
        },
        displayNegoscopesList: false,
        hideNegoscopesList(event) {
            let self = this;
            setTimeout(() => {
                self.instance.displayNegoscopesList = false;
            }, 200);
        },
        showNegoscopesList(event) {
            this.instance.displayNegoscopesList = true;
        },
        hideContractsListTimeOut() { },
        displayContractsList: false,
        clearHideContractsList(event) {
            clearTimeout(this.instance.hideContractsListTimeOut);
        },
        hideContractsList(event) {
            let self = this;
            this.instance.hideContractsListTimeOut = setTimeout(() => {
                self.instance.displayContractsList = false;
            }, 200);
        },
        showContractsList(event) {
            this.instance.displayContractsList = true;
        },
        contracts: [],
        contractIds: [],
        validTariff: {
            validTariffNegoYearMap: {},
            validTariffPEMap: {},
            validTariffPEMapping: {},
            validFoldingMap: {},
        },
        negoScopes: [],
        negoscope: {
            oInstance: {},
            searchTimeOut: undefined,
            searchTerm: '',
            data: [],
            hasSearchTerm: false,
            isNoItemToDisplay: false,
            get url() { return '/' + this.oInstance.Id; },
            setCurrentItem(event) {
                _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'setCurrentItem' });
                this.contractRecordTypes.forEach(item => item.show = false);
                this.instance.showSideBar = false;
                this.instance.readyToDisplay = false;
                this.instance.loadingSelection = true;
                this.instance.supplier.displayNegoscopePopup = false;
                this.instance.supplier.negoscopes = [];
                this.instance.supplier.searchTerm = '';
                this.instance.supplier.data = [];
                this.instance.supplier.hasSearchTerm = this.instance.supplier.searchTerm.length > 2;
                this.instance.negoscope.oInstance = {};
                this.instance.supplier.oInstance = {};
                let selectedNegoScopeId = event.target.dataset.id;
                let negoYear = this.instance.negoYear;
                this.instance.selectedNegoScopeId = selectedNegoScopeId;
                let self = this;
                getContracts({ negoYear: negoYear, negoScopeId: selectedNegoScopeId, postSigned: this.postSigned }).then(result => {
                    let data = JSON.parse(result);
                    if (data?.errors?.length == 0) {
                        self.instance.negoscope.oInstance = data.negoScope;
                        self.instance.supplier.oInstance = data.supplier;
                        self.instance.negoScopes = data.negoScopes;
                        self.instance.negoDiscountTypeLabelsMap = data.negoDiscountTypeLabelsMap;
                        self.instance.indexLabelsMap = data.indexLabelsMap;
                        self.instance.slabsMethodMap = data.slabsMethodMap;
                        self.instance.prioritizeSortBDateNegotiate = data.prioritizeSortBDateNegotiate;
                        self.instance.contractRTN1Settings = data.contractRTN1Settings;
                        let contractsOptions = [];
                        let hasRefNegoBase = false;
                        let hasValidRefNegoBase = false;
                        let hasOtherContracts = false;
                        self.instance.contracts = data.contracts.map(item => {
                            let newItem = {
                                Id: item.Id,
                                isOnTop: item[API_NAMES.Contract__c.Is_OnTop_Simulation__c],
                                DeveloperName: item.RecordType.DeveloperName,
                                value: item.Id,
                                label: item.Name,
                                checked: true,
                                bdate: new Date(item[API_NAMES.Contract__c.Contract_BDate__c]),
                                disabled: (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear) && (item.RecordType.DeveloperName == 'Nego_Base'),
                                weight: data.contractWeightMap[item.RecordType.DeveloperName + '-' + new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()],
                                get class() {
                                    return 'slds-listbox__item slds-truncate ' + (this.isOnTop ? 'cell_On_Top' : ' cell_' + this.DeveloperName.replace(/_/g, '-').toLocaleLowerCase());
                                },
                            };
                            newItem[API_NAMES.Contract__c.SimulationNumber__c] = item[API_NAMES.Contract__c.SimulationNumber__c];
                            hasRefNegoBase |= new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear && item.RecordType.DeveloperName == 'Nego_Base';
                            hasValidRefNegoBase |= (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear) && (item.RecordType.DeveloperName == 'Nego_Base' && item[API_NAMES.Contract__c.Status__c] == 'Validated');
                            hasOtherContracts |= item.RecordType.DeveloperName != 'Nego_Base';
                            contractsOptions.push(newItem);
                            item.bdate = new Date(item[API_NAMES.Contract__c.Contract_BDate__c]);
                            item.weight = data.contractWeightMap[item.RecordType.DeveloperName + '-' + new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()];
                            return item;
                        });
                        if (data.prioritizeSortBDateNegotiate) {
                            self.instance.contracts = self.instance.contracts.sort((c1, c2) => {
                                if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                                    if (c1.weight == c2.weight) {
                                        if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                            return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                        } else {
                                            return c1.Id.localeCompare(c2.Id);
                                        }
                                    }
                                    return c1.weight - c2.weight;
                                }
                                return c1.bdate.getTime() - c2.bdate.getTime();
                            });
                            contractsOptions = contractsOptions.sort((c1, c2) => {
                                if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                                    if (c1.weight == c2.weight) {
                                        if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                            return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                        } else {
                                            return c1.Id.localeCompare(c2.Id);
                                        }
                                    }
                                    return c1.weight - c2.weight;
                                }
                                return c1.bdate.getTime() - c2.bdate.getTime();
                            });
                        }
                        self.displayFirstMessage = !hasOtherContracts;
                        if (!hasRefNegoBase) {
                            self.lockedActions = false;
                            if (LightningAlert && LightningAlert.open) {
                                LightningAlert.open({
                                    message: data.warningNegoBaseNotExistLabel,
                                    theme: 'warning',
                                    label: Labels.LBL_Info
                                });
                            } else {
                                self.dispatchEvent(new ShowToastEvent({
                                    // title: Labels.LBL_Info,
                                    message: data.warningNegoBaseNotExistLabel,
                                    variant: INFO_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            }
                        } else {
                            if (!hasValidRefNegoBase) {
                                if (LightningAlert && LightningAlert.open) {
                                    LightningAlert.open({
                                        message: data.warningNegoBaseNotValidLabel,
                                        theme: 'warning',
                                        label: Labels.LBL_Info
                                    });
                                } else {
                                    self.dispatchEvent(new ShowToastEvent({
                                        // title: Labels.LBL_Info,
                                        message: data.warningNegoBaseNotValidLabel,
                                        variant: INFO_VARIANT,
                                        mode: STICKY_VARIANT
                                    }));
                                }
                                self.lockedActions = true;
                            } else {
                                self.lockedActions = false;
                            }
                        }
                        self.instance.hasData = data.contracts.length != 0;
                        self.instance.contractsOptions = contractsOptions;
                        self.instance.contractWeightMap = data.contractWeightMap;
                        self.instance.contractIds = self.instance.contracts.map(item => item.Id);
                        self.instance.hasPE = self.instance.contracts.some(item => {
                            if ((new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Period_Extension')) {
                                let bDate = new Date(item[API_NAMES.Contract__c.Contract_BDate__c]);
                                let eDate = new Date(item[API_NAMES.Contract__c.Contract_EDate__c]);
                                _fireEvent(self.pageRef, 'setPTDates', { bDate, eDate });
                                return true;
                            }
                            return false;
                        });
                        _fireEvent(self.pageRef, 'updateHasPEOnRefresh', { hasPe: self.instance.hasPE });
                        self.instance.hasPeSigned = self.instance.contracts.some(item => {
                            return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Period_Extension') && (item[API_NAMES.Contract__c.Status__c] == 'Signed');
                        });
                        _fireEvent(self.pageRef, 'updateHasPESignedOnRefresh', { hasPeSigned: self.instance.hasPeSigned });
                        self.instance.hasTop = self.instance.contracts.some(item => {
                            return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && item[API_NAMES.Contract__c.Is_OnTop_Simulation__c];
                        });
                        self.instance.hasTopNotSimulation = self.instance.contracts.some(item => {
                            return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && item[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && (item.RecordType.DeveloperName != 'Simulation');
                        });
                        self.instance.hasNegoBaseExit = self.instance.contracts.some(item => {
                            return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Nego_Base_Exit');
                        });
                        self.instance.Labels.createSimulFromNegoBaseLabel = data.createSimulFromNegoBaseLabel;
                        self.instance.Labels.createSafeBalanceFromNegoBaseLabel = data.createSafeBalanceFromNegoBaseLabel;
                        self.instance.Labels.createSimulFromSafeBalanceLabel = data.createSimulFromSafeBalanceLabel;
                        self.instance.Labels.createSimulFromSimulLabel = data.createSimulFromSimulLabel;
                        self.instance.Labels.duplicateNegoBasetoPE = data.duplicateNegoBasetoPE;
                        self.instance.Labels.duplicateSafeBalanceToPE = data.duplicateSafeBalanceToPE;
                        self.instance.Labels.warningNegoBaseNotValidLabel = data.warningNegoBaseNotValidLabel;
                        self.instance.Labels.LBL_Duplicate_Contracts = data.createSimulFromNegoBaseLabel + '/' + data.createSafeBalanceFromNegoBaseLabel + '/' + data.createSimulFromSafeBalanceLabel + '/' + data.createSimulFromSimulLabel + '/' + data.duplicateNegoBasetoPE + '/' + data.duplicateSafeBalanceToPE;
                        self.instance.validTariff = {
                            validTariffNegoYearMap: data.validTariffNegoYearMap,
                            validTariffPEMap: data.validTariffPEMap,
                            validTariffPEMapping: data.validTariffPEMapping,
                            validFoldingMap: data.validFoldingMap,
                        };
                        self.instance.readyToDisplay = true;
                        self.instance.loadingSelection = false;
                        _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'setCurrentItem' });
                        _fireEvent(self.pageRef, 'registerAllContractIds', {});
                    } else {
                        data?.errors?.forEach(error => {
                            self.dispatchEvent(new ShowToastEvent({
                                // title: Labels.LBL_Info,
                                message: error,
                                variant: INFO_VARIANT,
                                mode: STICKY_VARIANT
                            }));
                        });
                    }
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'setCurrentItem' });
                });
            },
            _setCurrentItem(instance) {
                return new Promise((resolve, reject) => {
                    instance.readyToDisplay = false;
                    instance.loadingSelection = true;
                    instance.supplier.displayNegoscopePopup = false;
                    instance.supplier.negoscopes = [];
                    instance.supplier.searchTerm = '';
                    instance.supplier.data = [];
                    instance.supplier.hasSearchTerm = instance.supplier.searchTerm.length > 2;
                    instance.negoscope.oInstance = {};
                    instance.supplier.oInstance = {};
                    let selectedNegoScopeId = instance.selectedNegoScopeId;
                    let negoYear = instance.negoYear;
                    getContracts({ negoYear: negoYear, negoScopeId: selectedNegoScopeId, postSigned: this.postSigned }).then(result => {
                        let data = JSON.parse(result);
                        if (data?.errors?.length == 0) {
                            instance.negoscope.oInstance = data.negoScope;
                            instance.supplier.oInstance = data.supplier;
                            instance.negoScopes = data.negoScopes;
                            instance.negoDiscountTypeLabelsMap = data.negoDiscountTypeLabelsMap;
                            instance.indexLabelsMap = data.indexLabelsMap;
                            instance.slabsMethodMap = data.slabsMethodMap;
                            instance.prioritizeSortBDateNegotiate = data.prioritizeSortBDateNegotiate;
                            instance.contractRTN1Settings = data.contractRTN1Settings;
                            let contractsOptions = [];
                            let hasRefNegoBase = false;
                            let hasValidRefNegoBase = false;
                            let hasOtherContracts = false;
                            instance.contracts = data.contracts.map(item => {
                                let newItem = {
                                    Id: item.Id,
                                    isOnTop: item[API_NAMES.Contract__c.Is_OnTop_Simulation__c],
                                    DeveloperName: item.RecordType.DeveloperName,
                                    value: item.Id,
                                    label: item.Name,
                                    checked: true,
                                    bdate: new Date(item[API_NAMES.Contract__c.Contract_BDate__c]),
                                    disabled: (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear) && (item.RecordType.DeveloperName == 'Nego_Base'),
                                    weight: data.contractWeightMap[item.RecordType.DeveloperName + '-' + new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()],
                                    get class() {
                                        return 'slds-listbox__item slds-truncate ' + (this.isOnTop ? 'cell_On_Top' : ' cell_' + this.DeveloperName.replace(/_/g, '-').toLocaleLowerCase());
                                    },
                                };
                                newItem[API_NAMES.Contract__c.SimulationNumber__c] = item[API_NAMES.Contract__c.SimulationNumber__c];
                                hasRefNegoBase |= new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear && item.RecordType.DeveloperName == 'Nego_Base';
                                hasValidRefNegoBase |= (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear) && (item.RecordType.DeveloperName == 'Nego_Base' && item[API_NAMES.Contract__c.Status__c] == 'Validated');
                                hasOtherContracts |= item.RecordType.DeveloperName != 'Nego_Base';
                                contractsOptions.push(newItem);
                                item.bdate = new Date(item[API_NAMES.Contract__c.Contract_BDate__c]);
                                item.weight = data.contractWeightMap[item.RecordType.DeveloperName + '-' + new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()];
                                return item;
                            });
                            if (data.prioritizeSortBDateNegotiate) {
                                instance.contracts = instance.contracts.sort((c1, c2) => {
                                    if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                                        if (c1.weight == c2.weight) {
                                            if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                                return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                            } else {
                                                return c1.Id.localeCompare(c2.Id);
                                            }
                                        }
                                        return c1.weight - c2.weight;
                                    }
                                    return c1.bdate.getTime() - c2.bdate.getTime();
                                });
                                contractsOptions = contractsOptions.sort((c1, c2) => {
                                    if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                                        if (c1.weight == c2.weight) {
                                            if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                                return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                            } else {
                                                return c1.Id.localeCompare(c2.Id);
                                            }
                                        }
                                        return c1.weight - c2.weight;
                                    }
                                    return c1.bdate.getTime() - c2.bdate.getTime();
                                });
                            }
                            instance.self.displayFirstMessage = !hasOtherContracts;
                            if (!hasRefNegoBase) {
                                instance.self.lockedActions = false;
                                if (LightningAlert && LightningAlert.open) {
                                    LightningAlert.open({
                                        message: data.warningNegoBaseNotExistLabel,
                                        theme: 'warning',
                                        label: Labels.LBL_Info
                                    });
                                } else {
                                    instance.self.dispatchEvent(new ShowToastEvent({
                                        // title: Labels.LBL_Info,
                                        message: data.warningNegoBaseNotExistLabel,
                                        variant: INFO_VARIANT,
                                        mode: STICKY_VARIANT
                                    }));
                                }
                            } else {
                                if (!hasValidRefNegoBase) {
                                    if (LightningAlert && LightningAlert.open) {
                                        LightningAlert.open({
                                            message: data.warningNegoBaseNotValidLabel,
                                            theme: 'warning',
                                            label: Labels.LBL_Info
                                        });
                                    } else {
                                        instance.self.dispatchEvent(new ShowToastEvent({
                                            // title: Labels.LBL_Info,
                                            message: data.warningNegoBaseNotValidLabel,
                                            variant: INFO_VARIANT,
                                            mode: STICKY_VARIANT
                                        }));
                                    }
                                    instance.self.lockedActions = true;
                                } else {
                                    instance.self.lockedActions = false;
                                }
                            }
                            instance.hasData = data.contracts.length != 0;
                            instance.contractsOptions = contractsOptions;
                            instance.contractWeightMap = data.contractWeightMap;
                            instance.contractIds = instance.contracts.map(item => item.Id);
                            instance.hasPE = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Period_Extension')
                            });
                            _fireEvent(instance.self.pageRef, 'updateHasPEOnRefresh', { hasPe: instance.hasPE });
                            instance.hasPeSigned = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Period_Extension') && (item[API_NAMES.Contract__c.Status__c] == 'Signed')
                            });
                            _fireEvent(instance.self.pageRef, 'updateHasPESignedOnRefresh', { hasPeSigned: instance.hasPeSigned });
                            instance.hasTop = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && item[API_NAMES.Contract__c.Is_OnTop_Simulation__c]
                            });
                            instance.hasTopNotSimulation = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && item[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && (item.RecordType.DeveloperName != 'Simulation')
                            });
                            instance.hasNegoBaseExit = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Nego_Base_Exit');
                            });
                            instance.Labels.createSimulFromNegoBaseLabel = data.createSimulFromNegoBaseLabel;
                            instance.Labels.createSafeBalanceFromNegoBaseLabel = data.createSafeBalanceFromNegoBaseLabel;
                            instance.Labels.createSimulFromSafeBalanceLabel = data.createSimulFromSafeBalanceLabel;
                            instance.Labels.createSimulFromSimulLabel = data.createSimulFromSimulLabel;
                            instance.Labels.duplicateNegoBasetoPE = data.duplicateNegoBasetoPE;
                            instance.Labels.duplicateSafeBalanceToPE = data.duplicateSafeBalanceToPE;
                            instance.Labels.warningNegoBaseNotValidLabel = data.warningNegoBaseNotValidLabel;
                            instance.Labels.LBL_Duplicate_Contracts = data.createSimulFromNegoBaseLabel + '/' + data.createSafeBalanceFromNegoBaseLabel + '/' + data.createSimulFromSafeBalanceLabel + '/' + data.createSimulFromSimulLabel + '/' + data.duplicateNegoBasetoPE + '/' + data.duplicateSafeBalanceToPE;
                            instance.validTariff = {
                                validTariffNegoYearMap: data.validTariffNegoYearMap,
                                validTariffPEMap: data.validTariffPEMap,
                                validTariffPEMapping: data.validTariffPEMapping,
                                validFoldingMap: data.validFoldingMap,
                            };
                            instance.readyToDisplay = true;
                            instance.loadingSelection = false;
                        } else {
                            data?.errors?.forEach(error => {
                                instance.self.dispatchEvent(new ShowToastEvent({
                                    // title: Labels.LBL_Info,
                                    message: error,
                                    variant: INFO_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            });
                        }
                        // self.instance = Object.assign({}, self.instance);
                        resolve(instance);
                    });
                });
            },
            _renewCurrentItem(instance) {
                return new Promise((resolve, reject) => {
                    let selectedNegoScopeId = instance.selectedNegoScopeId;
                    let negoYear = instance.negoYear;
                    getContracts({ negoYear: negoYear, negoScopeId: selectedNegoScopeId, postSigned: this.postSigned }).then(result => {
                        let data = JSON.parse(result);
                        if (data?.errors?.length == 0) {
                            let contractsOptions = [];
                            let hasRefNegoBase = false;
                            let hasValidRefNegoBase = false;
                            let hasOtherContracts = false;
                            instance.contracts = data.contracts.map(item => {
                                let newItem = {
                                    Id: item.Id,
                                    isOnTop: item[API_NAMES.Contract__c.Is_OnTop_Simulation__c],
                                    DeveloperName: item.RecordType.DeveloperName,
                                    value: item.Id,
                                    label: item.Name,
                                    checked: true,
                                    bdate: new Date(item[API_NAMES.Contract__c.Contract_BDate__c]),
                                    disabled: (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear) && (item.RecordType.DeveloperName == 'Nego_Base'),
                                    weight: data.contractWeightMap[item.RecordType.DeveloperName + '-' + new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()],
                                    get class() {
                                        return 'slds-listbox__item slds-truncate ' + (this.isOnTop ? 'cell_On_Top' : ' cell_' + this.DeveloperName.replace(/_/g, '-').toLocaleLowerCase());
                                    },
                                };
                                newItem[API_NAMES.Contract__c.SimulationNumber__c] = item[API_NAMES.Contract__c.SimulationNumber__c];
                                hasRefNegoBase |= new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear && item.RecordType.DeveloperName == 'Nego_Base';
                                hasValidRefNegoBase |= (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() < negoYear) && (item.RecordType.DeveloperName == 'Nego_Base' && item[API_NAMES.Contract__c.Status__c] == 'Validated');
                                hasOtherContracts |= item.RecordType.DeveloperName != 'Nego_Base';
                                contractsOptions.push(newItem);
                                item.bdate = new Date(item[API_NAMES.Contract__c.Contract_BDate__c]);
                                item.weight = data.contractWeightMap[item.RecordType.DeveloperName + '-' + new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()];
                                return item;
                            });
                            if (data.prioritizeSortBDateNegotiate) {
                                instance.contracts = instance.contracts.sort((c1, c2) => {
                                    if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                                        if (c1.weight == c2.weight) {
                                            if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                                return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                            } else {
                                                return c1.Id.localeCompare(c2.Id);
                                            }
                                        }
                                        return c1.weight - c2.weight;
                                    }
                                    return c1.bdate.getTime() - c2.bdate.getTime();
                                });
                                contractsOptions = contractsOptions.sort((c1, c2) => {
                                    if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                                        if (c1.weight == c2.weight) {
                                            if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                                return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                            } else {
                                                return c1.Id.localeCompare(c2.Id);
                                            }
                                        }
                                        return c1.weight - c2.weight;
                                    }
                                    return c1.bdate.getTime() - c2.bdate.getTime();
                                });
                            }
                            if (!hasRefNegoBase) {
                                instance.self.lockedActions = false;
                                if (LightningAlert && LightningAlert.open) {
                                    LightningAlert.open({
                                        message: data.warningNegoBaseNotExistLabel,
                                        theme: 'warning',
                                        label: Labels.LBL_Info
                                    });
                                } else {
                                    instance.self.dispatchEvent(new ShowToastEvent({
                                        // title: Labels.LBL_Info,
                                        message: data.warningNegoBaseNotExistLabel,
                                        variant: INFO_VARIANT,
                                        mode: STICKY_VARIANT
                                    }));
                                }
                            } else {
                                if (!hasValidRefNegoBase) {
                                    if (LightningAlert && LightningAlert.open) {
                                        LightningAlert.open({
                                            message: data.warningNegoBaseNotValidLabel,
                                            theme: 'warning',
                                            label: Labels.LBL_Info
                                        });
                                    } else {
                                        instance.self.dispatchEvent(new ShowToastEvent({
                                            // title: Labels.LBL_Info,
                                            message: data.warningNegoBaseNotValidLabel,
                                            variant: INFO_VARIANT,
                                            mode: STICKY_VARIANT
                                        }));
                                    }
                                    instance.self.lockedActions = true;
                                } else {
                                    instance.self.lockedActions = false;
                                }
                            }
                            instance.hasData = data.contracts.length != 0;
                            instance.contractsOptions = contractsOptions;
                            instance.contractWeightMap = data.contractWeightMap;
                            instance.contractIds = instance.contracts.map(item => item.Id);
                            instance.hasPE = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Period_Extension')
                            });
                            _fireEvent(instance.self.pageRef, 'updateHasPEOnRefresh', { hasPe: instance.hasPE });
                            instance.hasPeSigned = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Period_Extension') && (item[API_NAMES.Contract__c.Status__c] == 'Signed')
                            });
                            _fireEvent(instance.self.pageRef, 'updateHasPESignedOnRefresh', { hasPeSigned: instance.hasPeSigned });
                            instance.hasTop = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && item[API_NAMES.Contract__c.Is_OnTop_Simulation__c]
                            });
                            instance.hasTopNotSimulation = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && item[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && (item.RecordType.DeveloperName != 'Simulation')
                            });
                            instance.hasNegoBaseExit = instance.contracts.some(item => {
                                return (new Date(item[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear() == negoYear) && (item.RecordType.DeveloperName == 'Nego_Base_Exit');
                            });
                            instance.Labels.createSimulFromNegoBaseLabel = data.createSimulFromNegoBaseLabel;
                            instance.Labels.createSafeBalanceFromNegoBaseLabel = data.createSafeBalanceFromNegoBaseLabel;
                            instance.Labels.createSimulFromSafeBalanceLabel = data.createSimulFromSafeBalanceLabel;
                            instance.Labels.createSimulFromSimulLabel = data.createSimulFromSimulLabel;
                            instance.Labels.duplicateNegoBasetoPE = data.duplicateNegoBasetoPE;
                            instance.Labels.duplicateSafeBalanceToPE = data.duplicateSafeBalanceToPE;
                            instance.Labels.warningNegoBaseNotValidLabel = data.warningNegoBaseNotValidLabel;
                            instance.Labels.LBL_Duplicate_Contracts = data.createSimulFromNegoBaseLabel + '/' + data.createSafeBalanceFromNegoBaseLabel + '/' + data.createSimulFromSafeBalanceLabel + '/' + data.createSimulFromSimulLabel + '/' + data.duplicateNegoBasetoPE + '/' + data.duplicateSafeBalanceToPE;
                            instance.validTariff = {
                                validTariffNegoYearMap: data.validTariffNegoYearMap,
                                validTariffPEMap: data.validTariffPEMap,
                                validTariffPEMapping: data.validTariffPEMapping,
                                validFoldingMap: data.validFoldingMap,
                            };
                            instance.readyToDisplay = true;
                            instance.loadingSelection = false;
                            let contractsCmp = instance.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
                            if (contractsCmp && contractsCmp.updateContractIds) {
                                contractsCmp.updateContractIds(JSON.stringify(instance.contractIds));
                            }
                        } else {
                            data?.errors?.forEach(error => {
                                instance.self.dispatchEvent(new ShowToastEvent({
                                    // title: Labels.LBL_Info,
                                    message: error,
                                    variant: INFO_VARIANT,
                                    mode: STICKY_VARIANT
                                }));
                            });
                        }
                        resolve(instance);
                    });
                });
            },
            getData(event) {
                window.clearTimeout(this.instance.negoscope.searchTimeOut);
                this.instance.negoscope.searchTerm = event.detail.value;
                this.instance.negoscope.hasSearchTerm = this.instance.negoscope.searchTerm.length > 2;
                if (this.instance.negoscope.searchTerm.length == 0) {
                    this.instance.negoscope.data = [];
                    this.instance.negoscope.isNoItemToDisplay = this.instance.negoscope.data.length == 0;
                }
                if (this.instance.negoscope.hasSearchTerm) {
                    let self = this;
                    this.instance.negoscope.searchTimeOut = setTimeout(() => {
                        if (self.instance.negoscope.searchTerm && self.instance.negoscope.searchTerm.length > 2) {
                            getNegoScopes({ searchTerm: self.instance.negoscope.searchTerm }).then(result => {
                                self.instance.negoscope.data = JSON.parse(result).map(item => {
                                    item.link = '/' + item.Id;
                                    return item;
                                });
                                self.instance.negoscope.isNoItemToDisplay = self.instance.negoscope.data.length == 0;
                            }).catch(error => {
                                console.log(error);
                            });
                        }
                    }, SEARCH_TIME_OUT);
                }
            },
        },
        supplier: {
            displayNegoscopePopup: false,
            negoscopes: [],
            oInstance: {},
            searchTimeOut: undefined,
            searchTerm: '',
            data: [],
            hasSearchTerm: false,
            isNoItemToDisplay: false,
            getData(event) {
                window.clearTimeout(this.instance.supplier.searchTimeOut);
                this.instance.supplier.searchTerm = event.detail.value;
                this.instance.supplier.hasSearchTerm = this.instance.supplier.searchTerm.length > 2;
                if (this.instance.supplier.searchTerm.length == 0) {
                    this.instance.supplier.data = [];
                    this.instance.supplier.isNoItemToDisplay = this.instance.supplier.data.length == 0;
                }
                if (this.instance.supplier.hasSearchTerm) {
                    let self = this;
                    this.instance.supplier.searchTimeOut = setTimeout(() => {
                        if (self.instance.supplier.searchTerm && self.instance.supplier.searchTerm.length > 2) {
                            getSuppliers({ searchTerm: self.instance.supplier.searchTerm }).then(result => {
                                self.instance.supplier.data = JSON.parse(result).map(item => {
                                    item.link = '/' + item.Id;
                                    return item;
                                });
                                self.instance.supplier.isNoItemToDisplay = self.instance.supplier.data.length == 0;
                            }).catch(error => {
                                console.log(error);
                            });
                        }
                    }, SEARCH_TIME_OUT);
                }
            },
            cancelSelectNegoscope(event) {
                this.instance.supplier.displayNegoscopePopup = false;
                this.instance.supplier.negoscopes = [];
                this.instance.supplier.searchTerm = '';
                this.instance.supplier.data = [];
                this.instance.supplier.hasSearchTerm = this.instance.supplier.searchTerm.length > 2;
            },
            setCurrentItem(event) {
                let selectedSupplierId = event.target.dataset.id;
                this.instance.selectedSupplierId = selectedSupplierId;
                let self = this;
                getNegoScopesBySupplier({ supplierId: selectedSupplierId }).then(result => {
                    let data = JSON.parse(result);
                    self.instance.supplier.negoscopes = data;
                    self.instance.supplier.displayNegoscopePopup = true;
                });
            },
        },
        negoplanReadyHandler(event) {
            let wrapper = event.detail.value;
            this.instance.negoPlan.wrapper.negoPlan = wrapper.negoPlan;
            this.instance.negoPlan.wrapper.negoBaseInitContract = wrapper.negoBaseInitContract;
            this.instance.negoPlan.wrapper.negoBaseContract = wrapper.negoBaseContract;
            this.instance.negoPlan.wrapper.ref_CA_index3 = wrapper.ref_CA_index3;
            this.instance.negoPlan.wrapper.ref_valeurReelle_index4 = wrapper.ref_valeurReelle_index4;
            this.instance.negoPlan.wrapper.negoBaseInit_valeurReelle_index4 = wrapper.negoBaseInit_valeurReelle_index4;
            // this.instance.negoPlan.wrapper.isCorrectedRate = wrapper.negoPlan[API_NAMES.Nego_Plan__c.SPITM_Is_Corrected_Rise_Rate__c] && wrapper.negoPlan[API_NAMES.Nego_Plan__c.SPITM_Last_Corrected_RR_Nb__c] == wrapper.negoPlan[API_NAMES.Nego_Plan__c.NEGO_Rise_Rate_Validated_Nb__c];
            this.instance.negoPlan.wrapper.negoBaseInit_valeurReelle_index5 = wrapper.negoBaseInit_valeurReelle_index5;
            this.instance.negoPlan.oInstance = wrapper.negoPlan;
            _fireEvent(this.pageRef, 'setNegoPlan', {
                // riseRateDiff: wrapper.negoPlan[API_NAMES.Nego_Plan__c.NEGO_Rise_Rate_Validated__c] || 0,
                // depreciationRiseRateDiff: wrapper.negoPlan[API_NAMES.Nego_Plan__c.NEGO_Depreciation_Rate_Validated__c] || 0,
            });
        },
        contracts: [],
        contractsOptions: [],
        toggleShowContract(event) {
            let index = event.target.dataset.index;
            let contractOption = this.instance.contractsOptions[index];
            contractOption.checked = !contractOption.checked;
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            if (contractsCmp && contractsCmp.toggleContract) {
                contractsCmp.toggleContract(contractOption.value, contractOption.checked);
            }
            _fireEvent(this.pageRef, 'refreshList', {});
        },
        consolidateContract(event) {
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'consolidateContract' });
            let self = this;
            let hasTopNotSimulation = this.instance.hasTopNotSimulation;
            let hasNegoBaseExit = this.instance.hasNegoBaseExit;
            let instance = this.instance;
            let negoYear = this.instance.negoYear;
            let nsId = this.instance.negoscope.oInstance.Id;
            let supplierId = this.instance.supplier.oInstance.Id;
            self.consoRunning = true;
            consolidateContract({ supplierId: supplierId, nsId: nsId, negoYear: negoYear, isCreateNegoBaseExit: hasTopNotSimulation && !hasNegoBaseExit }).then(errorMsgs => {
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'consolidateContract' });
                _fireEvent(self.pageRef, 'refreshAfterConso', {});
                let _errorMsgs = [];
                (errorMsgs && errorMsgs.length ? errorMsgs : []).forEach(it => _errorMsgs = [..._errorMsgs, ...it.split('\n')]);
                errorMsgs = _errorMsgs;
                if (errorMsgs && errorMsgs.length) {
                    errorMsgs = errorMsgs.filter((item, index) => item && item.trim() && index == errorMsgs.indexOf(item));
                    let warningMessage = errorMsgs.find(i => i.includes(Labels.MSG_Contract_Exist_Same_Period));
                    if (warningMessage) {
                        errorMsgs = errorMsgs.filter(i => i != warningMessage);
                        self.dispatchEvent(new ShowToastEvent({
                            // title: Labels.LBL_Error,
                            message: warningMessage,
                            // variant: ERROR_VARIANT,
                            variant: WARNING_VARIANT,
                            mode: STICKY_VARIANT
                        }));
                    }
                    if (errorMsgs && errorMsgs.length) {
                        self.dispatchEvent(new ShowToastEvent({
                            // title: Labels.LBL_Error,
                            message: errorMsgs ? errorMsgs.join('\n') : '',
                            variant: ERROR_VARIANT,
                            mode: STICKY_VARIANT
                        }));
                    }
                } else {
                    if (!errorMsgs || !errorMsgs.length) {
                        if (self.instance.executiveSummaryPopUp.url) {
                            let a = document.createElement('A');
                            a.href = self.instance.executiveSummaryPopUp.url;
                            a.target = '_blank';
                            a.click();
                            self.instance.executiveSummaryPopUp.url = undefined;
                            self.instance.executiveSummaryPopUp.isOpen = false;
                        }
                        // self.dispatchEvent(new ShowToastEvent({
                        //     // title: Labels.LBL_Success,
                        //     message: Labels.LBL_Consolidate_Contracts,
                        //     variant: SUCCESS_VARIANT
                        // }));
                        if (instance.selectedNegoScopeId) {
                            instance.negoscope._renewCurrentItem(instance).then(result => {
                                self.instance = result;
                                // _fireEvent(self.pageRef, 'registerAllContractIds', {});
                            });
                        } else {
                            instance.readyToDisplay = true;
                        }
                    }
                }
                self.consoRunning = false;
                self.requireConso = false;
            }).catch(error => {
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'consolidateContract' });
                _fireEvent(self.pageRef, 'refreshAfterConso', {});
                self.dispatchEvent(new ShowToastEvent({
                    // title: Labels.LBL_Error,
                    message: error,
                    variant: ERROR_VARIANT,
                    mode: STICKY_VARIANT
                }));
                self.consoRunning = false;
                self.requireConso = false;
            });
        },
        generateFolding(event) {
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'generateFolding' });
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            if (contractsCmp && contractsCmp.generateFolding) {
                contractsCmp.generateFolding();
            }
            _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'generateFolding' });
        },
        calculateAllIndexes(event) {
            _fireEvent(this.pageRef, 'calculateAllIndexes', {});
        },
    }
    @track walkthroughStyle = 'opacity: 0;';
    constructor() {
        super();
        window.addEventListener('beforeunload', (event) => {
            if (this.hasChanges) {
                event.preventDefault();
                event.returnValue = 'block leave';
            }
        });
    }
    @track headerHeight;
    connectedCallback() {
        if (this.negoyear) {
            this.instance.negoYear = this.negoyear;
        }
        if (this.negoId) {
            this.instance.selectedNegoScopeId = this.negoId;
        }
        if (this.contractId) {
            this.instance.selectedContractId = this.contractId;
            this.instance.backUrl = '/' + this.contractId;
            this.instance.hasBackUrl = true;
        }
        if (this.negoyear && this.negoId && this.contractId) {
            this.instance.currentUrl = '/apex/NegoptimNavigator?' + ['c__componentName=Negoptim:negotiate', 'a__negoyear=' + this.negoyear, 'a__negoId=' + this.negoId, 'a__contractId=' + this.contractId].join('&');
            this.ready_setCurrentPageReference = true;
            // if (this.instance.selectedNegoScopeId) {
            //     this.instance.negoscope._setCurrentItem(this.instance).then(result => {
            //         self.instance = result;
            //         _fireEvent(self.pageRef, 'registerAllContractIds', {});
            //     });
            // }
        }
        _registerListener('unlockLoadingLockedActions', () => {
            this.loadingLockedActions = false;
        }, this);
        _registerListener('openExecutiveSummary', (executiveSummaryUrl) => {
            if (!this.hasChangesToSave || this.lockedActions) {
                // window.open(window.location.origin + executiveSummaryUrl, '_blank');
                let a = document.createElement('A');
                a.href = executiveSummaryUrl;
                a.target = '_blank';
                a.click();
                this.instance.executiveSummaryPopUp.isOpen = false;
            } else {
                this.instance.executiveSummaryPopUp.url = executiveSummaryUrl;
                this.currentStatusMSG = Labels.MSG_Save_Before_Open_URL;
                this.instance.executiveSummaryPopUp.buttonsFlag = true;
                this.instance.executiveSummaryPopUp.isOpen = true;
            }
        }, this);
        let self = this;
        window.addEventListener('resize', this.setHeaderHeight);
        _registerListener('hasChanges', () => {
            this.hasChanges = true;
        }, this);
        _registerListener('ref_contract_clone_icon', ({ top, left }) => {
            clearTimeout(this.wakthroughtTimeOut);
            this.wakthroughtTimeOut = setTimeout(() => {
                let walktrought = this.template.querySelector('[data-id="walkthrough"]');
                if (walktrought) {
                    let width = walktrought.getBoundingClientRect().width;
                    let height = walktrought.getBoundingClientRect().height;
                    left -= width / 2 - 10;
                    top -= height / 2 + 50;
                    this.walkthroughStyle = 'position: fixed; left:' + left + 'px; top:' + top + 'px;';
                }
            }, 200);
        }, this);
        _registerListener('registerAllContractIds', () => {
            this.contractLoaderQueue = this.instance.contractIds.map(item => item);
            _fireEvent(this.pageRef, 'loadNextContract', {});
        }, this);
        _registerListener('loadNextContract', () => {
            let pageRef = this.pageRef;
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            if (contractsCmp) {
                let contractId = this.contractLoaderQueue.shift();
                if (contractId) {
                    _fireEvent(pageRef, 'registerContractId', { contractId: contractId });
                    _fireEvent(pageRef, 'reloadFilter', {});
                } else {
                    _fireEvent(pageRef, 'unlockLoadingLockedActions', {});
                }
            } else {
                setTimeout(() => {
                    _fireEvent(pageRef, 'loadNextContract', {});
                }, 200);
            }
        }, this);
        _registerListener('updateHasPe', () => {
            this.hasPE = true;
        }, this);
        _registerListener('updateHasPESigned', () => {
            this.hasPeSigned = true;
        }, this);
        _registerListener('lockedByApprovalProcess', ({ isActive }) => {
            this.lockedByApprovalProcess = isActive;
            this.lockedActions |= this.lockedByApprovalProcess;
        }, this);
        _registerListener('requireConso', () => {
            self.requireConso = true;
        }, this);
        _registerListener('synchroAdvancedContracts', () => {
            self.savePopUp = true;
            _fireEvent(self.pageRef, 'triggerLoading', { isLoading: true, fname: 'registerListener_synchroAdvancedContracts' });
            self.currentStatusMSG = Labels.LBL_Synchro;
            synchroAdvancedContracts({ contractIds: self.instance.contractIds }).then((batchId) => {
                if (batchId != null) {
                    let nIntervId = setInterval(() => {
                        checkBatchRunning({ jobId: batchId }).then(result => {
                            if (!result) {
                                // Batch finished – close the popup
                                self.savePopUp = false;
                                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'registerListener_synchroAdvancedContracts' });
                                clearInterval(nIntervId);
                            }
                        });
                    }, 2000);
                } else {
                    // Nothing to poll (not enqueued / already handled) – close gracefully
                    self.savePopUp = false;
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'registerListener_synchroAdvancedContracts' });
                    return;
                }
            }).catch((error) => {
                self.savePopUp = false;
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'registerListener_synchroAdvancedContracts' });
                console.error(error);
                self.dispatchEvent(new ShowToastEvent({
                    // title: Labels.LBL_Error,
                    message: error,
                    variant: ERROR_VARIANT,
                    mode: STICKY_VARIANT
                }));
            });
        }, this);
        _registerListener('consolidateContracts', () => {
            self.savePopUp = true;
            _fireEvent(self.pageRef, 'triggerLoading', { isLoading: true, fname: 'registerListener_consolidateContracts' });
            self.currentStatusMSG = Labels.LBL_Consolidate_Contracts;
            let hasTopNotSimulation = self.instance.hasTopNotSimulation;
            let instance = self.instance;
            let negoYear = self.instance.negoYear;
            let nsId = self.instance.negoscope.oInstance.Id;
            let supplierId = self.instance.supplier.oInstance.Id;
            consolidateContract({ supplierId: supplierId, nsId: nsId, negoYear: negoYear, isCreateNegoBaseExit: hasTopNotSimulation }).then(errorMsgs => {
                if (isAdvanced) {
                    _fireEvent(self.pageRef, 'synchroAdvancedContracts');
                    done = false;
                } else {
                    self.savePopUp = false;
                    self.instance.executiveSummaryPopUp.isOpen = false;
                    _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'registerListener_consolidateContracts' });
                }
                _fireEvent(self.pageRef, 'refreshAfterConso', {});
                let _errorMsgs = [];
                (errorMsgs && errorMsgs.length ? errorMsgs : []).forEach(it => _errorMsgs = [..._errorMsgs, ...it.split('\n')]);
                errorMsgs = _errorMsgs;
                if (errorMsgs && errorMsgs.length) {
                    errorMsgs = errorMsgs.filter((item, index) => item && item.trim() && index == errorMsgs.indexOf(item));
                    self.dispatchEvent(new ShowToastEvent({
                        // title: Labels.LBL_Error,
                        message: errorMsgs ? errorMsgs.join('\n') : '',
                        variant: ERROR_VARIANT,
                        mode: STICKY_VARIANT
                    }));
                }
                if (!errorMsgs || !errorMsgs.length) {
                    if (self.instance.executiveSummaryPopUp.url) {
                        let a = document.createElement('A');
                        a.href = self.instance.executiveSummaryPopUp.url;
                        a.target = '_blank';
                        a.click();
                        self.instance.executiveSummaryPopUp.url = undefined;
                    }
                    if (instance.selectedNegoScopeId) {
                        instance.negoscope._renewCurrentItem(instance).then(result => {
                            self.instance = result;
                            // _fireEvent(self.pageRef, 'registerAllContractIds', {});
                        });
                    } else {
                        instance.readyToDisplay = true;
                    }
                }
            }).catch(error => {
                _fireEvent(self.pageRef, 'triggerLoading', { isLoading: false, fname: 'registerListener_consolidateContracts' });
                _fireEvent(self.pageRef, 'refreshAfterConso', {});
                self.dispatchEvent(new ShowToastEvent({
                    // title: Labels.LBL_Error,
                    message: error,
                    variant: ERROR_VARIANT,
                    mode: STICKY_VARIANT
                }));
            });
        }, this);
        _registerListener('toggleRTLegend', (recordTypeDeveloperName) => {
            this.contractRecordTypes.forEach(item => {
                if (item.RT == recordTypeDeveloperName) {
                    item.show = true;
                }
            });
        }, this);
        if (this.instance.showIndexes) {
            this.instance.indexesClass = '';
        } else {
            this.instance.indexesClass = 'slds-hide';
        }
        _registerListener('triggerLoading', ({ isLoading, fname }) => {
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
        _registerListener('reloadFilter', () => {
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            if (contractsCmp && contractsCmp.toggleContract) {
                this.instance.contractsOptions.forEach(contractOption => {
                    contractsCmp.toggleContract(contractOption.value, contractOption.checked);
                });
            }
        }, this);
        _registerListener('handleNewOnTop', () => {
            this.instance.hasTop = true;
        }, this);
        _registerListener('reorderContracts', ({ contract }) => {
            contract.weight = this.instance.contractWeightMap[contract.RecordType.DeveloperName + '-' + new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()];
            contract.bdate = new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]);
            let contracts = this.instance.contracts;
            let contractsOptions = this.instance.contractsOptions;
            let currentConract = contracts.find(item => item.Id == contract.Id);
            if (currentConract) {
                currentConract.weight = this.instance.contractWeightMap[contract.RecordType.DeveloperName + '-' + new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()];
                currentConract.bdate = new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]);
                if (this.instance.prioritizeSortBDateNegotiate) {
                    contracts = contracts.sort((c1, c2) => {
                        if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                            if (c1.weight == c2.weight) {
                                if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                    return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                                } else {
                                    return c1.Id.localeCompare(c2.Id);
                                }
                            }
                            return c1.weight - c2.weight;
                        }
                        return c1.bdate.getTime() - c2.bdate.getTime();
                    });
                } else {
                    contracts = contracts.sort((c1, c2) => {
                        if (c1.weight == c2.weight) {
                            if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                            } else {
                                return c1.Id.localeCompare(c2.Id);
                            }
                        }
                        return c1.weight - c2.weight;
                    });
                }
                this.instance.contractsOptions = contracts.map(item => contractsOptions.find(_item => item.Id == item.value));
                this.instance.contractIds = contracts.map(item => item.Id);
                let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
                if (contractsCmp && contractsCmp.updateContractIds) {
                    contractsCmp.updateContractIds(JSON.stringify(this.instance.contractIds));
                }
            }
        }, this);
        _registerListener('handleNewContract', (contract) => {
            this.displayFirstMessage = false;
            // _fireEvent(this.pageRef, 'triggerLoading', { isLoading: true, fname: 'registerListener_handleNewContract' });
            contract.weight = this.instance.contractWeightMap[contract.RecordType.DeveloperName + '-' + new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]).getFullYear()];
            contract.bdate = new Date(contract[API_NAMES.Contract__c.Contract_BDate__c]);
            let contracts = this.instance.contracts;
            let insertIndex;
            // if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
            //     if (c1.weight == c2.weight) {
            //         if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
            //             return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
            //         } else {
            //             return c1.Id.localeCompare(c2.Id);
            //         }
            //     }
            //     return c1.weight - c2.weight;
            // }
            // return c1.bdate.getTime() - c2.bdate.getTime();
            if (this.instance.prioritizeSortBDateNegotiate) {
                insertIndex = [...contracts, contract].sort((c1, c2) => {
                    if (c1.bdate.getTime() - c2.bdate.getTime() == 0) {
                        if (c1.weight == c2.weight) {
                            if (!isNaN(c1[API_NAMES.Contract__c.SimulationNumber__c]) && !isNaN(c2[API_NAMES.Contract__c.SimulationNumber__c])) {
                                return +c1[API_NAMES.Contract__c.SimulationNumber__c] - + c2[API_NAMES.Contract__c.SimulationNumber__c];
                            } else {
                                return c1.Id.localeCompare(c2.Id);
                            }
                        }
                        return c1.weight - c2.weight;
                    }
                    return c1.bdate.getTime() - c2.bdate.getTime();
                }).indexOf(contract)
            } else {
                contracts.forEach((item, index) => {
                    if (!insertIndex && insertIndex != 0 && contract.weight < item.weight) {
                        insertIndex = index;
                    }
                });
            }
            if (!insertIndex || insertIndex == -1) {
                insertIndex = contracts.length;
            }
            let contractOption = {
                value: contract.Id,
                label: contract.Name,
                checked: true,
                disabled: false,
                get class() {
                    return 'slds-listbox__item slds-truncate ' + (contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] ? 'cell_On_Top' : ' cell_' + contract.RecordType.DeveloperName.replace(/_/g, '-').toLocaleLowerCase());
                },
            };
            contracts.splice(insertIndex, 0, contract);
            this.instance.contractsOptions.splice(insertIndex, 0, contractOption);
            this.instance.contractIds = contracts.map(item => item.Id);
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            if (contractsCmp && contractsCmp.updateContractIds) {
                contractsCmp.updateContractIds(JSON.stringify(this.instance.contractIds));
            }
            this.dispatchEvent(new ShowToastEvent({
                // title: Labels.LBL_Success,
                message: Labels.MSG_New_Contract_Added,
                variant: SUCCESS_VARIANT
            }));
            // _fireEvent(this.pageRef, 'triggerLoading', { isLoading: false, fname: 'registerListener_handleNewContract' });
        }, this);
        _registerListener('setRefNegoBaseFieldForNegoPlan', ({ ref_CA_index3, ref_valeurReelle_index4 }) => {
            this.instance.negoPlan.wrapper.ref_CA_index3 = ref_CA_index3;
            this.instance.negoPlan.wrapper.ref_valeurReelle_index4 = ref_valeurReelle_index4;
        }, this);
        _registerListener('setNegoBaseInitFieldForNegoPlan', ({ negoBaseInit_valeurReelle_index4, negoBaseInit_valeurReelle_index5 }) => {
            this.instance.negoPlan.wrapper.negoBaseInit_valeurReelle_index4 = negoBaseInit_valeurReelle_index4;
            this.instance.negoPlan.wrapper.negoBaseInit_valeurReelle_index5 = negoBaseInit_valeurReelle_index5;
        }, this);
        _registerListener('deletecontract', (event) => {
            let delContractId = new String(event.detail.contractId).valueOf();
            let instance = this.instance;
            let self = this;
            let contractsCmp = this.template.querySelector(`[data-id="negotiate-contracts-cmp"]`);
            deleteContract({ contractId: delContractId }).then(result => {
                let results = JSON.parse(result);
                if (results.isSuccess) {
                    instance.contractIds = instance.contractIds.filter(contractId => contractId != delContractId);
                    instance.contracts = instance.contracts.filter(item => item.Id != delContractId);
                    self.dispatchEvent(new ShowToastEvent({
                        // title: Labels.LBL_Success,
                        message: Labels.MSG_Successfully_Deleted,
                        variant: SUCCESS_VARIANT
                    }));
                    if (contractsCmp && contractsCmp.updateContractIds) {
                        contractsCmp.updateContractIds(JSON.stringify(instance.contractIds));
                    }
                } else {
                    if (results && results.errors) {
                        let errorMesages = results.errors.filter((item, index) => index == results.errors.indexOf(item));
                        self.dispatchEvent(new ShowToastEvent({
                            // title: Labels.LBL_Error,
                            message: errorMesages.join('\n'),
                            variant: ERROR_VARIANT,
                            mode: STICKY_VARIANT
                        }));
                    }
                }
            });
        }, this);
        this.instance.template = this.template;
        this.instance.self = this;
        Promise.all([
            loadStyle(this, negotiateSRURL + '/contractColouring.css'),
            loadStyle(this, negotiateSRURL + '/customStyle.css'),
        ]);
        getObjectLabels().then(result => {
            let data = JSON.parse(result);
            let translation = data.labelsMap;
            let contractRTLabelsMap = data.contractRTLabelsMap;
            let contractRecordTypes = [];
            for (let obj of Object.keys(translation)) {
                self.Label[obj] = translation[obj];
            }
            self.translation = translation;
            contractRecordTypes.push({ label: self.Label[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Is_OnTop_Simulation__c], class: 'slds-grid slds-size_1-of-2 legend_On_Top', show: true });
            for (let contractRTDeveloperName in contractRTLabelsMap) {
                contractRecordTypes.push({ label: contractRTLabelsMap[contractRTDeveloperName], class: 'slds-grid slds-size_1-of-2 legend_' + contractRTDeveloperName.replace(/_/g, '-').toLocaleLowerCase(), show: false, RT: contractRTDeveloperName });
            }
            this.contractRecordTypes = contractRecordTypes.sort((item1, item2) => item1.label.localeCompare(item2.label));
            self.Label.LBL_Is_OnTop_Simulation = self.Label[API_NAMES.Contract__c.objectApiName][API_NAMES.Contract__c.Is_OnTop_Simulation__c];
            self.ready_connectedCallback = true;
            if (self.ready_setCurrentPageReference && self.ready_connectedCallback) {
                if (self.instance.selectedNegoScopeId) {
                    self.instance.negoscope._setCurrentItem(self.instance).then(result => {
                        self.instance = result;
                        _fireEvent(self.pageRef, 'registerAllContractIds', {});
                    });
                } else {
                    self.instance.readyToDisplay = true;
                }
            }
        });
        // if (this.negoyear && this.negoId && this.contractId) {
        //     if (this.instance.selectedNegoScopeId) {
        //         this.instance.negoscope._setCurrentItem(this.instance).then(result => {
        //             self.instance = result;
        //             _fireEvent(self.pageRef, 'registerAllContractIds', {});
        //         });
        //     }
        // }
    }
    blockSubmit(event) {
        if (event.keyCode == 13) {
            event.preventDefault();
            return false;
        }
    }
    setHeaderStyle = false;
    headerClass = 'header slds-page-header sticky-header';
    renderedCallback() {
        _fireEvent(this.pageRef, 'refresh_walkthrought_position', {});
        if (!this.setHeaderStyle) {
            let sticky_header = this.template.querySelector('.sticky-header');
            if (sticky_header) {
                const boundingClientRect = sticky_header.getBoundingClientRect();
                if (boundingClientRect.top > 125) {
                    this.headerClass = 'slds-page-header sticky-header sticky-header-with-bar';
                } else {
                    this.headerClass = 'slds-page-header sticky-header sticky-header-without-bar';
                }
                this.setHeaderStyle = true;
            }
        }
        window.addEventListener('scroll', (event) => {
            let headerDetail = this.template.querySelector('.headerDetail');
            let stickyHeader = this.template.querySelector('.sticky-header');
            if (headerDetail) {
                if (window.scrollY < 30) {
                    headerDetail.classList.remove('slds-hide');
                }
                if (window.scrollY >= 110) {
                    headerDetail.classList.add('slds-hide');
                }
            }
            if (stickyHeader) {
                if (window.scrollY > 30) {
                    stickyHeader.classList.add('docked-header');
                } else {
                    stickyHeader.classList.remove('docked-header');
                }
            }
        });
        window.addEventListener('scroll', (event) => {
            _fireEvent(this.pageRef, 'ref_contract_clone_icon', {});
        });
        window.addEventListener('resize', (event) => {
            _fireEvent(this.pageRef, 'ref_contract_clone_icon', {});
        });
        this.setHeaderHeight();
    }
    @track displayFirstMessage = false;
    closeDisplayFirstMessage(event) {
        this.displayFirstMessage = false;
    }

    setHeaderHeight = () => {
        let pageHeader = this.template.querySelector('.slds-page-header');
        if (pageHeader) {
            this.headerHeight = pageHeader.getBoundingClientRect().height;
        }
    };
}