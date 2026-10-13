import { LightningElement,api ,track} from 'lwc';
import {labels} from './properties.js';

export default class ScnSelectSupplier extends LightningElement {
    @api suppliers;
    @track selectedSupplier=null;
    @track labels = labels;

    get supplierList(){
        return Array.isArray(this.suppliers)
            ? this.suppliers
            : [];
    }
    get isNextDisabled(){
        return !this.selectedSupplier;
    }

    handleChange(event){
        this.selectedSupplier = event.detail.value;
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent('close'));
    }

    nextModal(){
        this.dispatchEvent(new CustomEvent('next', {detail:this.selectedSupplier}));
    }

}