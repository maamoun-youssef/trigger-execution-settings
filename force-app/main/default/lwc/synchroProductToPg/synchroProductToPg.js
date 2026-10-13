import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import initData from "@salesforce/apex/SynchroProductToPgController.initData";
import loadData from "@salesforce/apex/SynchroProductToPgController.loadData";
import ProductToPGBatch from "@salesforce/apex/SynchroProductToPgController.ProductToPGBatch";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Record_Type from "@salesforce/label/c.LBL_Record_Type";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Success from "@salesforce/label/c.LBL_Success";

export default class SynchroProductToPg extends LightningElement {
    @api recordId;
    @track firstThStyle = '';
    @track pageSize = 25;
    @track initDataWrapper = {};
    @track loadDataWrapper = {};
    @track records = [];
    @track displayedFields = [];
    selectedIds = new Set();
    tableStyle = '';
    pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];
    isLoading = false;
    labels = {LBL_No_Item_To_Display,
                LBL_First,
                LBL_Previous,
                LBL_Next,
                LBL_Last,
                LBL_Of,
                LBL_Error,
                LBL_Record_Type,
                LBL_Save,
                LBL_Success
            };

    connectedCallback() {
        this.initData();
    }

    renderedCallback() {
        try {
            setTimeout(() => {
                this.tableSize()
            }, 200);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.loading = true;
        }
    }

    tableSize() {
        let popUpBodyDiv = this.template.querySelector(".tableBody");
        if (!popUpBodyDiv) return;
        popUpBodyDiv.style.height = (window.innerHeight / 2) + "px";
    }

    initData() {
        try {
            this.isLoading = true;
            this.pageNumber = 1;
            initData().then(result => {
                        this.initDataWrapper = JSON.parse(result);
                        console.log('🎧 ~ relatedContracts.js:83 -> initDataWrapper: ', JSON.stringify(this.initDataWrapper));
                        this.pageSize = '' + this.initDataWrapper.gridSettingsManager.Default_Page_Size;
                        this.tableStyle = 'width: 100%;' + (this.cmpHeight ? 'height: ' + this.cmpHeight + '; min-height: ' + this.cmpHeight + ';' : 'height: ' + this.template.querySelector('.initial-table')?.offsetHeight + 'px;');
                        this.buildDisplayedFields();
                    }).catch(error => {
                        console.log('initData %c' + error.message, 'color : red');
                        console.log('initData %c' + error.body?.message, 'color : red');
                        this.isLoading = false;
                    })
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('initData: %c' + error.message, 'color : red');
            console.log('initData: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    // Builds the grid column definitions (displayed fields) from Apex data.
    buildDisplayedFields() {
        try {
            this.displayedFields = [];
            for (let field of this.initDataWrapper?.gridSettingsManager?.GRID_FIELDS) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.isNumberField,
                    isReference: field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    link: '',
                    scale: field.scale,
                    step: '',
                    isInputField: field.isInputField,
                    style: field.style,
                    headerStyle: field.stringHeaderStyle,
                    pickListValues: field.pickListValues,
                    isSortable: field.isSortable,
                    isFilterable: field.isFilterable,
                    isEncrypted: field.isEncrypted,
                    filterValue: '',
                    sortedField: false,
                    picklistColorsMap: field.picklistColorsMap,
                }
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.fieldName == 'RecordTypeId') {
                    fieldWrapper.fieldLabel = this.labels.LBL_Record_Type;
                }
                this.displayedFields.push(fieldWrapper);
            }
            this.firstThStyle = (this.displayedFields[0].headerStyle ? this.displayedFields[0].headerStyle : '') + 'text-align: center;';
            this.loadData();
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    loadData() {
        try {
            this.isLoading = true;
            this.records = [];
            loadData({
                gridSettings: JSON.stringify(this.initDataWrapper.gridSettingsManager),
                pageSize: this.pageSize,
                pageNumber: this.pageNumber
            }).then(result => {
                this.loadDataWrapper = JSON.parse(result) || [];
                console.log('this.loadDataWrapper :', JSON.stringify(this.loadDataWrapper));
                this.records = this.buildData(this.loadDataWrapper.records);
                console.log('this.records :', JSON.stringify(this.records));
                this.isLoading = false;

            }).catch(error => {
                this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
                console.log('loadData:', error?.message);
                console.log('loadData:', error?.body?.message);
                this.isLoading = false;
            });
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    buildData(data) {
        try {
            let records = [];
            for (let item of data) {
                let productWrapper = {
                    Name: item.Name,
                    Id: item.Id,
                    link: '/' + item.Id,
                    values: [],
                    rowColor: '',
                    firstTdStyle: '',
                    isSelected: this.selectedIds.has(item.Id)
                }
                for (let field of this.displayedFields) {
                    let fieldWrapper = {
                        ...field,
                        Id: item.Id,
                        fieldValue: '',
                        fieldOutputValue: '',
                        isNameField: field.fieldName == 'Name',
                        link: field.fieldName == 'Name' ? '/' + item.Id : '',
                        style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                    }
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let val = index == 0 ? item : fieldWrapper.fieldValue;
                        if (val) {
                            if (index == values.length - 1 && fieldWrapper.isReference) {
                                fieldWrapper.fieldOutputValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                fieldWrapper.link = '/' + val[values[index]];
                            } else if (index == values.length - 1 && fieldWrapper.fieldName.endsWith('RecordTypeId')) {
                                fieldWrapper.fieldValue = val[values[index].replace('Id', '')]?.Name;
                            } else {
                                fieldWrapper.fieldValue = val[values[index]];
                            }
                        }
                    }
                    if (fieldWrapper.isPicklist) {
                        for (let pickVal of field.pickListValues) {
                            if (fieldWrapper.fieldValue == pickVal.value) {
                                fieldWrapper.fieldOutputValue = pickVal.label;
                            }
                        }
                        productWrapper.rowColor += field.picklistColorsMap && fieldWrapper.fieldValue !== '' && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue) && field.picklistColorsMap[fieldWrapper.fieldValue] !== '' ? field.picklistColorsMap[fieldWrapper.fieldValue] : '';
                    }
                    productWrapper.values.push(fieldWrapper);
                }
                if (productWrapper.rowColor !== '') {
                        productWrapper.values.forEach(fieldWrapper => {
                            if (!fieldWrapper.style.includes('background-color')) {
                                fieldWrapper.style += `background-color:${productWrapper.rowColor};`;
                            }
                        });
                    }
                const lastStyle = productWrapper.values[productWrapper.values.length - 1]?.style || '';
                const match = lastStyle.match(/background-color\s*:\s*([^;]+)/i);
                productWrapper.firstTdStyle = match ? `background-color:${match[1].trim()};` : null;
                records.push(productWrapper);
            }
            return records;
        } catch (error) {
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
        }
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.loadDataWrapper.total ? this.pageNumber * pageSize + 1 - pageSize : this.loadDataWrapper.total - this.loadDataWrapper.records.length) + '-' + (this.pageNumber * pageSize > this.loadDataWrapper.total ? this.loadDataWrapper.total : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.loadDataWrapper.total;
    }

    get hasPagination() {
        return (this.initDataWrapper?.gridSettingsManager ? this.loadDataWrapper?.total > this.initDataWrapper?.gridSettingsManager?.Default_Page_Size : false) /* && !(this.initDataWrapper?.gridSettingsManager?.gridTypeValue == 'tree') */;
    }

    // Disables the 'Previous' page button
    get previousDisabled() {
        return this.pageNumber == 1;
    }

    // Disables the 'Next' page button (Salesforce limits query offset, often around 10k)
    get nextDisabled() {
        // Max records fetchable is 10k, so total pages is based on Math.min(total, 10000)
        let noOfRecords = this.loadDataWrapper.total > 10000 ? Math.ceil((10000 / this.pageSize)) : Math.ceil((this.loadDataWrapper.total / this.pageSize));
        return this.pageNumber >= noOfRecords;
    }

    // Handler for row checkbox change
    handleRowSelect(event) {
        const id = event.target.dataset.id;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedIds.add(id);
        } else {
            this.selectedIds.delete(id);
        }
        this.records = this.records.map(row => ({
            ...row,
            isSelected: this.selectedIds.has(row.Id)
        }));
        console.log('selectedIds :', JSON.stringify([...this.selectedIds]));
    }

    // Handles change in the number of records per page (page size).
    handlePageSize(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.isLoading = true;
        this.loadData();
    }

    handleChangePage(event) {
        this.isLoading = true;
        try {
            const type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.loadDataWrapper.total > 10000 ? Math.ceil((10000 / this.pageSize)) : Math.ceil((this.loadDataWrapper.total / this.pageSize));
            }
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    handleSave() {
        try {
            this.isLoading = true;
            const selectedIds = [...this.selectedIds];
            console.log(this.recordId)
            if (selectedIds.length === 0) {
                this.showNotification(this.labels.LBL_Error, 'Please select at least one product.', 'error');
                return;
            }
            ProductToPGBatch({
                supplierId: this.recordId,
                productIds: selectedIds
            }).then(result => {
                console.log(result)
                this.selectedIds.clear();
                this.loadData();
                this.showNotification(this.labels.LBL_Success, '', 'success');
            })
            // 👉 your logic here
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    get IsIdSelected() {
        return this.selectedIds.size == 0;
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}