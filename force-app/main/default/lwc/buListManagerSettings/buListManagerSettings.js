import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//APEX
import getData from "@salesforce/apex/BUListManagerSettingsCtrl.getData";
import saveSettings from "@salesforce/apex/BUListManagerSettingsCtrl.saveSettings";
import checkDeploymentStatus from "@salesforce/apex/BUListManagerSettingsCtrl.checkDeploymentStatus";
//LABELS
import LBL_BUListManagerSettings from "@salesforce/label/c.LBL_BUListManagerSettings";
import LBL_Default_Grid_Settings_Template from "@salesforce/label/c.LBL_Default_Grid_Settings_Template";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import MSG_Request_Timed_Out from "@salesforce/label/c.MSG_Request_Timed_Out";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";

const MAX_STATUS_CHECKS = 10;
const STATUS_CHECK_INTERVAL = 5000;

export default class BuListManagerSettings extends LightningElement {
    //BOOLEANS
    isLoading = false;
    //STRINGS
    childrenBUDefaultGridSettingsTemplate = '';
    savedTemplate = '';
    //LISTS
    @track gridSettingsOptions = [];
    //OBJECTS
    labels = {
        LBL_BUListManagerSettings,
        LBL_Default_Grid_Settings_Template,
        LBL_Save,
        LBL_Success,
        LBL_Error,
        LBL_Info,
        LBL_Warning,
        MSG_Successfully_Saved,
        MSG_No_Changes_To_Save,
        MSG_Request_Timed_Out,
        MSG_Deploy_Last_Status,
        MSG_Deploy_Ended_With_Status,
    };

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.isLoading = true;
        getData().then(result => {
            const data = JSON.parse(result);
            this.gridSettingsOptions = (data.gridSettingsOptions || []).map(option => ({
                label: option.label,
                value: option.value,
            }));
            this.childrenBUDefaultGridSettingsTemplate = data.buListManagerConfiguration?.childrenBUDefaultGridSettingsTemplate || '';
            this.savedTemplate = this.childrenBUDefaultGridSettingsTemplate;
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message, 'error');
        }).finally(() => {
            this.isLoading = false;
        });
    }

    handleChange(event) {
        this.childrenBUDefaultGridSettingsTemplate = event.detail.value;
    }

    handleSave() {
        if (this.childrenBUDefaultGridSettingsTemplate === this.savedTemplate) {
            this.showNotification(this.labels.LBL_Warning, this.labels.MSG_No_Changes_To_Save, 'warning');
            return;
        }
        this.isLoading = true;
        const buListManagerConfiguration = {
            childrenBUDefaultGridSettingsTemplate: this.childrenBUDefaultGridSettingsTemplate
        };
        saveSettings({ buListManagerConfigurationJSON: JSON.stringify(buListManagerConfiguration) }).then(result => {
            this.checkDeployementStatus(result);
        }).catch(error => {
            this.isLoading = false;
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message, 'error');
        });
    }

    checkDeployementStatus(idDeployment) {
        let counter = 0;
        const check = () => {
            checkDeploymentStatus({ idDeployment }).then(result => {
                const deployResult = JSON.parse(result).deployResult;
                if (deployResult.done) {
                    if (deployResult.success) {
                        this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                        this.loadData();
                    } else {
                        this.isLoading = false;
                        this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + deployResult.status, 'info');
                    }
                } else if (counter++ >= MAX_STATUS_CHECKS) {
                    this.isLoading = false;
                    this.showNotification(this.labels.LBL_Error, this.labels.MSG_Request_Timed_Out + ' ' + this.labels.MSG_Deploy_Last_Status + ' ' + deployResult.status, 'error');
                } else {
                    // eslint-disable-next-line @lwc/lwc/no-async-operation
                    setTimeout(check, STATUS_CHECK_INTERVAL);
                }
            }).catch(error => {
                this.isLoading = false;
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message, 'error');
            });
        };
        check();
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}