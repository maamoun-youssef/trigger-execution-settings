//**
/* @author ULiT
/* @date 29-07-2024
/* @description 
/*******************************************************************************************************************************************
/*/
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from 'lightning/uiRecordApi';

//OBJECTS
import Tax__c from '@salesforce/schema/Tax__c';
//FIELDS
import BusinessUnitVAT__c from "@salesforce/schema/Tax__c.BusinessUnitVAT__c";
import Category__c from "@salesforce/schema/Tax__c.Category__c";
import IsForeignSupplier__c from "@salesforce/schema/Tax__c.IsForeignSupplier__c";
import Zone__c from "@salesforce/schema/Tax__c.Zone__c";
import Code__c from "@salesforce/schema/Tax__c.Code__c";
import Tax_Name from "@salesforce/schema/Tax__c.Name";
import TaxApplied__c from "@salesforce/schema/Tax__c.TaxApplied__c";
import TaxRate__c from "@salesforce/schema/Tax__c.TaxRate__c";
import Name from "@salesforce/schema/Tax__c.Name";
import BU_NAME from "@salesforce/schema/BusinessUnit__c.Name";
//APEX
import getData from "@salesforce/apex/VatCategorySettingsCtrl.getData";
import saveData from "@salesforce/apex/VatCategorySettingsCtrl.saveData";
//LABELS
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
// Custom Labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Modify from "@salesforce/label/c.LBL_Modify";
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_Please_Select_A_Record from "@salesforce/label/c.LBL_Please_Select_A_Record";
import LBL_VAT_Rate_Settings_By_Category from "@salesforce/label/c.LBL_VAT_Rate_Settings_By_Category";
import LBL_Vat_Placeholder from '@salesforce/label/c.LBL_Vat_Placeholder';
import LBL_Remove from '@salesforce/label/c.LBL_Remove';
import LBL_Actions from '@salesforce/label/c.LBL_Actions';
export default class VatByCategorySettings extends LightningElement {
    //LABELS
    @track labels = {
        MSG_Successfully_Saved,
        LBL_Save,
        LBL_Warning,
        LBL_Modify,
        LBL_Add,
        LBL_Delete,
        LBL_Please_Select_A_Record,
        LBL_VAT_Rate_Settings_By_Category,
        MSG_No_Changes_To_Save,
        LBL_Vat_Placeholder,
        LBL_Remove,
        LBL_Actions,
        //objects and fields labels
        Tax__c: {}
    }
    API_NAMES = {
        Tax__c: {
            objectApiName: Tax__c.objectApiName,
            BusinessUnitVAT__c: BusinessUnitVAT__c.fieldApiName,
            Category__c: Category__c.fieldApiName,
            IsForeignSupplier__c: IsForeignSupplier__c.fieldApiName,
            Zone__c: Zone__c.fieldApiName,
            TaxApplied__c: TaxApplied__c.fieldApiName,
            TaxRate__c: TaxRate__c.fieldApiName,
            Code__c: Code__c.fieldApiName,
            Name: Tax_Name.fieldApiName,
            TaxApplied__r: TaxApplied__c.fieldApiName.replace(/__c$/, '__r')
        }
    }
    displayInfo = {
        primaryField: Name.fieldApiName,
        additionalFields: [Code__c.fieldApiName],
    };
    @track recordPickerfilter;

    @wire(getRecord, { recordId: '$buId', fields: [BU_NAME] })
    record({ error, data }) {
        if (data) {
            this.recordName = data.fields.Name.value;
        } else if (error) {
            console.error(error);
        }
    }

    //IDS
    @api buId;
    //BOOLEANS
    isLoading = true;
    isEditMode = false;
    newRow = false;
    headerFieldsListLabels = {};
    @track showUpdateVATPopup = false;
    @track vatRecordId;
    @track hasError = false;
    // maps
    @track fieldsMap = {};
    @track taxDataMap = {};
    picklistLabelsMap = {};
    @track recordType;
    @track selectedRow;
    @track selectedRowIndex;
    @track matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: this.API_NAMES.Tax__c.TaxRate__c }],
    };

    // Lists
    @track taxesList = [];
    @track categoryOptions = [];
    @track zoneOptions = [];

    connectedCallback() {
        this.loadData();
        addEventListener('resize', this.setPageSize);
    }

    renderedCallback() {
        try {
            this.setPageSize();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');

        }
    }
    //LIFECYCLE
    setPageSize = () => {
        try {
            const mainContainer = this.template.querySelector(".mainContainer");
            const pageHeader = this.template.querySelector(".pageHeader");
            const pageBodyDiv = this.template.querySelector(".pageBody");
            const pageBodySection = this.template.querySelector(".pageBodySection");
            if (mainContainer && pageHeader && pageBodyDiv && pageBodySection) {
                const windowHeight = window.innerHeight;
                const headerHeight = pageHeader.offsetHeight;
                const remainingHeight = windowHeight - headerHeight - 400;
                pageBodySection.style.height = remainingHeight + "px";
                pageBodyDiv.style.height = remainingHeight + "px";
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    };

    //LOAD
    loadData() {
        this.isLoading = true;
        getData({
            buId: this.buId
        }).then((result) => {
            this.afterload(result);
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification('Error', error.body?.message, 'error');
        });
    }
    afterload(result) {
        let data = JSON.parse(result);
        this.picklistLabelsMap = data.picklistLabelsMap;
        this.fieldsMap = data.fieldsMap;
        let taxesFieldsMap = this.fieldsMap[this.API_NAMES.Tax__c.objectApiName];
        let headerLabelsMap = {};
        headerLabelsMap['BusinessUnitVAT__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.BusinessUnitVAT__c].label;
        headerLabelsMap['Category__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.Category__c].label;
        headerLabelsMap['IsForeignSupplier__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.IsForeignSupplier__c].label;
        headerLabelsMap['Zone__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.Zone__c].label;
        headerLabelsMap['TaxApplied__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.TaxApplied__c].label;
        headerLabelsMap['TaxRate__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.TaxRate__c].label;
        this.headerFieldsListLabels = { ...headerLabelsMap }
        this.taxDataMap = data.taxRateMap;
        this.deletedTaxes = [];
        this.selectedRow = '';
        this.selectedRowIndex = '';
        this.newEndDate = '';
        this.newEndDate = '';
        this.recordType = data.recordType;
        this.recordPickerfilter = {
            criteria: [
                {
                    fieldPath: 'RecordTypeId',
                    operator: 'eq',
                    value: data.recordTypeIdVAT,
                },
                {
                    fieldPath: this.API_NAMES.Tax__c.BusinessUnitVAT__c,
                    operator: 'eq',
                    value: this.buId,
                }
            ],
            filterLogic: '1 AND 2',
        };
        let tempcategoryOptions = [];
        for (let key in data.picklistLabelsMap[this.API_NAMES.Tax__c.objectApiName + '-' + this.API_NAMES.Tax__c.Category__c]) {
            let label = data.picklistLabelsMap[this.API_NAMES.Tax__c.objectApiName + '-' + this.API_NAMES.Tax__c.Category__c][key];
            tempcategoryOptions.push({ label: label, value: key })
        }
        this.categoryOptions = tempcategoryOptions;
        let tempZoneOptions = [];
        for (let key in data.picklistLabelsMap[this.API_NAMES.Tax__c.objectApiName + '-' + this.API_NAMES.Tax__c.Zone__c]) {
            let label = data.picklistLabelsMap[this.API_NAMES.Tax__c.objectApiName + '-' + this.API_NAMES.Tax__c.Zone__c][key];
            tempZoneOptions.push({ label: label, value: key })
        }
        this.zoneOptions = tempZoneOptions;
        data.taxes.forEach(element => {
            if (element[this.API_NAMES.Tax__c.Zone__c]) {
                let zoneLabel = this.zoneOptions.find(item => item.value == element[this.API_NAMES.Tax__c.Zone__c]);
                element[this.API_NAMES.Tax__c.Zone__c] = zoneLabel.value;
                element.Zone = this.getPicklistLabel(this.API_NAMES.Tax__c.Zone__c, element[this.API_NAMES.Tax__c.Zone__c]);
            }
            if (element[this.API_NAMES.Tax__c.Category__c]) {
                let categoryLabel = this.categoryOptions.find(item => item.value == element[this.API_NAMES.Tax__c.Category__c]);
                element[this.API_NAMES.Tax__c.Category__c] = categoryLabel.value;
                element.Category = this.getPicklistLabel(this.API_NAMES.Tax__c.Category__c, element[this.API_NAMES.Tax__c.Category__c]);
            }
            element.isSelected = false;
            if (element[this.API_NAMES.Tax__c.TaxApplied__c]) {
                element.taxRate = element[this.API_NAMES.Tax__c.TaxApplied__r][this.API_NAMES.Tax__c.TaxRate__c];
                element.taxName = element[this.API_NAMES.Tax__c.TaxApplied__r][this.API_NAMES.Tax__c.Name];
            }
        });
        let tmpTaxesList = [];
        data.taxes.forEach(tax => {
            tmpTaxesList.push({
                Id: tax.Id,
                RecordTypeId: tax.RecordTypeId,
                BusinessUnitVAT__c: tax[this.API_NAMES.Tax__c.BusinessUnitVAT__c],
                Category__c: tax[this.API_NAMES.Tax__c.Category__c],
                IsForeignSupplier__c: tax[this.API_NAMES.Tax__c.IsForeignSupplier__c],
                Zone__c: tax[this.API_NAMES.Tax__c.Zone__c],
                TaxApplied__c: tax[this.API_NAMES.Tax__c.TaxApplied__c],
                Category: tax.Category,
                Zone: tax.Zone,
                taxRate: tax.taxRate,
                taxName: tax.taxName,
                isSelected: tax.isSelected,
            });
        });
        this.taxesList = tmpTaxesList;
        this.isLoading = false;
    }

    getPicklistLabel(field, value) {
        let picklistMap;
        if (field === this.API_NAMES.Tax__c.Zone__c) {
            picklistMap = this.zoneOptions;
        } else if (field === this.API_NAMES.Tax__c.Category__c) {
            picklistMap = this.categoryOptions;
        } else {
            return value;
        }
        let selectedOption = picklistMap.find(option => option.value === value);
        return selectedOption ? selectedOption.label : value;
    }
    // handleRowSelection(event) {
    //     let dataIndex = event.target.dataset.index;
    //     let allRadioButtons = this.template.querySelectorAll('.radioBtn');
    //     allRadioButtons.forEach(element => {
    //         element.checked = false;
    //     });
    //     allRadioButtons[dataIndex].checked = true;
    //     this.selectedRow = this.taxesList[dataIndex].Id;
    //     this.selectedRowIndex = dataIndex;
    // }
    handleAddNewRow() {
        this.taxesList.push({
            BusinessUnitVAT__c: this.buId,
            Category__c: null,
            IsForeignSupplier__c: false,
            Zone__c: null,
            TaxApplied__c: null,
            RecordTypeId: this.recordType,
            taxRate: null,
            isSelected: true,
            isEdited: true,
            isnewRow: true,
            showRemoveButton: true,
            removeButtonClass: 'visible',
            addButtonClass: 'visible',
            editButtonClass: 'hidden',
            deleteButtonClass: 'hidden',
        });
    }

    // handleEdit(event) {
    //     if (this.selectedRow) {
    //         let found = this.taxesList.find((element) => element.Id == this.selectedRow);
    //         found.isSelected = true;
    //         found.isEdited = true;
    //         let index = this.taxesList.findIndex((element) => element.Id == this.selectedRow);
    //         this.template.querySelectorAll('.rows')[index].classList.add('slds-is-edited');
    //     }
    //     else {
    //         this.showNotification('Warning', LBL_Please_Select_A_Record, 'warning');
    //     }
    // }
    @track deletedTaxes = [];
    // handleDeleteTax(event) {
    //     if (this.selectedRowIndex) {
    //         const deletedRow = this.taxesList[this.selectedRowIndex];
    //         if (deletedRow.isnewRow) {
    //         } else {
    //             this.deletedTaxes.push(deletedRow);
    //         }
    //         this.taxesList.splice(this.selectedRowIndex, 1);
    //         this.selectedRowIndex = '';
    //     } else {
    //         this.showNotification('Warning', LBL_Please_Select_A_Record, 'warning');
    //     }

    // }

    handleEditRow(event) {
        const index = event.target.dataset.index;
        let tax = this.taxesList[index];
        tax.isSelected = true;
        tax.isEdited = true;
        this.template.querySelectorAll('.rows')[index].classList.add('slds-is-edited');
        tax.showRemoveButton = true;
        tax.editButtonClass = 'hidden';
        tax.deleteButtonClass = 'hidden';
        tax.removeButtonClass = 'visible';
    }

    handleDeleteRow(event) {
        const index = event.target.dataset.index;
        const deletedRow = this.taxesList[index];
        deletedRow.showRemoveButton = true;
        deletedRow.editButtonClass = 'hidden';
        deletedRow.deleteButtonClass = 'hidden';
        deletedRow.removeButtonClass = 'visible';
        if (deletedRow && !deletedRow.isnewRow) {
            this.deletedTaxes.push(deletedRow);
        }
        this.taxesList.splice(index, 1);
        this.taxesList.forEach((tax) => {
            if (!tax.isnewRow) {
                tax.showRemoveButton = true;
                tax.editButtonClass = 'visible';
                tax.deleteButtonClass = 'visible';
                tax.removeButtonClass = 'hidden';
            }
        });
    }

    handleCancel(event) {
        const index = event.target.dataset.index;
        const cancelRow = this.taxesList[index];
        if (cancelRow.isnewRow) {
            this.taxesList.splice(index, 1);
        } else {
            this.taxesList[index].isEdited = false;
            this.taxesList[index].isSelected = false;
            this.taxesList[index].showRemoveButton = false;
            this.taxesList[index].editButtonClass = 'visible';
            this.taxesList[index].deleteButtonClass = 'visible';
            this.taxesList[index].removeButtonClass = 'hidden';
        }
        this.template.querySelectorAll('.rows')[index].classList.remove('slds-is-edited');
    }

    handleSave() {
        this.hasError = false;
        let requiredFields = this.template.querySelectorAll('.requiredField');
        let allValid = true;
        requiredFields.forEach(field => {
            if (!field.checkValidity() && !field.closest('tr').classList.contains('slds-is-deleted')) {
                field.reportValidity();
                allValid = false;
            }
        });
        const hasChanges = this.taxesList.some(tax => tax.isEdited || tax.isnewRow);
        const hasDeletions = this.deletedTaxes.length > 0;
        if (allValid) {
            if (hasChanges || hasDeletions) {
                this.isLoading = true;
                let toUpsert = [];
                this.taxesList.forEach(tax => {
                    if (Object.hasOwn(tax, 'isnewRow')) {
                        delete tax.isnewRow;
                    }
                    if (Object.hasOwn(tax, 'isSelected')) {
                        delete tax.isSelected;
                    }
                    if (Object.hasOwn(tax, 'isEdited')) {
                        delete tax.isEdited;
                    }
                    if (Object.hasOwn(tax, 'taxRate')) {
                        delete tax.taxRate;
                    }
                    if (Object.hasOwn(tax, 'Category')) {
                        delete tax.Category;
                    }
                    if (Object.hasOwn(tax, 'Zone')) {
                        delete tax.Zone;
                    }
                    if (Object.hasOwn(tax, 'taxName')) {
                        delete tax.taxName;
                    }
                    if (tax[this.API_NAMES.Tax__c.Zone__c]) {
                        let zoneLabel = this.zoneOptions.find(item => item.value == tax[this.API_NAMES.Tax__c.Zone__c]);
                        tax.Zone = zoneLabel.label;
                        tax[this.API_NAMES.Tax__c.Zone__c] = zoneLabel.value;
                    }
                    if (tax.Category__c) {
                        let zoneLabel = this.categoryOptions.find(item => item.value == tax.Category__c);
                        tax.Category = zoneLabel.label;
                        tax.Category__c = zoneLabel.value;
                    }
                    let taxToUpsert = {
                        Id: tax.Id,
                        RecordTypeId: tax.RecordTypeId,
                        [this.API_NAMES.Tax__c.BusinessUnitVAT__c]: tax.BusinessUnitVAT__c,
                        [this.API_NAMES.Tax__c.Category__c]: tax.Category__c,
                        [this.API_NAMES.Tax__c.IsForeignSupplier__c]: tax.IsForeignSupplier__c,
                        [this.API_NAMES.Tax__c.Zone__c]: tax.Zone__c,
                        [this.API_NAMES.Tax__c.TaxApplied__c]: tax.TaxApplied__c,
                    }
                    if (!tax.isnewRow || !tax.isDeleted) {
                        toUpsert.push(taxToUpsert);
                    }
                });
                saveData({
                    taxesToUpsertJSON: JSON.stringify(toUpsert),
                    taxesToDeleteJSON: this.deletedTaxes ? JSON.stringify(this.deletedTaxes) : null,
                    buId: this.buId
                }).then((result) => {
                    if (result == 'SUCCESS') {
                        this.showNotification('Success', MSG_Successfully_Saved, 'success');
                        this.loadData();
                        this.isLoading = false;
                    } else {
                        this.showNotification('Error', result, 'error');
                    }
                }).catch(error => {
                    this.showNotification('Error', error, 'error');
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                });
            } else {
                if (!hasDeletions) {
                    this.showNotification(this.labels.LBL_Warning, this.labels.MSG_No_Changes_To_Save, 'warning');
                }
            }
        } else {
            this.hasError = true;
        }
    }

    getPicklistValue(field, label) {
        let picklistMap;
        if (field === this.API_NAMES.Tax__c.Zone__c) {
            picklistMap = this.zoneOptions;
        } else if (field === this.API_NAMES.Tax__c.Category__c) {
            picklistMap = this.categoryOptions;
        } else {
            return label;
        }
        let selectedOption = picklistMap.find(option => option.label === label);
        return selectedOption ? selectedOption.value : label;
    }

    handleFieldEdits(event) {
        let dataIndex = event.target.dataset.index;
        let field = event.target.dataset.field;
        let value = event.target.value;
        let evtRecordId = event.detail.recordId;
        this.vatRecordId = event.detail.recordId;
        let checkboxvalue = event.target.checked;
        if (field == 'IsForeignSupplier__c') {
            this.taxesList[dataIndex][field] = checkboxvalue;
        } else if (field == 'TaxRate__c') {
            let newTaxAppliedRate = {
                TaxRate__c: value
            }
            this.taxesList[dataIndex]['TaxApplied__c'] = newTaxAppliedRate;
        } else if (field == 'TaxApplied__c') {
            let tax = this.taxDataMap[evtRecordId];
            this.taxesList[dataIndex].taxRate = tax?.TaxRate__c;
            this.taxesList[dataIndex].TaxApplied__c = evtRecordId;
            this.taxesList[dataIndex].taxName = tax?.name;

        } else {
            this.taxesList[dataIndex][field] = value;
            if (field === 'Zone__c') {
                this.taxesList[dataIndex]['Zone__c'] = value;
            } else if (field === 'Category__c') {
                this.taxesList[dataIndex].Category__c = value;
            }
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
            duration: 3000
        });
        this.dispatchEvent(evt);
        setTimeout(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable',
                duration: 1
            }));
        }, 5000);
    }
}