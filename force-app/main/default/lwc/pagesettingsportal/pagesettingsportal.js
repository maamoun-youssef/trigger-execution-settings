import { LightningElement, api, wire } from 'lwc';
import getPageSettingByName from '@salesforce/apex/ConnectSettingsCtrl.getPageSettingByName';


export default class Pagesettingsportal extends LightningElement {

    @api selectedName;
    setting;

    @wire(getPageSettingByName, { name: '$selectedName' })
    wiredSetting({ error, data }) {
        if (data) {
            this.setting = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.setting = undefined;
        }
    }

}