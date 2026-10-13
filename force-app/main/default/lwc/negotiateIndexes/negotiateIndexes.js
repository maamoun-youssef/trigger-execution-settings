import { LightningElement, api, track, wire } from 'lwc';

import getContracts from '@salesforce/apex/NegotiateIndexesCmpController.getContracts';

import { Labels, API_NAMES } from "c/contractServices";
import { CurrentPageReference } from 'lightning/navigation';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubSub';

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
export default class NegotiateIndexes extends LightningElement {
    @api nonce;
    @api isProgHidden = false;
    @api postSigned = false;
    API_NAMES = API_NAMES;
    @track lockedByApprovalProcess = false;
    @api lockedActions;
    @track loadingLockedActions = true;
    @api contractRTN1Settings;
    @wire(CurrentPageReference) pageRef;
    Labels = Labels;
    @api negoYear;
    @api negoscopeId;
    @api contractId;
    @api readyEvent;
    @api isOnTopSimulation;
    @api isSafeBalance;
    @api isRefNegoBase;
    @api isNegoBaseInitNegoYear;
    @track wIndex = { values: [] };
    @track negoDiscountTypes = [];
    /**
     * PubSub Reterieved attributes
     */
    refNegoBaseContract;
    get headerClass() {
        if (this.isSafeBalance) {
            return 'conditionTable_SafeBalance';
        }
        if (this.isOnTopSimulation) {
            return 'conditionTable_On_Top';
        }
    }
    disconnectedCallback() {
        // unsubscribe from inputChangeEvent event
        unregisterAllListeners(this);
    }
    connectedCallback() {
        this.isProgHidden = this.isProgHidden == true || this.isProgHidden == 'true';
        globalMethods._fireEvent = (pageref, eventName, details) => {
            fireEvent(pageref, eventName + '_' + this.nonce, details);
        }
        globalMethods._registerListener = (eventName, callback, cmpInstance) => {
            registerListener(eventName + '_' + this.nonce, callback, cmpInstance);
        }
        _registerListener('unlockLoadingLockedActions', () => {
            this.loadingLockedActions = false;
        }, this);
        _registerListener('lockedByApprovalProcess', ({ isActive }) => {
            this.lockedByApprovalProcess = isActive;
            this.lockedActions |= this.lockedByApprovalProcess;
        }, this);
        /**
         * Registre listener to fetch negoBase Contract From negotiateContracts
         */
        if (!this.isRefNegoBase) {
            _registerListener('NegoBaseCalculatedReference', (refWIndex) => {
                this.refWIndex = refWIndex;
                this.__handleGapCalculations();
            }, this);
        }
        this.wIndex = { values: [] };
        this._getContracts();
    }
    @api recalculate() {
        this._getContracts();
    }
    _getContracts() {
        // get contract
        getContracts({ nsId: this.negoscopeId, negoYear: this.negoYear, contractId: this.contractId, postSigned: this.postSigned }).then(result => {
            let [wIndex] = JSON.parse(result);
            this.wIndex = wIndex;
            wIndex.values.forEach(item => {
                item.displayV2 = wIndex.isCalculatedIndexV2 && item.Index != item.IndexV2;
            });
            if (this.isNegoBaseInitNegoYear) {
                try {
                    let negoBaseInit_valeurReelle_index4 = wIndex.values.find(item => item.indexName == 'Index4').Computed;
                    let negoBaseInit_valeurReelle_index5 = wIndex.values.find(item => item.indexName == 'Index5').Computed;
                    _fireEvent(this.pageRef, 'setNegoBaseInitFieldForNegoPlan', { negoBaseInit_valeurReelle_index4, negoBaseInit_valeurReelle_index5 });
                } catch (error) {
                    console.error(error);
                }
            }
            if (this.isRefNegoBase) {
                /**
                 * FireEvent to publish negoBaseInit contract in the negoBaseIniContract feed to be received by NegotiateIndex
                 */
                _fireEvent(this.pageRef, 'NegoBaseCalculatedReference', wIndex);
                let refNegoBaseIndex1 = wIndex.values.find(item => item.indexName == 'Index1').Index;
                if (refNegoBaseIndex1) {
                    _fireEvent(this.pageRef, 'setRefNegoBaseIndex1', refNegoBaseIndex1);
                }
                try {
                    let ref_CA_index3 = wIndex.values.find(item => item.indexName == 'Index3').To;
                    let ref_valeurReelle_index4 = wIndex.values.find(item => item.indexName == 'Index4').Computed;
                    _fireEvent(this.pageRef, 'setRefNegoBaseFieldForNegoPlan', { ref_CA_index3, ref_valeurReelle_index4 });
                } catch (error) {
                    console.error(error);
                }
            }
            if (this.isSafeBalance) {
                let safeBalanceIndex1 = wIndex.values.find(item => item.indexName == 'Index1').Index;
                if (safeBalanceIndex1) {
                    _fireEvent(this.pageRef, 'setSafeBalanceIndex1', safeBalanceIndex1);
                }
            }
            _fireEvent(this.pageRef, 'calculate_index_done_' + this.contractId, wIndex);
            this.__handleGapCalculations();
        });
    }
    @api setCalculation(calculation_JSON) {
        this._setCalculation(calculation_JSON);
    }
    _setCalculation(calculation_JSON) {
        let wIndex = JSON.parse(calculation_JSON);
        this.wIndex = wIndex;
        wIndex.values.forEach(item => {
            item.displayV2 = wIndex.isCalculatedIndexV2 && item.Index != item.IndexV2;
        });
        if (this.isNegoBaseInitNegoYear) {
            try {
                let negoBaseInit_valeurReelle_index4 = wIndex?.values?.find(item => item.indexName == 'Index4')?.Computed;
                let negoBaseInit_valeurReelle_index5 = wIndex?.values?.find(item => item.indexName == 'Index5')?.Computed;
                _fireEvent(this.pageRef, 'setNegoBaseInitFieldForNegoPlan', { negoBaseInit_valeurReelle_index4, negoBaseInit_valeurReelle_index5 });
            } catch (error) {
                console.error(error);
            }
        }
        if (this.isRefNegoBase) {
            /**
             * FireEvent to publish negoBaseInit contract in the negoBaseIniContract feed to be received by NegotiateIndex
             */
            _fireEvent(this.pageRef, 'NegoBaseCalculatedReference', wIndex);
            let refNegoBaseIndex1 = wIndex?.values?.find(item => item.indexName == 'Index1')?.Index;
            if (refNegoBaseIndex1) {
                _fireEvent(this.pageRef, 'setRefNegoBaseIndex1', refNegoBaseIndex1);
            }
            try {
                let ref_CA_index3 = wIndex?.values?.find(item => item.indexName == 'Index3')?.To;
                let ref_valeurReelle_index4 = wIndex?.values?.find(item => item.indexName == 'Index4')?.Computed;
                _fireEvent(this.pageRef, 'setRefNegoBaseFieldForNegoPlan', { ref_CA_index3, ref_valeurReelle_index4 });
            } catch (error) {
                console.error(error);
            }
        }
        if (this.isSafeBalance) {
            let safeBalanceIndex1 = wIndex?.values?.find(item => item.indexName == 'Index1')?.Index;
            if (safeBalanceIndex1) {
                _fireEvent(this.pageRef, 'setSafeBalanceIndex1', safeBalanceIndex1);
            }
        }
        this.__handleGapCalculations();
    }
    __handleGapCalculations() {
        let wIndex = this.wIndex;
        let refWIndex = this.refWIndex;
        if (wIndex && refWIndex) {
            for (let index in wIndex.values) {
                try {
                    if (wIndex?.values[index]?.hasOwnProperty('Gap')) {
                        delete wIndex.values[index].Gap;
                    }
                } catch (error) {
                    // console.log('error >>> ?', error?.body?.message || error?.message || error);
                }
                try {
                    Object.defineProperty(wIndex?.values[index], 'Gap', {
                        get: function () {
                            let ref = refWIndex?.values?.length > index ? refWIndex?.values[index]?.Index : 0;
                            let cur = wIndex?.values[index]?.Index;
                            return ref ? +((cur - ref) / (ref) * 100).toFixed(2) : 0;
                        }
                    });
                } catch (error) {
                    // console.log('error >>> ?', error?.body?.message || error?.message || error);
                }
                try {
                    Object.defineProperty(wIndex?.values[index], 'GapV2', {
                        get: function () {
                            let ref = refWIndex?.values?.length > index ? refWIndex?.values[index]?.Index : 0;
                            let cur = wIndex?.values[index]?.IndexV2;
                            return ref ? +((cur - ref) / (ref) * 100).toFixed(2) : 0;
                        }
                    });
                } catch (error) {
                    // console.log('error >>> ?', error?.body?.message || error?.message || error);
                }
            }
        }
    }
}