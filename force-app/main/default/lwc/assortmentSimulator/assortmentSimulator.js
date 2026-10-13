import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import loadData from '@salesforce/apex/AssortmentSimulatorController.loadData';

import Assortment__OBJECT from '@salesforce/schema/Assortment__c';
import AssortmentNegotiationRef__c from "@salesforce/schema/Assortment__c.AssortmentNegotiationRef__c";
import Version__c from "@salesforce/schema/Assortment__c.Version__c";
import OnTop__c from "@salesforce/schema/Assortment__c.OnTop__c";
import IsBreakingScenario__c from "@salesforce/schema/Assortment__c.IsBreakingScenario__c";

import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Compare_Bloc from "@salesforce/label/c.LBL_Compare_Bloc";
import LBL_Compare_Detail from "@salesforce/label/c.LBL_Compare_Detail";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Of from "@salesforce/label/c.LBL_Of";

export default class AssortmentSimulator extends NavigationMixin(LightningElement) {

    @api displayDataBasedOnBU;
    @api recordId;
    @track loading = false;
    @track pageSize = '10';
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPagesCount = 1;
    @track displayEvolutionArrows = true;
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '75', value: '75' },
        { label: '100', value: '100' }
    ];
    @track wiresIsDone = {
        objectInfoAS: false
    }
    ASFields = {};
    prefix;
    @wire(getObjectInfo, { objectApiName: Assortment__OBJECT }) objectInfoAS({ error, data }) {
        if (data) {
            this.labels.Assortment__c.label = data.label;
            this.ASFields = data.fields;
            this.labels.Name = this.ASFields['Name'].label;
            this.labels.simulationVersionOnTopBreakingScenario =
                this.ASFields[Version__c.fieldApiName].label + ' + ' +
                this.ASFields[OnTop__c.fieldApiName].label + ' + ' +
                this.ASFields[IsBreakingScenario__c.fieldApiName].label;
            this.wiresIsDone.objectInfoAS = true;
            this.checkWireIsDone();
        } else if (error) {
            console.log('error >> ' + JSON.stringify(error))
            this.showNotification('ERROR', error, 'ERROR');
        }
    }
    checkWireIsDone() {
        if (this.wiresIsDone.objectInfoAS) {
            this.loadData();
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }
    @track displayedFields = [];
    @track records = [];
    @track headerName = '';

    @track labels = {
        LBL_No_Item_To_Display,
        LBL_Compare_Bloc,
        LBL_Compare_Detail,
        LBL_First,
        LBL_Previous,
        LBL_Next,
        LBL_Last,
        LBL_Of,
        Name: '',
        simulationVersionOnTopBreakingScenario: '',
        Assortment__c: {
            label: '',
        },
    }

    get previousDisabled() {
        return this.pageNumber <= 1;
    }
    get nextDisabled() {
        return this.pageNumber >= this.totalPagesCount;
    }
    get paginationBadge() {
        let ps = parseInt(this.pageSize);
        let start = this.totalRecords === 0 ? 0 : (this.pageNumber - 1) * ps + 1;
        let end = Math.min(this.pageNumber * ps, this.totalRecords);
        return start + '-' + end + ' ' + this.labels.LBL_Of + ' ' + this.totalRecords;
    }

    get colspan() {
        return this.displayedFields.length + 2;
    }
    connectedCallback() {
    }

    renderedCallback() {
        this.setnumberOfFixedColumns();
    }

    resulstW;
    loadData() {
        this.loading = true;
        loadData({
            recordId: this.recordId,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            displayDataBasedOnBU: this.displayDataBasedOnBU
        }).then((result) => {
            let parsedResult = JSON.parse(result);
            this.prefix = parsedResult.prefix || '';
            this.resulstW = parsedResult;
            this.totalRecords = parsedResult.totalSize || 0;
            this.totalPagesCount = Math.ceil(this.totalRecords / parseInt(this.pageSize)) || 1;
            this.headerName = parsedResult.headerName;
            this.displayEvolutionArrows = parsedResult.displayEvolutionArrows;
            this.displayedFields = [];
            for (let kpi of parsedResult.kpiSetup || []) {
                if (!kpi.fields) continue;
                for (let field of kpi.fields) {
                    if (!field) continue;
                    if (!this.ASFields[field]) continue;
                    this.displayedFields.push({
                        fieldName: field,
                        fieldLabel: this.ASFields[field].label,
                        fieldType: this.ASFields[field].dataType.toUpperCase(),
                        scale: this.ASFields[field].scale,
                        style: {
                            header: `background-color:${kpi.backgroundColor};color:${kpi.textColor}; min-width:100px; width:100px; max-width:100px;`,
                            cell: this.getCellStyleFromGradient(kpi.backgroundColor) + 'min-width: 100px; width: 100px; max-width: 100px; white-space: pre-wrap; word-break: break-word;'
                        }
                    });
                }
            }
            let records = [];
            for (let record of parsedResult.assortmentList) {
                records.push(this.buildAS(record));
            }
            this.records = records;
            this.loading = false;
        }).catch(error => {
            console.log('error load data');
            console.error(error);
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }

    getCellStyleFromGradient(backgroundColor) {
        const match = backgroundColor.match(/#([0-9a-fA-F]{6})/g);
        if (!match || match.length === 0) return '';
        const baseColor = match[match.length - 1];
        return `background-color: ${baseColor}22;`;
    }

    buildAS(record) {
        let wAS = {
            Id: record.Id,
            Name: record.Name,
            link: '/' + record.Id,
            version: record[Version__c.fieldApiName],
            isOnTop: record[OnTop__c.fieldApiName],
            isBreakingScenario: record[IsBreakingScenario__c.fieldApiName],
            screenURL: '',
            hasNegoReference: record[AssortmentNegotiationRef__c.fieldApiName],
            rowClass: record.Id === this.recordId ? 'current-assortment-row' : '',
            fields: []
        }
        for (let field of this.displayedFields) {
            let fieldW = {
                fieldName: field.fieldName,
                fieldValue: record[field.fieldName],
                isNumber: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY',
                isBoolean: field.fieldType == 'BOOLEAN',
                scale: field.scale,
                isIncrease: false,
                showArrow: false,
                style: '',
            }
            if (fieldW.isNumber) {
                fieldW.fieldValue = fieldW.fieldValue == null ? 0 : fieldW.fieldValue;
                if (wAS.hasNegoReference && this.displayEvolutionArrows) {
                    let negoRefValue = record[AssortmentNegotiationRef__c.fieldApiName.replace('__c', '__r')][field.fieldName] ?? 0;
                    fieldW.showArrow = fieldW.fieldValue != negoRefValue;
                    fieldW.isIncrease = fieldW.fieldValue > negoRefValue;
                }
            }
            fieldW.isText = !fieldW.isNumber && !fieldW.isBoolean;
            fieldW.style = fieldW.isNumber ? (this.displayEvolutionArrows ? 'padding: 0 !important;text-align:right;' : 'text-align:right;') : '';
            fieldW.style += field.style.cell;

            switch (fieldW.fieldType) {
                case "REFERENCE":
                    fieldW.fieldValue = record[field.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                    break;
            }
            wAS.fields.push(fieldW);
        }
        return wAS;
    }

    OpenASDSimulatorMatrix() {
        window.open('/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentDetailSimulator&a__recordId=' + this.recordId + '&a__isBloc=true&a__headerName=' + this.headerName + '&a__displayDataBasedOnBU=' + this.displayDataBasedOnBU);
    }

    OpenASDSimulatorDetailMatrix() {
        window.open('/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentDetailSimulator&a__recordId=' + this.recordId + '&a__headerName=' + this.headerName + '&a__displayDataBasedOnBU=' + this.displayDataBasedOnBU);
    }
    openScreen(event) {
        let assortmentId = event.target.dataset.assortmentId;
        let index = event.target.dataset.index;
        let url = '';
        if (this.resulstW.assortmentList[index].RecordType.DeveloperName == 'ChannelBudget') {
            url = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentChannelBudget&a__recordId=' + assortmentId;
        } else {
            url = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + assortmentId;
            //url = '/apex/AssortmentMatrixExt?id=' + assortmentId + '&showSubtotal=true';
        }
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    handleChangePageSize(event) {
        this.pageSize = String(event.detail.value);
        this.pageNumber = 1;
        this.loadData();
    }

    handleChangePage(event) {
        let type = event.target.dataset.type;
        if (type === 'Previous') this.pageNumber--;
        else if (type === 'Next') this.pageNumber++;
        else if (type === 'First') this.pageNumber = 1;
        else if (type === 'Last') this.pageNumber = this.totalPagesCount;
        this.loadData();
    }

    setnumberOfFixedColumns() {
        let nbOfFixedColumns = 3;
        let table = this.template.querySelector('.main-table');
        if (!table) return;
        let tableTrs = table.rows;
        for (let index = 0; tableTrs && index < tableTrs.length; index++) {
            let childrens = tableTrs[index].children;
            let left = 0;
            for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                if (index2 < nbOfFixedColumns) {
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.left = left + 'px';
                    childrens[index2].style.zIndex = index == 0 ? 5 : 3;
                    left += childrens[index2].offsetWidth;
                    // keep background color
                    childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '#fff';
                } else {
                    childrens[index2].style.position = 'unset';
                    childrens[index2].style.left = 'unset';
                    childrens[index2].style.zIndex = 'unset';
                }
            }
        }
    }

    // show notification 
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}