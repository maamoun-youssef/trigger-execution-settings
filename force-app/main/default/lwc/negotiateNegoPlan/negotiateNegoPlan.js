import { LightningElement, api, track, wire } from 'lwc';
import getNegoPlan from "@salesforce/apex/NegotiateCmpController.getNegoPlan";
import saveNegoPlan from "@salesforce/apex/NegotiateCmpController.saveNegoPlan";
import getObjectLabels from "@salesforce/apex/NegotiateCmpController.getObjectLabels";
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
export default class NegotiateNegoPlan extends LightningElement {
    @api nonce;
    API_NAMES = API_NAMES;
    @track lockedByApprovalProcess = false;
    @api lockedActions;
    @track loadingLockedActions = true;
    @api contractRTN1Settings;
    @wire(CurrentPageReference) pageRef;
    @api negoYear;
    @api negoscopeId;
    @api readyEvent;
    @track Label = Labels;
    @track negoPlan;
    @track changedNegoPlan = {};
    @track readyToDisplay = false;
    section1Fields = [
        { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_MOM_RDV1__c },
        { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_MOM_RDV2__c },
        { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_MOM_RDV3__c },
        { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_Keynote_Marketing_Plan__c },
    ];
    section2Fields = {
        dates: [],
        NegoIntro_2_3Net_Prog: [],
        NegoIntro_2_3_4Net_Prog: [],
        NegoIntro_4Net_Prog: [],
        NegoIntro_4Net_Prog_val: [],
        NegoIntro_5Net_Prog_val: [],
    };
    @api get hasChangesToSave() {
        let negoPlan = this.changedNegoPlan;
        Object.keys(negoPlan).forEach(key => {
            if (negoPlan[key] == '') {
                negoPlan[key] = null;
            }
        });
        return Object.keys(negoPlan).some(key => key != 'Id');
    }
    @api save() {
        return new Promise((resolve, reject) => {
            // let negoPlan = this.negoPlan;
            let negoPlan = this.changedNegoPlan;
            Object.keys(negoPlan).forEach(key => {
                if (negoPlan[key] == '') {
                    negoPlan[key] = null;
                }
            });
            if (Object.keys(negoPlan).some(key => key != 'Id')) {
                saveNegoPlan({ negoPlan_JSON: JSON.stringify(negoPlan) }).then(result => {
                    resolve(result);
                });
            } else {
                resolve(JSON.stringify({ isEmpty: true, isSuccess: true, errors: [] }));
            }
        });
    }
    handleInputChangeSection1(event) {
        let value = event.detail.value;
        let index = event.target.dataset.index;
        let cell = this.section1Fields[index];
        cell.value = value;
        this.negoPlan[cell.fieldApiName] = value;
        this.changedNegoPlan[cell.fieldApiName] = value;
    }
    handleInputChangeSection2(event) {
        let value = event.detail.value;
        let rowIndex = event.target.dataset.rowIndex;
        let colIndex = event.target.dataset.colIndex;
        let cell = this.section2Fields[rowIndex][colIndex];
        cell.value = value;
        this.negoPlan[cell.fieldApiName] = value;
        this.changedNegoPlan[cell.fieldApiName] = value;
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
        _registerListener('lockedByApprovalProcess', ({ isActive }) => {
            this.lockedByApprovalProcess = isActive;
            this.lockedActions |= this.lockedByApprovalProcess;
        }, this);
        let self = this;
        let negoYear = this.negoYear;
        let negoscopeId = this.negoscopeId;
        getObjectLabels().then(result => {
            let translationMap = JSON.parse(result).labelsMap;
            self.section2Fields = [
                [
                    { isVal: false, label: Labels.LBL_Date },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_Posted_Date_v0__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_Posted_Date_v1__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_Posted_Date_v2__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_Posted_Date_v3__c, isVal: true },
                ],
                [
                    { isVal: false, label: translationMap[API_NAMES.Nego_Plan__c.objectApiName][API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3Net_Prog_v0__c] },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3Net_Prog_v0__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3Net_Prog_v1__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3Net_Prog_v2__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3Net_Prog_v3__c, isVal: true },
                ],
                [
                    { isVal: false, label: translationMap[API_NAMES.Nego_Plan__c.objectApiName][API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3_4Net_Prog_v0__c] },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3_4Net_Prog_v0__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3_4Net_Prog_v1__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3_4Net_Prog_v2__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_2_3_4Net_Prog_v3__c, isVal: true },
                ],
                [
                    { isVal: false, label: translationMap[API_NAMES.Nego_Plan__c.objectApiName][API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_v0__c] },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_v0__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_v1__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_v2__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_v3__c, isVal: true },
                ],
                [
                    { isVal: false, label: translationMap[API_NAMES.Nego_Plan__c.objectApiName][API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_val_v0__c] },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_val_v0__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_val_v1__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_val_v2__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_4Net_Prog_val_v3__c, isVal: true },
                ],
                [
                    { isVal: false, label: translationMap[API_NAMES.Nego_Plan__c.objectApiName][API_NAMES.Nego_Plan__c.NEGO_NegoIntro_5Net_Prog_val_v0__c] },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_5Net_Prog_val_v0__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_5Net_Prog_val_v1__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_5Net_Prog_val_v2__c, isVal: true },
                    { fieldApiName: API_NAMES.Nego_Plan__c.NEGO_NegoIntro_5Net_Prog_val_v3__c, isVal: true },
                ]
            ];
            getNegoPlan({ negoYear: negoYear, negoScopeId: negoscopeId }).then(result => {
                let negoPlanWrapper = JSON.parse(result);
                let negoPlan = negoPlanWrapper.negoPlan;
                self.negoPlan = negoPlan;
                self.changedNegoPlan.Id = negoPlan.Id;
                self.section1Fields.forEach(cell => {
                    cell.value = negoPlan[cell.fieldApiName];
                });
                self.section2Fields.forEach(row => {
                    row.forEach(cell => {
                        if (cell.isVal) {
                            cell.value = negoPlan[cell.fieldApiName];
                        }
                    })
                });
                const readyEvent = new CustomEvent(self.readyEvent, {
                    detail: { value: negoPlanWrapper },
                });
                if (self.dispatchEvent) {
                    self.dispatchEvent(readyEvent);
                } else {
                    console.error('event not available .... ');
                }
                self.readyToDisplay = true;
            });
        });
    }
}