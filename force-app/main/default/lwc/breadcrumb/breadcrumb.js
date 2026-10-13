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
        loadData({ hierarchyId: this.recordId }).then(result => {
            this.hierarchyList = result.map((item, index) => {
                const isOnly = result.length === 1;
                const isFirst = index === 0;
                const isLast = index === result.length - 1;
                const isCurrent = item.Id === this.recordId;

                let baseClass = 'breadcrumb-step';
                if (isOnly) {
                    baseClass += ' breadcrumb-single';
                } else if (isFirst) {
                    baseClass += ' breadcrumb-first';
                    baseClass += ' breadcrumb-last';
                } else if (isLast) {
                    baseClass += ' breadcrumb-last';
                }
                if (isCurrent) {
                    baseClass += ' breadcrumb-current';
                }
                return {
                    ...item,
                    cssClass: baseClass
                };
            });
            this.error = undefined;
        }).catch(error => {
            this.error = error.body ? error.body.message : error.message;
            this.breadcrumbPath = [];
        });
    }

    openHierarchy(event) {
        const selectedId = event.currentTarget.dataset.id;
        window.open('/' + selectedId, '_blank')
    }

}