import { api, track, LightningElement } from 'lwc';
import { API_NAMES, tableFields, Labels, defaultValues } from './properties';
import Toast from 'lightning/toast';
import loadData from '@salesforce/apex/MassPaymentManagerCtrl.loadData';
import createPayments from '@salesforce/apex/MassPaymentManagerCtrl.createPayments';
import getRelatedDetailsLinked from '@salesforce/apex/MassPaymentManagerCtrl.getRelatedDetailsLinked';

export default class MassPaymentManager extends LightningElement {
    @api massPaymentFilter;
    @api selectedFilter;
    @track labels = Labels;
    @track fieldsWrapperList = [];
    @track recordsWrapperList = [];
    @track invoicesList = []
    @track popup = {
        visibility: false,
        title: '',
        body: '',
        subBody: '',
        submitBtnClass: '',
        submitBtn: '',
        cancelBtn: ''
    }
    @track isLoading = true;
    @track allSelected = true;
    componentName = 'MassPaymentManager';
    relatedDetailsLink = {};
    invalidFieldsContainer = [];
    defaultMassPaymentList = {};
    nbOfFixedColumns = 2;

    // 🚀 ~ onLoad
    connectedCallback() {
        this.loadData();
        window.addEventListener('resize', this.resize.bind(this))
    }

    renderedCallback() {
        this.resize();
    }

    loadData() {
        this.defaultMassPaymentList = this.massPaymentFilter.defaultPayment;
        const invoiceIds = this.massPaymentFilter.invoicesID;
        const fields = this.fields();
        loadData({ invoiceIds: invoiceIds, fieldsParam: JSON.stringify(fields) })
            .then(result => {
                const parsedResult = JSON.parse(result);
                this.invoicesList = JSON.parse(JSON.stringify(parsedResult.invoicesList));
                this.fieldsWrapperList = this.buildFieldWrapper(parsedResult.paymentFields) || [];
                this.recordsWrapperList = this.buildDataWrapper(parsedResult?.invoicesList) || [];
                this.isLoading = false;
            }).catch(error => {
                console.log('%c' + (error?.body?.message || error?.message), 'color : red');
            });
    }

    fields() {
        const fields = Object.values(tableFields).flatMap(group => Object.values(group))
        return fields;
    }

    resize() {
        const header = this.template.querySelector('.header');
        const main = this.template.querySelector('.main');
        const body = this.template.querySelector('.negoptim-tablesection');
        if (header && main && body) {
            body.style.height = (main.offsetHeight - header.offsetHeight - 20) + 'px';
            this.setnumberOfFixedColumns();
        }
    }

    // 🚀 ~ Build Table Data"
    buildFieldWrapper(colFields) {
        try {
            let fieldsList = [];
            colFields.forEach(field => {
                let fieldWrapper = {
                    objectName: field.objectName,
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldHelpText: field.fieldHelpText,
                    fieldType: field.fieldType,
                    pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                    selectedValues: [],
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                    isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextArea: field.fieldType == 'TEXTAREA',
                    scale: field.scale || 0,
                    link: '',
                    style: 'min-width: 200px; max-width:200px; overflow-wrap: break-word;',
                    value: null,
                }
                fieldsList.push(fieldWrapper);
            });
            return fieldsList;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    buildDataWrapper(invoicesList) {
        const invoiceRecords = invoicesList.map(record => {
            record.InvoiceDetail__r = record[API_NAMES.Invoice__c.INVDInvoice__r]?.records;
            record.InvoiceLink__r = record[API_NAMES.Invoice__c.INVLInvoice__r]?.records;
            record.fieldsIndex = record[API_NAMES.Invoice__c.INVDInvoice__r]?.records.length;
            delete record[API_NAMES.Invoice__c.INVLInvoice__r]?.records;
            delete record[API_NAMES.Invoice__c.INVDInvoice__r]?.records;
            return record;
        });
        this.getRelatedDetailsLinked(invoiceRecords);
        invoiceRecords.forEach(invoiceRecord => {
            let records = [];
            invoiceRecord.valid = true;
            invoiceRecord.columns = [];
            let fields = structuredClone(this.fieldsWrapperList);
            invoiceRecord.InvoiceDetail__r.forEach((invD, invDIndex) => {
                let invDRecord = [];
                fields.forEach(field => {
                    let newfield = structuredClone(field);
                    const fieldRow = (newfield.objectName == API_NAMES.Invoice__c.objectApiName ? invoiceRecord : invD);
                    if ((tableFields.mergedFieldsStart[newfield.fieldName] && invDIndex !== 0)
                        || (tableFields.mergedFieldsEnd[newfield.fieldName] && invDIndex !== 0)) {
                        return;
                    }
                    newfield.rowspan = (tableFields.mergedFieldsStart[newfield.fieldName] || tableFields.mergedFieldsEnd[newfield.fieldName]) && invDIndex === 0 ? invoiceRecord.fieldsIndex : 1;
                    if (newfield.objectName !== API_NAMES.Payment__c.objectApiName) {
                        if (newfield.isReference) {
                            if (newfield.fieldName.endsWith('Id')) {
                                newfield.value = fieldRow[newfield.fieldName.replace('Id', '')]?.Name;
                            } else {
                                newfield.value = fieldRow[newfield.fieldName.replace('__c', '__r')]?.Name;
                                newfield.style = 'min-width: 150px;'
                            }
                            newfield.link = '/' + newfield.value;
                            if (fieldRow[API_NAMES.InvoiceDetail__c.RestToPaidAmountwVAT__c] < 1) {
                                fieldRow.valid = false;
                            }
                        } else if (newfield.fieldName == API_NAMES.Invoice__c.InvNumber__c) {
                            newfield.value = fieldRow[API_NAMES.Invoice__c.InvNumber__c];
                            newfield.link = `/${fieldRow.Id}`;
                            newfield.isLink = true;
                        } else if (newfield.isPicklist) {
                            let found = newfield.pickListValues.find(item => item.value === fieldRow[newfield.fieldName]);
                            newfield.value = found?.label;

                        } else if (newfield.fieldName.includes('.')) {
                            let values = newfield.fieldName.split('.');
                            for (let index = 0; index < values.length; index++) {
                                let val = index == 0 ? fieldRow : newfield.value;
                                if (val) {
                                    if (index == values.length - 1 && ((newfield.isReference && newfield.fieldName != 'Name') || newfield.fieldName.endsWith('RecordTypeId'))) {
                                        newfield.value = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                        newfield.value = '/' + val[values[index]];
                                    } else {
                                        newfield.value = val[values[index]];
                                    }
                                }
                            }
                        } else if (newfield.isNumberField) {
                            newfield.value = fieldRow[newfield.fieldName];
                            newfield.style = 'text-align: right;'
                        } else {
                            newfield.value = fieldRow[newfield.fieldName];
                        }
                        newfield.isEditable = false
                    } else {
                        newfield.isEditable = true;
                        if (newfield.isPicklist) {
                            if (newfield.fieldName == 'SupplierCreditNote') {
                                newfield.isEditable = invoiceRecord.InvoiceLink__r ? true : false;
                                newfield.value = this.labels.LBL_None;
                                invoiceRecord['SupplierCreditNote'] = this.labels.LBL_None;
                                let pickListValues = [
                                    {
                                        label: this.labels.LBL_None,
                                        value: this.labels.LBL_None,
                                    }
                                ]
                                if (invoiceRecord.InvoiceLink__r) {
                                    invoiceRecord?.InvoiceLink__r?.map(item =>
                                        pickListValues.push(
                                            {
                                                label: item[API_NAMES.InvoiceLink__c.InvoiceLinked__r][API_NAMES.Invoice__c.InvNumber__c],
                                                value: item[API_NAMES.InvoiceLink__c.InvoiceLinked__r][API_NAMES.Invoice__c.InvNumber__c],
                                            }
                                        )
                                    )
                                }
                                newfield.pickListValues = pickListValues;
                            } else {
                                newfield.value = this.defaultMassPaymentList[newfield.fieldName] ? this.defaultMassPaymentList[newfield.fieldName] : '';
                                if (newfield.fieldName == API_NAMES.Payment__c.PaymentType__c) {
                                    newfield.style = 'max-width: fit-content;'
                                }
                            }
                        } else if (newfield.isDate) {
                            if (newfield.fieldName == API_NAMES.Payment__c.EffectiveDate__c && this.defaultMassPaymentList[API_NAMES.Payment__c.PaymentType__c] !== 'Effect') {
                                newfield.isHidden = true;
                            }
                            newfield.value = this.defaultMassPaymentList[newfield.fieldName] ? this.defaultMassPaymentList[newfield.fieldName] : new Date().toISOString().split('T')[0];
                        } else if (newfield.isNumberField) {
                            newfield.step = 1 / Math.pow(10, newfield.scale);
                            if ([API_NAMES.Payment__c.AmountwVAT__c, API_NAMES.Payment__c.VATAmount__c].includes(newfield.fieldName)) {
                                const fieldApiName = [API_NAMES.Payment__c.AmountwVAT__c] == newfield.fieldName ? API_NAMES.Invoice__c.RestToPaidAmountwVAT__c : API_NAMES.Invoice__c.RestToPaidVATAmount__c
                                newfield.value = invD[fieldApiName];
                                invD[newfield.fieldName] = invD[fieldApiName];
                            } else {
                                newfield.value = this.defaultMassPaymentList[newfield.fieldName] ? this.defaultMassPaymentList[newfield.fieldName] : 0
                            }
                        } else if (newfield.isTextArea) {
                            newfield.value = this.defaultMassPaymentList[newfield.fieldName] ? this.defaultMassPaymentList[newfield.fieldName] : ''
                        } else if (newfield.isBoolean) {
                            //
                        }
                    }
                    invDRecord.push(newfield);
                })
                if (invDIndex == 0) {
                    invDRecord.unshift({
                        fieldName: 'selected',
                        value: true,
                        rowspan: invoiceRecord.fieldsIndex,
                        isBoolean: true,
                        isEditable: true
                    })
                }
                records.push(invDRecord)
            })
            // Set Default Values
            Object.entries(this.defaultMassPaymentList).forEach(([key, value]) => {
                invoiceRecord[key] = value;
            });
            invoiceRecord.selected = this.allSelected;
            invoiceRecord.columns = records;
        });
        // remove invalid Record
        return invoiceRecords.filter(item => item.valid);
    }

    changeInvoiceCreditNote(data) {
        const { isSuplierCreditNote, recordIndex, columnIndex, invoiceNumber } = data;
        let record = {};
        let creditNoteRecord = {};
        let invDRecord = {};
        invDRecord = this.recordsWrapperList[recordIndex].InvoiceDetail__r[columnIndex];
        record = invDRecord;
        if (isSuplierCreditNote) {
            creditNoteRecord = this.recordsWrapperList[recordIndex]?.InvoiceLink__r.find(
                i => i[API_NAMES.InvoiceLink__c.InvoiceLinked__r][API_NAMES.Invoice__c.InvNumber__c] == invoiceNumber)[API_NAMES.InvoiceLink__c.InvoiceLinked__r];
            record = creditNoteRecord
        }
        this.recordsWrapperList[recordIndex].columns[columnIndex].forEach(item => {
            if ([API_NAMES.InvoiceDetail__c.RestToPaidVATAmount__c, API_NAMES.InvoiceDetail__c.RestToPaidAmountwVAT__c].includes(item.fieldName)) {
                item.value = record[item.fieldName]
            } else if ([API_NAMES.Payment__c.AmountwVAT__c, API_NAMES.Payment__c.VATAmount__c].includes(item.fieldName)) {
                const fieldApiName = [API_NAMES.Payment__c.AmountwVAT__c] == item.fieldName ? API_NAMES.Invoice__c.RestToPaidAmountwVAT__c : API_NAMES.Invoice__c.RestToPaidVATAmount__c
                item.value = isSuplierCreditNote ? Math.min(creditNoteRecord[fieldApiName], invDRecord[fieldApiName]) : record[fieldApiName];
                if (isSuplierCreditNote) {
                    creditNoteRecord[item.fieldName] = creditNoteRecord[fieldApiName];
                }
            }
        })
    }

    getRelatedDetailsLinked(data) {
        const isValid = data.some(inv => inv?.InvoiceLink__r?.length > 0);
        if (!isValid) return {};
        const invoiceIds = data.flatMap(inv => {
            return inv.InvoiceLink__r?.map(invL => invL[API_NAMES.InvoiceLink__c.InvoiceLinked__r].Id);
        });
        const invoiceDetailIds = data.flatMap(inv => {
            return inv.InvoiceDetail__r.map(invD => invD.Id);
        });
        getRelatedDetailsLinked({ invoiceIds: invoiceIds, invoiceDetailIds: invoiceDetailIds })
            .then(result => {
                const parsedResult = JSON.parse(result);
                const data = {}
                parsedResult.map(item => {
                    if (data[item.Invoice__c] == null) {
                        data[item.Invoice__c] = item.Id;
                    }
                })
                this.relatedDetailsLink = data;
            }).catch(error => {
                console.log('%c' + (error?.body?.message || error?.message), 'color : red');
            })
    }

    // End ~ Build Table Data

    // 🚀 ~ handle Stylation
    setnumberOfFixedColumns() {
        let tables = this.template.querySelectorAll('.main-table');
        let headers = this.template.querySelectorAll('.main-header');
        let maxCols = 0;
        for (let table of tables) {
            for (let tr of table?.rows) {
                if (tr.children.length > maxCols) {
                    maxCols = tr.children.length;
                }
            }
        }
        for (const table of tables) {
            let tableTrs = table?.rows
            if (tableTrs) {
                let top = 0;
                for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                    let childrens = tableTrs[index].children;
                    let left = 0;
                    for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                        if (index2 < this.nbOfFixedColumns && childrens.length + (index2 + 1) > maxCols) {
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.left = (left - (index2 + 1)) + 'px';
                            childrens[index2].style.zIndex = 10;
                            left += childrens[index2].offsetWidth;
                            childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                        } else {
                            childrens[index2].style.position = 'unset';
                            childrens[index2].style.left = 'unset';
                            childrens[index2].style.zIndex = 'unset';
                        }
                    }
                }
            }
        }
        let left = 0;
        for (let index = 0; headers && index < headers.length; index++) {
            let childrens = headers[index];
            if (index < this.nbOfFixedColumns) {
                childrens.style.position = 'sticky';
                childrens.style.left = ((left - (index + 1)) + 'px');
                childrens.style.zIndex = 1;
                left += childrens.offsetWidth;
            } else {
                childrens.style.position = 'relative';
                childrens.style.left = 'unset';
                childrens.style.zIndex = 'unset';
            }
        }
    }
    // 🚀 ~ handle Methods
    handleFieldEdits(event) {
        const field = event.target.dataset.field;
        const recordIndex = event.target.dataset.index;
        const columnIndex = event.target.dataset.columnindex;
        const value = event.target.value;
        let suplierCreditNote = this.recordsWrapperList[recordIndex].columns[columnIndex].find(item => item.fieldName == 'SupplierCreditNote').value;
        if (field == API_NAMES.Payment__c.AmountwVAT__c || field == API_NAMES.Payment__c.VATAmount__c) {
            let creditNoteRecord = {};
            let invDRecord = this.recordsWrapperList[recordIndex].InvoiceDetail__r[columnIndex];
            const fieldApiName = [API_NAMES.Payment__c.AmountwVAT__c] == field ? API_NAMES.Invoice__c.RestToPaidAmountwVAT__c : API_NAMES.Invoice__c.RestToPaidVATAmount__c;
            if (suplierCreditNote != this.labels.LBL_None) {
                creditNoteRecord = this.recordsWrapperList[recordIndex]?.InvoiceLink__r.find(i => i[API_NAMES.InvoiceLink__c.InvoiceLinked__r][API_NAMES.Invoice__c.InvNumber__c] == suplierCreditNote)[API_NAMES.InvoiceLink__c.InvoiceLinked__r];
            }
            if ((suplierCreditNote != this.labels.LBL_None && value > Math.min(creditNoteRecord[fieldApiName], invDRecord[fieldApiName])) || (value > invDRecord[fieldApiName])) {
                this.invalidFieldsContainer.push(event.target);
                return;
            }
            if (suplierCreditNote != this.labels.LBL_None) {
                creditNoteRecord[field] = value;
            }
            if (this.invalidFieldsContainer.includes(event.target)) {
                this.invalidFieldsContainer = this.invalidFieldsContainer.filter(item => item !== event.target);
                event.target.setCustomValidity('');
                event.target.reportValidity();
            }

        } else if ((field == API_NAMES.Payment__c.AmountwVAT__c &&
            value > this.recordsWrapperList[recordIndex].columns[columnIndex].find(i => i.fieldName == API_NAMES.InvoiceDetail__c.RestToPaidAmountwVAT__c).value) ||
            (field == API_NAMES.Payment__c.VATAmount__c &&
                value > this.recordsWrapperList[recordIndex].columns[columnIndex].find(i => i.fieldName == API_NAMES.InvoiceDetail__c.RestToPaidVATAmount__c).value)) {
            this.invalidFieldsContainer.push(event.target);
            return;
        }
        if (field == API_NAMES.Payment__c.PaymentType__c) {
            const effectiveDate = this.recordsWrapperList[recordIndex].columns[columnIndex].find(i => i.fieldName == API_NAMES.Payment__c.EffectiveDate__c);
            effectiveDate.isHidden = (value !== 'Effect');
            this.recordsWrapperList[recordIndex][API_NAMES.Payment__c.EffectiveDate__c] = value === 'Effect' ? new Date().toISOString().split('T')[0] : null;
        }
        if (tableFields.mergedFieldsStart[field] || tableFields.mergedFieldsEnd[field] || field == 'selected') {
            this.recordsWrapperList[recordIndex][field] = value || event.target.checked || '';
        } else if (suplierCreditNote != this.labels.LBL_None) {
            const creditNoteRecord = this.recordsWrapperList[recordIndex]?.InvoiceLink__r.find(i =>
                i[API_NAMES.InvoiceLink__c.InvoiceLinked__r][API_NAMES.Invoice__c.InvNumber__c] == suplierCreditNote)[API_NAMES.InvoiceLink__c.InvoiceLinked__r];

            creditNoteRecord[field] = value || event.target.checked || '';
        } else {
            this.recordsWrapperList[recordIndex].InvoiceDetail__r[columnIndex][field] = value || event.target.checked || '';
        }
        if (field == 'SupplierCreditNote') {
            let supplierCreditNoteParam = {
                isSuplierCreditNote: event.target.value != this.labels.LBL_None,
                recordIndex: recordIndex,
                columnIndex: columnIndex,
                invoiceNumber: event.target.value
            };
            this.recordsWrapperList[recordIndex].columns[columnIndex].find(item => item.fieldName == 'SupplierCreditNote').value = event.target.value;
            this.changeInvoiceCreditNote(supplierCreditNoteParam);
        }
    }

    handleCreatePayments() {
        if (this.invalidFieldsContainer.length > 0) {
            this.showNotification(this.labels.LBL_Error, this.labels.LBL_MassPayment_AmountError, 'error');
            this.invalidFieldsContainer.map(inputs => {
                inputs.setCustomValidity(this.labels.LBL_MassPayment_AmountError);
                inputs.reportValidity();
            })
            return;
        }
        const selectedRecords = [...this.recordsWrapperList.filter(item => item.selected)];
        if (selectedRecords.length === 0) {
            this.showNotification(this.labels.LBL_Info, this.labels.LBL_Connect_InvoiceManager_SelectError, 'error');
            return;
        } else {
            this.popup = {
                title: this.labels.LBL_MassPayment_PopupTitle,
                body: this.labels.LBL_MassPayment_PopupWarningMsg,
                subBody: this.labels.LBL_MassPayment_PopupNextMsg,
                submitBtn: this.labels.LBL_MassPayment_PopupNextButton,
                submitBtnClass: 'slds-button slds-button_brand',
                cancelBtn: this.labels.LBL_MassAction_CancelButton,
            }
            this.popupNotification().then(submmited => {
                this.popup.visibility = false;
                if (submmited) {
                    this.popup = {
                        title: this.labels.LBL_MassPayment_PopupTitle,
                        body: this.labels.LBL_MassPayment_ConfirmMessage,
                        submitBtn: this.labels.LBL_MassAction_ConfirmButton,
                        submitBtnClass: 'slds-button slds-button_brand'
                    }
                    this.popupNotification().then(submmited => {
                        this.popup.visibility = false;
                        this.isLoading = true;
                        this.createPaymentsData(selectedRecords, (err, result) => {
                            this.isLoading = false;
                            if (err) {
                                this.showNotification(this.labels.LBL_Error, err, 'error');
                            } else {
                                this.showNotification(this.labels.LBL_Info, this.labels.LBL_Success, 'success');
                                this.isLoading = true;
                                setTimeout(() => {
                                    this.handleBackButton();
                                }, 4000);
                            }
                        })
                    })
                }
            })
        }
    }

    handleSelectAll(event) {
        this.allSelected = event.target.checked;
        this.recordsWrapperList.forEach(item => {
            item.selected = this.allSelected;
        })
    }
    //End ~ handle Methods

    // 🚀 ~ Create Payment
    createPaymentsData(data, callback) {
        try {
            const dataToInsert = this.populatePaymentsData(data);
            if (dataToInsert.length) {
                createPayments({
                    dataToInsert: JSON.stringify(dataToInsert),
                    invoicesListJson: JSON.stringify(this.invoicesList)
                }).then(data => {
                    if (callback && typeof callback === 'function') {
                        callback(null, data);
                    }
                }).catch(err => {
                    console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                    callback(err, null);
                })
            } else {
                if (callback && typeof callback === 'function') {
                    callback(null, data);
                }
            }
        } catch (e) {
            callback(e, null);
            return;
        }
    }

    populatePaymentsData(data) {
        const paymendWrapper = [];
        structuredClone(data).map(record => {
            record[API_NAMES.Payment__c.isOverdue__c] = false;
            let paymentDetails = [];
            let totalAmountwVAT = 0;
            let totalVATAmount = 0;
            let totalOverdueTVA = 0;
            let totalOverdueTTC = 0;
            record.columns.forEach((col, colIndex) => {
                const suplierCreditNote = col.find(item => item.fieldName == 'SupplierCreditNote').value;
                if (suplierCreditNote == this.labels.LBL_None) {
                    let invD = Object.values(record.InvoiceDetail__r)[colIndex];
                    if (record[API_NAMES.Payment__c.isOverdue__c] != true) {
                        record[API_NAMES.Payment__c.isOverdue__c] = (invD[API_NAMES.Payment__c.PaymentTVA] > 0 || invD.PaymentTTC > 0)
                    }
                    totalAmountwVAT += Number(invD[API_NAMES.Payment__c.AmountwVAT__c]) || 0;
                    totalVATAmount += Number(invD[API_NAMES.Payment__c.VATAmount__c]) || 0;
                    totalOverdueTVA += Number(invD.PaymentTVA) || 0;
                    totalOverdueTTC += Number(invD.PaymentTTC) || 0;
                    paymentDetails.push({
                        ...defaultValues.PaymentDetail__c.default,
                        [API_NAMES.PaymentDetail__c.InvoiceDetail__c]: invD.Id,
                        [API_NAMES.PaymentDetail__c.PayDCurrencyIsoCode]: invD[API_NAMES.Payment__c.CurrencyIsoCode],
                        [API_NAMES.PaymentDetail__c.AmountwVAT__c]: invD[API_NAMES.PaymentDetail__c.AmountwVAT__c],
                        [API_NAMES.PaymentDetail__c.VATAmount__c]: invD[API_NAMES.PaymentDetail__c.VATAmount__c],
                    })
                } else {
                    let creditNoteRecord = record.InvoiceLink__r?.find(i =>
                        i[API_NAMES.InvoiceLink__c.InvoiceLinked__r][API_NAMES.Invoice__c.InvNumber__c] == suplierCreditNote)[API_NAMES.InvoiceLink__c.InvoiceLinked__r];
                    if (record[API_NAMES.Payment__c.isOverdue__c] != true) {
                        record[API_NAMES.Payment__c.isOverdue__c] = (creditNoteRecord.PaymentTVA > 0 || creditNoteRecord.PaymentTTC > 0)
                    }
                    totalAmountwVAT += Number(creditNoteRecord[API_NAMES.Payment__c.AmountwVAT__c]) || 0;
                    totalVATAmount += Number(creditNoteRecord[API_NAMES.Payment__c.VATAmount__c]) || 0;
                    totalOverdueTVA += Number(creditNoteRecord.PaymentTVA) || 0;
                    totalOverdueTTC += Number(creditNoteRecord.PaymentTTC) || 0;
                    paymentDetails.push({
                        ...defaultValues.PaymentDetail__c.creditNote,
                        [API_NAMES.PaymentDetail__c.InvoiceDetail__c]: this.relatedDetailsLink[creditNoteRecord.Id],
                        [API_NAMES.PaymentDetail__c.PayDCurrencyIsoCode]: creditNoteRecord[API_NAMES.Payment__c.CurrencyIsoCode],
                        [API_NAMES.PaymentDetail__c.AmountwVAT__c]: creditNoteRecord[API_NAMES.PaymentDetail__c.AmountwVAT__c],
                        [API_NAMES.PaymentDetail__c.VATAmount__c]: creditNoteRecord[API_NAMES.PaymentDetail__c.VATAmount__c],
                    })
                }
            })
            const payment = {
                ...defaultValues.Payment__c,
                [API_NAMES.Payment__c.EffectiveDate__c]: record[API_NAMES.Payment__c.EffectiveDate__c],
                [API_NAMES.Payment__c.PaymentDate__c]: record[API_NAMES.Payment__c.PaymentDate__c],
                [API_NAMES.Payment__c.PaymentType__c]: record[API_NAMES.Payment__c.PaymentType__c],
                [API_NAMES.Payment__c.ExchangeRate__c]: record[API_NAMES.Payment__c.ExchangeRate__c],
                [API_NAMES.Payment__c.CurrencyIsoCode]: record[API_NAMES.Payment__c.CurrencyIsoCode],
                [API_NAMES.Payment__c.BusinessUnitSeller__c]: record[API_NAMES.Invoice__c.BusinessUnitSeller__c],
                [API_NAMES.Payment__c.SupplierBuyer__c]: record[API_NAMES.Invoice__c.SupplierBuyer__c],
                [API_NAMES.Payment__c.isOverdue__c]: record[API_NAMES.Payment__c.isOverdue__c],
                // [API_NAMES.Payment__c.InvoiceDocLinked__c]: record.Id,
                [API_NAMES.Payment__c.AmountwVAT__c]: totalAmountwVAT + totalOverdueTTC,
                [API_NAMES.Payment__c.VATAmount__c]: totalVATAmount + totalOverdueTVA,
                [API_NAMES.Payment__c.Reference__c]: record[API_NAMES.Payment__c.Reference__c],
                [API_NAMES.Payment__c.BankingInformation__c]: record[API_NAMES.Payment__c.BankingInformation__c],
                [API_NAMES.Payment__c.Note__c]: record[API_NAMES.Payment__c.Note__c]
            }
            if (payment[API_NAMES.Payment__c.VATAmount__c] === 0 && payment[API_NAMES.Payment__c.AmountwVAT__c] === 0) {
                return;
            }
            paymendWrapper.push({
                payment: payment,
                // PaymentDetail__c Structure
                paymentDetails: paymentDetails,
                invoiceId: record.Id, /*{
                    Id: record.Id,
                    [API_NAMES.Invoice__c.Name]: record[API_NAMES.Invoice__c.Name],
                    [API_NAMES.Invoice__c.InvNumber__c]: record[API_NAMES.Invoice__c.InvNumber__c],
                    [API_NAMES.Invoice__c.AccDoc__c]: record[API_NAMES.Invoice__c.AccDoc__c],
                    [API_NAMES.Invoice__c.TotalAmountwVAT__c]: record[API_NAMES.Invoice__c.TotalAmountwVAT__c],
                    [API_NAMES.Invoice__c.BusinessUnitSeller__c]: record[API_NAMES.Invoice__c.BusinessUnitSeller__c],
                    [API_NAMES.Invoice__c.SupplierBuyer__c]: record[API_NAMES.Invoice__c.SupplierBuyer__c]
                }*/
            })
        });
        return paymendWrapper
    }

    // 🚀 ~ Handle Back
    handleBackButton() {
        if (this.selectedFilter.parentPage && this.selectedFilter.parentPage != null) {
            const encodedFilters = encodeURIComponent(JSON.stringify(this.selectedFilter));
            const a = document.createElement('a');
            a.href = `/lightning/n/` + this.selectedFilter.parentPage + `?c__appliedfilters=${btoa(encodedFilters)}`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        } else if (window.history.length > 1) {
            window.history.back();
        }
    }

    // 🚀 ~ popup
    popupNotification() {
        this.popup.visibility = true;
        return new Promise((resolve, reject) => {
            this._PopupResolve = resolve
        });
    }

    submitPopUp(event) {
        const state = event.target.dataset.id == 'confirm' ? true : false;
        this._PopupResolve(state)
    }

    // 🚀 ~ Notificaton
    showNotification(title, message, variant, mode) {
        let errorMessage = message?.body?.message || message?.message || message;
        // create and show the alert
        Toast.show({
            label: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        }, this);
    }

    // 🚀 ~ Get Methods
    get colspanDisplayedFields() {
        let colspan = this.fieldsWrapperList.length;
        return colspan;
    }

    get isBackButtonDisabled() {
        return this.selectedFilter == null ? window.history.length === 0 : false;
    }

    get pageIcon() {
        return 'standard:change_request'
    }
}