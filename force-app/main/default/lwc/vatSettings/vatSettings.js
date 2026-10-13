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
import ListingOrder__c from "@salesforce/schema/Tax__c.ListingOrder__c";
import BusinessUnitVAT__c from "@salesforce/schema/Tax__c.BusinessUnitVAT__c";
import Code__c from "@salesforce/schema/Tax__c.Code__c";
import Name from "@salesforce/schema/Tax__c.Name";
import TaxRate__c from "@salesforce/schema/Tax__c.TaxRate__c";
import BDate__c from "@salesforce/schema/Tax__c.BDate__c";
import EDate__c from "@salesforce/schema/Tax__c.EDate__c";
//APEX
import getData from "@salesforce/apex/VatSettingsCtrl.getData";
import saveData from "@salesforce/apex/VatSettingsCtrl.saveData";
//LABELS
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Ok from "@salesforce/label/c.LBL_Ok";
// Custom Labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_VATUpdateRate from "@salesforce/label/c.LBL_VATUpdateRate";
import LBL_Modify from "@salesforce/label/c.LBL_Modify";
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import MSG_VATUpdate from "@salesforce/label/c.MSG_VATUpdate";
import MSG_VATUpdateEnddate from "@salesforce/label/c.MSG_VATUpdateEnddate";
import MSG_VATUpdateRate from "@salesforce/label/c.MSG_VATUpdateRate";
import LBL_Please_Select_A_Record from "@salesforce/label/c.LBL_Please_Select_A_Record";
import LBL_VAT_Rate_Settings from "@salesforce/label/c.LBL_VAT_Rate_Settings";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_UpdateLog from "@salesforce/label/c.LBL_UpdateLog";
import LBL_Remove from "@salesforce/label/c.LBL_Remove";
import LBL_Actions from '@salesforce/label/c.LBL_Actions';

export default class VatSettings extends LightningElement {
    //LABELS
    @track labels = {
        LBL_Success,
        MSG_Successfully_Saved,
        LBL_Error,
        LBL_Warning,
        LBL_Ok,
        LBL_Save,
        LBL_Cancel,
        LBL_VATUpdateRate,
        LBL_Modify,
        LBL_Add,
        LBL_Delete,
        MSG_VATUpdate,
        MSG_VATUpdateEnddate,
        MSG_VATUpdateRate,
        LBL_Please_Select_A_Record,
        LBL_VAT_Rate_Settings,
        MSG_No_Changes_To_Save,
        LBL_UpdateLog,
        LBL_Remove,
        LBL_Actions,
        //objects and fields labels
        Tax__c: {}
    }
    API_NAMES = {
        Tax__c: {
            objectApiName: Tax__c.objectApiName,
            ListingOrder__c: ListingOrder__c.fieldApiName,
            BusinessUnitVAT__c: BusinessUnitVAT__c.fieldApiName,
            Code__c: Code__c.fieldApiName,
            Name: Name.fieldApiName,
            TaxRate__c: TaxRate__c.fieldApiName,
            BDate__c: BDate__c.fieldApiName,
            EDate__c: EDate__c.fieldApiName,
        }

    }
    @track recordName;
    // @track showRemoveButton = false;
    // Wire the getRecord method to fetch the record's details
    @wire(getRecord, { recordId: '$buId', fields: [Name] })
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

    // maps
    @track fieldsMap = {};
    picklistLabelsMap = {};
    @track selectedRow;
    @track selectedRowIndex;

    // Lists
    @track taxesList = [];
    @track orderOptions = [];
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
    connectedCallback() {
        this.loadData();
        addEventListener('resize', this.setPageSize);
    }

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
        headerLabelsMap['ListingOrder__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.ListingOrder__c].label;
        headerLabelsMap['BusinessUnitVAT__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.BusinessUnitVAT__c].label;
        headerLabelsMap['Code__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.Code__c].label;
        headerLabelsMap['Name'] = taxesFieldsMap[this.API_NAMES.Tax__c.Name].label;
        headerLabelsMap['TaxRate__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.TaxRate__c].label;
        headerLabelsMap['BDate__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.BDate__c].label;
        headerLabelsMap['EDate__c'] = taxesFieldsMap[this.API_NAMES.Tax__c.EDate__c].label;
        this.headerFieldsListLabels = { ...headerLabelsMap }
        this.deletedTaxes = [];
        this.selectedRow = '';
        this.selectedRowIndex = '';
        this.newEndDate = '';
        let tempOrderOptions = [];
        for (let key in data.picklistLabelsMap[this.API_NAMES.Tax__c.objectApiName + '-' + this.API_NAMES.Tax__c.ListingOrder__c]) {
            let value = data.picklistLabelsMap[this.API_NAMES.Tax__c.objectApiName + '-' + this.API_NAMES.Tax__c.ListingOrder__c][key];
            tempOrderOptions.push({ label: value, value: value })
        }
        this.orderOptions = tempOrderOptions;
        data.taxes.forEach(element => {
            element.isSelected = false;
            element.isEdited = false;
        });
        let tmpTaxesList = [];
        data.taxes.forEach(tax => {
            tmpTaxesList.push({
                Id: tax.Id,
                RecordTypeId: tax.RecordTypeId,
                ListingOrder__c: tax[this.API_NAMES.Tax__c.ListingOrder__c],
                BusinessUnitVAT__c: tax[this.API_NAMES.Tax__c.BusinessUnitVAT__c],
                Code__c: tax[this.API_NAMES.Tax__c.Code__c],
                Name: tax[this.API_NAMES.Tax__c.Name],
                TaxRate__c: tax[this.API_NAMES.Tax__c.TaxRate__c],
                BDate__c: tax[this.API_NAMES.Tax__c.BDate__c],
                EDate__c: tax[this.API_NAMES.Tax__c.EDate__c],
            });
        });
        this.taxesList = tmpTaxesList;
        this.isLoading = false;
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
            ListingOrder__c: null,
            BusinessUnitVAT__c: this.buId,
            Code__c: null,
            Name: null,
            TaxRate__c: null,
            BDate__c: null,
            EDate__c: null,
            isSelected: true,
            isnewRow: true,
            showRemoveButton: true,
            removeButtonClass: 'visible',
            addButtonClass: 'visible',
            editButtonClass: 'hidden',
            logEventButtonClass: 'hidden',
            deleteButtonClass: 'hidden',
        });
    }
    // handleEdit(event) {
    //     if (this.selectedRowIndex) {
    //         this.taxesList[this.selectedRowIndex].isSelected = true;
    //         this.taxesList[this.selectedRowIndex].isEdited = true;
    //         this.template.querySelectorAll('.rows')[this.selectedRowIndex].classList.add('slds-is-edited');

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
    @track toUpdateVATDate;
    @track toUpdateVAT = {};
    @track newVAT = {};
    @track newEndDate;
    handleUpdateVATSettings(event) {
        if (this.selectedRow) {
            this.showUpdateVATPopup = true;
        }
        else {
            this.showNotification('Warning', LBL_Please_Select_A_Record, 'warning');
        }
        let found = this.taxesList.find((element) => element.Id == this.selectedRow);
        this.toUpdateVATDate = found.EDate__c;
        this.toUpdateVAT.rate = found.TaxRate__c;
        this.toUpdateVAT.name = found.Name;
    }
    handleUpdateVATDate(event) {
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.newVAT = {};
        if (field == 'EDate__c') {
            this.newEndDate = value;
            let date = new Date(value);
            let date2 = new Date(date.getFullYear(), date.getMonth() + 1, 1);
            let nextMonth = date.getMonth() + 2;
            let year = date.getFullYear();
            let date100 = new Date(year + '-' + nextMonth + '-' + 1);
            if (nextMonth == 12) {
                nextMonth = 0;
                year++;
            }
            this.newVAT.Bdate = date100;
        }
        if (field == 'TaxRate__c') {
            this.newVAT.Rate = value;
        }
    }

    closeVATPopup() {
        this.showUpdateVATPopup = false;
    }
    @track popuphasError = false;
    // handleSaveVATPopup() {
    //     this.popuphasError = false;
    //     let requiredFields = this.template.querySelectorAll('.popupfield');
    //     let allValid = true;
    //     requiredFields.forEach(field => {
    //         if (!field.checkValidity()) {
    //             field.reportValidity();
    //             allValid = false;
    //         }
    //     });

    //     if (allValid) {
    //         let found = this.taxesList.find((element) => element.Id == this.selectedRow);
    //         let endDate;
    //         this.newEndDate ?
    //             found.EDate__c = this.newEndDate
    //             : this.newEndDate = found.EDate__c;
    //         let newDate = new Date(this.newEndDate);
    //         let nextMonth = newDate.getMonth() + 2;
    //         let year = newDate.getFullYear();
    //         let dayy = 1;
    //         let monthh = newDate.getMonth() + 2; // Months are zero-based
    //         let yearr = newDate.getFullYear();
    //         let formattedDay = dayy < 10 ? `0${dayy}` : dayy;
    //         let formattedMonth;
    //         if (monthh == 13) {
    //             formattedMonth = '01';
    //             yearr = yearr + 1;
    //         }
    //         else {
    //             formattedMonth = monthh < 10 ? `0${monthh}` : monthh;
    //         }
    //         let formattedDate = yearr + '-' + formattedMonth + '-' + formattedDay
    //         // next day 
    //         let nextDayDate = newDate.setDate(newDate.getDate() + 1);
    //         let nextDay = newDate.getDate();
    //         let currentMonth = newDate.getMonth() + 1; // Months are zero-based in JavaScript
    //         let currentYear = newDate.getFullYear();

    //         // Format the components with leading zeros
    //         let formattedDay2 = nextDay < 10 ? `0${nextDay}` : nextDay;
    //         let formattedMonth2 = currentMonth < 10 ? `0${currentMonth}` : currentMonth;

    //         // Combine the components into the desired format
    //         let formattedDate2 = `${currentYear}-${formattedMonth2}-${formattedDay2}`;
    //         this.taxesList.push({
    //             ListingOrder__c: found.ListingOrder__c,
    //             BusinessUnitVAT__c: this.buId,
    //             Code__c: found.Code__c,
    //             Name: found.Name,
    //             TaxRate__c: this.newVAT.Rate,
    //             BDate__c: formattedDate2,
    //             isSelected: false,
    //             isEdited: true

    //         });
    //         this.showUpdateVATPopup = false;
    //         this.newEndDate = '';
    //     }
    //     else {
    //         this.popuphasError = true;
    //     }

    // }

    // handleCancel(event) {
    //     const index = event.target.dataset.index;
    //     const cancelRow = this.taxesList[index];
    //     console.log('Row to cancel:', cancelRow);
    //     console.log('Row index:', index);
    //     if (cancelRow.isnewRow) {
    //         this.taxesList.splice(index, 1);
    //     } else {
    //         this.taxesList[index].isEdited = false;
    //         this.taxesList[index].isSelected = false;
    //         this.taxesList[index].showRemoveButton = false;
    //         this.taxesList[index].editButtonClass = 'visible';
    //         this.taxesList[index].logEventButtonClass = 'visible';
    //         this.taxesList[index].deleteButtonClass = 'visible';
    //         this.taxesList[index].removeButtonClass = 'hidden';
    //     }
    //     this.template.querySelectorAll('.rows')[index].classList.remove('slds-is-edited');
    // }

    handleCancel(event) {
        const index = event.target.dataset.index;
        const cancelRow = this.taxesList[index];
        this.template.querySelectorAll('.rows')[index].classList.remove('slds-is-edited');
        if (cancelRow.isnewRow) {
            this.taxesList.splice(index, 1);
        } else {
            this.taxesList[index].isEdited = false;
            this.taxesList[index].isSelected = false;
            this.taxesList[index].showRemoveButton = false;
            this.taxesList[index].editButtonClass = 'visible';
            this.taxesList[index].logEventButtonClass = 'visible';
            this.taxesList[index].deleteButtonClass = 'visible';
            this.taxesList[index].removeButtonClass = 'hidden';
            let found = this.taxesList.find((element) => element.Id == this.selectedRow);
            found.EDate__c = this.toUpdateVATDate;
            found.TaxRate__c = this.toUpdateVAT.rate;
            this.taxesList = this.taxesList.filter((row) => !row.isNewVatRow);
            this.newEndDate = '';
            this.newVAT = {};
        }
    }


    @track hasError = false;

    handleSave() {
        this.hasError = false;
        let requiredFields = this.template.querySelectorAll('.requiredField');
        let allValid = true;
        requiredFields.forEach(field => {
            let row = field.closest('tr');
            if (row && !row.classList.contains('slds-is-deleted') && !row.classList.contains('newRow')) {
                if (!field.checkValidity()) {
                    field.reportValidity();
                    allValid = false;
                }
            }
        });
        const hasChanges = this.taxesList.some(tax => tax.isEdited || tax.isnewRow);
        const hasDeletions = this.deletedTaxes.length > 0;
        if (allValid) {
            if (hasChanges || hasDeletions) {
                this.isLoading = true;
                let filteredTaxesList = this.taxesList.filter(tax => !tax.isDeleted);
                this.taxesList = filteredTaxesList;
                let toUpdate = [];
                let toInsert = [];
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
                    let taxToUpsert = {
                        Id: tax.Id,
                        RecordTypeId: tax.RecordTypeId,
                        [this.API_NAMES.Tax__c.ListingOrder__c]: tax.ListingOrder__c,
                        [this.API_NAMES.Tax__c.BusinessUnitVAT__c]: this.buId,
                        [this.API_NAMES.Tax__c.Code__c]: tax.Code__c,
                        [this.API_NAMES.Tax__c.Name]: tax.Name,
                        [this.API_NAMES.Tax__c.TaxRate__c]: tax.TaxRate__c,
                        [this.API_NAMES.Tax__c.BDate__c]: tax.BDate__c,
                        [this.API_NAMES.Tax__c.EDate__c]: tax.EDate__c,
                    }
                    if (taxToUpsert.Id) {
                        toUpdate.push(taxToUpsert);
                    } else {
                        toInsert.push(taxToUpsert);
                    }
                });
                saveData({
                    taxesToInsertJSON: JSON.stringify(toInsert),
                    taxesToUpdateJSON: JSON.stringify(toUpdate),
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
                    this.isLoading = false;
                }).catch(error => {
                    this.showNotification('Error', error.message, 'error');
                    console.log('%c' + error.message, 'color : red');
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
    handleFieldEdits(event) {
        let dataIndex = event.target.dataset.index;
        let field = event.target.dataset.field;
        let value = event.target.value;
        this.taxesList[dataIndex][field] = value;
        if (field === 'ListingOrder__c') {
            let currentOrder = this.taxesList[dataIndex].ListingOrder__c;
            let found = this.taxesList.find((element, index) => index !== dataIndex && element.ListingOrder__c === currentOrder);
            if (found) {
                this.taxesList[dataIndex].isRequired = true;
                let inputElement = this.template.querySelector(`lightning-input[data-field="EDate__c"][data-index="${dataIndex}"]`);
                if (inputElement) {
                    inputElement.setAttribute('required', 'true');
                    inputElement.classList.add('requiredField');
                } else {
                }
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
    // connectedCallback() {
    //     this.loadData();
    // }
    // renderedCallback() {
    //     try {
    //     } catch (error) {
    //         console.log('%c' + error.message, 'color : red');
    //         console.log('%c' + error.body?.message, 'color : red');
    //     }
    // }

    renderedCallback() {
        try {
            this.setPageSize();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.loading = true;
        }
    }

    handleEditRow(event) {
        const index = event.target.dataset.index;
        let tax = this.taxesList[index];
        tax.isSelected = true;
        tax.isEdited = true;
        this.template.querySelectorAll('.rows')[index].classList.add('slds-is-edited');
        tax.showRemoveButton = true;
        tax.editButtonClass = 'hidden';
        tax.logEventButtonClass = 'hidden';
        tax.deleteButtonClass = 'hidden';
        tax.removeButtonClass = 'visible';
    }

    handleDeleteRow(event) {
        const index = event.target.dataset.index;
        const deletedRow = this.taxesList[index];
        deletedRow.showRemoveButton = true;
        deletedRow.editButtonClass = 'hidden';
        deletedRow.logEventButtonClass = 'hidden';
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
                tax.logEventButtonClass = 'visible';
                tax.deleteButtonClass = 'visible';
                tax.removeButtonClass = 'hidden';
            }
        });
    }

    handleUpdateRow(event) {
        try {
            let dataIndex = event.target.dataset.index;
            this.selectedRow = this.taxesList[dataIndex].Id;
            this.selectedRowIndex = dataIndex;
            if (this.selectedRow) {
                this.showUpdateVATPopup = true;
            }
            else {
                this.showNotification('Warning', LBL_Please_Select_A_Record, 'warning');
            }
            let found = this.taxesList.find((element) => element.Id == this.selectedRow);
            this.toUpdateVATDate = found.EDate__c;
            this.toUpdateVAT.rate = found.TaxRate__c;
            this.toUpdateVAT.name = found.Name;
            this.taxesList[dataIndex].showRemoveButton = true;
            this.taxesList[dataIndex].editButtonClass = 'hidden';
            this.taxesList[dataIndex].logEventButtonClass = 'hidden';
            this.taxesList[dataIndex].deleteButtonClass = 'hidden';
            this.taxesList[dataIndex].removeButtonClass = 'visible';
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }

    }

    handleSaveVATPopup() {
        this.popuphasError = false;
        let requiredFields = this.template.querySelectorAll('.popupfield');
        let allValid = true;
        requiredFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                allValid = false;
            }
        });

        if (allValid) {
            let found = this.taxesList.find((element) => element.Id == this.selectedRow);
            let endDate;
            this.newEndDate ?
                found.EDate__c = this.newEndDate
                : this.newEndDate = found.EDate__c;
            let newDate = new Date(this.newEndDate);
            let nextMonth = newDate.getMonth() + 2;;
            let year = newDate.getFullYear();
            let dayy = 1;
            let monthh = newDate.getMonth() + 2;
            let yearr = newDate.getFullYear();
            let formattedDay = dayy < 10 ? `0${dayy}` : dayy;
            let formattedMonth;
            if (monthh == 13) {
                formattedMonth = '01';
                yearr = yearr + 1;
            }
            else {
                formattedMonth = monthh < 10 ? `0${monthh}` : monthh;
            }
            let formattedDate = yearr + '-' + formattedMonth + '-' + formattedDay
            let nextDayDate = newDate.setDate(newDate.getDate() + 1);
            let nextDay = newDate.getDate();
            let currentMonth = newDate.getMonth() + 1;
            let currentYear = newDate.getFullYear();
            let formattedDay2 = nextDay < 10 ? `0${nextDay}` : nextDay;
            let formattedMonth2 = currentMonth < 10 ? `0${currentMonth}` : currentMonth;
            let formattedDate2 = `${currentYear}-${formattedMonth2}-${formattedDay2}`;
            this.taxesList.push({
                ListingOrder__c: found.ListingOrder__c,
                BusinessUnitVAT__c: this.buId,
                Code__c: found.Code__c,
                Name: found.Name,
                TaxRate__c: this.newVAT.Rate,
                BDate__c: formattedDate2,
                isSelected: false,
                isEdited: true,
                isNewVatRow: true
            });
            this.showUpdateVATPopup = false;
            this.newEndDate = '';
        }
        else {
            this.popuphasError = true;
        }

    }

}