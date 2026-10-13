import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class FlowManager extends LightningElement {
    //API
    @api flowName;
    flow_Variables;
    urlParams = {}; // Object to store the URL parameters
    @track openFlow = true;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            // Extracting URL parameters
            this.urlParams = pageRef.state;
            console.log('this.urlParams >>> ' + JSON.stringify(this.urlParams));
        }
    }

    handleClose(event) {
        this.openFlow = !this.openFlow;
    }
}