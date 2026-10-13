import { api, LightningElement, track } from 'lwc';
import getFields from "@salesforce/apex/FieldPickerController.getFields";

export default class FieldPicker extends LightningElement {
    _mainObject;
    @track objectFieldsArray = [];
    @track pathArray = [];
    @track loading = true;
    @api getOptions = false;
    _filter = '';
    hasMainObject = false;
    hasFilter = false;
    initialized = false;
    getObjectFieldsArray() {
        return this.objectFieldsArray;
    }

    @api
    set mainObject(value) {
        this.dispatchLoadingEvent();
        this._mainObject = value;
        this.hasMainObject = true;
        this.initialized = false;
        this.objectFieldsArray = [];
        this.pathArray = [];
        this.loading = true;
        this.initializeIfReady();
    }


    get mainObject() {
        return this._mainObject;
    }

    @api
    set filter(value) {
        this._filter = value;
        this.hasFilter = true;
        this.initialized = false;
        this.objectFieldsArray = [];
        this.pathArray = [];
        this.loading = true;
        this.initializeIfReady();
    }

    get filter() {
        return this._filter;
    }

    initializeIfReady() {
        if (!this.hasMainObject || !this.hasFilter || this.initialized) {
            return;
        }

        this.initialized = true;
        this.loading = true;
        this.dispatchLoadingEvent();
        getFields({
            objectApiName: this._mainObject,
            getOptions: this.getOptions,
            dataTypeFilter: this._filter
        })
        .then(result => {
            this.objectFieldsArray = [{
                objectApiName: this._mainObject,
                fields: JSON.parse(result),
                index: 0
            }];

            this.loading = false;
            this.dispatchLoadingEvent();
        })
        .catch(error => {
            console.error(error);
            this.loading = false;
            this.dispatchLoadingEvent();
        });
    }

    handleFieldSelection(event) {
        if (this.loading || event.target.dataset.field === 'Group') {return;}
        const fieldApiName = event.target.dataset.field;
        const inputType = event.target.dataset.inputType;
        const isReference = event.target.dataset.reference && event.target.dataset.reference === 'true';
        const isPicklist = event.target.dataset.isPicklist && event.target.dataset.isPicklist === 'true';
        const isBoolean = event.target.dataset.isBoolean && event.target.dataset.isBoolean === 'true';
        const options = event.target.dataset.options;
        const referenceTo = event.target.dataset.referenceTo;
        const objectIndex = +event.target.dataset.index;
        const label = event.target.dataset.label;
        console.log('Field Selected: ', fieldApiName, ' Is Reference: ', isReference, ' Reference To: ', referenceTo, ' Object Index: ', objectIndex, ' Is Picklist: ', isPicklist, ' Is Boolean: ', isBoolean, 'label: ', label);

        if (objectIndex !== this.objectFieldsArray.length - 1) {
            this.pathArray.splice(objectIndex);
            this.objectFieldsArray.splice(objectIndex + 1);
        }
        if (objectIndex === this.objectFieldsArray.length - 1 && this.pathArray.length == objectIndex + 1) {
            this.pathArray.pop();
        }
        if (objectIndex === this.objectFieldsArray.length - 1) {
            if (this.pathArray[objectIndex - 1] && this.pathArray[objectIndex - 1].isReference) {
                console.log('incide');
                if (this.pathArray[objectIndex - 1].part.endsWith('__c')){
                    this.pathArray[objectIndex - 1].part = this.pathArray[objectIndex - 1].part.slice(0, -3) + '__r';
                }
                if (this.pathArray[objectIndex - 1].part.endsWith('Id')){
                    this.pathArray[objectIndex - 1].part = this.pathArray[objectIndex - 1].part.slice(0, -2);
                }
            }
        }
        let pathAddition = fieldApiName;
        if (isReference && referenceTo) {
            this.loading = true;
            this.dispatchLoadingEvent();
            getFields({ objectApiName: referenceTo, getOptions: this.getOptions, dataTypeFilter: this.filter }).then(result => {
                const currentIndex = this.objectFieldsArray.length > 0 ? this.objectFieldsArray.length : 0;
                this.objectFieldsArray.push({objectApiName: referenceTo, fields: JSON.parse(result), index: currentIndex});
                this.loading = false;
                this.dispatchLoadingEvent();
            }).catch(error => {
                console.error('Error fetching reference fields: ', error);
                this.loading = false;
                this.dispatchLoadingEvent();
            });
        }

        this.pathArray.push({part: pathAddition, isReference: isReference});
        console.log('Updated Path Array: ', JSON.stringify(this.pathArray));
        let fullPathArray = [];
        this.pathArray.forEach(partObj => {
            fullPathArray.push(partObj.part);
        });
        console.log('Current Path: ', fullPathArray.join('.'));
        const pathEvent = new CustomEvent('selectfield', {
            detail: { eventType:'select', fieldPath: fullPathArray.join('.'), isReference, isPicklist, isBoolean, options, inputType, label}
        });

        console.log('Dispatching field selection event: ', JSON.stringify(pathEvent.detail));
        // Dispatch the event
        this.dispatchEvent(pathEvent);
    }

    @api
    retrieveFieldSelection(fieldPath) {
        try{
            if (this.loading || !fieldPath) {
                return;
            }
            const pathParts = fieldPath.split('.');
            this.objectFieldsArray = [];
            this.pathArray = [];
            this.loading = true;
            this.dispatchLoadingEvent();

            let currentObjectApiName = this.mainObject;
            let stepIndex = 0;
            let lastFieldMeta = {};

            const fetchNext = () => {
                getFields({ objectApiName: currentObjectApiName, getOptions: this.getOptions, dataTypeFilter: this.filter})
                    .then(result => {
                        const fields = JSON.parse(result);
                        const currentIndex = this.objectFieldsArray.length;

                        this.objectFieldsArray.push({
                            objectApiName: currentObjectApiName,
                            fields,
                            index: currentIndex
                        });

                        const pathPart = pathParts[stepIndex];
                        let selectedField = fields.find(
                            f => f.fieldApiName.toLowerCase() === pathPart.toLowerCase()
                        );

                        // Try relationship resolution
                        if (!selectedField) {
                            const normalized = this.normalizeReferenceFieldApiName(pathPart);
                            selectedField = fields.find(
                                f => f.fieldApiName.toLowerCase() === normalized
                            );
                        }

                        const isReference = selectedField.isReference === true;
                        const isPicklist = selectedField.isPicklist === true;
                        const isBoolean = selectedField.isBoolean === true;

                        this.pathArray.push({
                            part: selectedField.fieldApiName,
                            isReference
                        });

                        lastFieldMeta = {
                            isReference,
                            isPicklist,
                            isBoolean,
                            options: selectedField.options,
                            inputType: selectedField.inputType
                        };

                        stepIndex++;

                        // Continue traversal if reference
                        if (isReference && selectedField.referenceTo && stepIndex < pathParts.length) {
                            currentObjectApiName = selectedField.referenceTo;
                            fetchNext();
                        } else {
                            // Final dispatch (same as handler)
                            const fullPath = this.pathArray.map(p => p.part).join('.');

                            this.dispatchEvent(
                                new CustomEvent('retrievefield', {
                                    detail: {
                                        eventType: 'retrieve',
                                        fieldPath: fullPath,
                                        isReference: lastFieldMeta.isReference,
                                        isPicklist: lastFieldMeta.isPicklist,
                                        isBoolean: lastFieldMeta.isBoolean,
                                        options: lastFieldMeta.options,
                                        inputType: lastFieldMeta.inputType,
                                        label: selectedField.label
                                    }
                                })
                            );

                            this.selectOptionsInUI();

                            this.loading = false;
                            this.dispatchLoadingEvent();
                        }
                    })
                    .catch(error => {
                        console.error('Error restoring field selection:', error);
                        this.loading = false;
                        this.dispatchLoadingEvent();
                    });
            };
            // Start traversal
            fetchNext();
        } catch(error) {
            console.error('HANDLE FIELD SELECTION ERROR');
            console.error(error);
            console.error(error?.stack);
        }
    }

    normalizeReferenceFieldApiName(pathPart) {
        // Custom relationship: Parent__r → Parent__c
        if (pathPart.endsWith('__r')) {
            return pathPart.replace(/__r$/, '__c').toLowerCase();
        }

        // Standard relationship: Owner → OwnerId
        return (pathPart + 'Id').toLowerCase();
    }

    selectOptionsInUI() {
        // Wait for DOM to render
        requestAnimationFrame(() => {
            this.pathArray.forEach((pathPart, index) => {
                const selectEl = this.template.querySelector(
                    `select[data-index="${index}"]`
                );

                if (!selectEl) {
                    return;
                }

                Array.from(selectEl.options).forEach(option => {
                    option.selected = option.value === pathPart.part;
                });
            });
        });
    }

    dispatchLoadingEvent() {        
        const loadingEvent = new CustomEvent('loading', {
            detail: {isLoading: this.loading}
        });

        console.log('Dispatching loading event: ', JSON.stringify(loadingEvent.detail));
        // Dispatch the event
        this.dispatchEvent(loadingEvent);
    }

}