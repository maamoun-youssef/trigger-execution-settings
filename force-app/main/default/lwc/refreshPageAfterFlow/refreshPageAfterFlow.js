/**
 * ULIT DEV
 * This component is used in community flows in order to refresh the current page they've been launched from
 *
 */

import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class RefreshPageAfterFlow extends NavigationMixin(LightningElement) {
    @api recordId;
    @api url;
    connectedCallback() {
        if (this.recordId) {
            let recordId = this.recordId;
            //window.open('/' + recordId, '_self');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view',
                },
                replace: true  // Force page replacement to refresh the data
            });
        } else if (this.url) {
            const url = (this.url || '').trim();
            window.open(url, '_self');
        } else {
            location.reload();
        }
    }
}