import { LightningElement } from 'lwc';
import Toast from 'lightning/toast';
/* LABELS */
import MSG_Information from "@salesforce/label/c.MSG_Information";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import MSG_Request_Timed_Out from "@salesforce/label/c.MSG_Request_Timed_Out";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Success from "@salesforce/label/c.MSG_Success";

/* SERVICES */
import checkDeployementStatus from "@salesforce/apex/NegoptimHelper.checkDeploymentStatus";
import checkCompletedBatch from "@salesforce/apex/NegoptimHelper.checkCompletedBatches";
import getSessionIdApex from "@salesforce/apex/NegoptimHelper.getSessionId";

/* CONSTANT */
const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';

export default class AppHelper extends LightningElement { }

/* Utility Methods */
/**
 * @description This Method to alert the user
 * @param {String} title message title
 * @param {String} message the message content
 * @param {String} variant the message type (success, warning, ..)
 */
const showNotification = (component, title, message, variant, mode) => {
    let msg = message?.body?.message || message?.message || message;
    Toast.show({
        label: title,
        message: msg,
        variant: variant,
        mode: mode
    }, component);
}

const checkDeploymentStatus = (component, idDeployment, loading) => {
    let counter = 0;
    let status, done;
    checkDeployementStatus({
        'idDeployment': idDeployment,
    }).then(result => {
        done = JSON.parse(result).deployResult.done;
        status = JSON.parse(result).deployResult.status;
        if (!done) {
            let interval = setInterval(() => {
                if (counter > 10) {
                    loading = false;
                    clearInterval(interval);
                    let message = MSG_Request_Timed_Out + ' ' + MSG_Deploy_Last_Status + ' ' + status;
                    showNotification(component, MSG_Information, message, INFO_VARIANT, STICKY_VARIANT);
                }
                checkDeployementStatus({
                    'idDeployment': idDeployment,
                }).then(result => {
                    done = JSON.parse(result).deployResult.done;
                    let success = JSON.parse(result).deployResult.success;
                    status = JSON.parse(result).deployResult.status;
                    if (done) {
                        loading = false;
                        clearInterval(interval);
                        if (success) {
                            showNotification(component, LBL_Save, MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
                        } else {
                            showNotification(component, MSG_Information, MSG_Deploy_Ended_With_Status + ' ' + status, INFO_VARIANT, STICKY_VARIANT);
                        }
                        return success;
                    }
                });
                counter++;
            }, 5000);
        } else {
            loading = false;
            showNotification(component, LBL_Save, MSG_Save_Complete, SUCCESS_VARIANT, STICKY_VARIANT);
            return false;
        }
    });
    return false;
}

const checkCompletedBatches = (component, batchId) => {
    return new Promise((resolve, reject) => {
        let nIntervId = setInterval(() => {
            checkCompletedBatch({ batchJobId: batchId }).then(result => {
                if (result) {
                    showNotification(component, LBL_Success, MSG_Success, SUCCESS_VARIANT, STICKY_VARIANT);
                    clearInterval(nIntervId);
                    resolve(result);
                }
            }).catch(error => {
                clearInterval(nIntervId);
                reject(error); // optional but recommended
            });
        }, 2000);
    });
}

const getSessionId = () => {
    return getSessionIdApex();
}

export { showNotification, checkDeploymentStatus, checkCompletedBatches, getSessionId };