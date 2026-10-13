import { LightningElement, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import USER_OBJECT from '@salesforce/schema/User';
import USER_ID from '@salesforce/user/Id';

export default class UsersProfeil extends LightningElement {
    API_NAMES = {
        User: {
            ...USER_OBJECT,
            fields: [],
        }
    }
    userId = USER_ID;

    @track loading = true;

    // Get Object Info
    @wire(getObjectInfo, { objectApiName: USER_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.userLabels = {};
            this.API_NAMES.User.fields = Object.values(data.fields);
            console.log('this.API_NAMES.User.fields >>', this.API_NAMES.User.fields);
            this.loading = false;
        } else if (error) {
            console.error('Error loading User object info:', error);
        }
    }

}