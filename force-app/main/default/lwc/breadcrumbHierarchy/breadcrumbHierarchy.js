import { LightningElement, api, track } from 'lwc';
import loadData from '@salesforce/apex/BreadcrumbHierarchyController.loadData';

export default class Breadcrumb extends LightningElement {
    @api recordId;
    @track hierarchyList = [];
    error;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        loadData({ hierarchyId: this.recordId })
        .then(result => {
            if (!result || result.length === 0) {
                this.hierarchyList = [];
                this.currentStageName = '';
                return;
            }
            this.hierarchyList = result.map((item) => {
                const isCurrent = item.Id === this.recordId;
                let sldsClass = 'slds-path__item';
                if (isCurrent) {
                    sldsClass += ' slds-is-current slds-is-active';
                } else {
                    sldsClass += ' slds-is-incomplete';
                }
                return {...item, isCurrent, tabIndex: isCurrent ? '0' : '-1', sldsClass};
            });
            this.error = undefined;
        })
        .catch(error => {
            this.error = error.body ? error.body.message : error.message;
            this.hierarchyList = [];
        });
    }

    openHierarchy(event) {
        const selectedId = event.currentTarget.dataset.id;
        window.open('/' + selectedId, '_blank')
    }
}