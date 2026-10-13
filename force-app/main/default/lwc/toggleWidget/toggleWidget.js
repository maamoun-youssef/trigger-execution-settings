/**
 * @author ULIT
 * @date 12/12/2020
 * @description JS for negOptim toggle widget LWC to toggle values on boolean fields in a record page
 * */
import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecordData from "@salesforce/apex/ToggleWidgetCmpController.getRecordData";
import saveRecord from "@salesforce/apex/ToggleWidgetCmpController.saveRecord";
import { RefreshEvent } from 'lightning/refresh';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubSub' ; 
//custom labels:
import LBL_Close from '@salesforce/label/c.LBL_Close';
import LBL_Cancel from '@salesforce/label/c.LBL_Cancel';
import LBL_Confirm from '@salesforce/label/c.LBL_Confirm';
import LBL_Warning from '@salesforce/label/c.LBL_Warning';
import LBL_Error from '@salesforce/label/c.LBL_Error';
import Loading from '@salesforce/label/c.Loading';
import MSG_CONFIRM_SAVE from '@salesforce/label/c.MSG_CONFIRM_SAVE';

const NB_FIELDS = 3;
const VERTICAL = 'Vertical';
const ERROR_VARIANT = 'error';
const FIELD_LABEL = 'field';
const MESSAGE_TOGGLE_ACTIVE_LABEL = 'messageToggleActive';
const MESSAGE_TOGGLE_INACTIVE_LABEL = 'messageToggleInactive';
const SHOW_CONFIRM_MSG_LABEL = 'showConfirmMsg';
const BACKGROUND_COLOR_LABEL = 'backgroundColor';
const BORDER_COLOR_LABEL = 'borderColor';

export default class ToggleWidget extends LightningElement {
    //custom labels
    labels = { LBL_Close, LBL_Cancel, LBL_Confirm, LBL_Warning, LBL_Error, Loading, MSG_CONFIRM_SAVE };
    @wire(CurrentPageReference) pageRef;
    //global parameters
    @api recordId;
    @api objectApiName;
    @api layout;
    @api bgColor;
    @api title;
    @api description;
    @api descriptionPosition;

    //field 1 parameters
    @api field1;
    @api showConfirmMsg1;
    @api messageToggleActive1;
    @api messageToggleInactive1;
    @api borderColor1;
    @api backgroundColor1;

    //field 2 parameters
    @api field2;
    @api showConfirmMsg2;
    @api messageToggleActive2;
    @api messageToggleInactive2;
    @api borderColor2;
    @api backgroundColor2;

    //field 3 parameters
    @api field3;
    @api showConfirmMsg3;
    @api messageToggleActive3;
    @api messageToggleInactive3;
    @api borderColor3;
    @api backgroundColor3;

    @track saveEnd = false;
    @track loading = false;
    @track openModal = false;
    @track containerClass;
    @track fields = []; //fields for display
    fieldsInputMap = {}; //fields mapped by api names

    //properties for the currently toggled
    currentLabel;
    currentName;
    currentIndex;
    currentValue = false;

    //properties for css class getters
    //for getColSize()
    colSizeOnVertical = "slds-col slds-box slds-m-vertical_xx-small";
    colSizeOnHorizontal = "slds-col slds-m-horizontal_xx-small slds-box slds-size_1-of-";
    //for getGridClass()
    gridClassOnVertical = "slds-grid slds-grid_align-spread slds-gutters_x-large slds-p-horizontal_large";
    gridClassOnHorizontal = "";
    //for getLabelClass()
    labelClassOnVertical = "slds-form-element__label slds-col";
    labelClassOnHorizontal = "slds-form-element__label";
    //for getInputClass()
    inputClassOnVertical = "slds-col";
    inputClassOnHorizontal = "";

    //for containerClass property
    containerClassOnVertical = 'slds-grid slds-grid_vertical';
    containerClassOnHorizontal = 'slds-grid slds-m-right_large';
    
    
    //getters
    get getDescriptionClass() {
        // if (this.title)
        return 'slds-card__header slds-grid slds-p-top_none';
        // return 'slds-card__header slds-grid';
    }
    get getIsDescriptionPositionTop() {
        return this.descriptionPosition == 'Top';
    }
    get getColSize() {
        if (this.layout === VERTICAL)
            return this.colSizeOnVertical;
        return this.colSizeOnHorizontal + this.fields.length;
    }
    get getGridClass() {
        if (this.layout === VERTICAL)
            return this.gridClassOnVertical;
        return this.gridClassOnHorizontal;
    }
    get getLabelClass() {
        if (this.layout === VERTICAL)
            return this.labelClassOnVertical;
        return this.labelClassOnHorizontal;
    }
    get getInputClass() {
        if (this.layout === VERTICAL)
            return this.inputClassOnVertical;
        return this.inputClassOnHorizontal;
    }
    get hasFields() {
        return this.fields && this.fields.length > 0;
    }

    //populate and style elements
    connectedCallback() {
        this.register();
        this.loading = true;
        var fieldsNames = [];
        let tmp = {}; //todo:change name
        for (let index = 1; index <= NB_FIELDS; index++) {
            if (this[`${FIELD_LABEL}${index}`] && this[`${FIELD_LABEL}${index}`] != '') {
                let fieldName = this[`field${index}`];
                fieldsNames.push(fieldName);
                //populate fields map
                let fieldInput = {};
                fieldInput.fieldName = fieldName;
                fieldInput.index = index;
                tmp[fieldName] = fieldInput;
            }
        }
        this.containerClass = this.layout === VERTICAL ? this.containerClassOnVertical : this.containerClassOnHorizontal;
        this.styleDiv = this.bgColor ? "background-color:" + this.bgColor + ';' : undefined;
        if (fieldsNames && fieldsNames.length > 0 && Object.keys(tmp).length > 0) {
            getRecordData({ recordId: this.recordId, objectApiName: this.objectApiName, fields: fieldsNames })
                .then(res => {
                    let results = JSON.parse(res);
                    for (let name of fieldsNames) {
                        if (tmp[name]) {
                            tmp[name].checked = results[name].value;
                            tmp[name].fieldLabel = results[name].label;
                            tmp[name].inlineHelpText = results[name].inlineHelpText;
                            tmp[name].isReadable = results[name].isReadable;
                            tmp[name].isEditable = results[name].isEditable;
                            tmp[name].hasInlineHelpText = tmp[name].inlineHelpText ? true : false;
                            tmp[name].messageToggleActive = this[`${MESSAGE_TOGGLE_ACTIVE_LABEL}${tmp[name].index}`];
                            tmp[name].messageToggleInactive = this[`${MESSAGE_TOGGLE_INACTIVE_LABEL}${tmp[name].index}`];
                            tmp[name].styleDiv = (this[`${BACKGROUND_COLOR_LABEL}${tmp[name].index}`] ? "background-color:" + this[`${BACKGROUND_COLOR_LABEL}${tmp[name].index}`] + ';' : '')
                                + (this[`${BORDER_COLOR_LABEL}${tmp[name].index}`] ? "border-color:" + this[`${BORDER_COLOR_LABEL}${tmp[name].index}`] + ';' : '');
                        }
                    }
                    this.fieldsInputMap = tmp;
                    if (Object.keys(this.fieldsInputMap).length !== 0)
                        this.fields = Object.keys(this.fieldsInputMap).map(apiname => { return this.fieldsInputMap[apiname] });
                    this.loading = false;
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.labels.LBL_Error,
                        message: error.body.message,
                        variant: ERROR_VARIANT
                    }));
                    this.loading = false;
                })
        }
    }

    register(){
        window.console.log('event registered ');
        registerListener('simplevt', ({ loading }) => {
            this.loading = loading;
            console.log('loading' + loading);
        }, this);
    }
    
    
    firePubSub() {
        let self = this;
        fireEvent(this.pageRef, 'simplevt', {
            loading : self.loading
        });
        /*fireEvent('simplevt', message );*/
        window.console.log('Event Fired ');
    }
    //on toggle click, check if confirmation msg checked or not
    save(event) {
        this.currentIndex = event.target.dataset.index;
        this.currentName = event.target.dataset.apiname;
        this.currentValue = event.detail.checked;
        this.fieldsInputMap[this.currentName].checked = this.currentValue;
        if (this[`${SHOW_CONFIRM_MSG_LABEL}${this.currentIndex}`]) {
            this.openModal = true; //open confirmation modal
        } else {
            this.saveEnd = false;
            this.performSave(); //save immediatly
            var interval = setInterval(() => { 
                if (this.saveEnd) {
                    console.log('refreshhhhhh');
                    this.dispatchEvent(new RefreshEvent());
                    //eval("$A.get('e.force:refreshView').fire();");
                    clearInterval(interval);
                }
            }, 200);
        }
    }

    performSave() {
        this.loading = true;
        this.firePubSub();
        saveRecord({ recordId: this.recordId, objectApiName: this.objectApiName, fieldName: this.currentName, value: this.currentValue })
            .then(res => {
                //eval("$A.get('e.force:refreshView').fire();");
                this.loading = false;
                this.saveEnd = true;
                this.firePubSub();
                this.dispatchEvent(new RefreshEvent());
            }).catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: this.labels.LBL_Error,
                    message: error.body.message,
                    variant: ERROR_VARIANT
                }));
                this.fieldsInputMap[this.currentName].checked = !this.currentValue;
                this.loading = false;
                this.firePubSub();
                this.saveEnd = true;
            })
    }

    closeModal(evt) {
        this.currentLabel = this.fieldsInputMap[this.currentName].fieldLabel;
        this.fieldsInputMap[this.currentName].checked = !this.currentValue;
        this.openModal = false;
    }

    confirmModal(evt) {
        this.performSave(this.currentIndex, this.currentValue);
        this.openModal = false;
    }

}