import { LightningElement, api, track } from 'lwc';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initData from '@salesforce/apex/CockpitAdvancedRelatedContractsCtrl.initData';
import loadData from '@salesforce/apex/CockpitAdvancedRelatedContractsCtrl.loadData';
//Custom labels
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Record_Type from "@salesforce/label/c.LBL_Record_Type";
import LBL_Advanced from "@salesforce/label/c.LBL_Advanced";
import LBL_Actions from "@salesforce/label/c.LBL_Actions";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_ControlledContracts_Title  from "@salesforce/label/c.LBL_ControlledContracts_Title";
import LBL_ControlledContracts_SubTitle  from "@salesforce/label/c.LBL_ControlledContracts_SubTitle";
import LBL_CockpitRelatedContracts_Title  from "@salesforce/label/c.LBL_CockpitRelatedContracts_Title";
import LBL_CockpitRelatedContracts_SubTitle2  from "@salesforce/label/c.LBL_CockpitRelatedContracts_SubTitle2";
import LBL_Sibling_Contracts  from "@salesforce/label/c.LBL_Sibling_Contracts";
import showNotification  from "c/appHelper";

export default class CockpitAdvancedRelatedContracts extends LightningElement {
    @api recordId;
    @api gridLayout;
    @track isLoading = false;
    @track isAdvanced = false;
    @track mainData = {};
    @track records = [];
    @track displayedFields = [];
    @track labels = {
        LBL_Record_Type,
        LBL_Error,
        LBL_ControlledContracts_Title,
        LBL_ControlledContracts_SubTitle,
        LBL_CockpitRelatedContracts_Title,
        LBL_CockpitRelatedContracts_SubTitle2,
        LBL_No_Item_To_Display,
        LBL_Advanced,
        LBL_Sibling_Contracts,
        LBL_Actions
    }

    // Header Style Getters
  get lastThStyle() {
      return(this.displayedFields ?? []).findLast(field => !field.isHidden)?.headerStyle + `width: 75px;min-width: 75px;max-width: 75px;`;
  }
  
    connectedCallback() {
       this.initData();
    }

    initData() {
        try{
            this.isLoading = true;
            initData({recordId: this.recordId})
            .then(result => {
                this.mainData = JSON.parse(result);
                console.log('this.mainData>>> ' + JSON.stringify(this.mainData.gridSettingsManager.GRID_FIELDS));
                this.isAdvanced = this.mainData.isAdvanced;
                this.buildDisplayedFields();
            }).catch(error => {
                showNotification(this, this.labels.LBL_Error, error, 'error');
                console.log('initData %c' + error.message, 'color : red');
                console.log('initData %c' + error.body?.message, 'color : red');
                this.isLoading = false;
            })        
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error, 'error');
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
            showNotification(this, this.labels.LBL_Error, error, 'error');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    loadData() {
        try {
            this.records = [];
            this.isLoading = true;
            loadData({
                recordId: this.recordId,
                gridSettings: JSON.stringify(this.mainData.gridSettingsManager),
                isAdvanced : this.isAdvanced
            }).then(result => {
                let parsedResult = JSON.parse(result);
                console.log('🎂 ~ listContract.js:43 -> parsedResult: ', JSON.stringify(parsedResult));
                this.records = this.buildData(parsedResult);
                console.log('🚀 ~ cockpitAdvancedRelatedContracts.js:113 ->  this.records: ',  JSON.stringify(this.records));
            }).catch(error => {
                console.log('loadData: %c' + error.message, 'color : red');
                console.log('loadData: %c' + error.body?.message, 'color : red');
                this.isLoading = false;
            })
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error, 'error');
            console.log('loadData: %c' + error.message, 'color : red');
            console.log('loadData: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    buildData(data) {
        try {
            const isSingle = (data || []).length === 1;
            let result = (data || []).map(item => {
                const id = item.advancedContract?.Id;
                const isExpanded = this.isAdvanced || isSingle;
                return {
                    Id: id,
                    name: item.advancedContract?.Name,
                    url: `/${id}`,
                    siblingText: `${(item.records || []).length} siblings`,
                    isExpanded: isExpanded,
                    showChevron: !isSingle && item.records.length > 0,
                    rowClass: `masterRow slds-p-around--medium ${isExpanded ? 'masterRow_active' : ''}`,
                    chevronIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                    chevronClass: `chevronCircle ${isExpanded ? 'chevronCircle_active' : ''}`,
                    shieldClass: `slds-badge slds-shrink-none slds-m-right_x-small ${isExpanded ? 'rc-advancedPillCompact_active' : 'rc-advancedPillCompact'}`,
                    siblingClass: `slds-badge slds-theme_shade slds-shrink-none slds-m-left_x-small ${isExpanded ? 'siblingBadge' : ''}`,
                    rows: this.buildRow(item.records)
                };
            });
            this.isLoading = false;
            return result;
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error, 'error');
            console.log('buildGroups: %c' + error.message, 'color : red');
            console.log('buildGroups: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    buildRow(data) {
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
                        ...field,
                        Id: item.Id,
                        fieldValue: '',
                        fieldOutputValue: '',
                        isNameField: field.fieldName == 'Name',
                        link: field.fieldName == 'Name' ? `/${item.Id}`: '',
                        pickListValues: [],
                        style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                    }
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let val = index == 0 ? item : fieldWrapper.fieldValue;
                        if (val) {
                            if (index == values.length - 1 && (fieldWrapper.isReference)) {
                                fieldWrapper.fieldOutputValue = val[values[index].trim().replace(/__c$/, '__r').replace('Id', '')]?.Name;
                                fieldWrapper.link = '/' + val[values[index]];
                            } else if (index == values.length - 1 && fieldWrapper.fieldName.endsWith('RecordTypeId')) {
                                fieldWrapper.fieldValue = val[values[index].replace('Id', '')]?.Name;
                            }
                            else {
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
                if (contractWrapper.rowColor !== '') {
                        contractWrapper.values.forEach(fieldWrapper => {
                            if (!fieldWrapper.style.includes('background-color')) {
                                fieldWrapper.style += `background-color:${contractWrapper.rowColor};`;
                            }
                        });
                    }
                const lastStyle = contractWrapper.values[contractWrapper.values.length - 1]?.style || '';
                const match = lastStyle.match(/background-color\s*:\s*([^;]+)/i);
                contractWrapper.lastTdStyle = match ? `background-color:${match[1].trim()};` : null;
                records.push(contractWrapper);
            }
            return records;
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error, 'error');
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
            this.isLoading = false;
        }
    }

    toggleAdvancedContracts(event) {
        const clickedId = event.currentTarget.dataset.id;
        console.log('🛢️ ~ listContract.js:122 -> clickedId: ', clickedId);
        let temp = this.records.map(record => {
            const shouldExpand = (record.Id === clickedId) ? !record.isExpanded : false;
            return {
                ...record,
                isExpanded: shouldExpand,
                chevronIcon: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright',
                rowClass: `masterRow slds-p-around--medium ${shouldExpand ? 'masterRow_active' : ''}`,
                chevronClass: `chevronCircle ${shouldExpand ? 'chevronCircle_active' : ''}`,
                shieldClass: `slds-badge slds-shrink-none slds-m-right_x-small ${shouldExpand ? 'rc-advancedPillCompact_active' : 'rc-advancedPillCompact'}`,
                siblingClass: `slds-badge slds-theme_shade slds-shrink-none slds-m-left_x-small ${shouldExpand ? 'siblingBadge' : ''}`,
                
            };
        });
        this.records = temp;
    }

    handleConditionManager(event) {
        const contractId = event.currentTarget.dataset.id;
        console.log('💻 ~ listContract.js:141 -> contractId: ', contractId);
        let url =`/apex/${this.mainData.prefix ?? ''}NegoptimNavigator?c__componentName=${(this.mainData.prefix ? this.mainData.prefix.replace('__', ':') : 'c:')}conditionManager&a__recordId=${contractId}`;
        const a = document.createElement('a');
        a.href = url;
        a.target = '_blank';
        a.click();
    }
}