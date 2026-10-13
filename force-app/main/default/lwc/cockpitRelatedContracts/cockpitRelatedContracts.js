import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initData from '@salesforce/apex/CockpitRelatedContractsController.initData';
import loadData from '@salesforce/apex/CockpitRelatedContractsController.loadData';
// Custom Labels
import LBL_Duplicate_Contarct from "@salesforce/label/c.LBL_Duplicate_Contarct";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Record_Type from "@salesforce/label/c.LBL_Record_Type";
import LBL_CockpitRelatedContracts_Title  from "@salesforce/label/c.LBL_CockpitRelatedContracts_Title";
import LBL_CockpitRelatedContracts_SubTitle  from "@salesforce/label/c.LBL_CockpitRelatedContracts_SubTitle";
import LBL_Actions from "@salesforce/label/c.LBL_Actions";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Duplicate_Contract from "@salesforce/label/c.LBL_Duplicate_Contract";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";


export default class CockpitRelatedContracts extends LightningElement {
    @api recordId;
    @api templateName;
    @track selectedYear;
    @track isDuplicateModalOpen = false;
    @track isLoading = true;
    @track mainData = {};
    @track loadDataWrapper = {};
    @track records = [];
    @track displayedFields = [];
    @track selectedContract;
    labels = {
        LBL_Duplicate_Contarct,
        LBL_Record_Type,
        LBL_CockpitRelatedContracts_Title,
        LBL_Error,
        LBL_CockpitRelatedContracts_SubTitle,
        LBL_Actions,
        LBL_No_Item_To_Display,
        LBL_Duplicate_Contract,
        LBL_Cancel
    }

    get years() {
        console.log('this.loadDataWrapper >>>> ' + JSON.stringify(this.loadDataWrapper));
        console.log('Object.keys(this.loadDataWrapper) >>>> ' + JSON.stringify(Object.keys(this.loadDataWrapper)));
        return (Object.keys(this.loadDataWrapper) || [])
            .map(year => {
                const isSelected = parseInt(year) === this.selectedYear;
                return {
                    year: year,
                    count: this.loadDataWrapper[year].length || 0,
                    isSelected,
                    tabClass: `yearCell ${isSelected ? 'selected' : ''}`,
                    badgeClass: `countBadge ${isSelected ? 'selected' : ''}`
                };
            });
    }

     // Header Style Getters
    get lastThStyle() {
        return(this.displayedFields ?? []).findLast(field => !field.isHidden)?.headerStyle + `width: 75px;min-width: 75px;max-width: 75px;`;
    }

    get filteredRows() {
        const group = (this.records || []).find(record => record.year === this.selectedYear);
        return group ? group.rows : [];
    }

    connectedCallback() {
        this.initData();
    }

    renderedCallback() {
        try {
            setTimeout(() => {
                this.popUpSize()
            }, 200);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.loading = true;
        }
    }

    popUpSize() {
        let popUpBodyDiv = this.template.querySelector(".popUpBody");
        if (!popUpBodyDiv) return;
        popUpBodyDiv.style.height = (window.innerHeight / 1.3) + "px";
    }

    initData() {
        try {
            this.isLoading = true;
            initData({ templateName: this.templateName })
                .then(result => {
                    this.mainData = JSON.parse(result);
                    console.log('🎧 ~ relatedContracts.js:83 -> mainData: ', JSON.stringify(this.mainData));
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
            for (let field of this.mainData?.gridSettingsManager?.GRID_FIELDS) {
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
            loadData({
                recordId: this.recordId,
                gridSettings: JSON.stringify(this.mainData.gridSettingsManager),
            }).then(result => {
                this.loadDataWrapper = JSON.parse(result) || [];
                console.log('🛬 ~ relatedContracts.js:115 -> parsed: ', JSON.stringify(this.loadDataWrapper));
                this.records = this.buildGroups(this.loadDataWrapper);
                console.log('🤩 ~ cockpitRelatedContracts.js:132 -> records: ', JSON.stringify(this.records));
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

    buildGroups(data) {
        try {
            const groups = Object.entries(data).map(([yearKey, records]) => {
                const year = Number(yearKey);
                const count = records.length
                const rows = this.buildData(records)
                return { year, count, rows };
            });
            if (this.selectedYear == null && groups.length) {
                this.selectedYear = groups[groups.length - 1].year;
            }
            this.isLoading = false;
            return groups;
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('buildGroups: %c' + error.message, 'color : red');
            console.log('buildGroups: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    buildData(data) {
        try {
            let records = [];
            for (let item of data) {
                let contractWrapper = {
                    Name: item.Name,
                    Id: item.Id,
                    link: '/' + item.Id,
                    values: [],
                    rowColor: '',
                    lastTdStyle: '',
                }
                for (let field of this.displayedFields) {
                    let fieldWrapper = {
                        Id: item.Id,
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldValue: '',
                        fieldOutputValue: '',
                        isNumberField: field.isNumberField,
                        isReference: field.isReference,
                        isNameField: field.fieldName == 'Name',
                        isDate: field.isDate,
                        isDateTime: field.isDateTime,
                        isPicklist: field.isPicklist,
                        isBoolean: field.isBoolean,
                        isTextarea: field.isTextarea,
                        isText: field.isText,
                        link: field.fieldName == 'Name' ? '/' + item.Id : '',
                        scale: field.scale,
                        step: field.step,
                        isInputField: field.isInputField,
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
                        contractWrapper.rowColor += field.picklistColorsMap && fieldWrapper.fieldValue !== '' && field.picklistColorsMap.hasOwnProperty(fieldWrapper.fieldValue) && field.picklistColorsMap[fieldWrapper.fieldValue] !== '' ? field.picklistColorsMap[fieldWrapper.fieldValue] : '';
                    }
                    contractWrapper.values.push(fieldWrapper);
                }
                this.applyRowStyle(contractWrapper);
                records.push(contractWrapper);
            }
            return records;
        } catch (error) {
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
        }
    }

    applyRowStyle(contractWrapper) {
        if (contractWrapper.values && contractWrapper.values.length > 0) {
            for (const fieldWrapper of contractWrapper.values) {
                if (contractWrapper.rowColor !== '') {
                    fieldWrapper.style = this.setStyleProp(fieldWrapper.style, 'background-color', contractWrapper.rowColor)
                }
            }
            contractWrapper.lastTdStyle = this.getStyleProp(contractWrapper.values[contractWrapper.values.length - 1].style, 'background-color');
        }
    }

    setStyleProp(style, prop, value) {
        const regex = new RegExp(`${prop}\\s*:\\s*[^;]+`, 'i');
        if (regex.test(style)) {
            return style.replace(regex, `${prop}: ${value}`);
        }
        return style + `${prop}: ${value};`;
    }

    getStyleProp(style, prop) {
        const regex = new RegExp(`${prop}\\s*:\\s*([^;]+)`, 'i');
        const match = style.match(regex);
        return match ? (prop + ':' + match[1].trim() + ';') : null;
    }

    handleYearChange(event) {
        const year = Number(event.currentTarget.dataset.year);
        this.selectedYear = year;
    }

    handleActions(event) {
        const contractId = event.currentTarget.dataset.id;
        const componentName = this.mainData.prefix ? this.mainData.prefixx.replace('__', ':') : 'c:' + event.currentTarget.dataset.componentName;
        let url = `/apex/${this.mainData.prefix ?? ''}NegoptimNavigator?c__componentName=${componentName}&a__recordId=${contractId}`;
        window.open(url, '_blank');
    }

    handleOpenDuplicate(event) {
        let sourceId = event.currentTarget.dataset.id;
        this.selectedContract = Object.values(this.loadDataWrapper)
            .flat()
            .find(r => (r.Id ?? r.id) === sourceId);
        if (!this.selectedContract) {
            this.showNotification(LBL_Error, 'Couldnt find Contract', 'error');
            return;
        }
        this.togglePopupDuplicate();
    }

    togglePopupDuplicate() {
        this.isDuplicateModalOpen = !this.isDuplicateModalOpen;
    }

    handleDuplicate() {
        const child = this.template.querySelector('c-duplicate-contract');
        if (!child) return;
        child.handleSave();
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}