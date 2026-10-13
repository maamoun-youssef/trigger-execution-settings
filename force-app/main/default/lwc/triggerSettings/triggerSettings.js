import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getApexTriggerMap from '@salesforce/apex/TriggerSettingsCmpController.getApexTriggerMap';
import getTriggerSettings from '@salesforce/apex/TriggerSettingsCmpController.getTriggerSettings';
import getTriggersSettingsFields from '@salesforce/apex/TriggerSettingsCmpController.getTriggersSettingsFields';
import saveData from '@salesforce/apex/TriggerSettingsCmpController.saveData';

import LBL_Trigger_Settings from '@salesforce/label/c.LBL_Trigger_Settings';
import MSG_Success from '@salesforce/label/c.MSG_Success';
import MSG_Successfully_Saved from '@salesforce/label/c.MSG_Successfully_Saved';
import MSG_Error_Occurred from '@salesforce/label/c.MSG_Error_Occurred';

const SEARCH_DELAY = 300;

export default class TriggerSettings extends LightningElement {
    @track triggerSettingsList = [];//List of Trigger Settings to save
    @track triggerSettingsListall = [];//List of Search Trigger Settings to save
    @track triggerNameId = [];//map of ApexTrigger Name with Id
    //Data table variable:
    @track columns;
    @track triggerLabel;
    @track isDisabledLabel;
    @track sortBy = 'TriggerName';
    @track sortDirection = 'asc';
    @track searchTerm = "";
    @track draftValues = [];
    @track draftValuesMap = [];

    isLoading = false;

    @track Labels = {
        LBL_Trigger_Settings,
        MSG_Success,
        MSG_Successfully_Saved,
        MSG_Error_Occurred,
    }
    connectedCallback() {
        let self = this;
        getTriggersSettingsFields().then(triggerSettingsLabel => {
            let res = JSON.parse(JSON.stringify(triggerSettingsLabel));
            self.triggerLabel = res[0];
            self.isDisabledLabel = res[1];
            self.columns = [
                {
                    label: self.triggerLabel, fieldName: 'TriggerName', type: "text", sortable: "true", cellAttributes:
                        { iconName: { fieldName: 'iconName' }, iconPosition: 'left' }
                },
                { label: self.isDisabledLabel, fieldName: 'isDisabled', type: "boolean", sortable: "false", editable: "true", },
            ];
            self.fillData();
        }).catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body.message,
                variant: 'error'
            }));
        });
    }

    handleSearchChange(event) {
        var self = this;
        this.searchTerm = event.target.value;
        this.delayTimeout = setTimeout(() => {
            self.search();
        }, SEARCH_DELAY);
    }

    search() {
        if (this.searchTerm == "" || this.searchTerm == null) {
            this.triggerSettingsList = this.triggerSettingsListall.map(item => item);
        } else {
            this.triggerSettingsList = this.triggerSettingsListall.filter(item => item.TriggerName.toLowerCase().includes(this.searchTerm.toLowerCase()));
        }
        this.sortData();
    }

    fillData() {
        let self = this;
        this.triggerNameId = [];
        //get the map of apex trigger name with Id:
        getApexTriggerMap().then(triggersResult => {
            self.triggerNameId = Object.keys(triggersResult).map(k => {
                return { triggerName: k, triggerId: triggersResult[k] };
            });
            // for (let k in triggersResult) {
            //     self.triggerNameId.push({ triggerName: k, triggerId: triggersResult[k] });
            // }
            //map the name of the trigger with settings value:
            getTriggerSettings().then(triggerSettingsRes => {
                let triggerSettings = triggerSettingsRes;
                let triggerSettingsList = [];
                let i = 0;
                self.triggerNameId.forEach(item => {
                    let found = triggerSettings.find(element => element.TriggerName === item.triggerName);
                    if (found) {
                        triggerSettingsList.push({ id: found.id, Name: item.triggerId, TriggerName: item.triggerName, isDisabled: found.isDisabled, get iconName() { return this.isDisabled ? 'utility:ban' : ''; } });
                    } else {
                        //id = null0,null1,... selection in the data table the id must be unique because id used as key-field
                        triggerSettingsList.push({ id: 'null' + (i++), Name: item.triggerId, TriggerName: item.triggerName, isDisabled: false, get iconName() { return this.isDisabled ? 'utility:ban' : ''; } });
                    }
                });
                self.triggerSettingsList = triggerSettingsList.map(item => item);
                self.triggerSettingsListall = triggerSettingsList.map(item => item);
                self.draftValues = [];
                self.isLoading = false;
                self.search();
            }).catch(error => {
                self.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
        }).catch(error => {
            self.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body.message,
                variant: 'error'
            }));
        });
    }

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData();
    }

    sortData() {
        let fieldname = this.sortBy;
        let direction = this.sortDirection;
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.triggerSettingsList));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction
        let isReverse = direction === '' || direction == 'asc' ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
            // return isReverse * x.localeCompare(y);
        });

        // set the sorted data to data table data
        this.triggerSettingsList = parseData;
    }
    refreshTable() {
        this.isLoading = true;
        this.fillData();
    }
    handleSave(event) {
        this.isLoading = true;
        let self = this;
        let triggerSettingsToSave = [];
        self.draftValuesMap = event.detail.draftValues;
        //merge the draft values with triggerSettingsList to send the list to save with all parameters:
        self.draftValuesMap.forEach(item => {
            self.triggerSettingsList.forEach(item2 => {
                if (item2.id === item.id) {
                    triggerSettingsToSave.push({ id: item2.id, Name: item2.Name, TriggerName: item2.TriggerName, isDisabled: item.isDisabled });
                }
            });
        });

        //set all id contains null String to null, because in apex must pass a true id and not malformed id:
        triggerSettingsToSave.map(item => {
            if (item.id.includes('null')) {
                item.id = null;
            }
        });

        //pass the list to save with the Map of trigger name and Id:
        saveData({ triggerSettingsJson: JSON.stringify(triggerSettingsToSave), triggerNameIdMap: JSON.stringify(this.triggerNameId) }).then(exceptionResult => {
            console.log(exceptionResult);
            if (!exceptionResult) {
                self.dispatchEvent(new ShowToastEvent({
                    title: self.Labels.MSG_Success,
                    message: self.Labels.MSG_Successfully_Saved,
                    variant: 'success'
                }));
                setTimeout(() => {
                    self.fillData();
                }, 3000);
                // setTimeout(() => {
                //     self.draftValues = [];
                // }, 1000);
            }
        }).catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: self.Labels.MSG_Error_Occurred,
                message: error.body.message,
                variant: 'error'
            }));
        }).finally(() => {
            this.isLoading = false;
        });
    }

    reset() {
        this.draftValues = [];
    }
}